-- Inactive attachment; consumes the existing authoritative PlayerCore/Lifecycle.
local createMain = require 'kernel.server.main'
local createWeapons = require 'kernel.server.weapons'
local createCommands = require 'kernel.server.commands'

return function(base, playerCore, ports)
    assert(type(base) == 'table' and base.PlayerCore == playerCore, 'existing player core required')
    assert(type(playerCore) == 'table' and playerCore.Runtime == nil, 'fresh server runtime attachment required')
    local state = assert(playerCore.State, 'canonical server state required')
    local functions = assert(playerCore.Lifecycle, 'existing lifecycle required').Functions
    local players, lookup = assert(playerCore.Players), assert(playerCore.Lookup)
    assert(type(ports) == 'table', 'server runtime ports required')
    local services = {GetPlayer = lookup.GetPlayer, IsOptin = functions.IsOptin, Notify = functions.Notify,
        AddPermission = functions.AddPermission, RemovePermission = functions.RemovePermission,
        DeleteVehicle = functions.DeleteVehicle, ToggleOptin = functions.ToggleOptin,
        SetPlayerPrimaryJob = players.SetPlayerPrimaryJob, AddPlayerToJob = players.AddPlayerToJob,
        RemovePlayerFromJob = players.RemovePlayerFromJob, Logout = players.Logout,
        -- Installed public DeleteCharacter is the force-delete implementation, not the ownership callback.
        ForceDeleteCharacter = players.DeleteCharacter}
    local bindings = {core = state, native = ports.native, library = ports.library, helpers = ports.helpers,
        globalState = ports.globalState, newPromise = ports.newPromise, awaitPromise = ports.awaitPromise,
        random = ports.random, config = ports.config, logger = ports.logger, locale = ports.locale,
        json = ports.json, removeKeyItem = ports.removeKeyItem, chatMessage = ports.chatMessage, services = services}
    local api = {State = state, Main = createMain(bindings), Weapons = createWeapons(bindings), Commands = createCommands(bindings)}
    local initialized, initializing = false, false
    function api.Initialize()
        if initialized or initializing then return false end
        initializing = true
        local ok, err = pcall(function()
            api.Main.Initialize()
            api.Commands.Initialize()
        end)
        initializing = false
        if not ok then error(err, 0) end
        initialized = true
        return true
    end
    playerCore.Runtime = api
    return api
end
