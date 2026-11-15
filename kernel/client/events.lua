-- Inactive installed-QBX port; see NOTICE-09.md and LICENSE-QBX.
return function(ports)
    assert(type(ports) == 'table', 'explicit runtime ports required')
    local core = assert(ports.core, 'canonical client state required')
    local native = assert(ports.native, 'platform ports required')
    local cache = assert(ports.cache, 'cache port required')
    local config = assert(ports.config, 'local client configuration required')
    local api = {Events = {}, Callbacks = {}, Threads = {}, Exports = {}, StateBags = {}, EntityStateHandlers = {}}
    local function listen(name, handler, network)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = network == true}
    end
    local function network(name, handler) listen(name, handler, true) end
    local function callback(name, handler) api.Callbacks[name] = handler end
    local function thread(handler) api.Threads[#api.Threads + 1] = handler end
    local function describeExport(name, handler) api.Exports[name] = handler end
    local helpers = assert(ports.helpers, 'local Lib required')
    local library = assert(ports.library, 'explicit library ports required')
    local globalState = assert(ports.globalState, 'global state view required')
    local notify = assert(ports.notify, 'internal notification function required')
    local locale = assert(ports.locale, 'local translation port required')
    local function entityState(key, handler)
        api.EntityStateHandlers[#api.EntityStateHandlers + 1] = {key = key, handler = handler}
    end
    local function applyPvp(enabled)
        native.SetCanAttackFriendly(cache.ped, enabled, false)
        native.NetworkSetFriendlyFireOption(enabled)
    end

-- Player load and unload handling
network('QBCore:Client:OnPlayerLoaded', function()
    native.ShutdownLoadingScreenNui()
    -- Forge: sem statebag. Pede o estado global atual; as respostas chegam pelos eventos abaixo.
    native.TriggerServerEvent('qbx_core:server:requestGlobalState')

    if type(globalState.PVPEnabled) == 'boolean' then
        applyPvp(globalState.PVPEnabled)
    end

    native.NetworkEndTutorialSession()

    while native.NetworkIsInTutorialSession() do
        native.Wait(0)
    end

    local motd = native.GetConvar('qbx:motd', '')
    if motd ~= '' then
        -- exports.chat:addMessage({ template = motd })
    end
end)

---@param val PlayerData
network('QBCore:Player:SetPlayerData', function(val)
    local invokingResource = native.GetInvokingResource()
    if invokingResource and invokingResource ~= cache.resource then return end
    core.PlayerData = val
    core.BridgeCache.player(val, 'playerData')
    core.Session.refresh()
end)

---@param value boolean
-- Forge: sem statebag. O servidor envia cada mudanca do estado global por evento.
network('qbx_core:client:globalState:PVPEnabled', function(value)
    if native.source() ~= 65535 then return end
    if type(value) ~= 'boolean' then return end
    globalState.PVPEnabled = value
    applyPvp(value)
end)

network('qbx_core:client:globalState:MaxPlayers', function(value)
    if native.source() ~= 65535 then return end
    if type(value) ~= 'number' then return end
    globalState.MaxPlayers = value
end)

-- Teleport Commands

---@param coords vector3
network('QBCore:Command:TeleportToPlayer', function(coords)
    if native.GetInvokingResource() then return end

    core.BridgeCache.refreshContext('teleport')
    native.SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)
end)

---@param x number
---@param y number
---@param z number
---@param h number
network('QBCore:Command:TeleportToCoords', function(x, y, z, h)
    if native.GetInvokingResource() then return end
    core.BridgeCache.refreshContext('teleport')
    
    native.SetPedCoordsKeepVehicle(cache.ped, x, y, z)
    native.SetEntityHeading(cache.ped, h or native.GetEntityHeading(cache.ped))
end)

---@return 'marker'? error present if player did not place a blip
network('QBCore:Command:GoToMarker', function()
    if native.GetInvokingResource() then return end
    core.BridgeCache.refreshContext('teleport')
    local blipMarker <const> = native.GetFirstBlipInfoId(8)
    if not native.DoesBlipExist(blipMarker) then
        notify(locale('error.no_waypoint'), 'error')
        return 'marker'
    end

    -- Fade screen to hide how clients get teleported.
    native.DoScreenFadeOut(config.teleport.fadeDuration)
    while not native.IsScreenFadedOut() do
        native.Wait(0)
    end

    local ped, coords <const> = cache.ped, native.GetBlipInfoIdCoord(blipMarker)
    local vehicle = native.GetVehiclePedIsIn(ped, false)
    local oldCoords <const> = native.GetEntityCoords(ped)

    -- Unpack coords instead of having to unpack them while iterating.
    -- 825.0 seems to be the max a player can reach while 0.0 being the lowest.
    local x, y, groundZ, Z_START = coords.x, coords.y, config.teleport.groundSearchMaxZ, config.teleport.groundSearchStartZ
    local found = false
    if vehicle > 0 then
        native.FreezeEntityPosition(vehicle, true)
    else
        native.FreezeEntityPosition(ped, true)
    end

    for i = Z_START, 0, config.teleport.groundSearchStep do
        local z = i
        if (i % 2) ~= 0 then
            z = Z_START - i
        end

        native.NewLoadSceneStart(x, y, z, x, y, z, config.teleport.loadSceneRadius, 0)
        local curTime = native.GetGameTimer()
        while native.IsNetworkLoadingScene() do
            if native.GetGameTimer() - curTime > config.teleport.timeout then
                break
            end
            native.Wait(0)
        end
        native.NewLoadSceneStop()
        native.SetPedCoordsKeepVehicle(ped, x, y, z)

        while not native.HasCollisionLoadedAroundEntity(ped) do
            native.RequestCollisionAtCoord(x, y, z)
            if native.GetGameTimer() - curTime > config.teleport.timeout then
                break
            end
            native.Wait(0)
        end

        -- Get ground coord. As mentioned in the natives, this only works if the client is in render distance.
        found, groundZ = native.GetGroundZFor_3dCoord(x, y, z, false);
        if found then
            native.Wait(0)
            native.SetPedCoordsKeepVehicle(ped, x, y, groundZ)
            break
        end
        native.Wait(0)
    end

    -- Remove black screen once the loop has ended.
    native.DoScreenFadeIn(config.teleport.fadeDuration)
    if vehicle > 0 then
        native.FreezeEntityPosition(vehicle, false)
    else
        native.FreezeEntityPosition(ped, false)
    end

    if not found then
        -- If we can't find the coords, set the coords to the old ones.
        -- We don't unpack them before since they aren't in a loop and only called once.
        native.SetPedCoordsKeepVehicle(ped, oldCoords.x, oldCoords.y, oldCoords.z - 1.0)
        notify(locale('error.tp_error'), 'error')
    end

    -- If Z coord was found, set coords in found coords.
    native.SetPedCoordsKeepVehicle(ped, x, y, groundZ)
    notify(locale('success.teleported_waypoint'), 'success')
end)

-- Vehicle Commands

callback('qbx_core:client:getVehiclesInRadius', function(radius)
    local vehicles = library.getNearbyVehicles(native.GetEntityCoords(cache.ped), radius or config.getVehiclesInRadius.defaultRadius, true)

    for i = 1, #vehicles do
        vehicles[i] = native.VehToNet(vehicles[i].vehicle)
    end

    return vehicles
end)

-- Other stuff

---@see client/functions.lua:QBCore.Functions.Notify
network('QBCore:Notify', function(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
end)

-- Me command

---@param serverId number
---@param value string
-- Forge: sem statebag. O servidor envia (serverId, texto) por evento.
network('qbx_core:client:me', function(serverId, value)
    if native.source() ~= 65535 then return end
    if type(value) ~= 'string' then return end

    local playerId = native.GetPlayerFromServerId(tonumber(serverId) or -1)

    if not playerId or playerId == -1 or not native.NetworkIsPlayerActive(playerId) then return end

    local isLocalPlayer = playerId == cache.playerId
    local playerPed = isLocalPlayer and cache.ped or native.GetPlayerPed(playerId)

    -- Here we do a entity check to see if the player exsist within each clients scope --
    if not native.DoesEntityExist(playerPed) then return end

    -- Distance check to make sure that players do not see others me from 100s of meters away --
    if not isLocalPlayer and #(native.GetEntityCoords(playerPed) - native.GetEntityCoords(cache.ped)) > config.meCommand.distance then return end

    native.CreateThread(function()
        local displayTime = config.meCommand.displayTime + native.GetGameTimer()
        while displayTime > native.GetGameTimer() do
            playerPed = isLocalPlayer and cache.ped or native.GetPlayerPed(playerId)
            helpers.drawText3d({text = value, coords = native.GetEntityCoords(playerPed)})
            native.Wait(0)
        end
    end)
end)

-- Listen to Shared being updated
---@param tableName string
---@param key any
---@param value any
network('QBCore:Client:OnSharedUpdate', function(tableName, key, value)
    core.Shared[tableName][key] = value
    native.TriggerEvent('QBCore:Client:UpdateObject')
end)

---@param tableName string
---@param key any
network('QBCore:Client:OnSharedRemove', function(tableName, key)
    core.Shared[tableName][key] = nil
    native.TriggerEvent('QBCore:Client:UpdateObject')
end)

---@param tableName string
---@param values table<any, any>
network('QBCore:Client:OnSharedUpdateMultiple', function(tableName, values)
    for key, value in pairs(values) do
        core.Shared[tableName][key] = value
    end
    native.TriggerEvent('QBCore:Client:UpdateObject')
end)

-- Set vehicle props
---@param netId number
---@param props table<any, any>
network('qbx_core:client:setVehicleProperties', function(netId, props)
    if not props then return end
    local timeOut = native.GetGameTimer() + config.setVehicleProperties.timeout
    local vehicle = native.NetworkGetEntityFromNetworkId(netId)
    while true do
        if native.NetworkGetEntityOwner(vehicle) == cache.playerId then
            if library.setVehicleProperties(vehicle, props) then
                return
            end
        end
        if native.GetGameTimer() > timeOut then
            return
        end

        native.Wait(config.setVehicleProperties.waitInterval)
    end
end)

-- Clear vehicle peds
---@param vehicle number
---@param init boolean
entityState('initVehicle', function(vehicle, _, init)
    if not init then return end

    for _, i in ipairs(config.initVehicle.seats) do
        local ped = native.GetPedInVehicleSeat(vehicle, i)
        if ped ~= cache.ped and ped > 0 and native.NetworkGetEntityOwner(ped) == cache.playerId then
            native.DeleteEntity(ped)
        end
    end

    library.waitFor(function()
        return not native.IsEntityWaitingForWorldCollision(vehicle)
    end)

    if native.NetworkGetEntityOwner(vehicle) ~= cache.playerId then return end

    local state = native.Entity(vehicle).state

    native.SetVehicleOnGroundProperly(vehicle);

    native.SetTimeout(0, function()
        state:set('initVehicle', nil, true)
    end)
end)

    return api
end

