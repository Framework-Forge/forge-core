-- Private canonical QB server backend; no resource lookup or PR.framework callback.
local paths={GetSource='Lookup.GetSource',GetPlayer='Lookup.GetPlayer',GetPlayerByCitizenId='Lookup.GetPlayerByCitizenId',GetPlayerByPhone='Lookup.GetPlayerByPhone',GetQBPlayers='Lookup.GetQBPlayers',GetDutyCountJob='Lookup.GetDutyCountJob',Login='Players.Login',Logout='Players.Logout',Save='Players.Save',SaveOffline='Players.SaveOffline',CreatePlayer='Players.CreatePlayer',GetOfflinePlayer='Players.GetOfflinePlayer',DeleteCharacter='Players.DeleteCharacter',GenerateUniqueIdentifier='Players.GenerateUniqueIdentifier',GetBucketObjects='Lifecycle.Functions.Exports.GetBucketObjects',SetPlayerBucket='Lifecycle.Functions.Exports.SetPlayerBucket',SetEntityBucket='Lifecycle.Functions.Exports.SetEntityBucket',GetPlayersInBucket='Lifecycle.Functions.Exports.GetPlayersInBucket',GetEntitiesInBucket='Lifecycle.Functions.Exports.GetEntitiesInBucket',CreateUseableItem='Lifecycle.Functions.Exports.CreateUseableItem',CanUseItem='Lifecycle.Functions.Exports.CanUseItem',IsWhitelisted='Lifecycle.Functions.Exports.IsWhitelisted',AddPermission='Lifecycle.Functions.Exports.AddPermission',RemovePermission='Lifecycle.Functions.Exports.RemovePermission',HasPermission='Lifecycle.Functions.Exports.HasPermission',GetPermission='Lifecycle.Functions.Exports.GetPermission',IsOptin='Lifecycle.Functions.Exports.IsOptin',ToggleOptin='Lifecycle.Functions.Exports.ToggleOptin',IsPlayerBanned='Lifecycle.Functions.Exports.IsPlayerBanned',Notify='Lifecycle.Functions.Exports.Notify',GetCoreVersion='Lifecycle.Functions.Exports.GetCoreVersion',GetJob='Groups.GetJob',GetJobs='Groups.GetJobs',GetGang='Groups.GetGang',GetGangs='Groups.GetGangs',CreateJobs='Groups.CreateJobs',CreateGangs='Groups.CreateGangs',RemoveJob='Groups.RemoveJob',RemoveGang='Groups.RemoveGang'}
return function(graph,ports)
    local base,pc=assert(graph.Base),assert(graph.PlayerCore)
    local configOwner=assert(base.ServerConfigurationContext)
    local config=assert(configOwner.Config);local helpers=assert(base.Helpers);local lib=assert(helpers.Lib)
    local state,shared=pc.State,pc.Shared
    local phase,pending='open',0;local refs={}
    local api={OperationalReady=false,Core={},State=state,Shared=shared,Helpers=lib,Config=config}
    local function resolve(path)
        local value,parent=pc
        for key in path:gmatch('[^.]+')do parent=value;value=assert(value[key],'missing canonical QB service: '..path)end
        return value,parent
    end
    local anchors={{pc,'State',state},{pc,'Shared',shared},{state,'Players',state.Players},{state,'Player_Buckets',state.Player_Buckets},
        {state,'Entity_Buckets',state.Entity_Buckets},{state,'UsableItems',state.UsableItems},{base,'Shared',shared},
        {base,'Groups',pc.Groups},{base,'Helpers',helpers},{helpers,'Lib',lib},{base,'ServerConfigurationContext',configOwner},
        {configOwner,'Config',config},{config,'Server',config.Server},{config,'Shared',config.Shared}}
    for name,path in pairs(paths)do local fn,parent=resolve(path);assert(type(fn)=='function',path);refs[name]={path=path,fn=fn,parent=parent}end
    local function current()
        if phase~='open'or graph.State~='prepared-inactive'or graph.PlayerCore~=pc or base.PlayerCore~=pc
            or base.DomainAssembly~=graph or base.ServerAssembly~=graph.Central or base.Callbacks~=graph.Security
            or graph.Central.State~='prepared-inactive' then return false end
        for _,ref in ipairs(anchors)do if ref[1][ref[2]]~=ref[3]then return false end end
        for _,ref in pairs(refs)do local ok,fn,parent=pcall(resolve,ref.path);if not ok or fn~=ref.fn or parent~=ref.parent then return false end end
        local ok,owned=pcall(ports.isCurrent);return ok and owned==true
    end
    assert(current(),'canonical QB graph required')
    for name,ref in pairs(refs)do api.Core[name]=function(...)
        assert(current(),'qb_backend_replaced');pending=pending+1;local args=table.pack(...)
        local result=table.pack(pcall(function()
            assert(ports.isReady()==true,'qb_backend_unready');assert(current(),'qb_backend_replaced')
            return ref.fn(table.unpack(args,1,args.n))
        end));pending=pending-1
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end end
    function api.IsCurrent()return current()end
    function api.Close()phase='closed';return true end
    function api.Progress()return{phase=phase,pending=pending,complete=phase=='closed'and pending==0}end
    function api.Describe()local out={};for name,path in pairs(paths)do out[name]=path end;return out end
    return api
end
