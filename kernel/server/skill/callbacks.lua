-- Preserve Security18 classification when attaching after its initial configuration.
return function(ports)
    local PR,service={Skills=assert(ports.config)},assert(ports.service)
    local callbacks={}
    local admin={}
    for _,key in ipairs({'saveSkill','deleteSkill','saveReputation','deleteReputation','addXp'})do admin[PR.Skills.Callbacks[key]]=true end
    local function describeCallback(name,handler)
        callbacks[#callbacks+1]={name=name,handler=handler,options={access=admin[name]and'admin'or'player'}}
    end
describeCallback(PR.Skills.Callbacks.getAll, function(source)
    return service.getPayload(), service.canManage(source)
end)

describeCallback(PR.Skills.Callbacks.saveSkill, function(source, skill)
    return service.upsertSkill(source, skill)
end)

describeCallback(PR.Skills.Callbacks.deleteSkill, function(source, name)
    return service.deleteSkill(source, name)
end)

describeCallback(PR.Skills.Callbacks.saveReputation, function(source, reputation)
    return service.upsertReputation(source, reputation)
end)

describeCallback(PR.Skills.Callbacks.deleteReputation, function(source, name)
    return service.deleteReputation(source, name)
end)

describeCallback(PR.Skills.Callbacks.fetchPlayer, function(source)
    return service.fetchPlayer(source)
end)

describeCallback(PR.Skills.Callbacks.addXp, function(source, name, amount)
    return service.addXp(source, name, amount)
end)
    return callbacks
end

