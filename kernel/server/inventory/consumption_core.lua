-- Canonical server attachment, no registration or timers until explicit Initialize/refresh.
local createRegistry = require 'kernel.server.inventory.usable_registry'
local createConsumption = require 'kernel.server.inventory.consumables'
return function(base, ports)
    local pc, inventory, catalog = assert(base.PlayerCore), assert(base.InventoryCore), assert(base.JobCatalog)
    local deps, functions = assert(catalog.Dependencies), assert(assert(pc.Lifecycle).Functions)
    assert(base.Groups==pc.Groups and base.Groups==catalog.Groups, 'canonical Groups required')
    assert(deps.InventoryService==inventory.Service, 'canonical InventoryService required')
    assert(inventory.Consumption==nil and deps.ConsumableService==nil, 'consumption already attached')
    local registerLocal = assert(functions.Exports.CreateUseableItem)
    local usable = createRegistry({library=ports.library,native=ports.native,debug=ports.debug,
        frameworkLabel=ports.frameworkLabel,registerLocal=function(name,cb)
            registerLocal(name,cb) -- nil is the installed PR framework contract, not a failed registration.
        end})
    local service = createConsumption({services=deps,library=ports.library,native=ports.native,
        usable=usable,integrations=ports.integrations})
    local api = {Service=service,Usable=usable}
    inventory.Consumption, deps.ConsumableService = api, service
    return api
end
