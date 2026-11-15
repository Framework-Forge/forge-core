return function(ports)
    local PR,service=assert(ports.config),assert(ports.service)
    local callbacks={}
    local function describeCallback(name,handler)
        callbacks[#callbacks+1]={name=name,handler=handler,options={access=name==PR.Spotlights.Callbacks.getAll and 'player' or 'admin'}}
    end
describeCallback(PR.Spotlights.Callbacks.getAll, function(source)
    return true, service.getAll()
end)

describeCallback(PR.Spotlights.Callbacks.createGroup, function(source, name)
    return service.createGroup(source, name)
end)

describeCallback(PR.Spotlights.Callbacks.renameGroup, function(source, groupId, name)
    return service.renameGroup(source, groupId, name)
end)

describeCallback(PR.Spotlights.Callbacks.deleteGroup, function(source, groupId)
    return service.deleteGroup(source, groupId)
end)

describeCallback(PR.Spotlights.Callbacks.createLight, function(source, light)
    return service.createLight(source, light)
end)

describeCallback(PR.Spotlights.Callbacks.updateLight, function(source, lightId, changes)
    return service.updateLight(source, lightId, changes)
end)

describeCallback(PR.Spotlights.Callbacks.deleteLight, function(source, lightId)
    return service.deleteLight(source, lightId)
end)
    return callbacks
end
