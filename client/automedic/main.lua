ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local state = {
    settings = PR.AutoMedic.Defaults,
    deathAt = nil,
    category = 'other',
    active = false,
    ped = nil,
    blip = nil,
    token = nil,
    statusText = nil,
    statusVisible = false,
    deathDetected = false,
    deathReported = false,
    requesting = false,
    reviveGraceUntil = 0,
    patientPrepared = false,
    transferring = false,
    lifecycle = 0,
}

local firearmGroups = {
    [joaat('GROUP_PISTOL')] = true,
    [joaat('GROUP_SMG')] = true,
    [joaat('GROUP_RIFLE')] = true,
    [joaat('GROUP_MG')] = true,
    [joaat('GROUP_SHOTGUN')] = true,
    [joaat('GROUP_SNIPER')] = true,
    [joaat('GROUP_HEAVY')] = true,
}

local function awaitServer(name, ...)
    if not pr_lib or not pr_lib.callback or not pr_lib.callback.await then
        return false, 'callback_unavailable'
    end
    return pr_lib.callback.await(name, 10000, ...)
end

local function notify(description, kind)
    if pr_lib and pr_lib.Notify then
        pr_lib.Notify({
            title = 'AutoMedic',
            description = description,
            type = kind or 'inform',
            position = PR.NotifyPos,
        })
    end
end

local function isNativeDead()
    local ped = PlayerPedId()
    return IsEntityDead(ped) or IsPedFatallyInjured(ped) or GetEntityHealth(ped) <= 100
end

local function isDead()
    if GetGameTimer() < state.reviveGraceUntil then return false end
    if pr_lib and pr_lib.framework and pr_lib.framework.IsPlayerDead
        and pr_lib.framework.IsPlayerDead() then
        return true
    end
    return isNativeDead()
end

local function hasBleeding(value)
    if type(value) ~= 'table' then return false end
    for key, item in pairs(value) do
        if key == 'bleeding' and tonumber(item) and tonumber(item) > 0 then return true end
        if type(item) == 'table' and hasBleeding(item) then return true end
    end
    return false
end

local function classify(info)
    local cause = type(info) == 'table' and tonumber(info.deathCause) or GetPedCauseOfDeath(PlayerPedId())
    if cause and firearmGroups[GetWeapontypeGroup(cause)] then return 'gunshot' end

    local status = exports.qbx_core:GetStatus() or {}
    local playerData = exports.qbx_core:GetPlayerData() or {}
    local metadata = playerData.metadata or {}
    if (tonumber(status.hunger) or 100) <= 0
        or (tonumber(status.thirst) or 100) <= 0
        or hasBleeding(metadata.injuries)
        or (tonumber(metadata.bleeding) or 0) > 0 then
        return 'collapse'
    end

    return 'other'
end

local function cleanupNpc()
    if state.patientPrepared then
        local patient = PlayerPedId()
        if DoesEntityExist(patient) then
            FreezeEntityPosition(patient, false)
            SetEntityInvincible(patient, false)
            SetPedCanRagdoll(patient, true)
            ClearPedTasks(patient)
        end
        TriggerEvent('qbx_core:client:setDeathPoseOverride', false)
        state.patientPrepared = false
    end

    if state.blip and DoesBlipExist(state.blip) then RemoveBlip(state.blip) end
    if state.ped and DoesEntityExist(state.ped) then
        DeleteEntity(state.ped)
    end
    state.blip = nil
    state.ped = nil
    state.active = false
    state.token = nil
end

local function formatTime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    return ('%02d:%02d'):format(math.floor(seconds / 60), seconds % 60)
end

local function currentTime()
    return GetCloudTimeAsInt()
end

local function hideStatus()
    if state.statusVisible and pr_lib and pr_lib.HideTextUI then
        pr_lib.HideTextUI()
    end
    state.statusText = nil
    state.statusVisible = false
end

local function showStatus(text, icon)
    if state.statusVisible and state.statusText == text then return end
    if not pr_lib or not pr_lib.ShowTextUI then return end

    pr_lib.ShowTextUI(text, {
        position = 'bottom-center',
        icon = icon or 'heart-pulse-fill',
        iconColor = '#ff6b35',
    })
    state.statusText = text
    state.statusVisible = true
end

local function requestModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    return HasModelLoaded(hash) and hash or nil
end

local function requestAnimation(dict, timeoutMs)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + (timeoutMs or 5000)
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasAnimDictLoaded(dict)
end

