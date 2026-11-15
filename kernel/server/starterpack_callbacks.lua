return function(ports)
    local PR,service=assert(ports.config),assert(ports.service)
    local callbacks,admin={},{}
    for _,k in ipairs({'saveSettings','savePrologue','setItem','removeItem','setStop','removeStop','giveToPlayer','resetClaim'})do admin[PR.Starterpack.Callbacks[k]]=true end
    local function describeCallback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler,options={access=admin[name] and 'admin' or 'player'}}end
describeCallback(PR.Starterpack.Callbacks.getAll, function(source)
    return true, service.getAll(source)
end)

describeCallback(PR.Starterpack.Callbacks.saveSettings, function(source, settings)
    return service.saveSettings(source, settings)
end)

describeCallback(PR.Starterpack.Callbacks.savePrologue, function(source, prologue)
    return service.savePrologue(source, prologue)
end)

describeCallback(PR.Starterpack.Callbacks.setItem, function(source, item)
    return service.setItem(source, item)
end)

describeCallback(PR.Starterpack.Callbacks.removeItem, function(source, itemId)
    return service.removeItem(source, itemId)
end)

describeCallback(PR.Starterpack.Callbacks.setStop, function(source, stop)
    return service.setStop(source, stop)
end)

describeCallback(PR.Starterpack.Callbacks.removeStop, function(source, stopId)
    return service.removeStop(source, stopId)
end)

describeCallback(PR.Starterpack.Callbacks.grantReward, function(source, stopId, rewardId)
    return service.grantReward(source, stopId, rewardId)
end)

describeCallback(PR.Starterpack.Callbacks.completePrologue, function(source)
    return service.completePrologue(source)
end)

describeCallback(PR.Starterpack.Callbacks.claim, function(source)
    return service.claim(source, false)
end)

describeCallback(PR.Starterpack.Callbacks.giveToPlayer, function(source, targetSource)
    return service.giveToPlayer(source, targetSource)
end)

describeCallback(PR.Starterpack.Callbacks.resetClaim, function(source, citizenid)
    return service.resetClaim(source, citizenid)
end)
    return callbacks
end
