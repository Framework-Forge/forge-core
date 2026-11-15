local create=require 'kernel.shared.public_registration'
return function(graph,ports)
    local base,pc,central,security=assert(graph.Base),assert(graph.PlayerCore),assert(graph.Central),assert(graph.Security)
    assert(graph.State=='prepared-inactive'and base.DomainAssembly==graph and base.PlayerCore==pc,'canonical server48 required')
    local entries,callbacks,refs={}, {}, {}
    local function resolve(path)local value=graph;for key in path:gmatch('[^.]+')do value=assert(value[key],path)end;return value end
    local function module(path)
        local value=resolve(path);refs[#refs+1]={path=path,value=value};return value
    end
    local function export(path,name,fn)entries[#entries+1]={kind='export',owner=path,name=name,handler=assert(fn)}end
    local session=module('PlayerCore.Producers.Session').Exports.GetCachedState
    local world=module('Parts.World.World').Exports.GetCachedState
    local function collectExports(path,field,names)
        local value=module(path);local list=field and assert(value[field])or value
        if names then for _,name in ipairs(names)do export(path,name,list[name])end
        else
            local sorted={};for name in pairs(list)do sorted[#sorted+1]=name end;table.sort(sorted)
            for _,name in ipairs(sorted)do if name~='GetCachedState'then export(path,name,list[name])end end
        end
    end
    for _,path in ipairs({'PlayerCore.Runtime.Main','PlayerCore.Runtime.Weapons','Parts.Vehicles.Helpers.Persistence',
        'PlayerCore.Lifecycle.Functions','PlayerCore.Producers.Session','PlayerCore.Producers.Status','PlayerCore.Characters.Slots',
        'Central.Parts.Transport.Compat','Central.Parts.Inventory.Service','Central.Parts.Consumption.Service','Central.Parts.Finance.Vip',
        'Parts.Vehicles','Parts.CharacterAdmin'})do collectExports(path,'Exports')end
    collectExports('PlayerCore.Lookup',nil,{'GetSource','GetUserId','GetPlayer','GetPlayerByCitizenId','GetPlayerByUserId','GetPlayerByPhone','GetQBPlayers','GetDutyCountJob','GetDutyCountType'})
    collectExports('PlayerCore.Groups',nil,{'CreateJob','CreateJobs','RemoveJob','CreateGangs','RemoveGang','GetJobs','GetGangs','GetJob','GetGang',
        'UpsertJobData','UpsertGangData','UpsertJobGrade','UpsertGangGrade','RemoveJobGrade','RemoveGangGrade'})
    collectExports('PlayerCore.Players',nil,{'Login','GetOfflinePlayer','SetJob','SetJobDuty','SetPlayerPrimaryJob','AddPlayerToJob','RemovePlayerFromJob',
        'SetGang','SetPlayerPrimaryGang','AddPlayerToGang','RemovePlayerFromGang','Logout','CreatePlayer','Save','SaveOffline','SaveAllPlayers',
        'SetPlayerData','UpdatePlayerData','SetMetadata','GetMetadata','SetCharInfo','AddMoney','RemoveMoney','SetMoney','GetMoney','DeleteCharacter','GenerateUniqueIdentifier'})
    for _,d in ipairs(module('Parts.Skills.Boundary').Exports)do export('Parts.Skills.Boundary',d.name,d.handler)end
    export('Session+World','GetCachedState',function(domain,...)
        if type(domain)=='string'and domain:match('^session:%d+$')then return session(domain,...)end
        return world(domain,...)
    end)
    local function command(path,d,default)
        local mode=d.mode or d.provider or d.transport or default
        if mode=='library'then mode='pr'end
        local names=type(d.name)=='table'and d.name or{d.name}
        for _,name in ipairs(names)do entries[#entries+1]={kind='command',owner=path,name=name,handler=d.handler,
            mode=mode,properties=d.options or d.properties,restricted=d.restricted,
            externalOwner=d.externalOwner,isEnabled=d.isEnabled}end
    end
    local function commands(path,default)
        local value=module(path);local list=value.Commands or value
        for _,d in ipairs(list)do command(path,d,default)end
    end
    commands('PlayerCore.Runtime.Commands','ox');commands('Central.Parts.Transport.Commands','pr')
    commands('Central.Parts.Weapons.Commands','native');commands('Parts.Skills','pr');commands('Parts.Staff','pr');commands('Parts.Starterpack','pr')
    local storage=module('PlayerCore.Storage')
    local names={};for name in pairs(storage.Commands)do names[#names+1]=name end;table.sort(names)
    for _,name in ipairs(names)do local d=storage.Commands[name];command('PlayerCore.Storage',{name=name,handler=d.handler,restricted=d.restricted},'native')end
    for _,path in ipairs({'PlayerCore.Groups','PlayerCore.Players'})do
        local list=module(path).Callbacks;local sorted={};for name in pairs(list)do sorted[#sorted+1]=name end;table.sort(sorted)
        for _,name in ipairs(sorted)do callbacks[#callbacks+1]={owner=path,name=name,handler=list[name]}end
    end
    for _,name in ipairs(graph.Order)do module('Parts.'..name)end
    for _,path in ipairs({'PlayerCore.State','PlayerCore.Shared','PlayerCore.State.Players','PlayerCore.State.Status','PlayerCore.State.Session','PlayerCore.State.BridgeCache'})do module(path)end
    local function canonical()
        if graph.State~='prepared-inactive'or central.State~='prepared-inactive'or base.DomainAssembly~=graph or base.ServerAssembly~=central
            or base.PlayerCore~=pc or base.Callbacks~=security or graph.Security~=security or pc.Shared~=base.Shared or pc.Groups~=base.Groups then return false end
        for _,ref in ipairs(refs)do local ok,value=pcall(resolve,ref.path);if not ok or value~=ref.value then return false end end
        return true
    end
    return create({owner=base,side='server',entries=entries,callbacks=callbacks,isCurrent=canonical},ports)
end
