-- Inactive port of installed QBX source; see NOTICE-03.md and LICENSE-QBX.
-- Event descriptors are not runtime registrations. Server handlers take eventSource first.
return function(ports)
    assert(type(ports) == 'table', 'explicit producer ports required')
    local api = {Events = {}, Threads = {}, Exports = {}, Callbacks = {}}
    local function listen(name, handler, network)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = network == true}
    end
    local function describeExport(name, handler) api.Exports[name] = handler end
    local function thread(handler) api.Threads[#api.Threads + 1] = handler end
    local function callback(name, handler) api.Callbacks[name] = handler end
    local function network(name, handler) listen(name, handler, true) end
    local core = assert(ports.core, 'core state required')
    local native = assert(ports.native, 'native platform ports required')
    local DoesEntityExist = assert(native.DoesEntityExist, 'DoesEntityExist port required')
    local IsEntityDead = assert(native.IsEntityDead, 'IsEntityDead port required')
    local GetEntityMaxHealth = assert(native.GetEntityMaxHealth, 'GetEntityMaxHealth port required')
    local GetEntityHealth = assert(native.GetEntityHealth, 'GetEntityHealth port required')
    local PlayerPedId = assert(native.PlayerPedId, 'PlayerPedId port required')
    local IsEntityInWater = assert(native.IsEntityInWater, 'IsEntityInWater port required')
    local TriggerEvent = assert(native.TriggerEvent, 'TriggerEvent port required')
    local GetGameTimer = assert(native.GetGameTimer, 'GetGameTimer port required')
    local SetEntityHealth = assert(native.SetEntityHealth, 'SetEntityHealth port required')
    local SetPedArmour = assert(native.SetPedArmour, 'SetPedArmour port required')
    local SetPlayerUnderwaterTimeRemaining = assert(native.SetPlayerUnderwaterTimeRemaining, 'SetPlayerUnderwaterTimeRemaining port required')
    local PlayerId = assert(native.PlayerId, 'PlayerId port required')
    local DisableControlAction = assert(native.DisableControlAction, 'DisableControlAction port required')
    local DisablePlayerFiring = assert(native.DisablePlayerFiring, 'DisablePlayerFiring port required')
    local GetInvokingResource = assert(native.GetInvokingResource, 'GetInvokingResource port required')
    local TriggerServerEvent = assert(native.TriggerServerEvent, 'TriggerServerEvent port required')
    local GetPedArmour = assert(native.GetPedArmour, 'GetPedArmour port required')
    local IsPedFatallyInjured = assert(native.IsPedFatallyInjured, 'IsPedFatallyInjured port required')
    local SetPedToRagdoll = assert(native.SetPedToRagdoll, 'SetPedToRagdoll port required')
    local Wait = assert(native.Wait, 'Wait port required')
    local GetVehiclePedIsIn = assert(native.GetVehiclePedIsIn, 'GetVehiclePedIsIn port required')
    local GetVehicleClass = assert(native.GetVehicleClass, 'GetVehicleClass port required')
    local GetEntitySpeed = assert(native.GetEntitySpeed, 'GetEntitySpeed port required')
    local GetSelectedPedWeapon = assert(native.GetSelectedPedWeapon, 'GetSelectedPedWeapon port required')
    local GetHashKey = assert(native.GetHashKey, 'GetHashKey port required')
    local IsPedShooting = assert(native.IsPedShooting, 'IsPedShooting port required')
    local GetCurrentResourceName = assert(native.GetCurrentResourceName, 'GetCurrentResourceName port required')
    local SetPlayerHealthRechargeMultiplier = assert(native.SetPlayerHealthRechargeMultiplier, 'SetPlayerHealthRechargeMultiplier port required')
    local SetPlayerHealthRechargeLimit = assert(native.SetPlayerHealthRechargeLimit, 'SetPlayerHealthRechargeLimit port required')
    local GetPlayerUnderwaterTimeRemaining = assert(native.GetPlayerUnderwaterTimeRemaining, 'GetPlayerUnderwaterTimeRemaining port required')
    local GetPlayerSprintStaminaRemaining = assert(native.GetPlayerSprintStaminaRemaining, 'GetPlayerSprintStaminaRemaining port required')

local STATUS_KEYS = {
    health = true,
    armor = true,
    hunger = true,
    thirst = true,
    stress = true,
    oxygen = true,
}

local clientStatusConfig = assert(ports.config, 'client status configuration required')
local stressConfig = clientStatusConfig.stress or {}

core.Status = {
    health = 100,
    armor = 0,
    hunger = 100,
    thirst = 100,
    stress = 0,
    oxygen = 100,
}

local sessionLoaded = false
local sessionGeneration, sessionCharacter, lastSessionGeneration = nil, nil, 0
local nextDecayAt = 0
local decayIntervalMs = 300000
local hungerRate = 0
local thirstRate = 0
local wasDead = false
local nextRechargeDisableAt = 0
local seatbeltOn = false
local deathPoseOverride = false
local snapshotDirty = false
local snapshotDueAt = 0
local snapshotDebounceMs = math.max(250, math.floor(tonumber(clientStatusConfig.snapshotDebounceMs) or 500))

local function clamp(value)
    value = tonumber(value) or 0
    return math.max(0, math.min(100, value))
end

local function normalizeDelta(value)
    value = tonumber(value) or 0
    if value > 100 or value < -100 then value = value * 0.0001 end
    return math.max(-100, math.min(100, value))
end

local function healthPercent(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) or IsEntityDead(ped) then return 0 end
    local baseHealth = 100
    local maxHealth = math.max(baseHealth + 1, GetEntityMaxHealth(ped))
    local current = math.max(baseHealth, GetEntityHealth(ped))
    return clamp(math.floor(((current - baseHealth) / (maxHealth - baseHealth)) * 100 + 0.5))
end

local function nativeHealth(ped, percent)
    local baseHealth = 100
    local maxHealth = math.max(baseHealth + 1, GetEntityMaxHealth(ped))
    return math.floor(baseHealth + (maxHealth - baseHealth) * (clamp(percent) / 100) + 0.5)
end

local function snapshot()
    return {
        health = core.Status.health,
        armor = core.Status.armor,
        hunger = core.Status.hunger,
        thirst = core.Status.thirst,
        stress = core.Status.stress,
        oxygen = core.Status.oxygen,
    }
end

local function persistenceSnapshot(includeCharacterState)
    local values = snapshot()
    local character = core.PlayerData.citizenid
    local generation = sessionLoaded and sessionCharacter == character and sessionGeneration or nil
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) or not IsEntityInWater(ped) then
        -- Em terra o indicador representa stamina; stamina nao e um status persistente.
        values.oxygen = 100
    end
    values.extensions = {}
    -- Funcref collector works across resource boundaries; mutating an event's
    -- table argument in another resource does not update this Lua instance.
    local characterState, collecting = {}, true
    if includeCharacterState ~= false then TriggerEvent('forge-core:client:collectCharacterState', function(namespace, value)
        if collecting and type(namespace) == 'string' and #namespace <= 64
            and namespace:match('^[%w_%-]+$') and type(value) == 'table' then
            characterState[namespace] = value
        end
    end) end
    collecting = false
    if next(characterState) then values.extensions.clientState = characterState end
    TriggerEvent('qbx_core:client:collectStatusExtensions', values.extensions)
    -- Extension handlers may yield/reenter; never label the captured values with a later session.
    values._character, values._session = character, generation
    return values
