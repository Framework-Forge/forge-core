-- One administrative attachment over the existing runtime/catalog/inventory. No IO or installation.
local createConfig=require 'kernel.config.forge_weapons'
local createRegistry=require 'kernel.server.weapon.registry'
local createStorage=require 'kernel.server.weapon.storage'
local createProjection=require 'kernel.server.weapon.projection'
local createOxSync=require 'kernel.server.weapon.ox_sync'
local createService=require 'kernel.server.weapon.service'
local createCallbacks=require 'kernel.server.weapon.callbacks'
local createCommands=require 'kernel.server.weapon.commands'
return function(base,ports)
    local pc,catalog,inventory=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.InventoryCore)
    local deps,runtime=assert(catalog.Dependencies),assert(pc.Runtime)
    assert(base.Groups==pc.Groups and base.Groups==catalog.Groups,'canonical Groups required')
    assert(runtime.State==pc.State and type(pc.State.Shared.Weapons)=='table','canonical runtime catalog required')
    local jobService=assert(catalog.Service)
    assert(deps.InventoryService==inventory.Service,'canonical InventoryService required')
    assert(not base.WeaponCore and not deps.WeaponRegistry and not deps.WeaponStorage and not deps.WeaponQbxSync
        and not deps.WeaponOxSync and not deps.WeaponService,'weapons already attached')
    assert(base.Callbacks==nil and catalog.Transport==nil,'attach Weapons config before shared callback protection')
    local config=ports.config or createConfig()
    local weapons=assert(runtime.Weapons)
    local function ready()
        return base.PlayerCore==pc and pc.Runtime==runtime and runtime.State==pc.State and runtime.Weapons==weapons
            and base.JobCatalog==catalog and catalog.Dependencies==deps and catalog.Service==jobService
    end
    local services=setmetatable({JobService=jobService}, {__index=function(_,name)return deps[name]end})
    local bindings={services=services,config=config,library=ports.library,native=ports.native,
        translate=ports.translate,notifyPosition=ports.notifyPosition,adminAce=ports.adminAce,
        resource=ports.resource,kernel=weapons,isReady=ready,integrations=ports.integrations}
    local registry,storage=createRegistry(bindings),createStorage(bindings)
    local projection,oxSync=createProjection(bindings),createOxSync(bindings)
    local service=createService(bindings)
    local api={State=pc.State,Config=config,Registry=registry,Storage=storage,Projection=projection,OxSync=oxSync,Service=service,
        Callbacks=createCallbacks(bindings),Commands=createCommands(bindings)}
    deps.WeaponRegistry,deps.WeaponStorage,deps.WeaponQbxSync,deps.WeaponOxSync,deps.WeaponService=registry,storage,projection,oxSync,service
    base.WeaponCore=api
    return api
end
