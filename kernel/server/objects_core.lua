-- Same holder, Security, player authority and world; no automatic start or public installation.
local createConfig=require 'kernel.config.forge_objects'
local createService=require 'kernel.server.objects'
local createCallbacks=require 'kernel.server.objects_callbacks'
return function(base,ports)
    local catalog,pc,world=assert(base.JobCatalog),assert(base.PlayerCore),assert(base.WorldCore)
    local deps,security=assert(catalog.Dependencies),assert(base.Callbacks)
    assert(catalog.Groups==base.Groups and pc.Groups==base.Groups and catalog.Transport.Security==security,'canonical Player/Job/Security required')
    assert(world.Base==base and world.PlayerCore==pc and world.Security==security and deps.State==world.State,'canonical world required')
    assert(base.ObjectsCore==nil and deps.ObjectsService==nil,'objects already attached')
    local cfg=ports.config or{}
    local config={Objects=cfg.Objects or createConfig(),AdminAce=cfg.AdminAce,NotifyPos=cfg.NotifyPos}
    local service=createService({config=config,library=ports.library,native=ports.native,
        services={JobService=assert(catalog.Service)},translate=ports.translate,world=world.State})
    local api={Base=base,PlayerCore=pc,Security=security,World=world,State=world.State,Config=config,Service=service,
        Callbacks=createCallbacks({config=config,service=service})}
    deps.ObjectsService,base.ObjectsCore=service,api
    return api
end
