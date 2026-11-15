-- Attach metadata policy to the one existing Player/Groups/JobService/Security, never PR framework.
local createConfig=require 'kernel.config.forge_multijob'
local createPrison=require 'kernel.server.prison'
local createService=require 'kernel.server.multijob.service'
local createCallbacks=require 'kernel.server.multijob.callbacks'
return function(base,ports)
    local pc,catalog,groups=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.Groups)
    local transport=assert(catalog.Transport)
    assert(pc.Groups==groups and catalog.Groups==groups,'canonical Groups required')
    assert(base.Callbacks==transport.Security,'canonical Security required')
    assert(base.MultiJobCore==nil,'multi-job already attached')
    local deps=assert(catalog.Dependencies)
    assert(deps.MultiJobService==nil and deps.PrisonService==nil,'multi-job/prison already attached')
    local lookup,players=assert(pc.Lookup),assert(pc.Players)
    local service,registry=assert(catalog.Service),assert(catalog.Registry)
    local access={
        GetPlayer=lookup.GetPlayer,
        GetPlayerData=function(src)local p=lookup.GetPlayer(src);return p and p.PlayerData or nil end,
        GetPlayerMetadata=function(src,key)local p=lookup.GetPlayer(src);if not p then return nil end;return p.PlayerData.metadata[key]end,
        SetPlayerMetadata=function(src,key,value)
            local p=lookup.GetPlayer(src);if not p then return end
            -- The installed PR setter intentionally discards SetMetaData's result.
            p.Functions.SetMetaData(key,value)
        end,
        SetPlayerJob=function(src,name,grade)
            local ok,success,result=pcall(players.SetJob,src,name,tonumber(grade)or 0)
            if not ok then return false,success end
            return success==true,result
        end,
        SetPlayerDuty=function(src,duty)
            local ok,result=pcall(players.SetJobDuty,src,duty==true)
            if not ok then return false,result end
            return result~=false,result
        end,
    }
    local services={JobService=service,JobRegistry=registry}
    local prison=createPrison({services=services,playerAccess=access,provider=ports.prisonProvider})
    services.PrisonService=prison
    local config=ports.config or createConfig()
    local multi=createService({config=config,services=services,library=ports.library,translate=ports.translate,
        kernel={GetJob=groups.GetJob},playerAccess=access,native=ports.native,time=ports.time,
        notifyPosition=ports.notifyPosition,resource=ports.resource})
    local api={Base=base,PlayerCore=pc,Groups=groups,Config=config,Service=multi,PrisonService=prison,
        Security=transport.Security,Callbacks=createCallbacks({config=config,service=multi}),PlayerAccess=access}
    deps.MultiJobService,deps.PrisonService,base.MultiJobCore=multi,prison,api
    return api
end

