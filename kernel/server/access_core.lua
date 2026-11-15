-- Local authoritative admission/permanence services; external DB/JSON/RPC/webhook stay PR.
local createWhitelistConfig=require 'kernel.config.forge_whitelist'
local createAfkConfig=require 'kernel.config.forge_afk'
local createWhitelist=require 'kernel.server.whitelist.service'
local createAfk=require 'kernel.server.afk.service'
local createWhitelistCallbacks=require 'kernel.server.whitelist.callbacks'
local createAfkCallbacks=require 'kernel.server.afk.callbacks'
return function(base,ports)
    local pc,catalog,groups=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.Groups)
    local transport,deps=assert(catalog.Transport),assert(catalog.Dependencies)
    assert(pc.Groups==groups and catalog.Groups==groups and base.Callbacks==transport.Security,'canonical state/Security required')
    assert(base.AccessCore==nil and deps.WhitelistService==nil and deps.AfkService==nil,'access services already attached')
    local session=assert(base.ForgeSession,'canonical Forge Session view30 required')
    assert(base.AutoMedicCore and base.AutoMedicCore.Session==session and session.Session,'canonical Session identity required')
    local functions=assert(assert(pc.Lifecycle).Functions)
    local lookup=assert(pc.Lookup)
    local config=ports.config or {}
    assert(config.Whitelist==nil or type(config.Whitelist)=='table','local whitelist config required')
    assert(config.Afk==nil or type(config.Afk)=='table','local AFK config required')
    local localConfig={Whitelist=config.Whitelist or createWhitelistConfig(),Afk=config.Afk or createAfkConfig(),
        AdminAce=config.AdminAce,NotifyPos=config.NotifyPos}
    local services={JobService=assert(catalog.Service),Session=session.Session}
    local library,native=assert(ports.library),assert(ports.native)
    local whitelist=createWhitelist({config=localConfig,library=library,native=native,services=services,
        translate=ports.translate,json=ports.json,webhookIntegration=ports.webhookIntegration,
        kernel={GetPlayer=assert(lookup.GetPlayer),GetPlayerByCitizenId=assert(lookup.GetPlayerByCitizenId),
            SetPlayerBucket=assert(functions.Exports.SetPlayerBucket)}})
    local afk=createAfk({config=localConfig,library=library,native=native,services=services,translate=ports.translate})
    local api={Base=base,PlayerCore=pc,Groups=groups,Security=transport.Security,Session=session,
        Config=localConfig,Whitelist=whitelist,Afk=afk,Callbacks={}}
    for _,entry in ipairs(createWhitelistCallbacks({config=localConfig.Whitelist,service=whitelist.Service}))do api.Callbacks[#api.Callbacks+1]=entry end
    for _,entry in ipairs(createAfkCallbacks({config=localConfig.Afk,service=afk.Service}))do api.Callbacks[#api.Callbacks+1]=entry end
    deps.WhitelistService,deps.AfkService,base.AccessCore=whitelist.Service,afk.Service,api
    return api
end
