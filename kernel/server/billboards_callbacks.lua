return function(ports)
    local PR,service=assert(ports.config),assert(ports.service)
    local callbacks={}
    local function describeCallback(name,handler)
        callbacks[#callbacks+1]={name=name,handler=handler,options={access=name==PR.Billboards.Callbacks.getAll and 'player' or 'admin'}}
    end
describeCallback(PR.Billboards.Callbacks.getAll, function(source)
    return true, service.getAll()
end)

describeCallback(PR.Billboards.Callbacks.createGroup, function(source, name)
    return service.createGroup(source, name)
end)

describeCallback(PR.Billboards.Callbacks.renameGroup, function(source, groupId, name)
    return service.renameGroup(source, groupId, name)
end)

describeCallback(PR.Billboards.Callbacks.deleteGroup, function(source, groupId)
    return service.deleteGroup(source, groupId)
end)

describeCallback(PR.Billboards.Callbacks.createBillboard, function(source, billboard)
    return service.createBillboard(source, billboard)
end)

describeCallback(PR.Billboards.Callbacks.updateBillboard, function(source, billboardId, changes)
    return service.updateBillboard(source, billboardId, changes)
end)

describeCallback(PR.Billboards.Callbacks.deleteBillboard, function(source, billboardId)
    return service.deleteBillboard(source, billboardId)
end)
    return callbacks
end
