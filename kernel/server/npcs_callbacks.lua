return function(ports)
    local PR,service=assert(ports.config),assert(ports.service)
    local callbacks={}
    local function describeCallback(name,handler)
        callbacks[#callbacks+1]={name=name,handler=handler,options={access=name==PR.Npcs.Callbacks.getAll and 'player' or 'admin'}}
    end
describeCallback(PR.Npcs.Callbacks.getAll, function(source)
    return true, service.getAll()
end)

describeCallback(PR.Npcs.Callbacks.createGroup, function(source, data)
    return service.createGroup(source, data)
end)

describeCallback(PR.Npcs.Callbacks.renameGroup, function(source, groupId, data)
    return service.renameGroup(source, groupId, data)
end)

describeCallback(PR.Npcs.Callbacks.deleteGroup, function(source, groupId)
    return service.deleteGroup(source, groupId)
end)

describeCallback(PR.Npcs.Callbacks.createNpc, function(source, data)
    return service.createNpc(source, data)
end)

describeCallback(PR.Npcs.Callbacks.updateNpc, function(source, npcId, changes)
    return service.updateNpc(source, npcId, changes)
end)

describeCallback(PR.Npcs.Callbacks.deleteNpc, function(source, npcId)
    return service.deleteNpc(source, npcId)
end)
    return callbacks
end
