-- Private renderer port of the installed QBX client/character.lua (MIT; LICENSE-QBX).
-- No startup, registrations, global state, loading shutdown or external resource access.
return function(ports)
    local native = assert(ports.native, 'native ports required')
    local config = assert(ports.config, 'local client config required')
    local cache = assert(ports.cache, 'canonical cache required')
    local bridgeCache = assert(ports.bridgeCache, 'local BridgeCache required')
    local streaming = assert(ports.streaming, 'PR streaming ports required')
    local json = assert(ports.json, 'JSON codec required')
    local random = assert(ports.random, 'RNG port required')
    local getFallbackLocation = assert(ports.fallbackLocation, 'flow-owned fallback location required')
    local getPreviewPedData = assert(ports.getPreviewPedData, 'preview callback transport required')
    local setPedAppearance = assert(ports.setPedAppearance, 'PR arbitrary-ped appearance port required')

local function configuredPreviewLocations(payload)
    return type(payload) == 'table' and type(payload.previews) == 'table' and payload.previews or {}
end

local previewCam
local previewCameraRevision = 0
local previewCameraTarget
local previewPeds = {}
local previewLocations = {}
local configuredPreviewActive = false

local randomPeds = {
    {
        model = native.joaat('mp_m_freemode_01'),
        headOverlays = {
            beard = {color = 0, style = 0, secondColor = 0, opacity = 1},
            complexion = {color = 0, style = 0, secondColor = 0, opacity = 0},
            bodyBlemishes = {color = 0, style = 0, secondColor = 0, opacity = 0},
            blush = {color = 0, style = 0, secondColor = 0, opacity = 0},
            lipstick = {color = 0, style = 0, secondColor = 0, opacity = 0},
            blemishes = {color = 0, style = 0, secondColor = 0, opacity = 0},
            eyebrows = {color = 0, style = 0, secondColor = 0, opacity = 1},
            makeUp = {color = 0, style = 0, secondColor = 0, opacity = 0},
            sunDamage = {color = 0, style = 0, secondColor = 0, opacity = 0},
            moleAndFreckles = {color = 0, style = 0, secondColor = 0, opacity = 0},
            chestHair = {color = 0, style = 0, secondColor = 0, opacity = 1},
            ageing = {color = 0, style = 0, secondColor = 0, opacity = 1},
        },
        components = {
            {texture = 0, drawable = 0, component_id = 0},
            {texture = 0, drawable = 0, component_id = 1},
            {texture = 0, drawable = 0, component_id = 2},
            {texture = 0, drawable = 0, component_id = 5},
            {texture = 0, drawable = 0, component_id = 7},
            {texture = 0, drawable = 0, component_id = 9},
            {texture = 0, drawable = 0, component_id = 10},
            {texture = 0, drawable = 15, component_id = 11},
            {texture = 0, drawable = 15, component_id = 8},
            {texture = 0, drawable = 15, component_id = 3},
            {texture = 0, drawable = 34, component_id = 6},
            {texture = 0, drawable = 61, component_id = 4},
        },
        props = {
            {prop_id = 0, drawable = -1, texture = -1},
            {prop_id = 1, drawable = -1, texture = -1},
            {prop_id = 2, drawable = -1, texture = -1},
            {prop_id = 6, drawable = -1, texture = -1},
            {prop_id = 7, drawable = -1, texture = -1},
        }
    },
    {
        model = native.joaat('mp_f_freemode_01'),
        headBlend = {
            shapeMix = 0.3,
            skinFirst = 0,
            shapeFirst = 31,
            skinSecond = 0,
            shapeSecond = 0,
            skinMix = 0,
            thirdMix = 0,
            shapeThird = 0,
            skinThird = 0,
        },
        hair = {
            color = 0,
            style = 15,
            texture = 0,
            highlight = 0
        },
        headOverlays = {
            chestHair = {secondColor = 0, opacity = 0, color = 0, style = 0},
            bodyBlemishes = {secondColor = 0, opacity = 0, color = 0, style = 0},
            beard = {secondColor = 0, opacity = 0, color = 0, style = 0},
            lipstick = {secondColor = 0, opacity = 0, color = 0, style = 0},
            complexion = {secondColor = 0, opacity = 0, color = 0, style = 0},
            blemishes = {secondColor = 0, opacity = 0, color = 0, style = 0},
            moleAndFreckles = {secondColor = 0, opacity = 0, color = 0, style = 0},
            makeUp = {secondColor = 0, opacity = 0, color = 0, style = 0},
            ageing = {secondColor = 0, opacity = 1, color = 0, style = 0},
            eyebrows = {secondColor = 0, opacity = 1, color = 0, style = 0},
            blush = {secondColor = 0, opacity = 0, color = 0, style = 0},
            sunDamage = {secondColor = 0, opacity = 0, color = 0, style = 0},
        },
        components = {
            {drawable = 0, component_id = 0, texture = 0},
            {drawable = 0, component_id = 1, texture = 0},
            {drawable = 0, component_id = 2, texture = 0},
            {drawable = 0, component_id = 5, texture = 0},
            {drawable = 0, component_id = 7, texture = 0},
            {drawable = 0, component_id = 9, texture = 0},
            {drawable = 0, component_id = 10, texture = 0},
            {drawable = 15, component_id = 3, texture = 0},
            {drawable = 15, component_id = 11, texture = 3},
            {drawable = 14, component_id = 8, texture = 0},
            {drawable = 15, component_id = 4, texture = 3},
            {drawable = 35, component_id = 6, texture = 0},
        },
        props = {
            {prop_id = 0, drawable = -1, texture = -1},
            {prop_id = 1, drawable = -1, texture = -1},
            {prop_id = 2, drawable = -1, texture = -1},
            {prop_id = 6, drawable = -1, texture = -1},
            {prop_id = 7, drawable = -1, texture = -1},
        }
    }
}

