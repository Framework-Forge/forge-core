ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.AutoMedic.Callbacks.getSettings, function(source)
    if not ForgeCore.AutoMedicService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.AutoMedicService.getSettings()
end)

ForgeCore.Callbacks.register(PR.AutoMedic.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.AutoMedicService.save(source, settings)
end)

ForgeCore.Callbacks.register(PR.AutoMedic.Callbacks.getStatus, function(source)
    return true, ForgeCore.AutoMedicService.getStatus(source)
end, { limit = 6, window = 5000 })

ForgeCore.Callbacks.register(PR.AutoMedic.Callbacks.requestTreatment, function(source, category)
    return ForgeCore.AutoMedicService.requestTreatment(source, category)
end, { limit = 3, window = 10000 })

ForgeCore.Callbacks.register(PR.AutoMedic.Callbacks.completeTreatment, function(source, token)
    return ForgeCore.AutoMedicService.completeTreatment(source, token)
end, { limit = 3, window = 15000 })

ForgeCore.Callbacks.register(PR.AutoMedic.Callbacks.cancelTreatment, function(source, token)
    return ForgeCore.AutoMedicService.cancelTreatment(source, token)
end, { limit = 3, window = 10000 })
