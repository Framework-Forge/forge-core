ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Password.Callbacks.getSettings, function(source)
    if not ForgeCore.PasswordService.canManage(source) then
        return false, 'no_permission'
    end

    return true, ForgeCore.PasswordService.getSafeSettings()
end)

pr_lib.callback.register(PR.Password.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.PasswordService.save(source, settings)
end)
