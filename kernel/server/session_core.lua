-- Inactive internal composition; returns producer descriptors, never installs them.
local createPlayerCore = require 'kernel.server.player_core'
local createWriter = require 'kernel.shared.bridge_cache'
local createCache = require 'kernel.server.bridge_cache'
local createStatus = require 'kernel.server.status'
local createSession = require 'kernel.server.session'

return function(base, ports)
    assert(type(base) == 'table' and base.PlayerCore == nil, 'fresh prepared base required')
    assert(type(ports) == 'table' and type(ports.player) == 'table', 'player ports required')
    assert(type(ports.delivery) == 'table' and type(ports.status) == 'table', 'producer ports required')
    local getBucket = assert(ports.getBucket, 'bucket port required')
    local bindings = {}; for key, value in pairs(ports.player) do bindings[key] = value end
    local cacheModule, statusModule, playerCore
    bindings.cacheFactory = function(state)
        cacheModule = createCache({core = state, emit = bindings.platform.emitServer,
            writer = createWriter(ports.delivery, 'qbx_core:server:cacheChanged')})
        return cacheModule.Producer
    end
    bindings.statusFactory = function(state)
        statusModule = createStatus({core = state, config = ports.status.config,
            emit = bindings.platform.emitServer, emitClient = bindings.platform.emitClient,
            getInvokingResource = bindings.platform.getInvokingResource, wait = bindings.platform.wait,
            awaitSnapshot = ports.status.awaitSnapshot,
            save = function(...) return assert(playerCore, 'core composition incomplete').Players.Save(...) end})
        return statusModule.Status
    end
    playerCore = createPlayerCore(base, bindings)
    local sessionModule = createSession({core = playerCore.State, getPlayer = playerCore.Lookup.GetPlayer,
        getBucket = getBucket, emit = bindings.platform.emitServer})
    playerCore.State.Session = sessionModule.Session
    playerCore.Producers = {Cache = cacheModule, Status = statusModule, Session = sessionModule}
    -- No network registration or thread creation here. Future bootstrap owns exactly one install/dispose.
    return playerCore
end
