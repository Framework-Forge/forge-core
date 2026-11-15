-- Inactive attachment: scene-only renderer over the existing canonical client cache.
local createRenderer = require 'kernel.client.character_renderer'

return function(state, ports)
    assert(type(state) == 'table' and state.CharacterRenderer == nil, 'fresh renderer attachment required')
    assert(type(state.PlayerData) == 'table' and type(state.BridgeCache) == 'table', 'canonical client state/cache required')
    assert(type(state.BridgeCache.refreshContext) == 'function', 'local refreshContext required')
    local renderer = createRenderer({
        native = ports.native, config = ports.config, cache = ports.cache,
        bridgeCache = state.BridgeCache, streaming = ports.streaming, json = ports.json,
        random = ports.random, fallbackLocation = ports.fallbackLocation,
        getPreviewPedData = ports.getPreviewPedData, setPedAppearance = ports.setPedAppearance,
    })
    local api = {State = state, Renderer = renderer}
    state.CharacterRenderer = api
    return api
end
