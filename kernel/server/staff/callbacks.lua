-- Five protected descriptors only. No public callback installation.
return function(ports)
    local PR,service={Staff=assert(ports.config)},assert(ports.service)
    local callbacks={}
    local function describeCallback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler,options={access='admin'}}end
describeCallback(PR.Staff.Callbacks.getAll, function(source)
    if not service.canManage(source) then return false, 'no_permission' end
    return true, service.list()
end)

describeCallback(PR.Staff.Callbacks.getPlayers, function(source, sources)
    if not service.canManage(source) then return false, 'no_permission' end
    return true, service.getPlayers(sources)
end)

describeCallback(PR.Staff.Callbacks.catalog, function(source)
    if not service.canManage(source) then return false, 'no_permission' end
    return true, service.getPermissionCatalog()
end)

describeCallback(PR.Staff.Callbacks.add, function(source, data)
    return service.add(source, data)
end)

describeCallback(PR.Staff.Callbacks.remove, function(source, data)
    return service.remove(source, data)
end)
    return callbacks
end

