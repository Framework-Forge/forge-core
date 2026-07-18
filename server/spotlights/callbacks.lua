ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Spotlights.Callbacks.getAll, function(source)
    return true, ForgeCore.SpotlightsService.getAll()
end)

pr_lib.callback.register(PR.Spotlights.Callbacks.createGroup, function(source, name)
    return ForgeCore.SpotlightsService.createGroup(source, name)
end)

pr_lib.callback.register(PR.Spotlights.Callbacks.renameGroup, function(source, groupId, name)
    return ForgeCore.SpotlightsService.renameGroup(source, groupId, name)
end)

pr_lib.callback.register(PR.Spotlights.Callbacks.deleteGroup, function(source, groupId)
    return ForgeCore.SpotlightsService.deleteGroup(source, groupId)
end)

pr_lib.callback.register(PR.Spotlights.Callbacks.createLight, function(source, light)
    return ForgeCore.SpotlightsService.createLight(source, light)
end)

pr_lib.callback.register(PR.Spotlights.Callbacks.updateLight, function(source, lightId, changes)
    return ForgeCore.SpotlightsService.updateLight(source, lightId, changes)
end)

pr_lib.callback.register(PR.Spotlights.Callbacks.deleteLight, function(source, lightId)
    return ForgeCore.SpotlightsService.deleteLight(source, lightId)
end)
