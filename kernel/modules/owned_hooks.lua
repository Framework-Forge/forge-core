-- Owned facade for the unchanged internal06 registry, never the inventory's hook registry.
local createHooks=require 'kernel.modules.hooks'
return function(ports)
    local raw=createHooks(assert(ports.hooks));local current=assert(ports.isCurrent)
    assert(#raw.Events==1 and raw.Events[1].name=='onResourceStop','unique local hook cleanup required')
    local cleanup=raw.Events[1].handler
    local phase,entered,total='prepared',0,0;local ledger={}
    local api={Hooks={}}
    local function live()local ok,value=pcall(current);return phase=='open'and ok and value==true end
    local function owner(cb)local ok,value=pcall(function()return cb.resource end);if ok then return value end end
    local function clear()
        local seen={};local nilOwner={}
        for _,r in ipairs(ledger)do
            local resource=owner(r.callback);local key=resource;if key==nil then key=nilOwner end
            if not seen[key]then cleanup(resource);seen[key]=true end
        end
        if entered==0 then ledger={}end
    end
    local function invoke(fn,...)
        if not live()then return nil,'hooks_scope_closed'end
        entered=entered+1;local result=table.pack(pcall(fn,...));entered=entered-1
        if phase=='closed'then clear()end
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Hooks.registerHook(event,cb)
        return invoke(function()
            -- Record before the native caller lookup can yield/reenter Close.
            ledger[#ledger+1]={callback=cb};local id=raw.registerHook(event,cb);total=total+1;return id
        end)
    end
    function api.Hooks.removeHooks(...)return invoke(raw.removeHooks,...)end
    function api.Hooks.trigger(...)return invoke(raw.trigger,...)end
    function api.ResourceStopped(resource)return invoke(cleanup,resource)end
    function api.CheckDependencies()return raw.CheckDependencies()end
    function api.Open()if phase~='prepared'or not current()then return false end;phase='open';return true end
    function api.Close()phase='closed';clear();return true end
    function api.Progress()return{phase=phase,pending=entered,registrations=total,complete=phase=='closed'and entered==0}end
    return api
end