local function clearConfiguredPreviews()
    for _, ped in pairs(previewPeds) do
        if ped and ped ~= 0 and native.DoesEntityExist(ped) then native.DeleteEntity(ped) end
    end
    previewPeds = {}
    previewLocations = {}
    configuredPreviewActive = false
end

local function previewCameraTargetPosition(location)
    if location.ped and native.DoesEntityExist(location.ped) then
        return native.GetPedBoneCoords(location.ped, 31086, 0.0, 0.0, 0.0)
    end
    return native.vector3(location.x, location.y, location.z + 1.65)
end

local function previewCameraPosition(location)
    local heading = math.rad(tonumber(location.heading or location.w) or 0.0)
    local distance = tonumber(config.characters.previewCameraDistance) or 3.2
    distance = math.max(1.0, math.min(distance, 10.0))
    local target = previewCameraTargetPosition(location)
    return native.vector3(
        target.x - math.sin(heading) * distance,
        target.y + math.cos(heading) * distance,
        target.z
    )
end

local function configuredOverview()
    local first, firstSlot, occupied, occupiedSlot
    for slot, location in pairs(previewLocations) do
        if not firstSlot or slot < firstSlot then first, firstSlot = location, slot end
        if location.hasCharacter and (not occupiedSlot or slot < occupiedSlot) then
            occupied, occupiedSlot = location, slot
        end
    end
    return occupied or first
end

