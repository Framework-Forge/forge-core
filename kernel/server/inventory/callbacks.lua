-- Complete 13 callback descriptors, no public registration.
return function(ports)
    local PR, services = {Inventory=assert(ports.config)}, assert(ports.services)
    local callbacks = {}
    local function describeCallback(name,handler) callbacks[#callbacks+1]={name=name,handler=handler} end
describeCallback(PR.Inventory.Callbacks.getAll, function(source)
    if not services.InventoryService.canManage(source) then return false, 'no_permission' end
    return true, services.InventoryService.getPayload()
end)

describeCallback(PR.Inventory.Callbacks.saveItem, function(source, itemData)
    return services.InventoryService.upsertItem(source, itemData)
end)

describeCallback(PR.Inventory.Callbacks.deleteItem, function(source, name)
    return services.InventoryService.deleteItem(source, name)
end)

describeCallback(PR.Inventory.Callbacks.setItemActive, function(source, name, active)
    return services.InventoryService.setItemActive(source, name, active)
end)

describeCallback(PR.Inventory.Callbacks.saveAmmo, function(source, data)
    return services.InventoryService.upsertAmmo(source, data)
end)

describeCallback(PR.Inventory.Callbacks.deleteAmmo, function(source, name)
    return services.InventoryService.deleteAmmo(source, name)
end)

describeCallback(PR.Inventory.Callbacks.setAmmoActive, function(source, name, active)
    return services.InventoryService.setAmmoActive(source, name, active)
end)

describeCallback(PR.Inventory.Callbacks.saveComponent, function(source, data)
    return services.InventoryService.upsertComponent(source, data)
end)

describeCallback(PR.Inventory.Callbacks.deleteComponent, function(source, name)
    return services.InventoryService.deleteComponent(source, name)
end)

describeCallback(PR.Inventory.Callbacks.setComponentActive, function(source, name, active)
    return services.InventoryService.setComponentActive(source, name, active)
end)

describeCallback(PR.Inventory.Callbacks.parseDefinition, function(source, kind, snippet)
    return services.InventoryService.parseDefinition(source, kind, snippet)
end)

describeCallback(PR.Inventory.Callbacks.getGiveCatalog, function(source)
    return services.InventoryService.getGiveCatalog(source)
end)

describeCallback(PR.Inventory.Callbacks.give, function(source, target, kind, name, count)
    return services.InventoryService.give(source, target, kind, name, count)
end)


return callbacks
end