end

local function publish(changes, reason)
    core.PlayerData.metadata = core.PlayerData.metadata or {}
    core.PlayerData.metadata.health = nativeHealth(PlayerPedId(), core.Status.health)
    core.PlayerData.metadata.armor = core.Status.armor
    core.PlayerData.metadata.hunger = core.Status.hunger
    core.PlayerData.metadata.thirst = core.Status.thirst
    core.PlayerData.metadata.stress = core.Status.stress
    core.PlayerData.metadata.oxygen = core.Status.oxygen

    local current = snapshot()
    TriggerEvent('qbx_core:client:statusChanged', current, changes or current, reason or 'update')
    TriggerEvent('hud:client:UpdateNeeds', current.hunger, current.thirst)
    TriggerEvent('hud:client:UpdateStress', current.stress)

    if reason ~= 'initialize' then
        for key in pairs(changes or {}) do
            if key ~= 'oxygen' then
                if not snapshotDirty then snapshotDueAt = GetGameTimer() + snapshotDebounceMs end
                snapshotDirty = true
                break
            end
        end
    end
end

local function applyNative(key, value)
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    if key == 'health' then
        if clamp(value) <= 0 then
            SetEntityHealth(ped, 0)
        elseif not IsEntityDead(ped) then
            SetEntityHealth(ped, nativeHealth(ped, value))
        end
    elseif key == 'armor' then
        SetPedArmour(ped, math.floor(clamp(value) + 0.5))
    elseif key == 'oxygen' then
        if IsEntityInWater(ped) then SetPlayerUnderwaterTimeRemaining(PlayerId(), clamp(value) / 10.0) end
    end
