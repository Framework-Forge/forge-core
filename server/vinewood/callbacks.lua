ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.Vinewood.Callbacks.getSettings, function(source)
    if not ForgeCore.VinewoodService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.VinewoodService.getSettings()
end)

ForgeCore.Callbacks.register(PR.Vinewood.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.VinewoodService.save(source, settings)
end)
