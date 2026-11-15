-- Exact installed callbacks; Security18 admin policy remains explicit, no registrations.
return function(ports)
    local PR,service=assert(ports.config),assert(ports.service)
    local callbacks={}
    local function describeCallback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler,options={access='admin'}}end
describeCallback(PR.DatabaseBackup.Callbacks.getHistory, function(source)
    return service.getHistory(source)
end)

describeCallback(PR.DatabaseBackup.Callbacks.create, function(source, mode)
    return service.create(source, mode)
end)

    return callbacks
end
