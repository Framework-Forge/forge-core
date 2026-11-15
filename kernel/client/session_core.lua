-- Inactive client composition. State/events/native boundaries belong to the future bootstrap.
local createWriter = require 'kernel.shared.bridge_cache'
local createCache = require 'kernel.client.bridge_cache'
local createStatus = require 'kernel.client.status'
local createSession = require 'kernel.client.session'

return function(state, ports)
    assert(type(state) == 'table' and state.ProducerCore == nil, 'fresh client state required')
    assert(type(state.PlayerData) == 'table', 'client PlayerData required')
    assert(type(ports) == 'table' and type(ports.native) == 'table', 'client ports required')
    local writer = createWriter(ports.delivery, 'qbx_core:client:cacheChanged')
    local cacheModule = createCache({core = state, native = ports.native, writer = writer})
    state.BridgeCache = cacheModule.Producer
    local statusModule = createStatus({core = state, native = ports.native, config = ports.statusConfig})
    local sessionModule = createSession({core = state, native = ports.native})
    state.Session = sessionModule.Session
    local api = {State = state, Cache = cacheModule, Status = statusModule, Session = sessionModule}
    local initialized = false
    function api.Initialize()
        if initialized then return false end
        initialized = true
        cacheModule.Initialize()
        sessionModule.Initialize()
        return true
    end
    state.ProducerCore = api
    return api
end