end

local function restorePersistedDeath()
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    local metadata = core.PlayerData and core.PlayerData.metadata or {}
    local persistedHealth = tonumber(metadata.health)
    if metadata.isdead == true
        or metadata.inlaststand == true
        or (persistedHealth and persistedHealth <= 100) then
        core.Status.health = 0
        SetEntityHealth(ped, 0)
    end
end

local function shouldKeepPlayerDead()
    if not sessionLoaded then return false end

    local metadata = core.PlayerData and core.PlayerData.metadata or {}
    return metadata.isdead == true
        or metadata.inlaststand == true
        or clamp(core.Status.health) <= 0
end

local function disableDeadPlayerControls()
    DisableControlAction(0, 21, true) -- sprint
    DisableControlAction(0, 22, true) -- jump
    DisableControlAction(0, 23, true) -- enter vehicle
    DisableControlAction(0, 24, true) -- attack
    DisableControlAction(0, 25, true) -- aim
    DisableControlAction(0, 30, true) -- move left/right
    DisableControlAction(0, 31, true) -- move forward/back
    DisableControlAction(0, 32, true)
    DisableControlAction(0, 33, true)
    DisableControlAction(0, 34, true)
    DisableControlAction(0, 35, true)
    DisableControlAction(0, 37, true) -- weapon wheel
    DisableControlAction(0, 44, true) -- cover
    DisableControlAction(0, 45, true) -- reload
    DisableControlAction(0, 75, true) -- exit vehicle
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 143, true)
    DisablePlayerFiring(PlayerId(), true)
end

listen('qbx_core:client:setDeathPoseOverride', function(enabled)
    local invokingResource = GetInvokingResource()
    if invokingResource and invokingResource ~= 'forge-core' then return end
    deathPoseOverride = enabled == true
end)

local function applyValues(values, mode, shouldApplyNative, reason)
    if type(values) ~= 'table' then return false end
    local changes = {}
    for key, rawValue in pairs(values) do
        if STATUS_KEYS[key] then
            local oldValue = core.Status[key]
            local newValue = mode == 'add' and clamp(oldValue + normalizeDelta(rawValue)) or clamp(rawValue)
            if oldValue ~= newValue then
                core.Status[key] = newValue
                changes[key] = newValue
                if shouldApplyNative then applyNative(key, newValue) end
            end
        end
    end
    if next(changes) then
        publish(changes, reason)
        return true
    end
    return false
end

