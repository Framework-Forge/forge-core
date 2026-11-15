-- Private QB client backend over the existing locale75/domain50/central49 graph; no second state.
return function(graph,ports)
    local state,central=assert(graph.Core),assert(graph.Central)
    local configOwner=assert(state.ClientConfigurationContext)
    local configClient=assert(configOwner.Config.Client)
    local sharedConfig=assert(ports.sharedConfig,'explicit prepared shared config06 required')
    local importsOwner=assert(state.ClientRuntimeImportContext)
    local imports=assert(importsOwner.Imports);local cache=assert(imports.NativeCache)
    local helpers=assert(central.Parts.Helpers);local lib=assert(helpers.Lib)
    local legacy=assert(central.Parts.Legacy);local functions,groups=legacy.Functions,legacy.Groups
    local phase,pending='open',0
    local api={OperationalReady=false,Core={},State=state,Shared=state.Shared,Helpers=lib,NativeCache=cache,
        Config={Client=configClient,Shared=sharedConfig}}
    local refs={{graph,'Central',central},{central,'Config',central.Config},{central,'Parts',central.Parts},
        {ports,'sharedConfig',sharedConfig},{configOwner,'Config',configOwner.Config},
        {central.Config,'Client',configClient},{state,'ClientConfigurationContext',configOwner},
        {configOwner.Config,'Client',configClient},{state,'ClientRuntimeImportContext',importsOwner},
        {importsOwner,'Imports',imports},{imports,'NativeCache',cache},{central.Parts,'Helpers',helpers},
        {helpers,'Lib',lib},{central.Parts,'Legacy',legacy},{legacy,'Functions',functions},{legacy,'Groups',groups},
        {functions,'GetPlayerData',functions.GetPlayerData},{functions,'Notify',functions.Notify},
        {groups,'GetJobs',groups.GetJobs},{groups,'GetGangs',groups.GetGangs},
        {configClient,'hasKeys',configClient.hasKeys},{sharedConfig,'starterItems',sharedConfig.starterItems},
        {sharedConfig,'defaultSpawn',sharedConfig.defaultSpawn},{sharedConfig,'notifyPosition',sharedConfig.notifyPosition}}
    local function current()
        if phase~='open'or graph.State~='prepared-inactive'or state.ClientDomainAssembly~=graph or state.ClientAssembly~=central
            or central.State~='prepared-inactive'or central.Core~=state or state.Shared~=api.Shared then return false end
        local ok,value=pcall(graph.IsCanonical);if not ok or value~=true then return false end
        for _,ref in ipairs(refs)do if ref[1][ref[2]]~=ref[3]then return false end end
        local ok,value=pcall(ports.isCurrent);return ok and value==true
    end
    assert(current(),'canonical QB client graph required')
    local handlers={GetPlayerData=functions.GetPlayerData,Notify=functions.Notify,GetJobs=groups.GetJobs,GetGangs=groups.GetGangs}
    for name,fn in pairs(handlers)do
        assert(type(fn)=='function','canonical client service required: '..name)
        api.Core[name]=function(...)
            assert(current(),'qb_client_backend_replaced')
            pending=pending+1;local args=table.pack(...)
            local result=table.pack(pcall(function()
                assert(ports.isReady()==true,'qb_client_backend_unready');assert(current(),'qb_client_backend_replaced')
                return fn(table.unpack(args,1,args.n))
            end));pending=pending-1
            if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
        end
    end
    function api.IsCurrent()return current()end
    function api.Close()phase='closed';return true end
    function api.Progress()return{phase=phase,pending=pending,complete=phase=='closed'and pending==0}end
    return api
end
