return function(ports)
    local PR,service=assert(ports.config),assert(ports.service)
    local callbacks={}
    local function describeCallback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler,options={access='admin'}}end
describeCallback(PR.Vinewood.Callbacks.getSettings, function(source)
    if not service.canManage(source) then return false, 'no_permission' end
    return true, service.getSettings()
end)

describeCallback(PR.Vinewood.Callbacks.saveSettings, function(source, settings)
    return service.save(source, settings)
end)
    return callbacks
end
