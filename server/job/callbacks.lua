ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Job.Callbacks.getAll, function(source)
    if not ForgeCore.JobService.started then
        ForgeCore.JobService.start()
    end

    return ForgeCore.JobService.getPayload(), ForgeCore.JobService.canManage(source)
end)

pr_lib.callback.register(PR.Job.Callbacks.saveGroup, function(source, groupData)
    local forcedType = groupData and groupData.type
    local ok, result = ForgeCore.JobService.upsert(source, groupData, forcedType)

    return ok, result
end)

pr_lib.callback.register(PR.Job.Callbacks.deleteGroup, function(source, groupType, name)
    local ok, result = ForgeCore.JobService.delete(source, groupType, name)

    return ok, result
end)

pr_lib.callback.register(PR.Job.Callbacks.savePaymentSettings, function(source, settings)
    local ok, result = ForgeCore.JobPayments.update(source, settings)

    if ok then
        ForgeCore.JobService.sendTo(source)
    end

    return ok, result
end)

pr_lib.callback.register(PR.Job.Callbacks.forcePayment, function(source)
    local ok, result = ForgeCore.JobPayments.force(source)

    if ok then
        ForgeCore.JobService.sendTo(source)
    end

    return ok, result
end)

pr_lib.callback.register(PR.Job.Callbacks.saveMeiSettings, function(source, settings)
    local ok, result = ForgeCore.JobPayments.updateMei(source, settings)

    if ok then
        ForgeCore.JobService.sendTo(source)
    end

    return ok, result
end)

pr_lib.callback.register(PR.Job.Callbacks.createMei, function(source, data)
    local ok, result = ForgeCore.JobService.createMei(source, data)

    if ok then
        ForgeCore.JobService.broadcast(-1)
    end

    return ok, result
end)
