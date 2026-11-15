-- Installed custom OX items/hooks and PR adapter. All exports/platform/effects stay in memory.
local T=dofile('tests/kernel_server_startup_harness.lua');local I=dofile('tests/kernel_inventory_harness.lua')
local H=T.H;local P={H=H,T=T,I=I}
function P.new()
    local r={items=I.oxItems(),hooks={},refs={},post={},events={},removals={},caller='forge-core',executing='forge-core',ready=true,current=true}
    local env=H.environment({pr_lib={cache={resource='ox_inventory'}},GetInvokingResource=function()return r.caller end,
        os={microtime=function()return 0 end},shared={info=function()end},server={},warn=function()end,
        exports=function(name,fn)r.hooks[name]=fn end,AddEventHandler=function(name,fn)r.events[name]=fn end,
        SetTimeout=function(ms,fn)assert(ms==50);r.post[#r.post+1]=fn end,
        TriggerEvent=function(...)if r.onPost then r.onPost(...)end end})
    r.triggerRaw=H.load('../../../[ox]/ox_inventory/modules/hooks/server.lua',env)
    r.proxy={}
    for name,fn in pairs(r.items.exports)do r.proxy[name]=function(_,...)return fn(...)end end
    r.proxy.Items=function(_,name)return r.items.exports.Items(name)end
    r.proxy.registerHook=function(_,name,fn,options)
        -- Cfx export boundary supplies a callable reference, not a plain Lua function.
        local ref=setmetatable({},{__call=function(_,...)return fn(...)end});r.refs[#r.refs+1]=ref
        local token=r.hooks.registerHook(name,ref,options)
        if r.afterRegister then r.afterRegister(token)end;return token
    end
    r.proxy.removeHooks=function(_,id)
        assert(id~=nil,'no broad owner removal');r.removals[#r.removals+1]=id
        if r.removeError then error('virtual remove failure')end
        if r.removeFalse then return false,'refused'end
        return r.hooks.removeHooks(id)
    end
    r.library=H.load('../pr_bridge/bridge/inventories/ox/server.lua',H.environment({exports={ox_inventory=r.proxy},ActiveBridges={inventory='ox'},
        Debug=function()end,Lang={t=function(_,k)return k end},Bridge={framework=setmetatable({},{__index=function()error('framework cycle')end})}}))
    r.create=H.load('../pr_bridge/bridge/inventories/ox/forge_provider.lua',H.environment())
    r.ports={owner='forge-core',inventory=r.library,custom=r.proxy,isCurrent=function()return r.current end,
        resourceState=function(name)assert(name=='ox_inventory');return r.ready and'started'or'stopped'end,
        executingResource=function()return r.executing end}
    function r.mount()r.api=r.create(r.ports);return r.api end
    function r.trigger(name,payload,success)
        local result <close> = r.triggerRaw(name,payload or{})
        if result.success and success==false then result.success=false end;return result
    end
    function r.flush()local list=r.post;r.post={};for _,fn in ipairs(list)do fn()end end
    function r.foreign(name,fn,owner)
        local prior=r.caller;r.caller=owner or'foreign';local id=r.proxy:registerHook(name,fn);r.caller=prior;return id
    end
    return r
end
function P.context()
    local r=T.new();r.inventory=P.new();local i=r.inventory;local f=r.fixture
    r.invPorts={startup=r.startPorts,inventory=i.ports,createInventoryProvider=i.create}
    local env=T.T.W.D.R.env();env.print=function(...)f.central.record('print',...)end
    r.invFactory=H.load('kernel/server/inventory_context.lua',env)
    function r.prepareInventory()r.api=r.invFactory(f.base,r.invPorts);r.graph=r.api.Graph;i.api=r.api.Inventory;return r.api end
    function r.inventoryInstall()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return P
