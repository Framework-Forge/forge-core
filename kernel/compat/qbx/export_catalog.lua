-- Exact installed QBX export surface; inert references into the single prepared Forge graph.
local entries={
    {side='server',source='server/character_slots.lua',name='GetCharacterSlotSettings',path='PlayerCore.Characters.Slots.Exports.GetCharacterSlotSettings'},
    {side='server',source='server/character_slots.lua',name='SetCharacterSlotSettings',path='PlayerCore.Characters.Slots.Exports.SetCharacterSlotSettings'},
    {side='server',source='server/character_slots.lua',name='GetCharacterSlotState',path='PlayerCore.Characters.Slots.Exports.GetCharacterSlotState'},
    {side='server',source='server/character_slots.lua',name='CanUnlockCharacterSlots',path='PlayerCore.Characters.Slots.Exports.CanUnlockCharacterSlots'},
    {side='server',source='server/character_slots.lua',name='UnlockCharacterSlots',path='PlayerCore.Characters.Slots.Exports.UnlockCharacterSlots'},
    {side='server',source='server/character_slots.lua',name='SetCharacterSlotUnlocked',path='PlayerCore.Characters.Slots.Exports.SetCharacterSlotUnlocked'},
    {side='server',source='server/functions.lua',name='GetSource',path='PlayerCore.Lookup.GetSource'},
    {side='server',source='server/functions.lua',name='GetUserId',path='PlayerCore.Lookup.GetUserId'},
    {side='server',source='server/functions.lua',name='GetPlayer',path='PlayerCore.Lookup.GetPlayer'},
    {side='server',source='server/functions.lua',name='GetPlayerByCitizenId',path='PlayerCore.Lookup.GetPlayerByCitizenId'},
    {side='server',source='server/functions.lua',name='GetPlayerByUserId',path='PlayerCore.Lookup.GetPlayerByUserId'},
    {side='server',source='server/functions.lua',name='GetPlayerByPhone',path='PlayerCore.Lookup.GetPlayerByPhone'},
    {side='server',source='server/functions.lua',name='GetQBPlayers',path='PlayerCore.Lookup.GetQBPlayers'},
    {side='server',source='server/functions.lua',name='GetDutyCountJob',path='PlayerCore.Lookup.GetDutyCountJob'},
    {side='server',source='server/functions.lua',name='GetDutyCountType',path='PlayerCore.Lookup.GetDutyCountType'},
    {side='server',source='server/functions.lua',name='GetBucketObjects',path='PlayerCore.Lifecycle.Functions.Exports.GetBucketObjects'},
    {side='server',source='server/functions.lua',name='SetPlayerBucket',path='PlayerCore.Lifecycle.Functions.Exports.SetPlayerBucket'},
    {side='server',source='server/functions.lua',name='SetEntityBucket',path='PlayerCore.Lifecycle.Functions.Exports.SetEntityBucket'},
    {side='server',source='server/functions.lua',name='GetPlayersInBucket',path='PlayerCore.Lifecycle.Functions.Exports.GetPlayersInBucket'},
    {side='server',source='server/functions.lua',name='GetEntitiesInBucket',path='PlayerCore.Lifecycle.Functions.Exports.GetEntitiesInBucket'},
    {side='server',source='server/functions.lua',name='CreateUseableItem',path='PlayerCore.Lifecycle.Functions.Exports.CreateUseableItem'},
    {side='server',source='server/functions.lua',name='CanUseItem',path='PlayerCore.Lifecycle.Functions.Exports.CanUseItem'},
    {side='server',source='server/functions.lua',name='IsWhitelisted',path='PlayerCore.Lifecycle.Functions.Exports.IsWhitelisted'},
    {side='server',source='server/functions.lua',name='AddPermission',path='PlayerCore.Lifecycle.Functions.Exports.AddPermission'},
    {side='server',source='server/functions.lua',name='RemovePermission',path='PlayerCore.Lifecycle.Functions.Exports.RemovePermission'},
    {side='server',source='server/functions.lua',name='HasPermission',path='PlayerCore.Lifecycle.Functions.Exports.HasPermission'},
    {side='server',source='server/functions.lua',name='GetPermission',path='PlayerCore.Lifecycle.Functions.Exports.GetPermission'},
    {side='server',source='server/functions.lua',name='IsOptin',path='PlayerCore.Lifecycle.Functions.Exports.IsOptin'},
    {side='server',source='server/functions.lua',name='ToggleOptin',path='PlayerCore.Lifecycle.Functions.Exports.ToggleOptin'},
    {side='server',source='server/functions.lua',name='IsPlayerBanned',path='PlayerCore.Lifecycle.Functions.Exports.IsPlayerBanned'},
    {side='server',source='server/functions.lua',name='Notify',path='PlayerCore.Lifecycle.Functions.Exports.Notify'},
    {side='server',source='server/functions.lua',name='GetCoreVersion',path='PlayerCore.Lifecycle.Functions.Exports.GetCoreVersion'},
    {side='server',source='server/functions.lua',name='ExploitBan',path='PlayerCore.Lifecycle.Functions.Exports.ExploitBan'},
    {side='server',source='server/functions.lua',name='HasPrimaryGroup',path='PlayerCore.Lifecycle.Functions.Exports.HasPrimaryGroup'},
    {side='server',source='server/functions.lua',name='HasGroup',path='PlayerCore.Lifecycle.Functions.Exports.HasGroup'},
    {side='server',source='server/functions.lua',name='GetGroups',path='PlayerCore.Lifecycle.Functions.Exports.GetGroups'},
    {side='server',source='server/functions.lua',name='GetPlayersData',path='PlayerCore.Lifecycle.Functions.Exports.GetPlayersData'},
    {side='server',source='server/functions.lua',name='SearchPlayers',path='PlayerCore.Lifecycle.Functions.Exports.SearchPlayers'},
    {side='server',source='server/functions.lua',name='IsGradeBoss',path='PlayerCore.Lifecycle.Functions.Exports.IsGradeBoss'},
    {side='server',source='server/functions.lua',name='GetGroupMembers',path='PlayerCore.Lifecycle.Functions.Exports.GetGroupMembers'},
    {side='server',source='server/functions.lua',name='DeleteVehicle',path='PlayerCore.Lifecycle.Functions.Exports.DeleteVehicle'},
    {side='server',source='server/groups.lua',name='CreateJob',path='PlayerCore.Groups.CreateJob'},
    {side='server',source='server/groups.lua',name='CreateJobs',path='PlayerCore.Groups.CreateJobs'},
    {side='server',source='server/groups.lua',name='RemoveJob',path='PlayerCore.Groups.RemoveJob'},
    {side='server',source='server/groups.lua',name='CreateGangs',path='PlayerCore.Groups.CreateGangs'},
    {side='server',source='server/groups.lua',name='RemoveGang',path='PlayerCore.Groups.RemoveGang'},
    {side='server',source='server/groups.lua',name='GetJobs',path='PlayerCore.Groups.GetJobs'},
    {side='server',source='server/groups.lua',name='GetGangs',path='PlayerCore.Groups.GetGangs'},
    {side='server',source='server/groups.lua',name='GetJob',path='PlayerCore.Groups.GetJob'},
    {side='server',source='server/groups.lua',name='GetGang',path='PlayerCore.Groups.GetGang'},
    {side='server',source='server/groups.lua',name='UpsertJobData',path='PlayerCore.Groups.UpsertJobData'},
    {side='server',source='server/groups.lua',name='UpsertGangData',path='PlayerCore.Groups.UpsertGangData'},
    {side='server',source='server/groups.lua',name='UpsertJobGrade',path='PlayerCore.Groups.UpsertJobGrade'},
    {side='server',source='server/groups.lua',name='UpsertGangGrade',path='PlayerCore.Groups.UpsertGangGrade'},
    {side='server',source='server/groups.lua',name='RemoveJobGrade',path='PlayerCore.Groups.RemoveJobGrade'},
    {side='server',source='server/groups.lua',name='RemoveGangGrade',path='PlayerCore.Groups.RemoveGangGrade'},
    {side='server',source='server/main.lua',name='CreateSessionId',path='PlayerCore.Runtime.Main.Exports.CreateSessionId'},
    {side='server',source='server/main.lua',name='GetVehicleClass',path='PlayerCore.Runtime.Main.Exports.GetVehicleClass'},
    {side='server',source='server/main.lua',name='SetVehicles',path='PlayerCore.Runtime.Main.Exports.SetVehicles'},
    {side='server',source='server/main.lua',name='SetVehicleCatalog',path='PlayerCore.Runtime.Main.Exports.SetVehicleCatalog'},
    {side='server',source='server/main.lua',name='GetVehiclesByName',path='PlayerCore.Runtime.Main.Exports.GetVehiclesByName'},
    {side='server',source='server/main.lua',name='GetVehiclesByHash',path='PlayerCore.Runtime.Main.Exports.GetVehiclesByHash'},
    {side='server',source='server/main.lua',name='GetVehiclesByCategory',path='PlayerCore.Runtime.Main.Exports.GetVehiclesByCategory'},
    {side='server',source='server/main.lua',name='GetWeapons',path='PlayerCore.Runtime.Main.Exports.GetWeapons'},
    {side='server',source='server/main.lua',name='GetLocations',path='PlayerCore.Runtime.Main.Exports.GetLocations'},
    {side='server',source='server/player.lua',name='Login',path='PlayerCore.Players.Login'},
    {side='server',source='server/player.lua',name='GetOfflinePlayer',path='PlayerCore.Players.GetOfflinePlayer'},
    {side='server',source='server/player.lua',name='SetJob',path='PlayerCore.Players.SetJob'},
    {side='server',source='server/player.lua',name='SetJobDuty',path='PlayerCore.Players.SetJobDuty'},
    {side='server',source='server/player.lua',name='SetPlayerPrimaryJob',path='PlayerCore.Players.SetPlayerPrimaryJob'},
    {side='server',source='server/player.lua',name='AddPlayerToJob',path='PlayerCore.Players.AddPlayerToJob'},
    {side='server',source='server/player.lua',name='RemovePlayerFromJob',path='PlayerCore.Players.RemovePlayerFromJob'},
    {side='server',source='server/player.lua',name='SetGang',path='PlayerCore.Players.SetGang'},
    {side='server',source='server/player.lua',name='SetPlayerPrimaryGang',path='PlayerCore.Players.SetPlayerPrimaryGang'},
    {side='server',source='server/player.lua',name='AddPlayerToGang',path='PlayerCore.Players.AddPlayerToGang'},
    {side='server',source='server/player.lua',name='RemovePlayerFromGang',path='PlayerCore.Players.RemovePlayerFromGang'},
    {side='server',source='server/player.lua',name='Logout',path='PlayerCore.Players.Logout'},
    {side='server',source='server/player.lua',name='CreatePlayer',path='PlayerCore.Players.CreatePlayer'},
    {side='server',source='server/player.lua',name='Save',path='PlayerCore.Players.Save'},
    {side='server',source='server/player.lua',name='SaveOffline',path='PlayerCore.Players.SaveOffline'},
    {side='server',source='server/player.lua',name='SaveAllPlayers',path='PlayerCore.Players.SaveAllPlayers'},
    {side='server',source='server/player.lua',name='SetPlayerData',path='PlayerCore.Players.SetPlayerData'},
    {side='server',source='server/player.lua',name='UpdatePlayerData',path='PlayerCore.Players.UpdatePlayerData'},
    {side='server',source='server/player.lua',name='SetMetadata',path='PlayerCore.Players.SetMetadata'},
    {side='server',source='server/player.lua',name='GetMetadata',path='PlayerCore.Players.GetMetadata'},
    {side='server',source='server/player.lua',name='SetCharInfo',path='PlayerCore.Players.SetCharInfo'},
    {side='server',source='server/player.lua',name='AddMoney',path='PlayerCore.Players.AddMoney'},
    {side='server',source='server/player.lua',name='RemoveMoney',path='PlayerCore.Players.RemoveMoney'},
    {side='server',source='server/player.lua',name='SetMoney',path='PlayerCore.Players.SetMoney'},
    {side='server',source='server/player.lua',name='GetMoney',path='PlayerCore.Players.GetMoney'},
    {side='server',source='server/player.lua',name='DeleteCharacter',path='PlayerCore.Players.DeleteCharacter'},
    {side='server',source='server/player.lua',name='GenerateUniqueIdentifier',path='PlayerCore.Players.GenerateUniqueIdentifier'},
    {side='server',source='server/session.lua',name='IsPlayerLoaded',path='PlayerCore.Producers.Session.Exports.IsPlayerLoaded'},
    {side='server',source='server/session.lua',name='GetCachedState',path='PlayerCore.Producers.Session.Exports.GetCachedState'},
    {side='server',source='server/status.lua',name='GetStatus',path='PlayerCore.Producers.Status.Exports.GetStatus'},
    {side='server',source='server/status.lua',name='GetStatusSnapshot',path='PlayerCore.Producers.Status.Exports.GetStatusSnapshot'},
    {side='server',source='server/status.lua',name='SetStatus',path='PlayerCore.Producers.Status.Exports.SetStatus'},
    {side='server',source='server/status.lua',name='AddStatus',path='PlayerCore.Producers.Status.Exports.AddStatus'},
    {side='server',source='server/status.lua',name='AddStatuses',path='PlayerCore.Producers.Status.Exports.AddStatuses'},
    {side='server',source='server/vehicle-persistence.lua',name='EnablePersistence',path='Parts.Vehicles.Helpers.Persistence.Exports.EnablePersistence'},
    {side='server',source='server/vehicle-persistence.lua',name='DisablePersistence',path='Parts.Vehicles.Helpers.Persistence.Exports.DisablePersistence'},
    {side='server',source='server/weapons.lua',name='CreateWeapons',path='PlayerCore.Runtime.Weapons.Exports.CreateWeapons'},
    {side='server',source='server/weapons.lua',name='RemoveWeapon',path='PlayerCore.Runtime.Weapons.Exports.RemoveWeapon'},
    {side='server',source='server/weapons.lua',name='GetManagedWeapons',path='PlayerCore.Runtime.Weapons.Exports.GetManagedWeapons'},
    {side='server',source='server/weapons.lua',name='HasWeapon',path='PlayerCore.Runtime.Weapons.Exports.HasWeapon'},
    {side='client',source='client/bridge-cache.lua',name='PublishClientContext',path='Central.Parts.Producers.Cache.Exports.PublishClientContext'},
    {side='client',source='client/bridge-cache.lua',name='RefreshClientContext',path='Central.Parts.Producers.Cache.Exports.RefreshClientContext'},
    {side='client',source='client/functions.lua',name='Notify',path='Central.Parts.Legacy.Functions.Exports.Notify'},
    {side='client',source='client/functions.lua',name='GetPlayerData',path='Central.Parts.Legacy.Functions.Exports.GetPlayerData'},
    {side='client',source='client/functions.lua',name='HasPrimaryGroup',path='Central.Parts.Legacy.Functions.Exports.HasPrimaryGroup'},
    {side='client',source='client/functions.lua',name='HasGroup',path='Central.Parts.Legacy.Functions.Exports.HasGroup'},
    {side='client',source='client/functions.lua',name='GetGroups',path='Central.Parts.Legacy.Functions.Exports.GetGroups'},
    {side='client',source='client/groups.lua',name='GetJobs',path='Central.Parts.Legacy.Groups.Exports.GetJobs'},
    {side='client',source='client/groups.lua',name='GetGangs',path='Central.Parts.Legacy.Groups.Exports.GetGangs'},
    {side='client',source='client/groups.lua',name='GetJob',path='Central.Parts.Legacy.Groups.Exports.GetJob'},
    {side='client',source='client/groups.lua',name='GetGang',path='Central.Parts.Legacy.Groups.Exports.GetGang'},
    {side='client',source='client/main.lua',name='GetVehiclesByName',path='Central.Parts.Runtime.Main.Exports.GetVehiclesByName'},
    {side='client',source='client/main.lua',name='GetVehiclesByHash',path='Central.Parts.Runtime.Main.Exports.GetVehiclesByHash'},
    {side='client',source='client/main.lua',name='GetVehiclesByCategory',path='Central.Parts.Runtime.Main.Exports.GetVehiclesByCategory'},
    {side='client',source='client/main.lua',name='GetWeapons',path='Central.Parts.Runtime.Main.Exports.GetWeapons'},
    {side='client',source='client/main.lua',name='GetLocations',path='Central.Parts.Runtime.Main.Exports.GetLocations'},
    {side='client',source='client/session.lua',name='IsPlayerLoaded',path='Central.Parts.Producers.Session.Exports.IsPlayerLoaded'},
    {side='client',source='client/session.lua',name='GetCachedState',path='Central.Parts.Producers.Session.Exports.GetCachedState'},
    {side='client',source='client/status.lua',name='GetStatus',path='Central.Parts.Producers.Status.Exports.GetStatus'},
    {side='client',source='client/status.lua',name='GetStatusSnapshot',path='Central.Parts.Producers.Status.Exports.GetStatusSnapshot'},
    {side='client',source='client/status.lua',name='SetStatus',path='Central.Parts.Producers.Status.Exports.SetStatus'},
    {side='client',source='client/status.lua',name='AddStatus',path='Central.Parts.Producers.Status.Exports.AddStatus'},
    {side='client',source='client/status.lua',name='AddStatuses',path='Central.Parts.Producers.Status.Exports.AddStatuses'},
    {side='client',source='client/status.lua',name='FlushStatusSnapshot',path='Central.Parts.Producers.Status.Exports.FlushStatusSnapshot'},
}

