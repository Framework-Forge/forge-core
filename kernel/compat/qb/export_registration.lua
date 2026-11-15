-- Private QB export protocol binding over existing51/53 registries. No Cfx globals or automatic installation.
local createEvents=require 'kernel.shared.event_registration'
local createPublic=require 'kernel.shared.public_registration'
return function(bridge,ports)
    assert(ports.side=='server'or ports.side=='client','explicit QB export side required')
    local callbacks=assert(bridge.Exports);local resources=bridge.ResourceExports or{}
    local phase,busy,pending,attempted,closing='prepared',false,0,false,false
    local refs,names,resourceNames={},{},{}
    for name,fn in pairs(callbacks)do assert(type(name)=='string'and type(fn)=='function');names[#names+1]=name;refs['qb:'..name]=fn end
    for name,fn in pairs(resources)do assert(type(name)=='string'and type(fn)=='function');resourceNames[#resourceNames+1]=name;refs['resource:'..name]=fn end
    table.sort(names);table.sort(resourceNames)
    local api={OperationalReady=false,Counts={aliases=#names,exports=#resourceNames}}
    local function current()
        if closing or phase=='closed'or phase=='close-failed'or phase=='install-failed'or bridge.Exports~=callbacks
            or (bridge.ResourceExports or resources)~=resources then return false end
        local count=0
        for name,fn in pairs(callbacks)do if refs['qb:'..name]~=fn then return false end;count=count+1 end
        for name,fn in pairs(resources)do if refs['resource:'..name]~=fn then return false end;count=count+1 end
        if count~=#names+#resourceNames then return false end
        local ok,value=pcall(ports.isCurrent);if not ok or value~=true then return false end
        local ok,value=pcall(bridge.IsCurrent);return ok and value==true
    end
    assert(current(),'current QB bridge required')
    local function invoke(fn,...)
        if phase~='installed'or not current()then return end
        pending=pending+1
        local result=table.pack(pcall(fn,...));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    local eventEntries,publicEntries={},{}
    for _,name in ipairs(ports.externalAliases and{}or names)do
        local fn=callbacks[name]
        local callback=function(...)return invoke(fn,...)end
        eventEntries[#eventEntries+1]={owner='QBExports.'..name,name='__cfx_export_qb-core_'..name,network=false,sourceFirst=false,
            handler=function(setCB)invoke(function()setCB(callback)end)end}
    end
    for _,name in ipairs(resourceNames)do
        local fn=resources[name];publicEntries[#publicEntries+1]={kind='export',owner='QBResourceExports.'..name,name=name,
            handler=function(...)return invoke(fn,...)end}
    end
    local holder={};local eventPorts={}
    for key,value in pairs(assert(ports.events))do eventPorts[key]=value end
    eventPorts.listen=function(name,handler)
        assert(ports.aliasAvailable(name)==true,'QB alias changed before registration: '..name)
        assert(current(),'QB bridge changed before registration')
        return ports.events.listen(name,handler)
    end
    local events=createEvents({owner=holder,side=ports.side,entries=eventEntries,isCurrent=current},eventPorts)
    local public=createPublic({owner=holder,side=ports.side,entries=publicEntries,isCurrent=current},assert(ports.public))
    local function cleanup()
        local a,ea=events.Dispose();local b,eb=public.Dispose()
        a=a or ea=='already_disposed';b=b or eb=='already_revoked'
        phase=a and b and'closed'or'close-failed'
        return a and b,{events=ea,public=eb}
    end
    function api.Describe()return{aliases=events.Describe(),public=public.Describe()}end
    function api.Install()
        if busy or attempted or phase~='prepared'then return false,'installation_not_repeatable'end
        if bridge.Enabled~=true then return false,'qb_bridge_disabled'end
        if not current()then return false,'qb_bridge_replaced'end
        busy=true
        local ok,problem=pcall(function()
            for _,d in ipairs(eventEntries)do
                assert(ports.aliasAvailable(d.name)==true,'foreign QB export alias: '..d.name)
                assert(current(),'QB bridge changed during preflight')
            end
            for _,d in ipairs(publicEntries)do
                assert(ports.public.available('export',d.name)==true,'foreign QB resource export: '..d.name)
                assert(current(),'QB bridge changed during preflight')
            end
        end)
        busy=false
        if not ok then if closing then cleanup()end;return false,problem end
        if closing then cleanup();return false,'closed_during_preflight'end
        attempted=true;busy=true;phase='installing'
        local ok,problem=pcall(function()
            local accepted,why=public.Install();assert(accepted,why)
            local accepted,why=events.Install();assert(accepted,why)
            assert(current(),'QB bridge changed before commit')
        end)
        busy=false
        if not ok then closing=true;local clean,failures=cleanup();return false,problem,failures end
        phase='installed';return true
    end
    function api.Dispose()
        closing=true
        if busy then return false,'operation_in_progress'end
        return cleanup()
    end
    api.Close=api.Dispose
    function api.Progress()return{phase=phase,pending=pending,busy=busy,complete=phase=='closed'and pending==0 and not busy}end
    function api.IsCurrent()return current()end
    return api
end
