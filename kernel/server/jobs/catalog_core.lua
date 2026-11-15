-- Inactive assembly only. Reload/transactions/duty/membership/payroll belong to later Service reconciliation.
local createRegistry = require 'kernel.server.jobs.registry'
local createStorage = require 'kernel.server.jobs.storage'
local createProjection = require 'kernel.server.jobs.projection'

return function(base, ports)
    assert(type(base) == 'table' and base.JobCatalog == nil, 'fresh catalog attachment required')
    local groups = assert(base.Groups, 'existing canonical Groups required')
    for _, name in ipairs({'CreateJobs','CreateGangs','RemoveJob','RemoveGang','GetJobs','GetGangs'}) do
        assert(type(groups[name]) == 'function', 'internal Groups method required: ' .. name)
    end
    local config = assert(ports.config, 'local Forge job config required')
    local registry = createRegistry({config = config})
    local storage = createStorage({config = config, library = ports.library, translate = ports.translate})
    local projection = createProjection({
        config = config, groups = groups, library = ports.library, translate = ports.translate,
        getRegistry = function() return registry end,
        isReady = function() return base.Groups == groups end,
    })
    local api = {Config = config, Groups = groups, Registry = registry, Storage = storage, Projection = projection}
    base.JobCatalog = api
    return api
end
