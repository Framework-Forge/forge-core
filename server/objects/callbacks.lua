ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Objects.Callbacks.getAll, function(source)
    return true, ForgeCore.ObjectsService.getAll()
end)

pr_lib.callback.register(PR.Objects.Callbacks.createScene, function(source, name)
    return ForgeCore.ObjectsService.createScene(source, name)
end)

pr_lib.callback.register(PR.Objects.Callbacks.renameScene, function(source, sceneId, name)
    return ForgeCore.ObjectsService.renameScene(source, sceneId, name)
end)

pr_lib.callback.register(PR.Objects.Callbacks.deleteScene, function(source, sceneId)
    return ForgeCore.ObjectsService.deleteScene(source, sceneId)
end)

pr_lib.callback.register(PR.Objects.Callbacks.createObject, function(source, object)
    return ForgeCore.ObjectsService.createObject(source, object)
end)

pr_lib.callback.register(PR.Objects.Callbacks.updateObject, function(source, objectId, changes)
    return ForgeCore.ObjectsService.updateObject(source, objectId, changes)
end)

pr_lib.callback.register(PR.Objects.Callbacks.deleteObject, function(source, objectId)
    return ForgeCore.ObjectsService.deleteObject(source, objectId)
end)
