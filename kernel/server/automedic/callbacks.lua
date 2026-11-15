-- Preserve the installed Security classification and per-callback quotas, no installation.
return function(ports)
    local PR,service={AutoMedic=assert(ports.config)},assert(ports.service)
    local callbacks={}
    local function describeCallback(name,handler,options)
        local copy={};for k,v in pairs(options or {})do copy[k]=v end
        copy.access=(name==PR.AutoMedic.Callbacks.getSettings or name==PR.AutoMedic.Callbacks.saveSettings)and'admin'or'player'
        callbacks[#callbacks+1]={name=name,handler=handler,options=copy}
    end
describeCallback(PR.AutoMedic.Callbacks.getSettings, function(source)
    if not service.canManage(source) then return false, 'no_permission' end
    return true, service.getSettings()
end)

describeCallback(PR.AutoMedic.Callbacks.saveSettings, function(source, settings)
    return service.save(source, settings)
end)

describeCallback(PR.AutoMedic.Callbacks.getStatus, function(source)
    return true, service.getStatus(source)
end, { limit = 6, window = 5000 })

describeCallback(PR.AutoMedic.Callbacks.requestTreatment, function(source, category)
    return service.requestTreatment(source, category)
end, { limit = 3, window = 10000 })

describeCallback(PR.AutoMedic.Callbacks.completeTreatment, function(source, token)
    return service.completeTreatment(source, token)
end, { limit = 3, window = 15000 })

describeCallback(PR.AutoMedic.Callbacks.cancelTreatment, function(source, token)
    return service.cancelTreatment(source, token)
end, { limit = 3, window = 10000 })

describeCallback(PR.AutoMedic.Callbacks.recoverHospital, function(source, token, reason)
    return service.recoverHospital(source, token, reason)
end, { limit = 3, window = 15000 })
describeCallback(PR.AutoMedic.Callbacks.saveBed, function(source, bed)
    return service.saveBed(source, bed)
end)
describeCallback(PR.AutoMedic.Callbacks.deleteBed, function(source, id)
    return service.deleteBed(source, id)
end)
    return callbacks
end

