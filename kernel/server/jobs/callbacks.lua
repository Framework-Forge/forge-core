-- Complete job callback descriptors only; the future bootstrap installs protection/transport explicitly.
return function(ports)
    local services, PR = assert(ports.services), {Job=assert(ports.config)}
    local callbacks = {}
    local function describeCallback(name, handler, options)
        callbacks[#callbacks+1] = {name=name,handler=handler,options=options}
    end
describeCallback(PR.Job.Callbacks.getAll, function(source)
    if not services.JobService.started then
        services.JobService.start()
    end

    return services.JobService.getPayload(), services.JobService.canManage(source)
end)

describeCallback(PR.Job.Callbacks.saveGroup, function(source, groupData)
    local forcedType = groupData and groupData.type
    local ok, result = services.JobService.upsert(source, groupData, forcedType)

    return ok, result
end)

describeCallback(PR.Job.Callbacks.deleteGroup, function(source, groupType, name)
    local ok, result = services.JobService.delete(source, groupType, name)

    return ok, result
end)

describeCallback(PR.Job.Callbacks.savePaymentSettings, function(source, settings)
    local ok, result = services.JobPayments.update(source, settings)

    if ok then
        services.JobService.sendTo(source)
    end

    return ok, result
end)

describeCallback(PR.Job.Callbacks.forcePayment, function(source)
    local ok, result = services.JobPayments.force(source)

    if ok then
        services.JobService.sendTo(source)
    end

    return ok, result
end)

describeCallback(PR.Job.Callbacks.saveMeiSettings, function(source, settings)
    local ok, result = services.JobPayments.updateMei(source, settings)

    if ok then
        services.JobService.sendTo(source)
    end

    return ok, result
end)

describeCallback(PR.Job.Callbacks.createMei, function(source, data)
    local ok, result = services.JobService.createMei(source, data)

    if ok then
        services.JobService.broadcast(-1)
    end

    return ok, result
end)

describeCallback(PR.Job.Callbacks.openStash, function(source, groupType, groupName, pointId, password)
    return services.JobPoints.openStash(source, groupType, groupName, pointId, password)
end)

describeCallback(PR.Job.Callbacks.toggleDuty, function(source, groupName, pointId)
    return services.JobPoints.toggleDuty(source, groupName, pointId)
end)

describeCallback(PR.Job.Callbacks.getRegisterBalance, function(source, groupType, groupName, stationId, pointId)
    return services.JobBusiness.getRegisterBalance(source, groupType, groupName, stationId, pointId)
end)

describeCallback(PR.Job.Callbacks.registerAction, function(source, groupType, groupName, stationId, pointId, action, amount, password)
    return services.JobBusiness.registerAction(source, groupType, groupName, stationId, pointId, action, amount, password)
end)

describeCallback(PR.Job.Callbacks.robRegister, function(source, groupType, groupName, stationId, pointId, amount)
    return services.JobBusiness.robRegister(source, groupType, groupName, stationId, pointId, amount)
end)

describeCallback(PR.Job.Callbacks.openShop, function(source, groupType, groupName, stationId, pointId)
    return services.JobBusiness.openShop(source, groupType, groupName, stationId, pointId)
end)

describeCallback(PR.Job.Callbacks.getSupplyItems, function(source, groupType, groupName, stationId, pointId)
    return services.JobBusiness.getSupplyItems(source, groupType, groupName, stationId, pointId)
end)

describeCallback(PR.Job.Callbacks.supplyShop, function(source, groupType, groupName, stationId, pointId, itemName, amount, price)
    return services.JobBusiness.supplyShop(source, groupType, groupName, stationId, pointId, itemName, amount, price)
end)

describeCallback(PR.Job.Callbacks.sendAlarm, function(source, groupType, groupName, stationId, pointId)
    return services.JobBusiness.sendAlarm(source, groupType, groupName, stationId, pointId)
end)

describeCallback(PR.Job.Callbacks.submitApplication, function(source, groupType, groupName, stationId, pointId, answers)
    return services.JobBusiness.submitApplication(source, groupType, groupName, stationId, pointId, answers)
end)

describeCallback(PR.Job.Callbacks.getApplications, function(source, groupType, groupName, stationId, pointId)
    return services.JobBusiness.getApplications(source, groupType, groupName, stationId, pointId)
end)

describeCallback(PR.Job.Callbacks.reviewApplication, function(source, groupType, groupName, stationId, pointId, submissionId, status)
    return services.JobBusiness.reviewApplication(source, groupType, groupName, stationId, pointId, submissionId, status)
end)

describeCallback(PR.Job.Callbacks.getEmployees, function(source, groupType, groupName)
    return services.JobBusiness.getEmployees(source, groupType, groupName)
end)

describeCallback(PR.Job.Callbacks.hirePlayer, function(source, groupType, groupName, citizenid, grade)
    return services.JobBusiness.hirePlayer(source, groupType, groupName, citizenid, grade)
end)

describeCallback(PR.Job.Callbacks.fireEmployee, function(source, groupType, groupName, citizenid)
    return services.JobBusiness.fireEmployee(source, groupType, groupName, citizenid)
end)

describeCallback(PR.Job.Callbacks.setEmployeeGrade, function(source, groupType, groupName, citizenid, grade)
    return services.JobBusiness.setEmployeeGrade(source, groupType, groupName, citizenid, grade)
end)


return callbacks
end
