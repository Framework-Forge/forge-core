ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Starterpack = {
    payload = nil,
    lamar = nil,
    vehicle = nil,
    targetName = nil,
    boarding = false,
    routeActive = false,
    routeBlip = nil,
    routeCamera = nil,
    trafficOverride = false,
    usesRouteRewards = false,
    pendingRewards = 0,
    cameraEditor = nil,
    editorAddFrame = nil,
    playingCam = nil,
}

local stopRouteCamera
local stopTrafficOverride
local setVehicleRouteLock

ForgeCore.Client.Starterpack = Starterpack

local driveStyle = 786603
local defaultDriveSpeed = 22.0
local stopRange = 2.5
local clearTrafficInterval = 1500

local controlsToDisable = {
    24, 25, 257, 140, 141, 142, 143,
    23, 75, 76, 79, 80, 81, 82, 85, 86,
    32, 33, 34, 35, 59, 60, 63, 64, 71, 72,
}

local editorControls = {
    1, 2, 24, 25, 257, 140, 141, 142, 143,
    16, 17, 32, 33, 34, 35, 22, 36, 44, 38,
    21, 19, 172, 173, 174, 175, 241, 242,
    15, 14, 20, 26, 177, 178, 73,
    191, 194, 200, 202, 322,
}

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function notify(description, notifyType)
    if pr_lib and pr_lib.Notify then
        pr_lib.Notify({
            title = t('starterpack.title'),
            description = description,
            type = notifyType or 'inform',
            position = PR.NotifyPos,
        })
    end
end

local function vec3(value)
    if type(value) == 'vector3' then return value end
    value = type(value) == 'table' and value or {}
    return vector3(tonumber(value.x or value[1]) or 0.0, tonumber(value.y or value[2]) or 0.0, tonumber(value.z or value[3]) or 0.0)
end

local function serialVector(value)
    value = vec3(value)
    return {
        x = tonumber(('%0.3f'):format(value.x)),
        y = tonumber(('%0.3f'):format(value.y)),
        z = tonumber(('%0.3f'):format(value.z)),
    }
end

local function trim(value)
    if pr_lib and pr_lib.utils and pr_lib.utils.trim then return pr_lib.utils.trim(value) end
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function isZeroCoords(coords)
    coords = vec3(coords)
    return math.abs(coords.x) < 0.01 and math.abs(coords.y) < 0.01 and math.abs(coords.z) < 0.01
end

local function headingVector(heading)
    local rad = math.rad(tonumber(heading) or 0.0)
    return vector3(-math.sin(rad), math.cos(rad), 0.0)
end

local function rightVector(heading)
    local rad = math.rad(tonumber(heading) or 0.0)
    return vector3(math.cos(rad), math.sin(rad), 0.0)
end

