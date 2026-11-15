-- Local player/catalog authority, same world/security; inventory stays behind explicit PR contracts.
local createConfig=require 'kernel.config.forge_farms'
local createService=require 'kernel.server.farms'
local createCallbacks=require 'kernel.server.farms_callbacks'
return function(base,ports)
    local catalog,pc,world=assert(base.JobCatalog),assert(base.PlayerCore),assert(base.WorldCore)
    local deps,security=assert(catalog.Dependencies),assert(base.Callbacks)
    assert(catalog.Groups==base.Groups and pc.Groups==base.Groups and catalog.Transport.Security==security,'canonical Player/Job/Security required')
    assert(world.Base==base and world.PlayerCore==pc and world.Security==security and deps.State==world.State,'canonical world required')
    local runtime=assert(pc.Runtime,'canonical runtime10 required')
    assert(runtime.State==pc.State and base.VehicleCore and base.VehicleCore.Runtime==runtime,'canonical vehicle catalog required')
    assert(base.FarmsCore==nil and deps.FarmsService==nil,'farms already attached')
    local lookup=assert(pc.Lookup)
    local kernel={resourceState=assert(ports.coreState),getVehiclesByName=assert(runtime.Main.GetVehiclesByName)}
    function kernel.GetPlayerData(source)
        local value=lookup.GetPlayer(source)
        return value and value.PlayerData or nil
    end
    local cfg=ports.config or {}
    local config={Farms=cfg.Farms or createConfig({vec3=assert(ports.native.vec3),translate=ports.translate}),
        AdminAce=cfg.AdminAce,NotifyPos=cfg.NotifyPos,Debug=cfg.Debug}
    local boundary=createService({config=config,library=ports.library,native=ports.native,clock=ports.clock,math=ports.math,
        services={JobService=assert(catalog.Service),JobRegistry=assert(catalog.Registry)},translate=ports.translate,
        world=world.State,kernel=kernel,inventoryIntegration=ports.inventoryIntegration})
    local api={Base=base,PlayerCore=pc,Security=security,World=world,State=world.State,Config=config,Kernel=kernel,
        Service=boundary.Service,Boundary=boundary,Runtime=runtime,Events=boundary.Events,
        Callbacks=createCallbacks({config=config,service=boundary.Service})}
    deps.FarmsService,base.FarmsCore=api.Service,api
    return api
end