local function findSpawn(origin)
    local npc = PR.AutoMedic.Npc
    for _ = 1, 16 do
        local angle = math.random() * math.pi * 2
        local distance = npc.spawnMinDistance
            + math.random() * (npc.spawnMaxDistance - npc.spawnMinDistance)
        local x = origin.x + math.cos(angle) * distance
        local y = origin.y + math.sin(angle) * distance
        local found, ground = GetGroundZFor_3dCoord(x, y, origin.z + 25.0, false)
        if found then return vector3(x, y, ground) end
    end
    return GetOffsetFromEntityInWorldCoords(PlayerPedId(), 8.0, 8.0, 0.0)
end

local function cancelTreatment(reason)
    if state.token then awaitServer(PR.AutoMedic.Callbacks.cancelTreatment, state.token) end
    cleanupNpc()
    if reason then notify(reason, 'error') end
end

local function hospitalFallback(reason)
    if state.transferring or not state.token then return end
    local token = state.token
    local lifecycle = state.lifecycle
    state.transferring = true
    cleanupNpc()
    local callbackOk, ok, payload = pcall(awaitServer, PR.AutoMedic.Callbacks.recoverHospital, token, reason)
    if not callbackOk then ok, payload = false, tostring(ok) end
    if lifecycle ~= state.lifecycle then return end
    state.transferring = false
    if not ok then
        pcall(awaitServer, PR.AutoMedic.Callbacks.cancelTreatment, token)
        local detail = tostring(payload)
        if payload == 'no_hospital_beds' then detail = ForgeCore.t('automedic.no_beds') end
        if payload == 'disabled' then detail = ForgeCore.t('automedic.fallback_disabled') end
        notify(ForgeCore.t('automedic.recovery_failed', {error=detail}), 'error')
        if not IsScreenFadedIn() then DoScreenFadeIn(500) end
    else
        notify(ForgeCore.t('automedic.recovered'), 'success')
    end
end

local function getTreatmentPosition(medic, playerPed)
    local config = PR.AutoMedic.Npc.treatmentPosition or {}
    local sideOffset = math.abs(tonumber(config.sideOffset) or 0.72)
    local forwardOffset = tonumber(config.forwardOffset) or 0.18
    local verticalOffset = tonumber(config.verticalOffset) or 0.0
    local medicCoords = GetEntityCoords(medic)
    local playerCoords = GetEntityCoords(playerPed)
    local right = GetOffsetFromEntityInWorldCoords(playerPed, sideOffset, forwardOffset, verticalOffset)
    local left = GetOffsetFromEntityInWorldCoords(playerPed, -sideOffset, forwardOffset, verticalOffset)
    local target = #(medicCoords - right) <= #(medicCoords - left) and right or left
    -- O corpo ja esta sobre uma superficie valida. Consultar groundZ aqui pode
    -- retornar o piso inferior de interiores, pontes e MLOs ainda sem colisao.
    target = vector3(target.x, target.y, playerCoords.z)

    local heading = GetHeadingFromVector_2d(playerCoords.x - target.x, playerCoords.y - target.y)
    return target, heading
end

