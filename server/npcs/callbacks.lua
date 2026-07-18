ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Npcs.Callbacks.getAll, function(source)
    return true, ForgeCore.NpcsService.getAll()
end)

pr_lib.callback.register(PR.Npcs.Callbacks.createGroup, function(source, data)
    return ForgeCore.NpcsService.createGroup(source, data)
end)

pr_lib.callback.register(PR.Npcs.Callbacks.renameGroup, function(source, groupId, data)
    return ForgeCore.NpcsService.renameGroup(source, groupId, data)
end)

pr_lib.callback.register(PR.Npcs.Callbacks.deleteGroup, function(source, groupId)
    return ForgeCore.NpcsService.deleteGroup(source, groupId)
end)

pr_lib.callback.register(PR.Npcs.Callbacks.createNpc, function(source, data)
    return ForgeCore.NpcsService.createNpc(source, data)
end)

pr_lib.callback.register(PR.Npcs.Callbacks.updateNpc, function(source, npcId, changes)
    return ForgeCore.NpcsService.updateNpc(source, npcId, changes)
end)

pr_lib.callback.register(PR.Npcs.Callbacks.deleteNpc, function(source, npcId)
    return ForgeCore.NpcsService.deleteNpc(source, npcId)
end)
