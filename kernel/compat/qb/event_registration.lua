-- Bind only QB events after the existing core event registry. Preserve distinct installed listeners, not a serial multiplexer.
local createEvents=require 'kernel.shared.event_registration'
return function(bridge,core,ports)
    local side=assert(ports.side)
    assert((side=='client'or side=='server')and core.Side==side,'matching existing core event side required')
    assert(bridge.CompatEventRegistration==nil,'QB event registration already owned')
    local descriptors=assert(bridge.Events);local describe=assert(core.Describe)
    local coreEntries=describe();local coreNames,coreNetwork={},{}
    for _,d in ipairs(coreEntries)do
        coreNames[d.name]=(coreNames[d.name]or 0)+1
        if d.network then coreNetwork[d.name]=true end
    end
    local phase,pending,busy,closing,attempted='prepared',0,false,false,false
    local api={OperationalReady=false,Count=#descriptors,Core=core}
    bridge.CompatEventRegistration=api
    local refs,entries={},{}
    local function current()
        if closing or phase=='closed'or phase=='close-failed'or bridge.CompatEventRegistration~=api
            or bridge.Events~=descriptors or core.Describe~=describe or core.Side~=side
            or (core.State~='installed'and core.State~='prepared-inactive')or #descriptors~=#refs then return false end
        for i,r in ipairs(refs)do
            local d=descriptors[i]
            if d~=r.descriptor or d.name~=r.name or d.handler~=r.handler or d.network~=r.network or d.sourceFirst~=r.sourceFirst then return false end
        end
        local ok,value=pcall(ports.isCurrent);if not ok or value~=true then return false end
        local ok,value=pcall(bridge.IsCurrent);return ok and value==true
    end
    local function invoke(fn,...)
        if phase~='installed'or core.State~='installed'or not current()then return end
        pending=pending+1
        local result=table.pack(pcall(fn,...));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    for i,d in ipairs(descriptors)do
        assert(type(d.name)=='string'and type(d.handler)=='function'and type(d.network)=='boolean','explicit QB event required')
        refs[i]={descriptor=d,name=d.name,handler=d.handler,network=d.network,sourceFirst=d.sourceFirst}
        local fn=d.handler
        entries[i]={owner='QBEvents.'..d.name,name=d.name,network=d.network,
            sourceFirst=side=='server'and d.sourceFirst==true or false,handler=function(...)return invoke(fn,...)end}
    end
    assert(current(),'current core/bridge required')
    local eventPorts={};for k,v in pairs(assert(ports.events))do eventPorts[k]=v end
    eventPorts.markNetwork=function(name)
        if coreNetwork[name]then return true end
        return ports.events.markNetwork(name)
    end
    local registry=createEvents({owner={},side=side,entries=entries,isCurrent=current},eventPorts)
    function api.Describe()
        local list=registry.Describe()
        for _,d in ipairs(list)do d.coreHandlers=coreNames[d.name]or 0;d.policy='preserve_distinct_handlers'end
        return list
    end
    function api.Install()
        if busy or attempted or phase~='prepared'then return false,'installation_not_repeatable'end
        if bridge.Enabled~=true then return false,'qb_bridge_disabled'end
        if core.State~='installed'then return false,'core_events_not_installed'end
        if not current()then return false,'core_or_bridge_replaced'end
        attempted=true;busy=true;phase='installing'
        local result=table.pack(pcall(registry.Install));busy=false
        if closing then registry.Dispose();phase=registry.State=='disposed'and'closed'or'close-failed';return false,'closed_during_install'end
        if not result[1]or not result[2]then closing=true;registry.Dispose();phase=registry.State=='disposed'and'closed'or'close-failed'
            return false,result[1]and result[3]or result[2]end
        phase='installed';return true
    end
    function api.Dispose()
        closing=true
        if busy then return false,'operation_in_progress'end
        local ok,why=registry.Dispose();ok=ok or why=='already_disposed'
        phase=ok and'closed'or'close-failed';return ok,why
    end
    api.Close=api.Dispose
    function api.IsCurrent()return current()end
    function api.Progress()return{phase=phase,pending=pending,busy=busy,complete=phase=='closed'and pending==0 and not busy}end
    return api
end
