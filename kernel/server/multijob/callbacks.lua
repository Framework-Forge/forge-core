-- Descriptors only; explicit access preserves installed Security's MultiJob classification.
return function(ports)
    local PR,service={MultiJob=assert(ports.config)},assert(ports.service)
    local callbacks={}
    local admin={}
    for _,key in ipairs({'getSettings','saveSettings','addJob','removeJob','getTargetJobs'})do
        admin[PR.MultiJob.Callbacks[key]]=true
    end
    local function describeCallback(name,handler)
        callbacks[#callbacks+1]={name=name,handler=handler,options={access=admin[name]and'admin'or'player'}}
    end
describeCallback(PR.MultiJob.Callbacks.getSettings, function(source)
    if not service.canManage(source) then return false, 'no_permission' end
    return true, service.getSettings()
end)

describeCallback(PR.MultiJob.Callbacks.saveSettings, function(source, settings)
    return service.saveSettings(source, settings)
end)

describeCallback(PR.MultiJob.Callbacks.getPlayerJobs, function(source)
    return service.getPlayerJobs(source)
end)

describeCallback(PR.MultiJob.Callbacks.setActiveJob, function(source, jobName)
    return service.setActiveJob(source, jobName)
end)

describeCallback(PR.MultiJob.Callbacks.removeOwnJob, function(source, jobName)
    return service.removeJob(source, source, jobName, true)
end)

describeCallback(PR.MultiJob.Callbacks.addJob, function(source, target, jobName, grade)
    return service.addJob(source, target, jobName, grade)
end)

describeCallback(PR.MultiJob.Callbacks.removeJob, function(source, target, jobName)
    return service.removeJob(source, target, jobName, false)
end)

describeCallback(PR.MultiJob.Callbacks.getTargetJobs, function(source, target)
    if not service.canManage(source) then return false, 'no_permission' end
    return service.getPlayerJobs(tonumber(target) or 0)
end)
    return callbacks
end

