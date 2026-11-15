-- Local player/data/money authority; inventory remains an explicit PR integration.
local createConfig=require 'kernel.config.forge_stores'
local createService=require 'kernel.server.stores'
local createCallbacks=require 'kernel.server.stores_callbacks'
return function(base,ports)
    local catalog,pc,world=assert(base.JobCatalog),assert(base.PlayerCore),assert(base.WorldCore)
    local deps,security=assert(catalog.Dependencies),assert(base.Callbacks)
    assert(catalog.Groups==base.Groups and pc.Groups==base.Groups and catalog.Transport.Security==security,'canonical Player/Job/Security required')
    assert(world.Base==base and world.PlayerCore==pc and world.Security==security and deps.State==world.State,'canonical world required')
    assert(base.StoresCore==nil and deps.StoresService==nil,'stores already attached')
    local lookup,players=assert(pc.Lookup),assert(pc.Players)
    local player={}
    function player.GetPlayerData(source)
        local value=lookup.GetPlayer(source)
        return value and value.PlayerData or nil
    end
    -- Exact installed PR QBX PlayerHasJob policy, including secondary jobs and primary fallback.
    function player.PlayerHasJob(source,jobName,grade)
        local value=lookup.GetPlayer(source)
        if not value or not value.PlayerData then return false end
        jobName=tostring(jobName or ''):lower()
        local jobs=value.PlayerData.jobs or {}
        local playerGrade=jobs[jobName]
        if playerGrade==nil and value.PlayerData.job and value.PlayerData.job.name==jobName then
            local currentGrade=value.PlayerData.job.grade
            playerGrade=type(currentGrade)=='table' and (currentGrade.level or currentGrade.grade) or currentGrade
        end
        if playerGrade==nil then return false end
        if grade==nil then return true end
        return (tonumber(playerGrade)or 0)>=(tonumber(grade)or 0)
    end
    local function wallet(name)
        if name=='money'then return'cash'end
        if name=='black_money'then return'blackmoney'end
        return name
    end
    function player.getPlayerMoney(source,account)return players.GetMoney(source,wallet(account))end
    function player.addPlayerMoney(source,account,amount,reason)return players.AddMoney(source,wallet(account),amount,reason or 'Unknown')end
    function player.removePlayerMoney(source,account,amount,reason)return players.RemoveMoney(source,wallet(account),amount,reason or 'Unknown')end
    local cfg=ports.config or {}
    local config={Stores=cfg.Stores or createConfig({vec3=assert(ports.native.vec3)}),AdminAce=cfg.AdminAce,NotifyPos=cfg.NotifyPos,Debug=cfg.Debug}
    local boundary=createService({config=config,library=ports.library,native=ports.native,clock=ports.clock,
        services={JobService=assert(catalog.Service)},translate=ports.translate,world=world.State,
        player=player,inventoryIntegration=ports.inventoryIntegration})
    local api={Base=base,PlayerCore=pc,Security=security,World=world,State=world.State,Config=config,
        Service=boundary.Service,Events=boundary.Events,Player=player,Boundary=boundary,
        Callbacks=createCallbacks({config=config,service=boundary.Service})}
    deps.StoresService,base.StoresCore=api.Service,api
    return api
end
