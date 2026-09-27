ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.Job.Callbacks.getAll, function(source)
    if not ForgeCore.JobService.started then
        ForgeCore.JobService.start()
    end

    return ForgeCore.JobService.getPayload(), ForgeCore.JobService.canManage(source)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.saveGroup, function(source, groupData)
    local forcedType = groupData and groupData.type
    local ok, result = ForgeCore.JobService.upsert(source, groupData, forcedType)

    return ok, result
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.deleteGroup, function(source, groupType, name)
    local ok, result = ForgeCore.JobService.delete(source, groupType, name)

    return ok, result
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.savePaymentSettings, function(source, settings)
    local ok, result = ForgeCore.JobPayments.update(source, settings)

    if ok then
        ForgeCore.JobService.sendTo(source)
    end

    return ok, result
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.forcePayment, function(source)
    local ok, result = ForgeCore.JobPayments.force(source)

    if ok then
        ForgeCore.JobService.sendTo(source)
    end

    return ok, result
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.saveMeiSettings, function(source, settings)
    local ok, result = ForgeCore.JobPayments.updateMei(source, settings)

    if ok then
        ForgeCore.JobService.sendTo(source)
    end

    return ok, result
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.createMei, function(source, data)
    local ok, result = ForgeCore.JobService.createMei(source, data)

    if ok then
        ForgeCore.JobService.broadcast(-1)
    end

    return ok, result
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.openStash, function(source, groupType, groupName, pointId, password)
    return ForgeCore.JobPoints.openStash(source, groupType, groupName, pointId, password)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.toggleDuty, function(source, groupName, pointId)
    return ForgeCore.JobPoints.toggleDuty(source, groupName, pointId)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.getRegisterBalance, function(source, groupType, groupName, stationId, pointId)
    return ForgeCore.JobBusiness.getRegisterBalance(source, groupType, groupName, stationId, pointId)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.registerAction, function(source, groupType, groupName, stationId, pointId, action, amount, password)
    return ForgeCore.JobBusiness.registerAction(source, groupType, groupName, stationId, pointId, action, amount, password)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.robRegister, function(source, groupType, groupName, stationId, pointId, amount)
    return ForgeCore.JobBusiness.robRegister(source, groupType, groupName, stationId, pointId, amount)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.openShop, function(source, groupType, groupName, stationId, pointId)
    return ForgeCore.JobBusiness.openShop(source, groupType, groupName, stationId, pointId)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.getSupplyItems, function(source, groupType, groupName, stationId, pointId)
    return ForgeCore.JobBusiness.getSupplyItems(source, groupType, groupName, stationId, pointId)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.supplyShop, function(source, groupType, groupName, stationId, pointId, itemName, amount, price)
    return ForgeCore.JobBusiness.supplyShop(source, groupType, groupName, stationId, pointId, itemName, amount, price)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.sendAlarm, function(source, groupType, groupName, stationId, pointId)
    return ForgeCore.JobBusiness.sendAlarm(source, groupType, groupName, stationId, pointId)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.submitApplication, function(source, groupType, groupName, stationId, pointId, answers)
    return ForgeCore.JobBusiness.submitApplication(source, groupType, groupName, stationId, pointId, answers)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.getApplications, function(source, groupType, groupName, stationId, pointId)
    return ForgeCore.JobBusiness.getApplications(source, groupType, groupName, stationId, pointId)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.reviewApplication, function(source, groupType, groupName, stationId, pointId, submissionId, status)
    return ForgeCore.JobBusiness.reviewApplication(source, groupType, groupName, stationId, pointId, submissionId, status)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.getEmployees, function(source, groupType, groupName)
    return ForgeCore.JobBusiness.getEmployees(source, groupType, groupName)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.hirePlayer, function(source, groupType, groupName, citizenid, grade)
    return ForgeCore.JobBusiness.hirePlayer(source, groupType, groupName, citizenid, grade)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.fireEmployee, function(source, groupType, groupName, citizenid)
    return ForgeCore.JobBusiness.fireEmployee(source, groupType, groupName, citizenid)
end)

ForgeCore.Callbacks.register(PR.Job.Callbacks.setEmployeeGrade, function(source, groupType, groupName, citizenid, grade)
    return ForgeCore.JobBusiness.setEmployeeGrade(source, groupType, groupName, citizenid, grade)
end)