local function transitionPreviewCamera(location)
    if not location or not previewCam or not native.DoesCamExist(previewCam) then return false end
    previewCameraRevision = previewCameraRevision + 1
    local revision, cam = previewCameraRevision, previewCam
    local origin = native.GetCamCoord(cam)
    local destination = previewCameraPosition(location)
    local target = previewCameraTargetPosition(location)
    local originTarget = previewCameraTarget or target
    local started = native.GetGameTimer()
    native.CreateThread(function()
        while revision == previewCameraRevision and previewCam == cam and native.DoesCamExist(cam) do
            local fraction = math.min(1.0, (native.GetGameTimer() - started) / 900.0)
            local blend = fraction * fraction * (3.0 - 2.0 * fraction)
            local coords = origin + (destination - origin) * blend
            previewCameraTarget = originTarget + (target - originTarget) * blend
            native.SetCamCoord(cam, coords.x, coords.y, coords.z)
            native.PointCamAtCoord(cam, previewCameraTarget.x, previewCameraTarget.y, previewCameraTarget.z)
            if fraction >= 1.0 then break end
            native.Wait(0)
        end
    end)
    return true
end

local function showConfiguredOverview()
    if configuredPreviewActive then return transitionPreviewCamera(configuredOverview()) end
    return false
end

local function setupPreviewCam(location)
    native.DoScreenFadeIn(1000)
    native.SetTimecycleModifier('hud_def_blur')
    native.SetTimecycleModifierStrength(1.0)
    native.FreezeEntityPosition(cache.ped, configuredPreviewActive)
    if location then
        local camCoords = previewCameraPosition(location)
        previewCam = native.CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 40.0, false, 0)
        previewCameraTarget = previewCameraTargetPosition(location)
        native.PointCamAtCoord(previewCam, previewCameraTarget.x, previewCameraTarget.y, previewCameraTarget.z)
    else
        local randomLocation = getFallbackLocation()
        previewCam = native.CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', randomLocation.camCoords.x, randomLocation.camCoords.y, randomLocation.camCoords.z, -6.0, 0.0, randomLocation.camCoords.w, 40.0, false, 0)
    end
    native.SetCamActive(previewCam, true)
    native.SetCamUseShallowDofMode(previewCam, not configuredPreviewActive)
    native.SetCamNearDof(previewCam, 0.4)
    native.SetCamFarDof(previewCam, 1.8)
    native.SetCamDofStrength(previewCam, 0.7)
    native.RenderScriptCams(true, false, 1, true, true)
    native.CreateThread(function()
        while previewCam and native.DoesCamExist(previewCam) do
            if not configuredPreviewActive then native.SetUseHiDof() end
            native.Wait(0)
        end
    end)
end

local function destroyPreviewCam()
    previewCameraRevision = previewCameraRevision + 1
    previewCameraTarget = nil
    native.SetTimecycleModifier('default')
    if previewCam then
        native.SetCamActive(previewCam, false)
        native.DestroyCam(previewCam, true)
        native.RenderScriptCams(false, false, 1, true, true)
    end
    clearConfiguredPreviews()
    native.FreezeEntityPosition(cache.ped, false)
    native.SetEntityVisible(cache.ped, true, false)
    native.SetEntityCollision(cache.ped, true, true)
    native.DisplayRadar(true)
    previewCam = nil
end

