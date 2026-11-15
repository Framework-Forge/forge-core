-- Explicit Forge surface for an external PR adapter. Internal core services never call this adapter back.
local paths={
    GetPlayer='Lookup.GetPlayer',GetPlayerByCitizenId='Lookup.GetPlayerByCitizenId',GetOfflinePlayer='Players.GetOfflinePlayer',
    GetStatus='Producers.Status.Exports.GetStatus',SetStatus='Producers.Status.Exports.SetStatus',AddStatus='Producers.Status.Exports.AddStatus',
    HasPermission='Lifecycle.Functions.Exports.HasPermission',CreateUseableItem='Lifecycle.Functions.Exports.CreateUseableItem',
    SetJob='Players.SetJob',SetJobDuty='Players.SetJobDuty',AddPlayerToJob='Players.AddPlayerToJob',
    RemovePlayerFromJob='Players.RemovePlayerFromJob',SetPlayerPrimaryJob='Players.SetPlayerPrimaryJob',
    AddPlayerToGang='Players.AddPlayerToGang',RemovePlayerFromGang='Players.RemovePlayerFromGang',SetPlayerPrimaryGang='Players.SetPlayerPrimaryGang',
    GetMoney='Players.GetMoney',AddMoney='Players.AddMoney',RemoveMoney='Players.RemoveMoney'}
return function(graph,ports)
    local pc=assert(graph.PlayerCore);local owner,ready=assert(ports.isCurrent),assert(ports.isReady)
    assert(graph.State=='prepared-inactive'and graph.Base.DomainAssembly==graph,'canonical Forge graph required')
    assert(graph.Base.PlayerCore==pc,'shared PlayerCore required')
    local phase,pending='open',0;local refs={};local api={OperationalReady=false,Core={}}
    local function resolve(path)
        local object,parent=pc
        for part in path:gmatch('[^.]+')do parent=object;object=assert(object[part],'missing Forge backend '..path)end
        return object,parent
    end
    for name,path in pairs(paths)do
        local fn,parent=resolve(path);assert(type(fn)=='function','Forge backend function required: '..name)
        refs[name]={path=path,fn=fn,parent=parent}
    end
    local function canonical()
        if phase~='open'or graph.State~='prepared-inactive'or graph.PlayerCore~=pc or graph.Base.PlayerCore~=pc
            or graph.Base.DomainAssembly~=graph or graph.Base.ServerAssembly~=graph.Central
            or graph.Central.State~='prepared-inactive'or graph.Base.Callbacks~=graph.Security then return false end
        local ok,value=pcall(owner);if not ok or value~=true then return false end
        for _,ref in pairs(refs)do local found,value,parent=pcall(resolve,ref.path);if not found or value~=ref.fn or parent~=ref.parent then return false end end
        return true
    end
    for name,ref in pairs(refs)do api.Core[name]=function(...)
        assert(canonical(),'forge_framework_backend_replaced')
        pending=pending+1;local args=table.pack(...)
        local result=table.pack(pcall(function()
            local ok,value=pcall(ready);assert(ok and value==true,'forge_framework_backend_unready')
            assert(canonical(),'forge_framework_backend_replaced')
            return ref.fn(table.unpack(args,1,args.n))
        end));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end end
    function api.Describe()local out={};for name,path in pairs(paths)do out[name]=path end;return out end
    function api.IsCurrent()return canonical()end
    function api.Close()phase='closed';return true end
    function api.Progress()return{phase=phase,pending=pending,complete=phase=='closed'and pending==0}end
    return api
end
