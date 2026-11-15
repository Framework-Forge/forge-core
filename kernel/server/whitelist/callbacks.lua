-- Installed callback bodies and Security classification, no registrations.
return function(ports)
    local PR,service={Whitelist=assert(ports.config)},assert(ports.service)
    local callbacks={}
    local function describeCallback(name,handler)
        local player=name==PR.Whitelist.Callbacks.check or name==PR.Whitelist.Callbacks.submitPreExam
        callbacks[#callbacks+1]={name=name,handler=handler,options={access=player and'player'or'admin'}}
    end
describeCallback(PR.Whitelist.Callbacks.getConfig, function(source)
    if not service.canManage(source) then return false, 'no_permission' end
    return true, service.getConfig()
end)

describeCallback(PR.Whitelist.Callbacks.saveConfig, function(source, config)
    return service.saveConfig(source, config)
end)

describeCallback(PR.Whitelist.Callbacks.check, function(source)
    return service.check(source)
end)

describeCallback(PR.Whitelist.Callbacks.listPlayers, function(source)
    return service.listPlayers(source)
end)

describeCallback(PR.Whitelist.Callbacks.add, function(source, identifier)
    return service.add(source, identifier)
end)

describeCallback(PR.Whitelist.Callbacks.remove, function(source, identifier)
    return service.remove(source, identifier)
end)

describeCallback(PR.Whitelist.Callbacks.ban, function(source, data)
    return service.ban(source, data)
end)

describeCallback(PR.Whitelist.Callbacks.submitPreExam, function(source, data)
    return service.submitPreExam(source, data)
end)
    return callbacks
end
