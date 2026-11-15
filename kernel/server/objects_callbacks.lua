return function(ports)
    local PR,service=assert(ports.config),assert(ports.service)
    local callbacks={}
    local function describeCallback(name,handler)
        callbacks[#callbacks+1]={name=name,handler=handler,options={access=name==PR.Objects.Callbacks.getAll and 'player' or 'admin'}}
    end
describeCallback(PR.Objects.Callbacks.getAll, function(source)
    return true, service.getAll()
end)

describeCallback(PR.Objects.Callbacks.createScene, function(source, name)
    return service.createScene(source, name)
end)

describeCallback(PR.Objects.Callbacks.renameScene, function(source, sceneId, name)
    return service.renameScene(source, sceneId, name)
end)

describeCallback(PR.Objects.Callbacks.deleteScene, function(source, sceneId)
    return service.deleteScene(source, sceneId)
end)

describeCallback(PR.Objects.Callbacks.createObject, function(source, object)
    return service.createObject(source, object)
end)

describeCallback(PR.Objects.Callbacks.updateObject, function(source, objectId, changes)
    return service.updateObject(source, objectId, changes)
end)

describeCallback(PR.Objects.Callbacks.deleteObject, function(source, objectId)
    return service.deleteObject(source, objectId)
end)
    return callbacks
end
