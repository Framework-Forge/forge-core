-- Private, inactive composition; it neither creates nor resets canonical PlayerData.
local createMain = require 'kernel.client.main'
local createEvents = require 'kernel.client.events'
local createLoops = require 'kernel.client.loops'
local createDiscord = require 'kernel.client.discord'

return function(state, ports)
    assert(type(state) == 'table' and state.RuntimeCore == nil, 'fresh runtime attachment required')
    assert(type(state.PlayerData) == 'table' and type(state.Shared) == 'table', 'canonical client state/shared required')
    assert(type(state.BridgeCache) == 'table' and type(state.Session) == 'table' and type(state.Status) == 'table', 'local producers required')
    assert(type(ports) == 'table' and type(ports.functions) == 'table', 'local client functions required')
    local bindings = {core = state, native = ports.native, cache = ports.cache, config = ports.config,
        helpers = ports.helpers, library = ports.library, globalState = ports.globalState,
        notify = assert(ports.functions.Notify, 'internal Notify required'), locale = ports.locale, random = ports.random}
    local api = {State = state, Main = createMain(bindings), Events = createEvents(bindings),
        Loops = createLoops(bindings), Discord = createDiscord(bindings)}
    local initialized, initializing = false, false
    function api.Initialize()
        if initialized or initializing then return false end
        initializing = true
        local ok, err = pcall(function()
            api.Main.Initialize()
            api.Discord.Initialize()
        end)
        initializing = false
        if not ok then error(err, 0) end
        initialized = true
        return true
    end
    state.RuntimeCore = api
    return api
end
