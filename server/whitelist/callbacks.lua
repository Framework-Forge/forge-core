ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Whitelist.Callbacks.getConfig, function(source)
    if not ForgeCore.WhitelistService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.WhitelistService.getConfig()
end)

pr_lib.callback.register(PR.Whitelist.Callbacks.saveConfig, function(source, config)
    return ForgeCore.WhitelistService.saveConfig(source, config)
end)

pr_lib.callback.register(PR.Whitelist.Callbacks.check, function(source)
    return ForgeCore.WhitelistService.check(source)
end)

pr_lib.callback.register(PR.Whitelist.Callbacks.listPlayers, function(source)
    return ForgeCore.WhitelistService.listPlayers(source)
end)

pr_lib.callback.register(PR.Whitelist.Callbacks.add, function(source, identifier)
    return ForgeCore.WhitelistService.add(source, identifier)
end)

pr_lib.callback.register(PR.Whitelist.Callbacks.remove, function(source, identifier)
    return ForgeCore.WhitelistService.remove(source, identifier)
end)

pr_lib.callback.register(PR.Whitelist.Callbacks.ban, function(source, data)
    return ForgeCore.WhitelistService.ban(source, data)
end)

pr_lib.callback.register(PR.Whitelist.Callbacks.submitPreExam, function(source, data)
    return ForgeCore.WhitelistService.submitPreExam(source, data)
end)