local function flush(reason)
    if not sessionLoaded then return false end
    TriggerServerEvent('qbx_core:server:receiveStatusSnapshot', persistenceSnapshot(reason ~= 'client_cache'), reason or 'manual')
    snapshotDirty = false
    snapshotDueAt = 0
    return true
end

network('qbx_core:client:statusUpdated', function(status)
    if type(status) ~= 'table' then return end
    if status._session ~= nil or status._character ~= nil then
        local token = status._session
        if not sessionLoaded or status._character ~= core.PlayerData.citizenid
            or type(token) ~= 'number' or token <= 0 or token % 1 ~= 0 then return end
        if token < lastSessionGeneration or (token == lastSessionGeneration and token ~= sessionGeneration) then return end
        sessionGeneration, sessionCharacter, lastSessionGeneration = token, status._character, token
    elseif lastSessionGeneration > 0 then
        -- Once the Forge protocol is established, do not relabel legacy/stale data with a current generation.
        return
    end
    hungerRate = tonumber(status.hungerRate) or hungerRate
    thirstRate = tonumber(status.thirstRate) or thirstRate
    decayIntervalMs = math.max(60000, math.floor((tonumber(status.decayIntervalSeconds) or 300) * 1000))
    nextDecayAt = GetGameTimer() + math.max(1000, math.floor((tonumber(status.nextDecaySeconds) or 1) * 1000))
    local changed = applyValues(status, 'set', true, 'initialize')
    for _, key in ipairs({ 'health', 'armor', 'oxygen' }) do applyNative(key, core.Status[key]) end
    if not changed then publish(snapshot(), 'initialize') end
end)

network('qbx_core:client:applyStatusEffects', function(values)
    applyValues(values, 'add', true, 'effect')
end)

network('qbx_core:client:setStatus', function(key, value)
    applyValues({ [key] = value }, 'set', true, 'set')
end)

network('qbx_core:client:addStatus', function(key, value)
    applyValues({ [key] = value }, 'add', true, 'add')
end)

network('qbx_core:client:refreshNativeStatus', function()
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    applyValues({ health = healthPercent(ped), armor = GetPedArmour(ped) }, 'set', false, 'native')
end)

listen('forge-hud:client:seatbeltChanged', function(enabled)
    seatbeltOn = enabled == true
end)

listen('forge-hud:client:seatbeltChanged', function(enabled)
    seatbeltOn = enabled == true
end)

network('QBCore:Client:OnPlayerLoaded', function()
    sessionLoaded = true
    sessionGeneration, sessionCharacter = nil, nil
    wasDead = false
    snapshotDirty = false
    snapshotDueAt = 0
    restorePersistedDeath()
    TriggerServerEvent('qbx_core:server:requestStatus')
end)

