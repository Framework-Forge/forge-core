ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Density.Callbacks.getSettings, function(source)
    if not ForgeCore.DensityService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.DensityService.getSettings()
end)

pr_lib.callback.register(PR.Density.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.DensityService.save(source, settings)
end)
