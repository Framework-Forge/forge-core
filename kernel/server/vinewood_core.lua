-- One Vinewood service in the canonical Forge graph; construction does not start it.
local createConfig=require 'kernel.config.forge_vinewood'
local createService=require 'kernel.server.vinewood'
local createCallbacks=require 'kernel.server.vinewood_callbacks'
return function(base,ports)
    local catalog,pc,world=assert(base.JobCatalog),assert(base.PlayerCore),assert(base.WorldCore)
    local deps,security=assert(catalog.Dependencies),assert(base.Callbacks)
    assert(catalog.Groups==base.Groups and pc.Groups==base.Groups and catalog.Transport.Security==security,'canonical Player/Job/Security required')
    assert(world.Base==base and world.PlayerCore==pc and world.Security==security and deps.State==world.State,'canonical public world required')
    assert(base.VinewoodCore==nil and deps.VinewoodService==nil,'Vinewood already attached')
    local cfg=ports.config or{}
    local config={Vinewood=cfg.Vinewood or createConfig({vector3=assert(ports.native).vector3}),
        NotifyPos=cfg.NotifyPos,AdminAce=cfg.AdminAce}
    local service=createService({config=config,library=ports.library,native=ports.native,
        services={JobService=catalog.Service},translate=ports.translate,world=world.State})
    local api={Base=base,PlayerCore=pc,Security=security,World=world,State=world.State,Config=config,Service=service,
        Callbacks=createCallbacks({config=config,service=service})}
    deps.VinewoodService,base.VinewoodCore=service,api
    return api
end
