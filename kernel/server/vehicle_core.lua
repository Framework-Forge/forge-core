-- Attach catalog/ownership administration to the one local runtime and lookup.
local createConfig=require 'kernel.config.forge_vehicles'
local createCatalog=require 'kernel.server.vehicle_catalog'
local createCallbacks=require 'kernel.server.vehicle_callbacks'
local createProjection=require 'kernel.server.vehicle_projection'
return function(base,ports)
    local pc,catalog,groups=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.Groups)
    local runtime=assert(pc.Runtime,'canonical runtime10 required')
    local helpers=assert(base.Helpers,'canonical helpers07 required')
    local security=assert(base.Callbacks)
    local deps=assert(catalog.Dependencies)
    assert(pc.Groups==groups and catalog.Groups==groups and catalog.Transport.Security==security,'canonical Groups/Security required')
    assert(runtime.State==pc.State and type(runtime.Main.SetVehicleCatalog)=='function','canonical catalog runtime required')
    assert(helpers.Persistence and type(helpers.Persistence.EnablePersistence)=='function','local persistence07 required')
    assert(base.VehicleCore==nil and deps.VehicleService==nil,'vehicles already attached')
    local cfg=ports.config or{}
    local config={Vehicles=cfg.Vehicles or createConfig(),AdminAce=cfg.AdminAce,NotifyPos=cfg.NotifyPos}
    local native=assert(ports.native)
    local projection=createProjection({state=pc.State,native=native})
    local kernel={getPlayer=assert(pc.Lookup.GetPlayer),setVehicleCatalog=projection.SetVehicleCatalog,
        enablePersistence=helpers.Persistence.EnablePersistence,resourceState=assert(ports.coreState),resourceName=assert(native.GetCurrentResourceName)}
    local bindings={config=config,library=assert(ports.library),native=native,services={JobService=assert(catalog.Service)},
        translate=assert(ports.translate),catalogFile=assert(ports.catalogFile),json=assert(ports.json),compile=assert(ports.compile),
        kernel=kernel,vehicleIntegration=ports.vehicleIntegration}
    -- Constructors do not read or register; attachment happens only after all ports validate.
    local core=createCatalog(bindings)
    local callbacks=createCallbacks(setmetatable({service=core.Service},{__index=bindings}))
    core.Base,core.PlayerCore,core.Runtime,core.Helpers,core.Security,core.Config=base,pc,runtime,helpers,security,config
    core.Callbacks,core.Kernel,core.Projection=callbacks.Callbacks,kernel,projection
    deps.VehicleService,base.VehicleCore=core.Service,core
    return core
end
