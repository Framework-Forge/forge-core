ForgeCore.Callbacks.register(PR.DatabaseBackup.Callbacks.getHistory, function(source)
    return ForgeCore.DatabaseBackupService.getHistory(source)
end)

ForgeCore.Callbacks.register(PR.DatabaseBackup.Callbacks.create, function(source, mode)
    return ForgeCore.DatabaseBackupService.create(source, mode)
end)
