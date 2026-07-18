ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Farms.Callbacks.getAll, function(source)
    return true, ForgeCore.FarmsService.getAll()
end)

pr_lib.callback.register(PR.Farms.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.FarmsService.saveSettings(source, settings)
end)

pr_lib.callback.register(PR.Farms.Callbacks.createFarm, function(source, farm)
    return ForgeCore.FarmsService.createFarm(source, farm)
end)

pr_lib.callback.register(PR.Farms.Callbacks.updateFarm, function(source, farmId, farm)
    return ForgeCore.FarmsService.updateFarm(source, farmId, farm)
end)

pr_lib.callback.register(PR.Farms.Callbacks.deleteFarm, function(source, farmId)
    return ForgeCore.FarmsService.deleteFarm(source, farmId)
end)

pr_lib.callback.register(PR.Farms.Callbacks.startRoute, function(source, farmId, itemId)
    return ForgeCore.FarmsService.startRoute(source, farmId, itemId)
end)

pr_lib.callback.register(PR.Farms.Callbacks.finishRoute, function(source, farmId, itemId)
    return ForgeCore.FarmsService.finishRoute(source, farmId, itemId)
end)

pr_lib.callback.register(PR.Farms.Callbacks.collect, function(source, farmId, itemId)
    return ForgeCore.FarmsService.collect(source, farmId, itemId)
end)

pr_lib.callback.register(PR.Farms.Callbacks.getGroups, function(source, groupType)
    return ForgeCore.FarmsService.getGroups(source, groupType)
end)

pr_lib.callback.register(PR.Farms.Callbacks.getItems, function(source)
    return ForgeCore.FarmsService.getItems(source)
end)

pr_lib.callback.register(PR.Farms.Callbacks.getVehicles, function(source)
    return ForgeCore.FarmsService.getVehicles(source)
end)
