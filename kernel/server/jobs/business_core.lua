-- Attach only: no registration, inventories, HTTP, IO, SQL or runtime listeners.
local createPoints = require 'kernel.server.jobs.points'
local createBusiness = require 'kernel.server.jobs.business'
return function(base, ports)
    local catalog, pc, groups = assert(base.JobCatalog), assert(base.PlayerCore), assert(base.Groups)
    local deps, service, registry = assert(catalog.Dependencies), assert(catalog.Service), assert(catalog.Registry)
    assert(catalog.Groups == groups and pc.Groups == groups, 'canonical Groups required')
    assert(catalog.BusinessCore == nil and not deps.JobPoints and not deps.JobBusiness, 'job business already attached')
    local lookup, players = assert(pc.Lookup), assert(pc.Players)
    local functions = assert(assert(pc.Lifecycle).Functions)
    local library, json = assert(ports.library), assert(ports.json)
    local services = {JobRegistry = registry, JobService = service}
    local playerAccess = {
        GetPlayerData = function(source)
            local player = lookup.GetPlayer(source)
            return player and player.PlayerData or nil
        end,
        SetPlayerDuty = function(source, onDuty)
            local ok, result = pcall(players.SetJobDuty, source, onDuty == true)
            if not ok then return false, result end
            return result ~= false, result
        end,
        GetPlayerNameByIdentifier = function(identifier)
            local player = lookup.GetPlayerByCitizenId(identifier)
            if player then return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname end
            local row = library.database and library.database.single('SELECT charinfo FROM players WHERE citizenid = ?', {identifier})
            if row then
                local charinfo = json.decode(row.charinfo)
                return ('%s %s'):format(charinfo.firstname, charinfo.lastname)
            end
            return 'Unknown'
        end,
    }
    for _, name in ipairs({'AddPlayerToJob','AddPlayerToGang','RemovePlayerFromJob','RemovePlayerFromGang'}) do
        local action = assert(players[name], 'membership operation required: ' .. name)
        playerAccess[name] = function(identifier, groupName, grade)
            local ok, success, result
            if name:match('^Add') then
                ok, success, result = pcall(action, identifier, groupName, tonumber(grade) or 0)
            else
                ok, success, result = pcall(action, identifier, groupName)
            end
            if not ok then return false, success end
            return success == true, result
        end
    end
    local bindings = {services = services, library = library, playerAccess = playerAccess,
        native = ports.native, integrations = ports.integrations, translate = ports.translate, json = json,
        time = ports.time, config = catalog.Config, debug = ports.debug,
        kernel = {GetGroupMembers = assert(functions.GetGroupMembers)},
        isReady = function()
            return base.JobCatalog == catalog and base.PlayerCore == pc and base.Groups == groups
                and catalog.Groups == groups and pc.Groups == groups and catalog.Dependencies == deps
                and catalog.Service == service and catalog.Registry == registry
        end}
    local points, business = createPoints(bindings), createBusiness(bindings)
    local api = {Points = points, Business = business}
    deps.JobPoints, deps.JobBusiness, catalog.BusinessCore = points, business, api
    return api
end