local function preparePatientForTreatment(playerPed)
    local config = PR.AutoMedic.Npc.patientPosition or {}
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    TriggerEvent('qbx_core:client:setDeathPoseOverride', true)
    if IsEntityDead(playerPed) or IsPedFatallyInjured(playerPed) then
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, true, false)
        playerPed = PlayerPedId()
    end

    SetEntityHealth(playerPed, 100)
    ClearPedTasksImmediately(playerPed)
    -- Nunca altera o eixo Z do paciente: o ponto atual e a unica referencia
    -- segura em interiores, viadutos, coberturas e mapas customizados.
    SetEntityRotation(playerPed, 0.0, 0.0, heading, 2, true)
    SetEntityHeading(playerPed, heading)
    SetEntityInvincible(playerPed, true)
    SetPedCanRagdoll(playerPed, false)
    FreezeEntityPosition(playerPed, true)
    state.patientPrepared = true

    local dict = config.dict or 'mini@cpr@char_b@cpr_def'
    local clip = config.clip or 'cpr_pumpchest_idle'
    if requestAnimation(dict) then
        TaskPlayAnim(playerPed, dict, clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    end
end


local function playCrowdControlGesture(medic, playerPed)
    local config = PR.AutoMedic.Npc.crowdControl or {}
    if config.enabled == false then return true end

    local dict = config.dict or 'amb@code_human_police_crowd_control@idle_a'
    local clip = config.clip or 'idle_a'
    local duration = math.max(500, math.floor(tonumber(config.duration) or 2200))

    TaskTurnPedToFaceEntity(medic, playerPed, 500)
    Wait(500)
    if not state.active or not DoesEntityExist(medic) or not isDead() then return false end

    if requestAnimation(dict) then
        TaskPlayAnim(medic, dict, clip, 8.0, -8.0, duration, 0, 0.0, false, false, false)
        Wait(duration)
        RemoveAnimDict(dict)
    end

    return state.active and DoesEntityExist(medic) and isDead()
end

local function alignMedicForTreatment(medic, playerPed)
    local config = PR.AutoMedic.Npc.treatmentPosition or {}
    local target, heading = getTreatmentPosition(medic, playerPed)
    local exactDistance = tonumber(config.exactDistance) or 0.16
    local snapDistance = tonumber(config.snapDistance) or 0.65
    local timeout = GetGameTimer() + (tonumber(config.approachTimeout) or 8000)

    ClearPedTasksImmediately(medic)
    SetEntityNoCollisionEntity(medic, playerPed, true)
    TaskGoStraightToCoord(medic, target.x, target.y, target.z, PR.AutoMedic.Npc.walkSpeed, -1, heading, exactDistance)

    while state.active and DoesEntityExist(medic) and isDead() and GetGameTimer() < timeout do
        local distance = #(GetEntityCoords(medic) - target)
        if distance <= exactDistance then break end
        Wait(50)
    end

    local distance = #(GetEntityCoords(medic) - target)
    if distance > snapDistance then return false end

    ClearPedTasksImmediately(medic)
    if distance > exactDistance then
        SetEntityCoordsNoOffset(medic, target.x, target.y, target.z + 0.02, false, false, false)
    end
    SetEntityHeading(medic, heading)
    FreezeEntityPosition(medic, true)
    return true
end

local function performTreatment()
    local medic = state.ped
    if not medic or not DoesEntityExist(medic) or IsPedDeadOrDying(medic, true) or not isDead() then
        if isDead() then return hospitalFallback('npc_lost') end
        return cancelTreatment()
    end

    local playerPed = PlayerPedId()
    if not playCrowdControlGesture(medic, playerPed) then
        if isDead() then return hospitalFallback('npc_lost') end
        return cancelTreatment()
    end
    preparePatientForTreatment(playerPed)
    playerPed = PlayerPedId()
    if not alignMedicForTreatment(medic, playerPed) then
        return hospitalFallback('alignment_failed')
    end
    Wait(100)

    local dict = 'mini@cpr@char_a@cpr_str'
    if not requestAnimation(dict) then return hospitalFallback('animation_failed') end
    TaskPlayAnim(medic, dict, 'cpr_pumpchest', 8.0, -8.0, PR.AutoMedic.Npc.treatmentDuration, 1, 0.0, false, false, false)

    local keepAligned = true
    local fadeStarted = false
    CreateThread(function()
        while keepAligned and state.active and DoesEntityExist(medic) do
            SetEntityNoCollisionEntity(medic, playerPed, true)
            Wait(0)
        end
    end)
    CreateThread(function()
        local fadeLead = math.max(0, math.floor(tonumber(PR.AutoMedic.Npc.wakeup and PR.AutoMedic.Npc.wakeup.fadeLeadTime) or 900))
        Wait(math.max(0, PR.AutoMedic.Npc.treatmentDuration - fadeLead))
        if keepAligned and state.active and isDead() then
            fadeStarted = true
            if not IsScreenFadedOut() and not IsScreenFadingOut() then DoScreenFadeOut(fadeLead) end
        end
    end)

    local finished = true
    if pr_lib and type(pr_lib.progressBar) == 'function' then
        finished = pr_lib.progressBar({
            duration = PR.AutoMedic.Npc.treatmentDuration,
            label = 'ATENDIMENTO MEDICO...',
            useWhileDead = true,
            allowRagdoll = true,
            canCancel = false,
        })
    else
        Wait(PR.AutoMedic.Npc.treatmentDuration)
    end
    keepAligned = false
    if DoesEntityExist(medic) then FreezeEntityPosition(medic, false) end

    if not finished or not isDead() then
        if fadeStarted and not IsScreenFadedIn() then DoScreenFadeIn(500) end
        return cancelTreatment()
    end
    local ok, payload = awaitServer(PR.AutoMedic.Callbacks.completeTreatment, state.token)
    if not ok then
        if fadeStarted and not IsScreenFadedIn() then DoScreenFadeIn(500) end
        return cancelTreatment(('Nao foi possivel concluir: %s'):format(tostring(payload)))
    end

    cleanupNpc()
    state.deathAt = nil
    local message = payload and payload.inventoryLost and 'Atendimento concluido. Seu inventario foi perdido.' or 'Atendimento concluido.'
    if payload and (tonumber(payload.chargedAmount) or 0) > 0 then
        local account = payload.paymentAccount == 'cash' and 'dinheiro' or 'banco'
        message = ('%s Cobranca: R$ %d no %s.'):format(message, math.floor(payload.chargedAmount), account)
    end
    notify(message, 'success')
end

local function dispatchMedic()
    if state.active or state.requesting or state.transferring or ForgeCore.Hospital.isRecovering() then return end
    state.requesting = true
    local lifecycle = state.lifecycle
    local ok, payload, remaining = awaitServer(PR.AutoMedic.Callbacks.requestTreatment, state.category)
    if lifecycle ~= state.lifecycle then return end
    state.requesting = false
    if not ok then
        if payload == 'cooldown' then
            notify(('Aguarde %s para chamar o medico.'):format(formatTime(remaining)), 'warning')
        else
            notify(('Nao foi possivel chamar o medico: %s'):format(tostring(payload)), 'error')
        end
        return
    end

    state.active = true
    state.token = payload.token
    local token = state.token
    local model = requestModel(PR.AutoMedic.Npc.model)
    if lifecycle ~= state.lifecycle or state.token ~= token then
        if model then SetModelAsNoLongerNeeded(model) end
        return
    end
    if not model then return hospitalFallback('model_failed') end

    local playerPed = PlayerPedId()
    local spawn = findSpawn(GetEntityCoords(playerPed))
    local medic = CreatePed(4, model, spawn.x, spawn.y, spawn.z, 0.0, true, true)
    SetModelAsNoLongerNeeded(model)
    if not DoesEntityExist(medic) then return hospitalFallback('spawn_failed') end

    state.ped = medic
    SetEntityAsMissionEntity(medic, true, true)
    SetBlockingOfNonTemporaryEvents(medic, true)
    SetPedCanRagdoll(medic, false)
    state.blip = AddBlipForEntity(medic)
    SetBlipSprite(state.blip, 153)
    SetBlipColour(state.blip, 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('AutoMedic')
    EndTextCommandSetBlipName(state.blip)

    TaskGoToEntity(medic, playerPed, -1, PR.AutoMedic.Npc.treatmentDistance, PR.AutoMedic.Npc.walkSpeed, 0.0, 0)
    notify('Um paramedico foi enviado ate voce.', 'inform')

    CreateThread(function()
        local expires = GetGameTimer() + PR.AutoMedic.Npc.arrivalTimeout
        local lastCoords = GetEntityCoords(medic)
        local stuck = 0

        while lifecycle == state.lifecycle and state.token == token and state.active and DoesEntityExist(medic) and isDead() do
            if IsPedDeadOrDying(medic, true) then return hospitalFallback('npc_lost') end
            local playerCoords = GetEntityCoords(PlayerPedId())
            local medicCoords = GetEntityCoords(medic)
            if #(playerCoords - medicCoords) <= PR.AutoMedic.Npc.treatmentDistance + 0.5 then
                return performTreatment()
            end
            if GetGameTimer() >= expires then return hospitalFallback('unreachable') end

            if #(medicCoords - lastCoords) < 0.35 then
                stuck = stuck + 1
                if stuck >= 3 then
                    local near = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 1.5, 1.5, 0.0)
                    SetEntityCoords(medic, near.x, near.y, near.z, false, false, false, false)
                    stuck = 0
                end
            else
                stuck = 0
            end
            lastCoords = medicCoords
            TaskGoToEntity(medic, PlayerPedId(), -1, PR.AutoMedic.Npc.treatmentDistance, PR.AutoMedic.Npc.walkSpeed, 0.0, 0)
            Wait(3000)
        end

        if lifecycle == state.lifecycle and state.token == token and state.active then
            if isDead() then hospitalFallback('npc_lost') else cancelTreatment() end
        end
    end)
end

local function refreshStatus()
    state.category = classify(nil)
    local ok, payload = awaitServer(PR.AutoMedic.Callbacks.getStatus)
    if not ok or type(payload) ~= 'table' then return end
    state.settings.enabled = payload.enabled
    state.settings.cooldown = payload.cooldown
    state.settings.treatmentPrice = payload.treatmentPrice
    state.settings.reviveHealthPercent = payload.reviveHealthPercent
    state.deathAt = payload.deathAt
end

exports('useBandage', function(data, slot)
    local settings = state.settings or PR.AutoMedic.Defaults
    if settings.enabled ~= true then
        notify('A bandagem esta indisponivel enquanto o AutoMedic estiver desativado.', 'error')
        return false
    end

    local ped = PlayerPedId()
    if isDead() then
        notify('Nao e possivel usar uma bandagem enquanto estiver desacordado.', 'error')
        return false
    end

    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    if health >= maxHealth then
        notify('Sua saude ja esta completa.', 'inform')
        return false
    end

    exports.ox_inventory:useItem(data, function(used)
        if not used then return end

        local currentSettings = state.settings or PR.AutoMedic.Defaults
        if currentSettings.enabled ~= true then return end

        ped = PlayerPedId()
        health = GetEntityHealth(ped)
        maxHealth = GetEntityMaxHealth(ped)
        local percent = math.max(1, math.min(tonumber(currentSettings.bandageHealPercent) or 10, 100))
        local amount = math.max(1, math.floor(maxHealth * percent / 100))
        local newHealth = math.min(maxHealth, health + amount)
        SetEntityHealth(ped, newHealth)
        TriggerEvent('qbx_core:client:refreshNativeStatus')

        notify(('Bandagem aplicada: +%d%% de saude.'):format(math.floor(percent)), 'success')
    end)

    return true
end)
local function resetDeathState()
    state.deathDetected = false
    state.deathReported = false
    state.deathAt = nil
    state.category = 'other'
    state.requesting = false
    hideStatus()
end

local function markRevived()
    state.reviveGraceUntil = GetGameTimer() + 5000
    cleanupNpc()
    resetDeathState()
end

local function reportDeath()
    if state.deathReported then return end

    state.deathDetected = true
    state.deathReported = true
    if ForgeCore.Hospital.isRecovering() then ForgeCore.Hospital.clear(true) end
    state.category = classify(nil)
    state.deathAt = state.deathAt or currentTime()

    local payload = {
        deathCause = GetPedCauseOfDeath(PlayerPedId()),
        timestamp = state.deathAt,
    }

    SetTimeout(500, function()
        if state.deathDetected then
            TriggerServerEvent(PR.AutoMedic.Events.reportDeath, payload)
        end
    end)
end

local function playWakeupAnimation(ped)
    local config = PR.AutoMedic.Npc.wakeup or {}
    if config.enabled == false or not DoesEntityExist(ped) then
        if not IsScreenFadedIn() then DoScreenFadeIn(500) end
        return
    end

    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local sceneZ = pos.z + (tonumber(config.sceneZOffset) or -1.0)
    local dict = IsPedMale(ped)
        and (config.maleDict or 'anim@scripted@heist@ig25_beach@male@')
        or (config.femaleDict or 'anim@scripted@heist@ig25_beach@heeled@')

    if not IsScreenFadedOut() then
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(10) end
    end

    SetEntityCoords(ped, pos.x, pos.y, sceneZ, false, false, false, true)
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, true)

    if not requestAnimation(dict, 10000) then
        FreezeEntityPosition(ped, false)
        DoScreenFadeIn(500)
        return
    end

    local scene = NetworkCreateSynchronisedScene(pos.x, pos.y, sceneZ, 0.0, 0.0, heading, 2, false, false, 1.0, 0.0, 1.0)
    NetworkAddPedToSynchronisedScene(ped, scene, dict, 'action', 8.0, -8.0, 0, 0, 1000.0, 0)
    NetworkStartSynchronisedScene(scene)
    SetFacialIdleAnimOverride(ped, 'HS4F_IG25_BEACH', 0)

    local cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
    PlayCamAnim(cam, 'action_camera', dict, pos.x, pos.y, sceneZ, 0.0, 0.0, heading, false, 2)
    RenderScriptCams(true, false, 1000, true, false)
    DoScreenFadeIn(2000)

    Wait(tonumber(config.duration) or 13000)

    NetworkStopSynchronisedScene(scene)
    RenderScriptCams(false, true, 1000, true, false)
    DestroyCam(cam, false)
    ClearFacialIdleAnimOverride(ped)
    FreezeEntityPosition(ped, false)
    SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
    SetEntityHeading(ped, heading)
    RemoveAnimDict(dict)
