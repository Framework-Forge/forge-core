-- Inactive composition of internal player/storage/lookup services.
-- Not loaded by the live manifest; callers must supply the PR/platform boundaries.
local createLookup = require 'kernel.server.player_lookup'
local createStorage = require 'kernel.server.storage'
local createPlayer = require 'kernel.server.player'

return function(base, ports)
    assert(type(base) == 'table' and type(base.Shared) == 'table' and type(base.Groups) == 'table', 'prepared base kernel required')
    assert(base.PlayerCore == nil, 'player core already composed for this kernel')
    assert(type(ports) == 'table' and type(ports.platform) == 'table', 'player composition ports required')
    assert(type(ports.statusFactory) == 'function' and type(ports.cacheFactory) == 'function', 'internal status/cache factories required')
    local state = {Players = {}, Shared = base.Shared}
    state.Status = ports.statusFactory(state)
    state.BridgeCache = ports.cacheFactory(state)
    local lookup = createLookup({core = state, getIdentifiers = ports.platform.getIdentifiers})
    local player
    local storage = createStorage({db = ports.db, json = ports.json, vec4 = ports.platform.vec4,
        defaultSpawn = ports.defaultSpawn, characterDataTables = ports.config.characterDataTables,
        groups = base.Groups, log = ports.library.print, warn = ports.warn,
        date = ports.date, emitServer = ports.platform.emitServer,
        cleanPlayerGroups = ports.cleanPlayerGroups,
        addPlayerToJob = function(...) return assert(player, 'player core not composed').AddPlayerToJob(...) end,
        addPlayerToGang = function(...) return assert(player, 'player core not composed').AddPlayerToGang(...) end})
    player = createPlayer({core = state, config = ports.config, defaultSpawn = ports.defaultSpawn,
        storage = storage, lookup = lookup, groups = base.Groups, logger = ports.logger,
        triggerHook = ports.triggerHook, characterSlots = ports.characterSlots, library = ports.library,
        utils = ports.utils, inventory = ports.inventory, platform = ports.platform,
        counters = ports.counters, settings = ports.settings, resource = ports.resource})
    local composed = {State = state, Lookup = lookup, Storage = storage, Players = player,
        Groups = base.Groups, Shared = base.Shared}
    base.PlayerCore = composed
    return composed
end
