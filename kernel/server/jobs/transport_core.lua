-- Canonical attachment only. No callback, event, export or command installation.
local createSecurity = require 'kernel.server.callback_security'
local createCallbacks = require 'kernel.server.jobs.callbacks'
local createCommands = require 'kernel.server.jobs.commands'
local createCompat = require 'kernel.server.compat'
return function(base, ports)
    local catalog, pc, groups = assert(base.JobCatalog), assert(base.PlayerCore), assert(base.Groups)
    local deps, registry, service = assert(catalog.Dependencies), assert(catalog.Registry), assert(catalog.Service)
    assert(catalog.Groups == groups and pc.Groups == groups, 'canonical Groups required')
    assert(catalog.Finance and catalog.BusinessCore, 'canonical financial/business services required')
    assert(deps.JobPayments == catalog.Finance.Payments and deps.JobPoints == catalog.BusinessCore.Points
        and deps.JobBusiness == catalog.BusinessCore.Business, 'canonical job dependencies required')
    assert(base.Callbacks == nil and catalog.Transport == nil, 'job transport already attached')
    local library, native = assert(ports.library), assert(ports.native)
    local config = {}; for key,value in pairs(assert(ports.config)) do config[key]=value end
    assert(config.Job == nil or config.Job == catalog.Config, 'canonical Job config required')
    config.Job = catalog.Config
    local services = setmetatable({JobService=service,JobRegistry=registry},
        {__index=function(_,name)return deps[name]end})
    local security = createSecurity({services=services,library=library,config=config,json=ports.json,native=native})
    local api = {Security=security,
        Callbacks=createCallbacks({services=services,config=catalog.Config}),
        Commands=createCommands({services=services,config=config,library=library,translate=ports.translate,time=ports.time}),
        Compat=createCompat({services=services,library=library,native=native,
            kernel={GetJobs=groups.GetJobs,GetPlayer=assert(pc.Lookup).GetPlayer}})}
    base.Callbacks, catalog.Transport = security, api
    return api
end
