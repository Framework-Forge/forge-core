ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Inventory.Callbacks.getAll, function(source)
    if not ForgeCore.InventoryService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.InventoryService.getPayload()
end)

pr_lib.callback.register(PR.Inventory.Callbacks.saveItem, function(source, itemData)
    return ForgeCore.InventoryService.upsertItem(source, itemData)
end)

pr_lib.callback.register(PR.Inventory.Callbacks.deleteItem, function(source, name)
    return ForgeCore.InventoryService.deleteItem(source, name)
end)

pr_lib.callback.register(PR.Inventory.Callbacks.setItemActive, function(source, name, active)
    return ForgeCore.InventoryService.setItemActive(source, name, active)
end)

pr_lib.callback.register(PR.Inventory.Callbacks.saveAmmo, function(source, data)
    return ForgeCore.InventoryService.upsertAmmo(source, data)
end)

pr_lib.callback.register(PR.Inventory.Callbacks.deleteAmmo, function(source, name)
    return ForgeCore.InventoryService.deleteAmmo(source, name)
end)

pr_lib.callback.register(PR.Inventory.Callbacks.setAmmoActive, function(source, name, active)
    return ForgeCore.InventoryService.setAmmoActive(source, name, active)
end)

pr_lib.callback.register(PR.Inventory.Callbacks.saveComponent, function(source, data)
    return ForgeCore.InventoryService.upsertComponent(source, data)
end)

pr_lib.callback.register(PR.Inventory.Callbacks.deleteComponent, function(source, name)
    return ForgeCore.InventoryService.deleteComponent(source, name)
end)

pr_lib.callback.register(PR.Inventory.Callbacks.setComponentActive, function(source, name, active)
    return ForgeCore.InventoryService.setComponentActive(source, name, active)
end)

pr_lib.callback.register(PR.Inventory.Callbacks.parseDefinition, function(source, kind, snippet)
    return ForgeCore.InventoryService.parseDefinition(source, kind, snippet)
end)
