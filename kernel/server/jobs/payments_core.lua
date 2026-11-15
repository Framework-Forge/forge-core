-- One inactive financial attachment to the existing catalog/JobService/Player.
local createPayments = require 'kernel.server.jobs.payments'
local createVip = require 'kernel.server.vip.service'
local createVipConfig = require 'kernel.config.forge_vip'
return function(base, ports)
    local catalog, pc = assert(base.JobCatalog), assert(base.PlayerCore)
    assert(catalog.Finance == nil, 'finance already attached')
    local groups, deps = assert(base.Groups), assert(catalog.Dependencies)
    assert(catalog.Groups == groups and pc.Groups == groups, 'canonical Groups required')
    assert(catalog.Service and not deps.JobPayments and not deps.VipService, 'existing Service and fresh financial dependencies required')
    local lookup, players = assert(pc.Lookup), assert(pc.Players)
    local storage, service = assert(catalog.Storage), catalog.Service
    local config = ports.vipConfig or createVipConfig()
    local services = {JobStorage = storage, JobService = service}
    local kernel = {GetQBPlayers = assert(lookup.GetQBPlayers), GetJob = assert(groups.GetJob),
        GetPlayer = assert(lookup.GetPlayer), SetMetadata = assert(players.SetMetadata)}
    local function ready()
        return base.JobCatalog == catalog and base.PlayerCore == pc and base.Groups == groups
            and catalog.Groups == groups and pc.Groups == groups and catalog.Storage == storage
            and catalog.Service == service and catalog.Dependencies == deps
    end
    local vip = createVip({config = config, services = services, kernel = kernel, library = ports.library,
        integrations = ports.integrations, native = ports.native, time = ports.time, resource = ports.resource})
    services.VipService = vip
    local payments = createPayments({config = catalog.Config, services = services, kernel = kernel,
        isReady = ready, library = ports.library, integrations = ports.integrations,
        native = ports.native, time = ports.time, translate = ports.translate, notifyPosition = ports.notifyPosition})
    local api = {Payments = payments, Vip = vip, VipConfig = config}
    deps.JobPayments, deps.VipService, catalog.Finance = payments, vip, api
    return api
end
