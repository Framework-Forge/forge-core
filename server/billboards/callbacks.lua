ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Billboards.Callbacks.getAll, function(source)
    return true, ForgeCore.BillboardsService.getAll()
end)

pr_lib.callback.register(PR.Billboards.Callbacks.createGroup, function(source, name)
    return ForgeCore.BillboardsService.createGroup(source, name)
end)

pr_lib.callback.register(PR.Billboards.Callbacks.renameGroup, function(source, groupId, name)
    return ForgeCore.BillboardsService.renameGroup(source, groupId, name)
end)

pr_lib.callback.register(PR.Billboards.Callbacks.deleteGroup, function(source, groupId)
    return ForgeCore.BillboardsService.deleteGroup(source, groupId)
end)

pr_lib.callback.register(PR.Billboards.Callbacks.createBillboard, function(source, billboard)
    return ForgeCore.BillboardsService.createBillboard(source, billboard)
end)

pr_lib.callback.register(PR.Billboards.Callbacks.updateBillboard, function(source, billboardId, changes)
    return ForgeCore.BillboardsService.updateBillboard(source, billboardId, changes)
end)

pr_lib.callback.register(PR.Billboards.Callbacks.deleteBillboard, function(source, billboardId)
    return ForgeCore.BillboardsService.deleteBillboard(source, billboardId)
end)