end

local function applyReviveHealth(ped)
    local baseHealth = 100
    local maxHealth = math.max(baseHealth + 1, GetEntityMaxHealth(ped))
    local revivePercent = math.max(1, math.min(tonumber(state.settings.reviveHealthPercent) or 10, 100))
    local reviveHealth = baseHealth + math.floor((maxHealth - baseHealth) * (revivePercent / 100) + 0.5)
    SetEntityHealth(ped, reviveHealth)
    TriggerEvent('qbx_core:client:refreshNativeStatus')
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCanBeDamaged(ped, true)
    SetPedCanRagdoll(ped, true)
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    TriggerEvent('qbx_core:client:setDeathPoseOverride', false)
end

RegisterNetEvent(PR.AutoMedic.Events.revive, function(hospital)
    if source ~= 65535 then return end
    markRevived()
    if hospital then
        state.reviveGraceUntil = GetGameTimer() + 15000
        if ForgeCore.Hospital.recover(hospital, applyReviveHealth) then return end
    end
    ForgeCore.Hospital.clear(true)
    local oldPed = PlayerPedId()
    local coords, heading = GetEntityCoords(oldPed), GetEntityHeading(oldPed)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, true, false)
    local ped = PlayerPedId()
    applyReviveHealth(ped)
    markRevived()

    CreateThread(function()
        playWakeupAnimation(ped)
        TriggerEvent('qbx_core:client:refreshNativeStatus')
    end)