return function(graph,side,ports)
    assert(side=='server'or side=='client','explicit QBX compatibility side required')
    local owner=assert(ports.isCurrent);local list,refs,seen={},{},{}
    local function resolve(path)
        local value=graph;for key in path:gmatch('[^.]+')do value=assert(value[key],'missing canonical export path '..path)end;return value
    end
    local function ref(path)local value=resolve(path);refs[#refs+1]={path=path,value=value};return value end
    local root=side=='server'and assert(graph.Base)or assert(graph.Core)
    assert(graph.State=='prepared-inactive','prepared graph required')
    if side=='server'then
        assert(root.DomainAssembly==graph and root.PlayerCore==graph.PlayerCore,'canonical server graph required')
        for _,path in ipairs({'PlayerCore','PlayerCore.State','PlayerCore.State.Players','PlayerCore.Shared','PlayerCore.Groups'})do ref(path)end
    else
        assert(root.ClientDomainAssembly==graph and graph.IsCanonical(),'canonical client graph required')
        ref('Core');ref('Central')
    end
    for _,entry in ipairs(entries)do if entry.side==side then
        assert(not seen[entry.name],'duplicate native QBX export');seen[entry.name]=true
        local fn=ref(entry.path);assert(type(fn)=='function','export function required')
        list[#list+1]={name=entry.name,path=entry.path,source=entry.source,handler=fn}
    end end
    table.sort(list,function(a,b)return a.name<b.name end)
    local api={OperationalReady=false,Side=side,Count=#list};local closed=false
    local function canonical()
        if closed then return false end
        local ok,value=pcall(owner);if not ok or value~=true then return false end
        if side=='server'then
            if root.DomainAssembly~=graph or root.PlayerCore~=graph.PlayerCore then return false end
        elseif root.ClientDomainAssembly~=graph or not graph.IsCanonical()then return false end
        for _,r in ipairs(refs)do local good,v=pcall(resolve,r.path);if not good or v~=r.value then return false end end;return true
    end
    function api.Describe()
        local out={};for i,e in ipairs(list)do out[i]={name=e.name,path=e.path,source=e.source}end;return out
    end
    function api.Resolve(name)
        assert(canonical(),'qbx_export_graph_changed')
        for _,entry in ipairs(list)do if entry.name==name then return entry.handler end end
        error('unsupported_qbx_export: '..tostring(name),0)
    end
    function api.IsCurrent()return canonical()end
    function api.Close()closed=true;return true end
    return api
end
