-- Attach before the shared Transport: its immutable security classification needs this inventory config.
local createConfig = require 'kernel.config.forge_inventory'
local createService = require 'kernel.server.inventory.service'
local createCallbacks = require 'kernel.server.inventory.callbacks'
return function(base,ports)
    local catalog, pc, groups = assert(base.JobCatalog), assert(base.PlayerCore), assert(base.Groups)
    local deps = assert(catalog.Dependencies)
    assert(catalog.Groups==groups and pc.Groups==groups, 'canonical Groups required')
    assert(catalog.Finance and deps.VipService==catalog.Finance.Vip, 'canonical VIP required')
    assert(base.InventoryCore==nil and deps.InventoryService==nil, 'inventory already attached')
    assert(base.Callbacks==nil and catalog.Transport==nil, 'attach inventory config before shared callback protection')
    local config = ports.config or createConfig()
    local services = setmetatable({}, {__index=function(_,name)return deps[name]end})
    local lookup = assert(pc.Lookup)
    local service = createService({config=config,services=services,library=ports.library,native=ports.native,
        integrations=ports.integrations,translate=ports.translate,compile=ports.compile,resource=ports.resource,
        adminAce=ports.adminAce,notifyPosition=ports.notifyPosition,
        playerAccess={GetPlayerData=function(source)
            local player=lookup.GetPlayer(source)
            return player and player.PlayerData or nil
        end}})
    local api = {Config=config,Service=service,Callbacks=createCallbacks({config=config,services=services})}
    deps.InventoryService, base.InventoryCore = service, api
    return api
end
