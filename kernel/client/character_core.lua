-- Inactive client character composition over the same state and renderer.
local createFlow = require 'kernel.client.character'
local createRendererCore = require 'kernel.client.character_renderer_core'
local nationalities = require 'kernel.data.nationalities'

return function(state, ports)
    assert(type(state) == 'table' and state.CharacterCore == nil, 'fresh character attachment required')
    assert(type(state.PlayerData) == 'table' and type(state.BridgeCache) == 'table', 'canonical client state/cache required')
    assert(type(ports) == 'table' and type(ports.config) == 'table', 'local character config required')
    if ports.config.characters.useExternalCharacters then
        local api = {State = state, Flow = createFlow({config = ports.config})}
        state.CharacterCore = api
        return api
    end
    assert(state.CharacterRenderer == nil, 'renderer must be owned by this composition')
    assert(type(ports.functions) == 'table' and type(ports.functions.Notify) == 'function', 'local Notify required')
    local flow
    local rendererCore = createRendererCore(state, {
        native = ports.native, config = ports.config, cache = ports.cache,
        streaming = ports.streaming, json = ports.json, random = ports.random,
        fallbackLocation = function() return flow.GetFallbackLocation() end,
        getPreviewPedData = function(citizenId)
            return ports.callbacks.await('qbx_core:server:getPreviewPedData', false, citizenId)
        end,
        setPedAppearance = ports.setPedAppearance,
    })
    flow = createFlow({
        core = state, config = ports.config, defaultSpawn = ports.defaultSpawn,
        native = ports.native, cache = ports.cache, renderer = rendererCore.Renderer,
        ui = ports.ui, callbacks = ports.callbacks, integrations = ports.integrations,
        notify = ports.functions.Notify, locale = ports.locale, groupdigits = ports.groupdigits,
        strsplit = ports.strsplit, random = ports.random, nationalities = nationalities,
    })
    local api = {State = state, Flow = flow, Renderer = rendererCore.Renderer}
    state.CharacterCore = api
    return api
end