end)

RegisterNetEvent('qbx_core:client:onSetMetaData', function(key, _, value)
    if (key ~= 'isdead' and key ~= 'inlaststand') or value == true then return end

    SetTimeout(0, function()
        local playerData = exports.qbx_core:GetPlayerData() or {}
        local metadata = playerData.metadata or {}
        if (state.deathDetected or state.deathReported or state.active or state.statusVisible)
            and metadata.isdead ~= true and metadata.inlaststand ~= true and not isNativeDead() then
            markRevived()
        end
    end)
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(playerData)
    local metadata = type(playerData) == 'table' and playerData.metadata or {}
    if (state.deathDetected or state.deathReported or state.active or state.statusVisible)
        and metadata.isdead ~= true and metadata.inlaststand ~= true and not isNativeDead() then
        markRevived()
    end
end)

AddEventHandler('hospital:client:Revive', function()
    ForgeCore.Hospital.clear(true)
    state.reviveGraceUntil = GetGameTimer() + 5000
    SetTimeout(750, function()
        if not isNativeDead() then markRevived() end
    end)
end)

AddEventHandler('playerSpawned', function()
    SetTimeout(1000, function()
        local playerData = exports.qbx_core:GetPlayerData() or {}
        local metadata = playerData.metadata or {}
        local status = exports.qbx_core:GetStatus() or {}
        if metadata.isdead == true or metadata.inlaststand == true or (tonumber(status.health) or 100) <= 0 then
            return
        end
        if not isNativeDead() then markRevived() end
    end)
end)