local function randomPed()
    local ped = randomPeds[random(1, #randomPeds)]
    streaming.requestModel(ped.model, config.loadingModelsTimeout)
    native.SetPlayerModel(cache.playerId, ped.model)
    bridgeCache.refreshContext('model')
    pcall(function() setPedAppearance(native.PlayerPedId(), ped) end)
    native.SetModelAsNoLongerNeeded(ped.model)
end

---@param citizenId? string
local function previewPed(citizenId)
    if not citizenId then randomPed() return end

    local clothing, model = getPreviewPedData(citizenId)
    if model and clothing then
        streaming.requestModel(model, config.loadingModelsTimeout)
        native.SetPlayerModel(cache.playerId, model)
        bridgeCache.refreshContext('model')
        pcall(function() setPedAppearance(native.PlayerPedId(), json.decode(clothing)) end)
        native.SetModelAsNoLongerNeeded(model)
    else
        randomPed()
    end
end

local function playSlotPreviewAnimation(ped, location)
    native.ClearPedTasksImmediately(ped)
    if location.scenario and location.scenario ~= '' then
        native.TaskStartScenarioInPlace(ped, location.scenario, 0, false)
        return
    end
    if not location.animDict or not location.animName then return end
    streaming.requestAnimDict(location.animDict, config.loadingModelsTimeout)
    native.TaskPlayAnim(ped, location.animDict, location.animName, 8.0, -8.0, -1, tonumber(location.animFlag) or 1, 0.0, false, false, false)
end

local function createSlotPreviewPed(character, location)
    local appearance, model
    if character then
        local clothing
        clothing, model = getPreviewPedData(character.citizenid)
        if clothing then
            local decoded, value = pcall(json.decode, clothing)
            if decoded then appearance = value end
        end
    end
    if not model or type(appearance) ~= 'table' then
        appearance = randomPeds[random(1, #randomPeds)]
        model = appearance.model
    end

    streaming.requestModel(model, config.loadingModelsTimeout)
    local modelHash = type(model) == 'number' and model or native.joaat(model)
    local ped = native.CreatePed(4, modelHash, location.x, location.y, location.z, location.heading, false, false)
    if not ped or ped == 0 then return nil end
    native.SetEntityAsMissionEntity(ped, true, true)
    native.SetEntityInvincible(ped, true)
    native.SetBlockingOfNonTemporaryEvents(ped, true)
    native.SetEntityCollision(ped, false, false)
    native.SetEntityHeading(ped, location.heading)
    pcall(function() setPedAppearance(ped, appearance) end)
    -- Saved coordinates are the support surface; match the editor's ped origin offset.
    native.SetEntityCoords(ped, location.x, location.y, location.z, false, false, false, false)
    native.SetEntityHeading(ped, location.heading)
    native.FreezeEntityPosition(ped, true)
    playSlotPreviewAnimation(ped, location)
    native.FreezeEntityPosition(ped, true)
    native.SetModelAsNoLongerNeeded(modelHash)
    return ped
end

local function buildConfiguredPreviews(charactersBySlot, amount, locations)
    clearConfiguredPreviews()
    for slot = 1, math.min(amount, #locations) do
        local source = locations[slot]
        local location = {
            x = tonumber(source.x), y = tonumber(source.y), z = tonumber(source.z),
            heading = tonumber(source.heading or source.w), animation = source.animation,
            scenario = source.scenario, animDict = source.animDict, animName = source.animName,
            animFlag = source.animFlag,
        }
        if location.x and location.y and location.z and location.heading then
            previewLocations[slot] = location
            previewPeds[slot] = createSlotPreviewPed(charactersBySlot[slot], location)
            location.ped = previewPeds[slot]
            location.hasCharacter = charactersBySlot[slot] ~= nil
        end
    end
    configuredPreviewActive = next(previewPeds) ~= nil
    return configuredPreviewActive
end

local function focusConfiguredPreview(slot)
    local location = previewLocations[slot]
    if not configuredPreviewActive or not location or not previewCam then return false end
    return transitionPreviewCamera(location)
end

    return {
        configuredPreviewLocations = configuredPreviewLocations,
        clearConfiguredPreviews = clearConfiguredPreviews,
        previewCameraTargetPosition = previewCameraTargetPosition,
        previewCameraPosition = previewCameraPosition,
        configuredOverview = configuredOverview,
        transitionPreviewCamera = transitionPreviewCamera,
        showConfiguredOverview = showConfiguredOverview,
        setupPreviewCam = setupPreviewCam,
        destroyPreviewCam = destroyPreviewCam,
        randomPed = randomPed,
        previewPed = previewPed,
        playSlotPreviewAnimation = playSlotPreviewAnimation,
        createSlotPreviewPed = createSlotPreviewPed,
        buildConfiguredPreviews = buildConfiguredPreviews,
        focusConfiguredPreview = focusConfiguredPreview,
        IsConfigured = function() return configuredPreviewActive end,
    }
end

