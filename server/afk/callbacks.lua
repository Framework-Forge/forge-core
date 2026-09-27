ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.Afk.Callbacks.getSettings, function(source)
    if not ForgeCore.AfkService.canManage(source) then
        return false, 'no_permission'
    end

    return true, ForgeCore.AfkService.getSettings()
end)

ForgeCore.Callbacks.register(PR.Afk.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.AfkService.save(source, settings)
end)