RegisterNetEvent(PR.AutoMedic.Events.sync, function(settings)
    state.settings = type(settings) == 'table' and settings or PR.AutoMedic.Defaults
    if not state.settings.enabled then
        hideStatus()
        if state.active then cancelTreatment() end
    end
end)

CreateThread(function()
    Wait(2000)
    refreshStatus()

    while true do
        local dead = isDead()
        if dead and state.settings.enabled then
            if not state.deathReported then reportDeath() end
            if not state.deathAt then state.deathAt = currentTime() end

            local remaining = math.max(0, (state.settings.cooldown or 0) - (currentTime() - state.deathAt))
            if state.transferring then
                showStatus(ForgeCore.t('automedic.transferring'), 'hospital')
            elseif state.active then
                showStatus('AutoMedic: paramedico a caminho', 'ambulance')
            elseif remaining > 0 then
                showStatus(('AutoMedic disponivel em %s'):format(formatTime(remaining)))
            else
                showStatus('[E] Chamar atendimento AutoMedic', 'heart-pulse-fill')
                if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
                    dispatchMedic()
                end
            end
            Wait(0)
        else
            if state.active then cancelTreatment() end
            if state.deathDetected or state.deathReported then
                resetDeathState()
            else
                hideStatus()
            end
            if not dead then state.deathAt = nil end
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        hideStatus()
        cleanupNpc()
    end
end)

AddEventHandler('forge-core:session:changed', function()
    state.lifecycle = state.lifecycle + 1
    state.transferring = false
    cleanupNpc()
    resetDeathState()
end)
