-- Private coordination of QB registrations93/94 over one existing graph. No public activation or core shutdown.
local createExports=require 'kernel.compat.qb.export_registration'
local createEvents=require 'kernel.compat.qb.event_registration'
return function(graph,bridge,backend,ports)
    local side=assert(ports.side)
    assert(side=='client'or side=='server','explicit QB binding side required')
    local root=assert(side=='client'and graph.Core or graph.Base)
    local state=assert(side=='client'and root or graph.PlayerCore.State)
    local core=assert(root.EventRegistration,'existing core event registry required')
    assert(core.Side==side and backend.State==state and backend.Shared==state.Shared,'QB backend must belong to this core')
    assert(bridge.CompatBindingContext==nil,'QB binding context already owned')
    if bridge.Enabled~=true then
        local disabled={OperationalReady=false,Enabled=false,CoreRegistry=core};local closed=false
        bridge.CompatBindingContext=disabled
        function disabled.Install()return false,'qb_bridge_disabled'end
        function disabled.Close()bridge.Close();backend.Close();closed=true;return true end
        disabled.Dispose=disabled.Close;disabled.Poll=disabled.Close
        function disabled.Progress()return{phase=closed and'closed'or'disabled',complete=closed and bridge.Progress().complete and backend.Progress().complete}end
        function disabled.IsCurrent()return not closed and bridge.CompatBindingContext==disabled end
        function disabled.Describe()return{exports={},events={}}end
        return disabled
    end
    local getter,closeBridge=assert(bridge.GetCoreObject),assert(bridge.Close)
    local phase,busy,closing,attempted='constructing',false,false,false
    local api={OperationalReady=false,CoreRegistry=core,Bridge=bridge}
    bridge.CompatBindingContext=api
    local function current()
        if closing or phase=='closed'or bridge.CompatBindingContext~=api or bridge.GetCoreObject~=getter
            or bridge.Close~=closeBridge or root.EventRegistration~=core or backend.State~=state
            or backend.Shared~=state.Shared or graph.State~='prepared-inactive'then return false end
        if side=='client'then
            if graph.Core~=root or root.ClientDomainAssembly~=graph or root.ClientAssembly~=graph.Central then return false end
            local ok,value=pcall(graph.IsCanonical);if not ok or value~=true then return false end
        else
            if graph.Base~=root or root.DomainAssembly~=graph or root.ServerAssembly~=graph.Central or root.PlayerCore~=graph.PlayerCore then return false end
        end
        local ok,value=pcall(ports.isCurrent);if not ok or value~=true then return false end
        local ok,value=pcall(backend.IsCurrent);if not ok or value~=true then return false end
        local ok,value=pcall(bridge.IsCurrent);return ok and value==true
    end
    assert(current(),'canonical QB binding graph required')
    local function ingress(fn)return function(...)
        if phase~='installed'or not current()then return end
        return fn(...)
    end end
    local eventPorts,publicPorts={},{}
    for k,v in pairs(assert(ports.events))do eventPorts[k]=v end
    for k,v in pairs(assert(ports.public))do publicPorts[k]=v end
    eventPorts.listen=function(name,fn)return ports.events.listen(name,ingress(fn))end
    publicPorts.publishExport=function(name,fn)return ports.public.publishExport(name,ingress(fn))end
    local exportPorts={externalAliases=ports.externalAliases==true,side=side,events=eventPorts,public=publicPorts,
        aliasAvailable=assert(ports.aliasAvailable),isCurrent=current}
    local aliases=createExports(bridge,exportPorts)
    local events=createEvents(bridge,core,{side=side,events=eventPorts,isCurrent=current})
    api.Exports,api.Events=aliases,events
    phase='prepared'
    local function progress()
        local a,e,b,k=aliases.Progress(),events.Progress(),bridge.Progress(),backend.Progress()
        local complete=closing and not busy and a.complete and e.complete and b.complete and k.complete
        if complete then phase='closed'end
        return{phase=phase,busy=busy,exports=a,events=e,bridge=b,backend=k,complete=complete}
    end
    local function cleanup()
        closing=true;phase='closing'
        local results={}
        for _,entry in ipairs({{'events',events.Dispose},{'exports',aliases.Dispose},{'bridge',closeBridge},{'backend',backend.Close}})do
            local outcome=table.pack(pcall(entry[2]));results[entry[1]]=outcome
        end
        return progress().complete,results
    end
    function api.Install()
        if attempted or busy or phase~='prepared'then return false,'installation_not_repeatable'end
        if core.State~='installed'then return false,'core_events_not_installed'end
        if not current()then return false,'core_or_bridge_replaced'end
        attempted=true;busy=true;phase='installing'
        local ok,problem=pcall(function()
            assert(ports.isReady()==true,'QB binding not ready');assert(current(),'QB binding changed before identity check')
            local object=getter()
            assert(current(),'QB binding changed during identity check')
            assert(type(object)=='table'and type(object.Shared)=='table'and object.Shared.Vehicles==state.Shared.Vehicles
                and object.Shared.Weapons==state.Shared.Weapons,'QB object catalog belongs to another core')
            if side=='server'then
                assert(object.Players==state.Players and object.Player_Buckets==state.Player_Buckets
                    and object.Entity_Buckets==state.Entity_Buckets and object.UsableItems==state.UsableItems,'QB object state belongs to another core')
            else
                local data=object.Functions.GetPlayerData()
                assert(current(),'QB binding changed during PlayerData proof')
                assert(data==backend.Core.GetPlayerData(),'QB PlayerData belongs to another core')
                assert(current(),'QB binding changed after PlayerData proof')
            end
            local accepted,why=aliases.Install();assert(accepted,why)
            local accepted,why=events.Install();assert(accepted,why)
            assert(current(),'QB binding changed before commit')
        end)
        busy=false
        if not ok then local clean,details=cleanup();return false,problem,details end
        phase='installed';return true
    end
    function api.Close()return cleanup()end
    api.Dispose=api.Close
    function api.Poll()if not closing then return false,'not_closing'end;return cleanup()end
    function api.IsCurrent()return current()end
    function api.Progress()return progress()end
    function api.Describe()return{exports=aliases.Describe(),events=events.Describe()}end
    return api
end
