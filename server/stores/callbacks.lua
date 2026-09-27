ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.Stores.Callbacks.getAll, function(source)
    return true, ForgeCore.StoresService.getAll()
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.getStore, function(source, storeId)
    return ForgeCore.StoresService.getStore(source, storeId)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.getItems, function(source)
    return ForgeCore.StoresService.getItems(source)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.StoresService.saveSettings(source, settings)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.createStore, function(source, data)
    return ForgeCore.StoresService.createStore(source, data)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.updateStore, function(source, storeId, changes)
    return ForgeCore.StoresService.updateStore(source, storeId, changes)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.updateOwnerStore, function(source, storeId, changes)
    return ForgeCore.StoresService.updateOwnerStore(source, storeId, changes)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.deleteStore, function(source, storeId)
    return ForgeCore.StoresService.deleteStore(source, storeId)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.setItem, function(source, storeId, item)
    return ForgeCore.StoresService.setItem(source, storeId, item)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.removeItem, function(source, storeId, itemName)
    return ForgeCore.StoresService.removeItem(source, storeId, itemName)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.openShop, function(source, storeId)
    return ForgeCore.StoresService.openShop(source, storeId)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.buyItem, function(source, storeId, itemName, count)
    return ForgeCore.StoresService.buyItem(source, storeId, itemName, count)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.buyStore, function(source, storeId, account)
    return ForgeCore.StoresService.buyStore(source, storeId, account)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.transferStore, function(source, storeId, targetSource)
    return ForgeCore.StoresService.transferStore(source, storeId, targetSource)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.addManager, function(source, storeId, targetSource)
    return ForgeCore.StoresService.addManager(source, storeId, targetSource)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.removeManager, function(source, storeId, citizenid)
    return ForgeCore.StoresService.removeManager(source, storeId, citizenid)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.withdraw, function(source, storeId)
    return ForgeCore.StoresService.withdraw(source, storeId)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.getPlayerItems, function(source)
    return ForgeCore.StoresService.getPlayerItems(source)
end)

ForgeCore.Callbacks.register(PR.Stores.Callbacks.addStockFromPlayer, function(source, storeId, itemName, count, price)
    return ForgeCore.StoresService.addStockFromPlayer(source, storeId, itemName, count, price)
end)
