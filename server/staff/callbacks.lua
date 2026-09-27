ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.Staff.Callbacks.getAll, function(source)
    if not ForgeCore.StaffService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.StaffService.list()
end)

ForgeCore.Callbacks.register(PR.Staff.Callbacks.getPlayers, function(source, sources)
    if not ForgeCore.StaffService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.StaffService.getPlayers(sources)
end)

ForgeCore.Callbacks.register(PR.Staff.Callbacks.catalog, function(source)
    if not ForgeCore.StaffService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.StaffService.getPermissionCatalog()
end)

ForgeCore.Callbacks.register(PR.Staff.Callbacks.add, function(source, data)
    return ForgeCore.StaffService.add(source, data)
end)

ForgeCore.Callbacks.register(PR.Staff.Callbacks.remove, function(source, data)
    return ForgeCore.StaffService.remove(source, data)
end)
