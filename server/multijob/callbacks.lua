ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.MultiJob.Callbacks.getSettings, function(source)
    if not ForgeCore.MultiJobService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.MultiJobService.getSettings()
end)

ForgeCore.Callbacks.register(PR.MultiJob.Callbacks.saveSettings, function(source, settings)
    return ForgeCore.MultiJobService.saveSettings(source, settings)
end)

ForgeCore.Callbacks.register(PR.MultiJob.Callbacks.getPlayerJobs, function(source)
    return ForgeCore.MultiJobService.getPlayerJobs(source)
end)

ForgeCore.Callbacks.register(PR.MultiJob.Callbacks.setActiveJob, function(source, jobName)
    return ForgeCore.MultiJobService.setActiveJob(source, jobName)
end)

ForgeCore.Callbacks.register(PR.MultiJob.Callbacks.removeOwnJob, function(source, jobName)
    return ForgeCore.MultiJobService.removeJob(source, source, jobName, true)
end)

ForgeCore.Callbacks.register(PR.MultiJob.Callbacks.addJob, function(source, target, jobName, grade)
    return ForgeCore.MultiJobService.addJob(source, target, jobName, grade)
end)

ForgeCore.Callbacks.register(PR.MultiJob.Callbacks.removeJob, function(source, target, jobName)
    return ForgeCore.MultiJobService.removeJob(source, target, jobName, false)
end)

ForgeCore.Callbacks.register(PR.MultiJob.Callbacks.getTargetJobs, function(source, target)
    if not ForgeCore.MultiJobService.canManage(source) then return false, 'no_permission' end
    return ForgeCore.MultiJobService.getPlayerJobs(tonumber(target) or 0)
end)
