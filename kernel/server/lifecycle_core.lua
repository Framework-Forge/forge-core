-- Private attachment to the existing player/session core. No public bootstrap.
local createFunctions = require 'kernel.server.functions'
local createQueue = require 'kernel.server.queue'
local createQueueConfig = require 'kernel.config.queue'
local createEvents = require 'kernel.server.events'

return function(base, playerCore, ports)
    assert(type(base) == 'table' and base.PlayerCore == playerCore, 'existing authoritative player core required')
    assert(type(playerCore) == 'table' and playerCore.Lifecycle == nil, 'lifecycle already composed or no core')
    assert(type(base.Membership) == 'table', 'internal membership service required')
    assert(type(ports) == 'table' and type(ports.config) == 'table', 'lifecycle configuration required')
    local native = assert(ports.native, 'explicit platform ports required')
    local state = assert(playerCore.State)
    state.Player_Buckets = state.Player_Buckets or {}
    state.Entity_Buckets = state.Entity_Buckets or {}
    state.UsableItems = state.UsableItems or {}
    local functions = createFunctions({core = state, native = native, config = ports.config.server,
        notifyPosition = ports.notifyPosition, storage = playerCore.Storage, lookup = playerCore.Lookup,
        players = playerCore.Players, groups = base.Groups, membership = base.Membership,
        library = ports.library, logger = ports.logger, logging = ports.config.logging,
        notify = ports.notify, disablePersistence = ports.disablePersistence,
        resource = ports.resource, time = ports.time, date = ports.date})
    local queueOptions = assert(ports.queue, 'explicit queue options required')
    local queueConfig = queueOptions.config
    if queueOptions.enabled ~= false and not queueConfig then
        queueConfig = createQueueConfig({serverName = ports.serverName, isAceAllowed = native.isAceAllowed})
    end
    local queue = createQueue({enabled = queueOptions.enabled, config = queueConfig,
        maxPlayers = queueOptions.maxPlayers, native = native, library = ports.library, time = ports.time})
    local events = createEvents({core = state, config = ports.config.server, logging = ports.config.logging,
        library = ports.library, logger = ports.logger, storage = playerCore.Storage, queue = queue,
        globalState = ports.globalState, functions = functions, lookup = playerCore.Lookup,
        players = playerCore.Players, newPromise = ports.newPromise, time = ports.time,
        clock = ports.clock, querySchema = ports.querySchema, native = native, resource = ports.resource})
    local lifecycle = {Functions = functions, Queue = queue, Events = events, QueueConfig = queueConfig}
    playerCore.Lifecycle = lifecycle
    -- Hardcap/DDL/handlers remain unexecuted. Future bootstrap owns install, ordering and disposal.
    return lifecycle
end
