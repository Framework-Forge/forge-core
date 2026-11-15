-- Inactive attachment to the single existing catalog/player/lifecycle, not another core.
local createService = require 'kernel.server.jobs.service'

return function(base, ports)
    local catalog = assert(base.JobCatalog, 'existing job catalog required')
    assert(catalog.Service == nil, 'job service already attached')
    local playerCore = assert(base.PlayerCore, 'existing player core required')
    local groups, registry, storage, projection = base.Groups, catalog.Registry, catalog.Storage, catalog.Projection
    assert(groups == catalog.Groups and groups == playerCore.Groups, 'canonical Groups identity required')
    local lookup, players = assert(playerCore.Lookup), assert(playerCore.Players)
    local functions = assert(assert(playerCore.Lifecycle, 'existing lifecycle required').Functions)
    for _, name in ipairs({'GetJobs','GetGangs'}) do assert(type(groups[name]) == 'function') end
    assert(type(lookup.GetPlayer) == 'function' and type(players.SetJob) == 'function' and type(players.SetJobDuty) == 'function')
    assert(type(functions.HasPermission) == 'function')
    local native = assert(ports.native, 'platform ports required')
    assert(type(native.getPlayers) == 'function')
    local dependencies = assert(ports.dependencies, 'explicit Payments/Points/Business dependency holder required')
    -- Future reconciled services are supplied here; never import the active legacy globals.
    local services = setmetatable({JobRegistry = registry, JobStorage = storage, JobQbxSync = projection},
        {__index = function(_, name) return dependencies[name] end})
    local function ready()
        return base.JobCatalog == catalog and base.PlayerCore == playerCore and base.Groups == groups
            and catalog.Groups == groups and playerCore.Groups == groups
            and catalog.Registry == registry and catalog.Storage == storage and catalog.Projection == projection
    end
    local kernel = {GetJobs = groups.GetJobs, GetGangs = groups.GetGangs,
        GetPlayer = lookup.GetPlayer, SetJob = players.SetJob, HasPermission = functions.HasPermission}
    local playerAccess = {
        GetAllPlayers = function()
            local result = {}
            for _, source in ipairs(native.getPlayers()) do result[#result + 1] = tonumber(source) end
            return result
        end,
        GetPlayerJob = function(source)
            local player = lookup.GetPlayer(source)
            return player and player.PlayerData.job or nil
        end,
        SetPlayerDuty = function(source, onDuty)
            local ok, result = pcall(players.SetJobDuty, source, onDuty == true)
            if not ok then return false, result end
            return result ~= false, result
        end,
    }
    local service = createService({config = catalog.Config, services = services,
        library = ports.library, translate = ports.translate, kernel = kernel, playerAccess = playerAccess,
        native = native, isReady = ready, isAvailable = ready, time = ports.time,
        adminAce = ports.adminAce, command = ports.command, notifyPosition = ports.notifyPosition})
    catalog.Service, catalog.Dependencies = service, dependencies
    return service
end
