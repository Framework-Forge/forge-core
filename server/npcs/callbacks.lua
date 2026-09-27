ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.Npcs.Callbacks.getAll, function(source)
    return true, ForgeCore.NpcsService.getAll()
end)

ForgeCore.Callbacks.register(PR.Npcs.Callbacks.createGroup, function(source, data)
    return ForgeCore.NpcsService.createGroup(source, data)
end)

ForgeCore.Callbacks.register(PR.Npcs.Callbacks.renameGroup, function(source, groupId, data)
    return ForgeCore.NpcsService.renameGroup(source, groupId, data)
end)

ForgeCore.Callbacks.register(PR.Npcs.Callbacks.deleteGroup, function(source, groupId)
    return ForgeCore.NpcsService.deleteGroup(source, groupId)
end)

ForgeCore.Callbacks.register(PR.Npcs.Callbacks.createNpc, function(source, data)
    return ForgeCore.NpcsService.createNpc(source, data)
end)

ForgeCore.Callbacks.register(PR.Npcs.Callbacks.updateNpc, function(source, npcId, changes)
    return ForgeCore.NpcsService.updateNpc(source, npcId, changes)
end)

ForgeCore.Callbacks.register(PR.Npcs.Callbacks.deleteNpc, function(source, npcId)
    return ForgeCore.NpcsService.deleteNpc(source, npcId)
end)
