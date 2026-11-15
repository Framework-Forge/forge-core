-- Same local authority/world/security. External inventory remains PR; no registration or start here.
local createConfig=require 'kernel.config.forge_starterpack'
local createService=require 'kernel.server.starterpack'
local createCallbacks=require 'kernel.server.starterpack_callbacks'
local createCommands=require 'kernel.server.starterpack_commands'
return function(base,ports)
    local catalog,pc,world=assert(base.JobCatalog),assert(base.PlayerCore),assert(base.WorldCore)
    local deps,security=assert(catalog.Dependencies),assert(base.Callbacks)
    assert(catalog.Groups==base.Groups and pc.Groups==base.Groups and catalog.Transport.Security==security,'canonical Player/Job/Security required')
    assert(world.Base==base and world.PlayerCore==pc and world.Security==security and deps.State==world.State,'canonical world required')
    assert(base.StarterpackCore==nil and deps.StarterpackService==nil,'starterpack already attached')
    local lookup=assert(pc.Lookup)
    local player={GetPlayerData=function(source)local p=lookup.GetPlayer(source);return p and p.PlayerData or nil end}
    local cfg=ports.config or {}
    local config={Starterpack=cfg.Starterpack or createConfig(),AdminAce=cfg.AdminAce,NotifyPos=cfg.NotifyPos,Debug=cfg.Debug}
    local bindings={config=config,library=ports.library,native=ports.native,clock=ports.clock,print=ports.print,
        services={JobService=assert(catalog.Service)},world=world.State,player=player,translate=ports.translate,inventoryIntegration=ports.inventoryIntegration}
    local boundary=createService(bindings);bindings.service=boundary.Service
    local api={Base=base,PlayerCore=pc,Security=security,World=world,State=world.State,Config=config,Player=player,
        Service=boundary.Service,Boundary=boundary,Callbacks=createCallbacks(bindings),Commands=createCommands(bindings)}
    deps.StarterpackService,base.StarterpackCore=api.Service,api
    return api
end
