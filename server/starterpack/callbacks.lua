ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Starterpack.Callbacks.getAll, function(source)
    return true, ForgeCore.StarterpackService.getAll(source)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.StarterpackService.saveSettings(source, settings)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.savePrologue, function(source, prologue)
    return ForgeCore.StarterpackService.savePrologue(source, prologue)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.setItem, function(source, item)
    return ForgeCore.StarterpackService.setItem(source, item)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.removeItem, function(source, itemId)
    return ForgeCore.StarterpackService.removeItem(source, itemId)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.setStop, function(source, stop)
    return ForgeCore.StarterpackService.setStop(source, stop)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.removeStop, function(source, stopId)
    return ForgeCore.StarterpackService.removeStop(source, stopId)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.grantReward, function(source, stopId, rewardId)
    return ForgeCore.StarterpackService.grantReward(source, stopId, rewardId)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.completePrologue, function(source)
    return ForgeCore.StarterpackService.completePrologue(source)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.claim, function(source)
    return ForgeCore.StarterpackService.claim(source, false)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.giveToPlayer, function(source, targetSource)
    return ForgeCore.StarterpackService.giveToPlayer(source, targetSource)
end)

pr_lib.callback.register(PR.Starterpack.Callbacks.resetClaim, function(source, citizenid)
    return ForgeCore.StarterpackService.resetClaim(source, citizenid)
end)
