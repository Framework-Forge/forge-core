ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.Density.Callbacks.getSettings, function(source)
    if not ForgeCore.DensityService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.DensityService.getSettings()
end)

ForgeCore.Callbacks.register(PR.Density.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.DensityService.save(source, settings)
end)
