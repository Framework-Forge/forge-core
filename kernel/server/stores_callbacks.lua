return function(ports)
    local PR,service=assert(ports.config),assert(ports.service)
    local callbacks={}
    local admin={}
    for _,key in ipairs({"saveSettings","createStore","updateStore","deleteStore"})do admin[PR.Stores.Callbacks[key]]=true end
    local function describeCallback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler,options={access=admin[name] and 'admin' or 'player'}}end
describeCallback(PR.Stores.Callbacks.getAll, function(source)
    return true, service.getAll()
end)

describeCallback(PR.Stores.Callbacks.getStore, function(source, storeId)
    return service.getStore(source, storeId)
end)

describeCallback(PR.Stores.Callbacks.getItems, function(source)
    return service.getItems(source)
end)

describeCallback(PR.Stores.Callbacks.saveSettings, function(source, settings)
    return service.saveSettings(source, settings)
end)

describeCallback(PR.Stores.Callbacks.createStore, function(source, data)
    return service.createStore(source, data)
end)

describeCallback(PR.Stores.Callbacks.updateStore, function(source, storeId, changes)
    return service.updateStore(source, storeId, changes)
end)

describeCallback(PR.Stores.Callbacks.updateOwnerStore, function(source, storeId, changes)
    return service.updateOwnerStore(source, storeId, changes)
end)

describeCallback(PR.Stores.Callbacks.deleteStore, function(source, storeId)
    return service.deleteStore(source, storeId)
end)

describeCallback(PR.Stores.Callbacks.setItem, function(source, storeId, item)
    return service.setItem(source, storeId, item)
end)

describeCallback(PR.Stores.Callbacks.removeItem, function(source, storeId, itemName)
    return service.removeItem(source, storeId, itemName)
end)

describeCallback(PR.Stores.Callbacks.openShop, function(source, storeId)
    return service.openShop(source, storeId)
end)

describeCallback(PR.Stores.Callbacks.buyItem, function(source, storeId, itemName, count)
    return service.buyItem(source, storeId, itemName, count)
end)

describeCallback(PR.Stores.Callbacks.buyStore, function(source, storeId, account)
    return service.buyStore(source, storeId, account)
end)

describeCallback(PR.Stores.Callbacks.transferStore, function(source, storeId, targetSource)
    return service.transferStore(source, storeId, targetSource)
end)

describeCallback(PR.Stores.Callbacks.addManager, function(source, storeId, targetSource)
    return service.addManager(source, storeId, targetSource)
end)

describeCallback(PR.Stores.Callbacks.removeManager, function(source, storeId, citizenid)
    return service.removeManager(source, storeId, citizenid)
end)

describeCallback(PR.Stores.Callbacks.withdraw, function(source, storeId)
    return service.withdraw(source, storeId)
end)

describeCallback(PR.Stores.Callbacks.getPlayerItems, function(source)
    return service.getPlayerItems(source)
end)

describeCallback(PR.Stores.Callbacks.addStockFromPlayer, function(source, storeId, itemName, count, price)
    return service.addStockFromPlayer(source, storeId, itemName, count, price)
end)
    return callbacks
end