-- O spawnmanager pode recriar o ped depois da aplicacao inicial da vida.
-- Enquanto o cache/metadata ainda disser que o personagem esta morto, este
-- controlador mantem a morte nativa e impede locomocao sem bloquear a tecla E
-- usada para solicitar o AutoMedic.
thread(function()
    while true do
        if shouldKeepPlayerDead() then
            local ped = PlayerPedId()
            if ped ~= 0 and DoesEntityExist(ped) then
                if not deathPoseOverride and not IsEntityDead(ped) and not IsPedFatallyInjured(ped) then
                    SetEntityHealth(ped, 0)
                    SetPedToRagdoll(ped, 1500, 1500, 0, false, false, false)
                end
                disableDeadPlayerControls()
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

local function stressAllowed()
    if stressConfig.disablePoliceStress then
        local job = core.PlayerData and core.PlayerData.job
        if type(job) == 'table' and job.name == 'police' then return false end
    end
    return true
end

thread(function()
    while true do
        if not sessionLoaded then
            Wait(1000)
        else
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 and stressAllowed() then
                local classes = stressConfig.vehicleClasses or {}
                local threshold = seatbeltOn
                    and (tonumber(stressConfig.minimumSpeedBuckled) or 100)
                    or (tonumber(stressConfig.minimumSpeedUnbuckled) or 50)
                if classes[GetVehicleClass(vehicle)] == true and GetEntitySpeed(vehicle) * 3.6 >= threshold then
                    applyValues({ stress = math.random(1, 3) }, 'add', false, 'driving')
                end
            end
            Wait(10000)
        end
    end
end)

thread(function()
    while true do
        if not sessionLoaded then
            Wait(1000)
        else
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            local whitelisted = stressConfig.whitelistedWeapons or {}
            if weapon ~= GetHashKey('WEAPON_UNARMED') and IsPedShooting(ped) and whitelisted[weapon] ~= true then
                if stressAllowed() and math.random() < (tonumber(stressConfig.chance) or 0.1) then
                    applyValues({ stress = math.random(1, 3) }, 'add', false, 'shooting')
                end
                Wait(100)
            else
                Wait(500)
            end
        end
    end
end)

network('QBCore:Client:OnPlayerUnload', function()
    sessionLoaded = false
    sessionGeneration, sessionCharacter = nil, nil
    -- Context owners retain this table across character sessions.
    -- Reset values without invalidating their captured identity on logout.
    for key in pairs(core.Status) do core.Status[key] = nil end
    for key, value in pairs({ health = 100, armor = 0, hunger = 100, thirst = 100, stress = 0, oxygen = 100 }) do
        core.Status[key] = value
    end
    snapshotDirty = false
    snapshotDueAt = 0
    nextDecayAt = 0
end)

listen('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then flush('resource_stop') end
end)

callback('qbx_core:client:getStatusSnapshot', function()
    return persistenceSnapshot()
end)

thread(function()
    while true do
        if not sessionLoaded then
            Wait(1000)
        else
            Wait(200)
            local now = GetGameTimer()
            local player = PlayerId()
            local ped = PlayerPedId()
            if now >= nextRechargeDisableAt then
                SetPlayerHealthRechargeMultiplier(player, 0.0)
                SetPlayerHealthRechargeLimit(player, 0.0)
                nextRechargeDisableAt = now + 1000
            end
            local dead = IsEntityDead(ped) or IsPedFatallyInjured(ped)
            local oxygen = IsEntityInWater(ped)
                and clamp(GetPlayerUnderwaterTimeRemaining(player) * 10)
                or clamp(GetPlayerSprintStaminaRemaining(player))
            applyValues({
                health = healthPercent(ped),
                armor = GetPedArmour(ped),
                oxygen = oxygen,
            }, 'set', false, 'native')
            if dead and not wasDead then flush('death') end
            wasDead = dead
            if nextDecayAt > 0 and now >= nextDecayAt then
                local elapsedTicks = math.floor((now - nextDecayAt) / decayIntervalMs) + 1
                applyValues({
                    hunger = -elapsedTicks * hungerRate,
                    thirst = -elapsedTicks * thirstRate,
                }, 'add', false, 'decay')
                nextDecayAt = nextDecayAt + elapsedTicks * decayIntervalMs
            end
            if snapshotDirty and now >= snapshotDueAt then flush('client_cache') end
        end
    end
end)

local function GetStatus(key)
    if key then return STATUS_KEYS[key] and core.Status[key] or nil end
    return snapshot()
end

local function SetStatus(key, value)
    return applyValues({ [key] = value }, 'set', true, 'export')
end

local function AddStatus(key, value)
    return applyValues({ [key] = value }, 'add', true, 'export')
end

local function AddStatuses(values)
    return applyValues(values, 'add', true, 'export')
end

describeExport('GetStatus', GetStatus)
describeExport('GetStatusSnapshot', snapshot)
describeExport('SetStatus', SetStatus)
describeExport('AddStatus', AddStatus)
describeExport('AddStatuses', AddStatuses)
describeExport('FlushStatusSnapshot', flush)
    return api
end
