return function(ports)
    local PR,services=assert(ports.config),assert(ports.services)
    local callbacks={}
    local function describeCallback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler,options={access='admin'}}end
describeCallback(PR.PlayerManagement.Callbacks.list,function(source)return services.PlayerManagementService.list(source)end)
describeCallback(PR.PlayerManagement.Callbacks.details,function(source,target)return services.PlayerManagementService.details(source,target)end)
describeCallback(PR.PlayerManagement.Callbacks.whitelist,function(source,target,enabled)return services.PlayerManagementService.whitelist(source,target,enabled)end)
describeCallback(PR.PlayerManagement.Callbacks.prisonSentence,function(source,target,sentence)return services.PrisonService.setSentence(source,target,sentence)end)
describeCallback(PR.PlayerManagement.Callbacks.prisonRelease,function(source,target)return services.PrisonService.release(source,target)end)
    return callbacks
end
