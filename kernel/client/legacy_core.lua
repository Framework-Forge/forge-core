-- Inactive composition over an existing canonical state; no new PlayerData authority.
local createUtils = require 'kernel.modules.utils'
local createFunctions = require 'kernel.client.functions'
local createGroups = require 'kernel.client.groups'

return function(state, ports)
    assert(type(state) == 'table' and state.LegacyCore == nil, 'fresh attachment to existing client state required')
    assert(type(state.PlayerData) == 'table', 'canonical PlayerData table required')
    assert(type(ports) == 'table', 'legacy composition ports required')
    local utils = createUtils({isServer = false, native = ports.native, library = ports.library,
        helpers = ports.helpers, cache = ports.cache, random = ports.random,
        strsplit = ports.strsplit, searchInventory = ports.searchInventory})
    local functions = createFunctions({core = state, membership = ports.membership,
        notify = ports.notify, notifyPosition = ports.notifyPosition})
    local groups = createGroups({jobs = ports.jobs, gangs = ports.gangs, awaitGroups = ports.awaitGroups})
    local initialized, initializing = false, false
    local api = {State = state, Utils = utils, Functions = functions, Groups = groups}
    function api.Initialize()
        if initialized or initializing then return false end
        initializing = true
        local ok, err = pcall(function()
            utils.Initialize()
            groups.Initialize()
        end)
        initializing = false
        if not ok then error(err, 0) end
        initialized = true
        return true
    end
    state.LegacyCore = api
    return api
end
