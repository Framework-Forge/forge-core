return function(ports)
    local PR,service=assert(ports.config),assert(ports.service)
    local callbacks,admin={},{}
    for _,key in ipairs({"saveSettings","createFarm","updateFarm","deleteFarm"})do admin[PR.Farms.Callbacks[key]]=true end
    local function describeCallback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler,options={access=admin[name] and 'admin' or 'player'}}end
describeCallback(PR.Farms.Callbacks.getAll, function(source)
    return true, service.getAll()
end)

describeCallback(PR.Farms.Callbacks.saveSettings, function(source, settings)
    return service.saveSettings(source, settings)
end)

describeCallback(PR.Farms.Callbacks.createFarm, function(source, farm)
    return service.createFarm(source, farm)
end)

describeCallback(PR.Farms.Callbacks.updateFarm, function(source, farmId, farm)
    return service.updateFarm(source, farmId, farm)
end)

describeCallback(PR.Farms.Callbacks.deleteFarm, function(source, farmId)
    return service.deleteFarm(source, farmId)
end)

describeCallback(PR.Farms.Callbacks.startRoute, function(source, farmId, itemId)
    return service.startRoute(source, farmId, itemId)
end)

describeCallback(PR.Farms.Callbacks.finishRoute, function(source, farmId, itemId)
    return service.finishRoute(source, farmId, itemId)
end)

describeCallback(PR.Farms.Callbacks.collect, function(source, farmId, itemId)
    return service.collect(source, farmId, itemId)
end)

describeCallback(PR.Farms.Callbacks.getGroups, function(source, groupType)
    return service.getGroups(source, groupType)
end)

describeCallback(PR.Farms.Callbacks.getItems, function(source)
    return service.getItems(source)
end)

describeCallback(PR.Farms.Callbacks.getVehicles, function(source)
    return service.getVehicles(source)
end)
    return callbacks
end