local function deleteEntity(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end

    if pr_lib and pr_lib.fivem and pr_lib.fivem.streaming and pr_lib.fivem.streaming.deleteEntity then
        pr_lib.fivem.streaming.deleteEntity(entity)
        return
    end

    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
end

local function clearRouteBlip()
    if Starterpack.routeBlip and DoesBlipExist(Starterpack.routeBlip) then
        RemoveBlip(Starterpack.routeBlip)
    end

    Starterpack.routeBlip = nil
end

local function clearTarget()
    if Starterpack.targetName and Starterpack.lamar and DoesEntityExist(Starterpack.lamar) and pr_lib and pr_lib.target and pr_lib.target.removeLocalEntity then
        pr_lib.target.removeLocalEntity(Starterpack.lamar, Starterpack.targetName)
    end

    Starterpack.targetName = nil
end

local function cleanupScene(keepVehicles)
    Starterpack.boarding = false
    Starterpack.routeActive = false
    stopRouteCamera()
    stopTrafficOverride()
    clearTarget()
    clearRouteBlip()

    if not keepVehicles then
        deleteEntity(Starterpack.lamar)
        deleteEntity(Starterpack.vehicle)
        Starterpack.lamar = nil
        Starterpack.vehicle = nil
    end

    if Starterpack.playingCam then
        DestroyCam(Starterpack.playingCam, false)
        Starterpack.playingCam = nil
    end

    if Starterpack.vehicle and DoesEntityExist(Starterpack.vehicle) then
        SetVehicleDoorsLockedForPlayer(Starterpack.vehicle, PlayerId(), false)
        setVehicleRouteLock(Starterpack.vehicle, false)
    end

    RenderScriptCams(false, false, 0, true, false)
    if SetCinematicModeActive then SetCinematicModeActive(false) end
end

local function configureLamar(ped)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
end

local function configureVehicle(vehicle, lockDoors)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetEntityInvincible(vehicle, true)
    SetVehicleCanBreak(vehicle, false)
    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleTyresCanBurst(vehicle, false)
    SetVehicleEngineCanDegrade(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDoorsLocked(vehicle, lockDoors == true and 4 or 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    SetVehicleRadioEnabled(vehicle, false)
    SetEntityProofs(vehicle, true, true, true, true, true, true, true, true)
end

function setVehicleRouteLock(vehicle, locked)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    SetVehicleHandbrake(vehicle, locked == true)
    SetVehicleUndriveable(vehicle, locked == true)
    if locked then
        SetVehicleForwardSpeed(vehicle, 0.0)
    else
        SetVehicleEngineOn(vehicle, true, true, false)
    end
end

local function spawnVehicle(model, coords, heading)
    if pr_lib and pr_lib.fivem and pr_lib.fivem.streaming and pr_lib.fivem.streaming.createVehicle then
        return pr_lib.fivem.streaming.createVehicle(model, coords, heading, {
            networked = false,
            missionEntity = true,
            invincible = true,
            freeze = false,
            collision = true,
            timeout = 5000,
            placeProperly = true,
            placementType = 'vehicle',
        })
    end

    return nil
end

local function spawnPed(model, coords, heading)
    if pr_lib and pr_lib.fivem and pr_lib.fivem.streaming and pr_lib.fivem.streaming.createPed then
        return pr_lib.fivem.streaming.createPed(model, coords, heading, {
            networked = false,
            missionEntity = true,
            invincible = true,
            freeze = true,
            collision = true,
            timeout = 5000,
            placeProperly = true,
            placementType = 'ped',
        })
    end

    return nil
end

local function addLamarTarget()
    clearTarget()
    if not Starterpack.lamar or not DoesEntityExist(Starterpack.lamar) then return end
    if not pr_lib or not pr_lib.target or not pr_lib.target.addLocalEntity then return end

    local targetName = 'forge_core_starterpack_lamar'
    pr_lib.target.addLocalEntity(Starterpack.lamar, {
        {
            name = targetName,
            label = t('menu.starterpack.talk_lamar'),
            icon = 'signpost-split-fill',
            distance = 2.5,
            canInteract = function()
                return not Starterpack.routeActive
            end,
            onSelect = function()
                Starterpack.startPrologue(true)
            end,
        },
    })

    Starterpack.targetName = targetName
end

local function currentPrologue(payload)
    payload = payload or Starterpack.payload or {}
    return type(payload.prologue) == 'table' and payload.prologue or {}
end

local function ensureScene(payload)
    Starterpack.payload = payload or Starterpack.payload or GlobalState.forgeStarterpack
    local prologue = currentPrologue()
    if prologue.enabled ~= true then return false, 'prologue_disabled' end
    local vehicleStart = type(prologue.vehicleStart) == 'table' and prologue.vehicleStart or prologue.start
    if not vehicleStart or isZeroCoords(vehicleStart.coords) then return false, 'start_not_configured' end

    local vehicleCoords = vec3(vehicleStart.coords)
    local vehicleHeading = tonumber(vehicleStart.heading) or 0.0

    if not Starterpack.vehicle or not DoesEntityExist(Starterpack.vehicle) then
        Starterpack.vehicle = spawnVehicle(prologue.vehicleModel or 'asea', vehicleCoords, vehicleHeading)
        if not Starterpack.vehicle then return false, 'vehicle_spawn_failed' end
        configureVehicle(Starterpack.vehicle, false)
        FreezeEntityPosition(Starterpack.vehicle, true)
    end

    if not Starterpack.lamar or not DoesEntityExist(Starterpack.lamar) then
        local lamarStart = type(prologue.lamarStart) == 'table' and prologue.lamarStart or nil
        local lamarCoords = lamarStart and not isZeroCoords(lamarStart.coords)
            and vec3(lamarStart.coords)
            or vehicleCoords + rightVector(vehicleHeading) * 2.2 - headingVector(vehicleHeading) * 1.2
        local lamarHeading = lamarStart and not isZeroCoords(lamarStart.coords)
            and (tonumber(lamarStart.heading) or vehicleHeading)
            or (vehicleHeading + 180.0)
        Starterpack.lamar = spawnPed(prologue.lamarModel or 'ig_lamardavis', lamarCoords, lamarHeading)
        if not Starterpack.lamar then return false, 'lamar_spawn_failed' end
        configureLamar(Starterpack.lamar)
    end

    addLamarTarget()
    return true
end

local function showSubtitle(text, duration)
    text = trim(text)
    if text == '' then return end

    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(tonumber(duration) or 5000, true)
end

local function makeRouteBlip(stop)
    clearRouteBlip()

    local coords = vec3(stop.coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, tonumber(stop.blipSprite) or 1)
    SetBlipColour(blip, tonumber(stop.blipColor) or 5)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, tonumber(stop.blipColor) or 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(stop.title or t('menu.starterpack.stop_default_title'))
    EndTextCommandSetBlipName(blip)

    Starterpack.routeBlip = blip
end

local routeCameraPresets = {
    { x = 0.0, y = -7.0, z = 3.0, fov = 48.0 },
    { x = 4.5, y = -5.0, z = 2.5, fov = 52.0 },
    { x = -4.5, y = -4.0, z = 2.4, fov = 50.0 },
    { x = 0.0, y = 4.5, z = 2.8, fov = 54.0 },
}

stopTrafficOverride = function()
    if not Starterpack.trafficOverride then return end

    if SetTrafficLightsState then SetTrafficLightsState(5) end
    if SetTrafficLightsState2 then SetTrafficLightsState2(5) end
    Starterpack.trafficOverride = false
end

local function startTrafficOverride()
    if Starterpack.trafficOverride then return end

    if SetTrafficLightsState then SetTrafficLightsState(1) end
    if SetTrafficLightsState2 then SetTrafficLightsState2(1) end
    Starterpack.trafficOverride = true
end

stopRouteCamera = function()
    if not Starterpack.routeCamera then return end

    RenderScriptCams(false, true, 500, true, false)
    DestroyCam(Starterpack.routeCamera, false)
    Starterpack.routeCamera = nil
end

local function startRouteCamera()
    if Starterpack.routeCamera or not Starterpack.vehicle or not DoesEntityExist(Starterpack.vehicle) then return end

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', false)
    Starterpack.routeCamera = cam
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 800, true, false)

    CreateThread(function()
        local index = 1
        local nextIndex = 2
        local transitionStarted = GetGameTimer()
        local transitionDuration = 2200
        local manualYaw = 0.0
        local manualPitch = 0.0
        local lastManualInput = GetGameTimer()

        while Starterpack.routeCamera == cam and Starterpack.routeActive do
            if Starterpack.playingCam then
                Wait(100)
            elseif not Starterpack.vehicle or not DoesEntityExist(Starterpack.vehicle) then
                break
            else
                local now = GetGameTimer()
                local phase = math.min(1.0, (now - transitionStarted) / transitionDuration)
                local from = routeCameraPresets[index]
                local to = routeCameraPresets[nextIndex]
                local eased = phase * phase * (3.0 - 2.0 * phase)
                local x = from.x + (to.x - from.x) * eased
                local y = from.y + (to.y - from.y) * eased
                local z = from.z + (to.z - from.z) * eased
                local fov = from.fov + (to.fov - from.fov) * eased
                local coords = GetOffsetFromEntityInWorldCoords(Starterpack.vehicle, x, y, z)

                SetCamCoord(cam, coords.x, coords.y, coords.z)
                PointCamAtEntity(cam, Starterpack.vehicle, 0.0, 0.0, 0.8, true)
                SetCamFov(cam, fov)

                local mouseX = GetControlNormal(0, 1)
                local mouseY = GetControlNormal(0, 2)
                if math.abs(mouseX) > 0.001 or math.abs(mouseY) > 0.001 then
                    manualYaw = math.max(-75.0, math.min(75.0, manualYaw - mouseX * 5.0))
                    manualPitch = math.max(-35.0, math.min(35.0, manualPitch + mouseY * 4.0))
                    lastManualInput = now
                elseif now - lastManualInput > 3500 then
                    manualYaw = manualYaw * 0.96
                    manualPitch = manualPitch * 0.96
                end

                if math.abs(manualYaw) > 0.05 or math.abs(manualPitch) > 0.05 then
                    local baseRot = GetCamRot(cam, 2)
                    SetCamRot(cam, baseRot.x + manualPitch, baseRot.y, baseRot.z + manualYaw, 2)
                end

                if phase >= 1.0 then
                    index = nextIndex
                    nextIndex = (nextIndex % #routeCameraPresets) + 1
                    transitionStarted = now
                end

                Wait(0)
            end
        end

        if Starterpack.routeCamera == cam then
            stopRouteCamera()
        end
    end)
end

local function playCameraFrames(frames)
    frames = type(frames) == 'table' and frames or {}
    if #frames <= 0 then return end

    Starterpack.cameraPaused = true
    stopRouteCamera()
    if Starterpack.vehicle and DoesEntityExist(Starterpack.vehicle) then
        ClearPedTasks(PlayerPedId())
        SetVehicleForwardSpeed(Starterpack.vehicle, 0.0)
        SetVehicleHandbrake(Starterpack.vehicle, true)
    end

    if Starterpack.playingCam then
        DestroyCam(Starterpack.playingCam, false)
        Starterpack.playingCam = nil
    end

    local cam = CreateCam(#frames > 1 and 'DEFAULT_SPLINE_CAMERA' or 'DEFAULT_SCRIPTED_CAMERA', false)
    Starterpack.playingCam = cam

    if #frames > 1 then
        for _, frame in ipairs(frames) do
            local coords = vec3(frame.coords or frame.pos)
            local rot = vec3(frame.rot)
            AddCamSplineNode(cam, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, tonumber(frame.duration) or 2500, 0, 2)
        end
    else
        local frame = frames[1]
        local coords = vec3(frame.coords or frame.pos)
        local rot = vec3(frame.rot)
        SetCamCoord(cam, coords.x, coords.y, coords.z)
        SetCamRot(cam, rot.x, rot.y, rot.z, 2)
        SetCamFov(cam, tonumber(frame.fov) or 50.0)
    end

    SetCamActive(cam, true)
    RenderScriptCams(true, true, 800, true, false)

    if #frames > 1 then
        local timeout = GetGameTimer() + 120000
        while Starterpack.playingCam == cam and GetGameTimer() < timeout do
            if GetCamSplinePhase(cam) >= 0.999 then break end
            Wait(50)
        end
    else
        Wait(tonumber(frames[1].duration) or 2500)
    end

    if Starterpack.playingCam == cam then
        RenderScriptCams(false, true, 800, true, false)
        DestroyCam(cam, false)
        Starterpack.playingCam = nil
    end

    if Starterpack.vehicle and DoesEntityExist(Starterpack.vehicle) then
        SetVehicleHandbrake(Starterpack.vehicle, false)
    end
    Starterpack.cameraPaused = false
    RenderScriptCams(false, true, 800, true, false)
end

local function forcePassengerState(vehicle)
    local ped = PlayerPedId()

    DisablePlayerFiring(PlayerId(), true)
    for _, control in ipairs(controlsToDisable) do
        DisableControlAction(0, control, true)
        DisableControlAction(2, control, true)
    end
    DisableControlAction(0, 23, true)
    DisableControlAction(2, 23, true)
    DisableControlAction(0, 75, true)
    DisableControlAction(2, 75, true)
    DisableControlAction(0, 76, true)
    DisableControlAction(2, 76, true)

    if not IsPedInVehicle(ped, vehicle, false) then
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
    elseif GetPedInVehicleSeat(vehicle, -1) ~= ped then
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
    end
end

local function keepPlayerLockedInVehicle(vehicle)
    local ped = PlayerPedId()
    forcePassengerState(vehicle)

    if DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, 4)
        SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), true)
    end

    if not IsPedInVehicle(ped, vehicle, false) or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
    end
end

local function vehicleHasPlayer(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end

    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) or 0
    for seat = -1, seats - 2 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped and ped ~= 0 and IsPedAPlayer(ped) then return true end
    end

    return false
end

local function clearSlowTrafficAhead(routeVehicle)
    if not routeVehicle or routeVehicle == 0 or not DoesEntityExist(routeVehicle) then return end

    local origin = GetEntityCoords(routeVehicle)
    local forward = GetEntityForwardVector(routeVehicle)
    local vehicles = GetGamePool and GetGamePool('CVehicle') or {}

    for _, vehicle in ipairs(vehicles) do
        if vehicle ~= routeVehicle and DoesEntityExist(vehicle) and not vehicleHasPlayer(vehicle) then
            local coords = GetEntityCoords(vehicle)
            local offset = coords - origin
            local distance = #(offset)

            if distance > 2.5 and distance <= 22.0 then
                local dot = (offset.x * forward.x + offset.y * forward.y + offset.z * forward.z) / math.max(distance, 0.01)
                if dot > 0.72 and GetEntitySpeed(vehicle) <= 4.5 then
                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteVehicle(vehicle)
                end
            end
        end
    end
end

local function startAutopilotTask(ped, vehicle, coords, driveSpeed)
    if not ped or ped == 0 or not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    setVehicleRouteLock(vehicle, false)
    ClearPedTasks(ped)
    SetVehicleHandbrake(vehicle, false)
    SetVehicleForwardSpeed(vehicle, math.max(2.0, math.min(8.0, tonumber(driveSpeed) or defaultDriveSpeed)))
    TaskVehicleDriveToCoordLongrange(ped, vehicle, coords.x, coords.y, coords.z, driveSpeed, driveStyle, stopRange)
end

local function driveToStop(stop)
    local ped = PlayerPedId()
    local vehicle = Starterpack.vehicle
    local coords = vec3(stop.coords)
    local startCoords = GetEntityCoords(vehicle)
    local totalDistance = math.max(1.0, #(startCoords - coords))
    local shownDialogs = {}
    local shownRewards = {}
    local prologue = currentPrologue()
    local driveSpeed = tonumber(prologue.autopilotMaxSpeed) or defaultDriveSpeed
    local lastRemaining = totalDistance
    local stalledAt = GetGameTimer()
    local nextTrafficClear = 0

    makeRouteBlip(stop)
    showSubtitle(stop.routeText, 6000)
    startTrafficOverride()
    stopRouteCamera()
    RenderScriptCams(false, false, 0, true, false)
    startAutopilotTask(ped, vehicle, coords, driveSpeed)

    local timeout = GetGameTimer() + 240000
    while Starterpack.routeActive and DoesEntityExist(vehicle) and GetGameTimer() < timeout do
        forcePassengerState(vehicle)

        local now = GetGameTimer()
        local current = GetEntityCoords(vehicle)
        local remaining = #(current - coords)
        local progress = math.max(0.0, math.min(100.0, ((totalDistance - remaining) / totalDistance) * 100.0))

        if now >= nextTrafficClear then
            clearSlowTrafficAhead(vehicle)
            nextTrafficClear = now + clearTrafficInterval
        end

        for index, dialog in ipairs(type(stop.routeDialogs) == 'table' and stop.routeDialogs or {}) do
            if not shownDialogs[index] and progress >= (tonumber(dialog.progress) or 0) then
                shownDialogs[index] = true
                showSubtitle(dialog.text, tonumber(dialog.duration) or 5000)
            end
        end

        for index, reward in ipairs(type(stop.rewards) == 'table' and stop.rewards or {}) do
            if reward.enabled ~= false and not shownRewards[index] and progress >= (tonumber(reward.progress) or 0) then
                shownRewards[index] = true
                if trim(reward.dialogue) ~= '' then
                    showSubtitle(reward.dialogue, tonumber(reward.duration) or 5000)
                end

                Starterpack.pendingRewards = Starterpack.pendingRewards + 1
                CreateThread(function()
                    local ok, response = pr_lib.callback.await(PR.Starterpack.Callbacks.grantReward, 10000, stop.id, reward.id)
                    if not ok and response ~= 'already_granted' then
                        print(('[forge-core:starterpack] reward failed: %s'):format(tostring(response or 'unknown')))
                    end
                    Starterpack.pendingRewards = math.max(0, Starterpack.pendingRewards - 1)
                end)
            end
        end

        if remaining <= stopRange then break end

        if remaining < lastRemaining - 0.2 then
            lastRemaining = remaining
            stalledAt = now
        elseif now - stalledAt >= 5000 then
            startAutopilotTask(ped, vehicle, coords, driveSpeed)
            stalledAt = now
        end

        Wait(250)
    end

    ClearPedTasks(ped)
    SetVehicleForwardSpeed(vehicle, 0.0)
    setVehicleRouteLock(vehicle, true)
    Wait(450)
    clearRouteBlip()
end

local function finishRoute()
    local ped = PlayerPedId()
    local vehicle = Starterpack.vehicle
    local lamar = Starterpack.lamar

    Starterpack.routeActive = false
    stopRouteCamera()
    stopTrafficOverride()
    clearRouteBlip()
    if SetCinematicModeActive then SetCinematicModeActive(false) end

    if vehicle and DoesEntityExist(vehicle) then
        SetVehicleDoorsLocked(vehicle, 1)
        TaskLeaveVehicle(ped, vehicle, 0)
        Wait(1200)

        if lamar and DoesEntityExist(lamar) then
            ClearPedTasksImmediately(lamar)
            FreezeEntityPosition(lamar, false)
            setVehicleRouteLock(vehicle, false)
            TaskWarpPedIntoVehicle(lamar, vehicle, -1)
            Wait(350)
            TaskVehicleDriveWander(lamar, vehicle, 18.0, driveStyle)
        end
    end

    local completeCallback = Starterpack.usesRouteRewards and PR.Starterpack.Callbacks.completePrologue or PR.Starterpack.Callbacks.claim
    local waitUntil = GetGameTimer() + 10000
    while Starterpack.pendingRewards > 0 and GetGameTimer() < waitUntil do Wait(100) end
    pr_lib.callback.await(completeCallback, 10000)
    Starterpack.usesRouteRewards = false
    Starterpack.pendingRewards = 0

    SetTimeout(20000, function()
        cleanupScene(false)
    end)
end

local function configuredStops()
    local stops = {}
    local prologue = currentPrologue()

    for _, stop in ipairs(type(prologue.stops) == 'table' and prologue.stops or {}) do
        if stop.enabled ~= false and not isZeroCoords(stop.coords) then
            stops[#stops + 1] = stop
        end
    end

    return stops
end

local function hasRouteRewards(stops)
    for _, stop in ipairs(stops) do
        for _, reward in ipairs(type(stop.rewards) == 'table' and stop.rewards or {}) do
            if reward.enabled ~= false then return true end
        end
    end

    return false
end

local function runPrologueRoute(stops)
    local ped = PlayerPedId()
    local vehicle = Starterpack.vehicle
    local lamar = Starterpack.lamar

    Starterpack.boarding = false
    Starterpack.routeActive = true
    Starterpack.usesRouteRewards = hasRouteRewards(stops)
    clearTarget()
    configureVehicle(vehicle, false)
    setVehicleRouteLock(vehicle, true)

    if not lamar or not DoesEntityExist(lamar) then
        Starterpack.routeActive = false
        setVehicleRouteLock(vehicle, false)
        showSubtitle(t('notify.starterpack.prologue_start_failed', { error = 'lamar_missing' }), 4500)
        return
    end

    ClearPedTasksImmediately(lamar)
    FreezeEntityPosition(lamar, false)
    TaskEnterVehicle(lamar, vehicle, 15000, 0, 1.0, 1, 0)
    showSubtitle(t('notify.starterpack.lamar_boarding'), 5000)

    CreateThread(function()
        local timeout = GetGameTimer() + 30000
        while Starterpack.routeActive and GetGameTimer() < timeout do
            setVehicleRouteLock(vehicle, true)
            keepPlayerLockedInVehicle(vehicle)

            if not IsPedInVehicle(ped, vehicle, false) or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                Starterpack.routeActive = false
                setVehicleRouteLock(vehicle, false)
                SetVehicleDoorsLocked(vehicle, 1)
                SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
                addLamarTarget()
                showSubtitle(t('notify.starterpack.driver_required'), 3500)
                return
            end

            if IsPedInVehicle(lamar, vehicle, false) then break end
            Wait(0)
        end

        if not Starterpack.routeActive then return end
        if not IsPedInVehicle(lamar, vehicle, false) then
            Starterpack.routeActive = false
            setVehicleRouteLock(vehicle, false)
            SetVehicleDoorsLocked(vehicle, 1)
            SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
            addLamarTarget()
            showSubtitle(t('notify.starterpack.lamar_boarding_failed'), 4500)
            return
        end

        configureVehicle(vehicle, true)
        SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), true)
        setVehicleRouteLock(vehicle, false)
        CreateThread(function()
            while Starterpack.routeActive do
                if DoesEntityExist(vehicle) then keepPlayerLockedInVehicle(vehicle) end
                Wait(0)
            end

            if DoesEntityExist(vehicle) then
                SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
            end
        end)

        CreateThread(function()
            for index, stop in ipairs(stops) do
                if not Starterpack.routeActive then break end

                driveToStop(stop)
                if not Starterpack.routeActive then break end

                showSubtitle(stop.arrivalText, 6500)
                Wait(1200)
                playCameraFrames(stop.cameraFrames)
                showSubtitle(stop.nextText, 5500)

                if index < #stops then Wait(1800) end
            end

            if Starterpack.routeActive then finishRoute() end
        end)
    end)
end

function Starterpack.preparePrologue()
    if Starterpack.routeActive or Starterpack.boarding then return end

    local ok, reason = ensureScene(Starterpack.payload)
    if not ok then
        showSubtitle(t('notify.starterpack.prologue_start_failed', { error = tostring(reason or 'unknown') }), 4500)
        return
    end

    local stops = configuredStops()
    if #stops <= 0 then
        showSubtitle(t('notify.starterpack.no_stops'), 4500)
        return
    end

    local vehicle = Starterpack.vehicle
    Starterpack.boarding = true
    clearTarget()
    FreezeEntityPosition(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    showSubtitle(t('notify.starterpack.walk_to_vehicle'), 6500)

    CreateThread(function()
        local timeout = GetGameTimer() + 120000
        while Starterpack.boarding and GetGameTimer() < timeout do
            local ped = PlayerPedId()
            if IsPedInVehicle(ped, vehicle, false) then
                if GetPedInVehicleSeat(vehicle, -1) == ped then
                    runPrologueRoute(stops)
                    return
                end

                TaskLeaveVehicle(ped, vehicle, 0)
                showSubtitle(t('notify.starterpack.driver_required'), 3500)
            end
            Wait(300)
        end

        if Starterpack.boarding then
            Starterpack.boarding = false
            addLamarTarget()
            showSubtitle(t('notify.starterpack.boarding_timeout'), 4500)
        end
    end)
end

function Starterpack.startPrologue()
    Starterpack.preparePrologue()
end

local function openKeyframeHelp(count)
    local text = t('menu.starterpack.keyframe_help', {
        count = tostring(count or 0),
    })

    if pr_lib and pr_lib.ShowTextUI then
        pr_lib.ShowTextUI(text, {
            position = 'left-center',
            icon = 'camera-video-fill',
            iconColor = '#22c55e',
        })
    end
end

local function closeKeyframeHelp()
    if pr_lib and pr_lib.HideTextUI then pr_lib.HideTextUI() end
end

local function dirFromRot(rot)
    local rz = math.rad(rot.z)
    local rx = math.rad(rot.x)
    local cx = math.abs(math.cos(rx))
    return vector3(-math.sin(rz) * cx, math.cos(rz) * cx, math.sin(rx))
end

local function normalize(value)
    local len = math.sqrt(value.x * value.x + value.y * value.y + value.z * value.z)
    if len < 0.0001 then return vector3(0.0, 0.0, 0.0) end
    return vector3(value.x / len, value.y / len, value.z / len)
end

local function editorFrame(camPos, camRot, camFov, duration)
    return {
        coords = serialVector(camPos),
        rot = {
            x = tonumber(('%0.2f'):format(camRot.x)),
            y = tonumber(('%0.2f'):format(camRot.y)),
            z = tonumber(('%0.2f'):format(camRot.z)),
        },
        fov = tonumber(('%0.1f'):format(camFov)),
        duration = math.max(250, tonumber(duration) or 2500),
    }
end

local function editorControlJustPressed(control)
    return IsDisabledControlJustPressed(0, control)
end

function Starterpack.openStopKeyframer(stop)
    if Starterpack.cameraEditor then
        notify(t('notify.starterpack.keyframe_busy'), 'error')
        return
    end

    stop = type(stop) == 'table' and stop or {}
    if not stop.id then return end

    local ped = PlayerPedId()
    local camPos = GetEntityCoords(ped) + vector3(0.0, 0.0, 0.9)
    local camRot = vector3(0.0, 0.0, GetEntityHeading(ped))
    local camFov = 50.0
    local frames = {}

    for _, frame in ipairs(type(stop.cameraFrames) == 'table' and stop.cameraFrames or {}) do
        frames[#frames + 1] = frame
    end

    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, camRot.x, camRot.y, camRot.z, camFov, false, 2)
    Starterpack.cameraEditor = cam
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
    FreezeEntityPosition(ped, true)
    openKeyframeHelp(#frames)

    Starterpack.editorAddFrame = function()
        if Starterpack.cameraEditor ~= cam then return end
        frames[#frames + 1] = editorFrame(camPos, camRot, camFov, 2500)
        notify(t('notify.starterpack.keyframe_added', { count = tostring(#frames) }), 'success')
        openKeyframeHelp(#frames)
    end

    CreateThread(function()
        local cancelled = false

        while Starterpack.cameraEditor == cam do
            if IsPauseMenuActive() then SetPauseMenuActive(false) end

            for _, control in ipairs(editorControls) do
                DisableControlAction(0, control, true)
                DisableControlAction(2, control, true)
            end

            local dt = GetFrameTime() * 60.0
            local speed = 0.22 * dt
            if IsDisabledControlPressed(0, 21) then speed = speed * 4.0 end
            if IsDisabledControlPressed(0, 19) then speed = speed * 0.15 end

            local forward = dirFromRot(camRot)
            local right = rightVector(camRot.z)
            local move = vector3(0.0, 0.0, 0.0)

            if IsDisabledControlPressed(0, 32) then move = move + forward end
            if IsDisabledControlPressed(0, 33) then move = move - forward end
            if IsDisabledControlPressed(0, 34) then move = move - right end
            if IsDisabledControlPressed(0, 35) then move = move + right end
            if IsDisabledControlPressed(0, 22) then move = move + vector3(0.0, 0.0, 1.0) end
            if IsDisabledControlPressed(0, 36) then move = move - vector3(0.0, 0.0, 1.0) end

            if move.x ~= 0.0 or move.y ~= 0.0 or move.z ~= 0.0 then
                local normalized = normalize(move)
                camPos = camPos + normalized * speed
            end

            local turn = 1.6 * dt
            if IsDisabledControlPressed(0, 44) then camRot = vector3(camRot.x, camRot.y, camRot.z + turn) end
            if IsDisabledControlPressed(0, 38) then camRot = vector3(camRot.x, camRot.y, camRot.z - turn) end
            if IsDisabledControlPressed(0, 172) then camRot = vector3(math.max(-89.0, math.min(89.0, camRot.x + turn)), camRot.y, camRot.z) end
            if IsDisabledControlPressed(0, 173) then camRot = vector3(math.max(-89.0, math.min(89.0, camRot.x - turn)), camRot.y, camRot.z) end
            if IsDisabledControlPressed(0, 174) then camRot = vector3(camRot.x, camRot.y, camRot.z + turn) end
            if IsDisabledControlPressed(0, 175) then camRot = vector3(camRot.x, camRot.y, camRot.z - turn) end
            if IsDisabledControlPressed(0, 20) then camRot = vector3(camRot.x, camRot.y - 1.4 * dt, camRot.z) end
            if IsDisabledControlPressed(0, 26) then camRot = vector3(camRot.x, camRot.y + 1.4 * dt, camRot.z) end
            if IsDisabledControlJustPressed(0, 241) then camFov = math.max(5.0, math.min(120.0, camFov - 3.0)) end
            if IsDisabledControlJustPressed(0, 242) then camFov = math.max(5.0, math.min(120.0, camFov + 3.0)) end

            if editorControlJustPressed(322) or editorControlJustPressed(200) then
                SetPauseMenuActive(false)
                break
            elseif editorControlJustPressed(178) then
                frames = {}
                notify(t('notify.starterpack.keyframes_cleared'), 'inform')
                openKeyframeHelp(0)
            elseif editorControlJustPressed(194) then
                cancelled = true
                break
            elseif editorControlJustPressed(202) then
                SetPauseMenuActive(false)
                break
            elseif editorControlJustPressed(191) then
                Starterpack.editorAddFrame()
            elseif editorControlJustPressed(73) then
                playCameraFrames(frames)
                SetCamActive(cam, true)
                RenderScriptCams(true, false, 0, true, false)
            end

            SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
            SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)
            SetCamFov(cam, camFov)
            Wait(0)
        end

        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        Starterpack.cameraEditor = nil
        Starterpack.editorAddFrame = nil
        FreezeEntityPosition(ped, false)
        closeKeyframeHelp()

        if cancelled then
            notify(t('notify.starterpack.keyframe_cancelled'), 'inform')
            return
        end

        stop.cameraFrames = frames
        local ok, response = pr_lib.callback.await(PR.Starterpack.Callbacks.setStop, 10000, stop)
        if ok then
            notify(t('notify.starterpack.keyframes_saved'), 'success')
        else
            notify(t('notify.starterpack.stop_save_failed', { error = tostring(response or 'unknown') }), 'error')
        end
    end)
end

RegisterNetEvent(PR.Starterpack.Events.editStopKeyframes, function(stop)
    Starterpack.openStopKeyframer(stop)
end)

RegisterNetEvent(PR.Starterpack.Events.startTest, function(payload)
    Starterpack.payload = payload
    local ok, reason = ensureScene(payload)
    if not ok then
        showSubtitle(t('notify.starterpack.prologue_start_failed', { error = tostring(reason or 'unknown') }), 4500)
        return
    end

    showSubtitle(t('notify.starterpack.lamar_ready'), 5000)
end)

AddStateBagChangeHandler('forgeStarterpack', 'global', function(_, _, value)
    Starterpack.payload = type(value) == 'table' and value or nil
    if Starterpack.routeActive then return end

    cleanupScene(false)
    if Starterpack.payload and Starterpack.payload.prologue and Starterpack.payload.prologue.enabled == true then
        SetTimeout(1500, function()
            ensureScene(Starterpack.payload)
        end)
    end
end)

CreateThread(function()
    Wait(2500)
    Starterpack.payload = GlobalState.forgeStarterpack
    if Starterpack.payload and Starterpack.payload.prologue and Starterpack.payload.prologue.enabled == true then
        ensureScene(Starterpack.payload)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cleanupScene(false)
    closeKeyframeHelp()
end)
