ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Objects = {
    entries = {},
    debugIds = false,
    editorActive = false,
}

ForgeCore.Client.Objects = Objects

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function notify(description, notifyType)
    if pr_lib and pr_lib.notify and pr_lib.notify.Notify then
        pr_lib.notify.Notify({
            title = t('objects.title'),
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

local function deleteEntry(entry)
    if entry and entry.handle and DoesEntityExist(entry.handle) then
        SetEntityAsMissionEntity(entry.handle, true, true)
        DeleteEntity(entry.handle)
    end

    if entry then entry.handle = nil end
end

local function deleteAll()
    for _, entry in pairs(Objects.entries) do
        deleteEntry(entry)
    end
end

local function configureSpawned(entity)
    SetEntityAsMissionEntity(entity, true, true)
    FreezeEntityPosition(entity, true)
    SetEntityDynamic(entity, false)
    SetEntityProofs(entity, false, false, false, true, false, false, false, false)
end

local function spawnEntry(entry)
    if entry.handle and DoesEntityExist(entry.handle) then return entry.handle end
    if not pr_lib or not pr_lib.fivem or not pr_lib.fivem.streaming then return nil end

    local entity = pr_lib.fivem.streaming.createObject(entry.model, vec3(entry.coords), {
        networked = false,
        missionEntity = true,
        freeze = true,
        collision = true,
        noOffset = true,
        timeout = 5000,
    })

    if not entity or entity == 0 then return nil end

    local rotation = vec3(entry.rotation)
    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
    configureSpawned(entity)
    entry.handle = entity

    return entity
end

local function applyPayload(payload)
    payload = type(payload) == 'table' and payload or {}
    local nextEntries = {}

    for _, object in ipairs(type(payload.objects) == 'table' and payload.objects or {}) do
        local id = tonumber(object.id)
        if id then
            local existing = Objects.entries[id] or {}
            existing.id = id
            existing.sceneId = tonumber(object.sceneId or object.sceneid) or 0
            existing.model = tostring(object.model or '')
            existing.coords = vec3(object.coords)
            existing.rotation = vec3(object.rotation)
            existing.heading = tonumber(object.heading) or 0.0

            if existing.handle and DoesEntityExist(existing.handle) then
                SetEntityCoordsNoOffset(existing.handle, existing.coords.x, existing.coords.y, existing.coords.z, false, false, false)
                SetEntityRotation(existing.handle, existing.rotation.x, existing.rotation.y, existing.rotation.z, 2, true)
                FreezeEntityPosition(existing.handle, true)
            end

            nextEntries[id] = existing
        end
    end

    for id, entry in pairs(Objects.entries) do
        if not nextEntries[id] then
            deleteEntry(entry)
        end
    end

    Objects.entries = nextEntries
end

local function currentPayload()
    local payload = GlobalState.forgeObjects
    return type(payload) == 'table' and payload or { enabled = false, objects = {}, spawnDistance = PR.Objects.Defaults.spawnDistance }
end

function Objects.getByScene(sceneId)
    local items = {}
    sceneId = tonumber(sceneId)

    for _, entry in pairs(Objects.entries) do
        if tonumber(entry.sceneId) == sceneId then
            items[#items + 1] = entry
        end
    end

    table.sort(items, function(left, right) return tonumber(left.id) < tonumber(right.id) end)
    return items
end

function Objects.get(objectId)
    return Objects.entries[tonumber(objectId)]
end

function Objects.toggleDebug()
    Objects.debugIds = not Objects.debugIds

    if not Objects.debugIds then
        for _, entry in pairs(Objects.entries) do
            if entry.handle and DoesEntityExist(entry.handle) then
                SetEntityDrawOutline(entry.handle, false)
            end
        end
    end

    notify(Objects.debugIds and t('notify.objects.debug_on') or t('notify.objects.debug_off'), 'inform')
    return Objects.debugIds
end

local function getPropHash(model)
    if pr_lib and pr_lib.fivem and pr_lib.fivem.blips and pr_lib.fivem.blips.getPropHashId then
        return pr_lib.fivem.blips.getPropHashId(model)
    end

    local hash = joaat(tostring(model or ''))
    if hash < 0 then hash = hash + 4294967296 end
    return math.floor(hash)
end

local function drawDebugLabel(entry, coords, distance)
    local text = ('ID: %s\n%s\nHash: %s\n%.2fm'):format(
        tostring(entry.id),
        tostring(entry.model),
        tostring(getPropHash(entry.model) or 'unknown'),
        tonumber(distance) or 0.0
    )

    if pr_lib and pr_lib.fivem and pr_lib.fivem.drawtext and pr_lib.fivem.drawtext.drawText3d then
        pr_lib.fivem.drawtext.drawText3d({
            text = text,
            coords = vector3(coords.x, coords.y, coords.z + 1.15),
            scale = vec2(0.28, 0.28),
            font = 4,
            color = vec4(0, 180, 255, 255),
            enableOutline = true,
            drawRect = true,
            rectAlpha = 115,
        })
        return
    end

    SetDrawOrigin(coords.x, coords.y, coords.z + 1.15, 0)
    SetTextScale(0.28, 0.28)
    SetTextFont(4)
    SetTextColour(0, 180, 255, 255)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function disableEditorControls()
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 257, true)
    DisablePlayerFiring(PlayerId(), true)
end

local function applyPrecisionControls(entity, editPos, editRot)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    SetPauseMenuActive(false)

    for _, control in ipairs({ 32, 31, 34, 35, 44, 38, 174, 175, 172, 173, 83, 84, 314, 315, 241, 242 }) do
        DisableControlAction(0, control, true)
    end

    local precisionSpeed = pr_lib.fivem.gizmo.getPrecisionSpeed and pr_lib.fivem.gizmo.getPrecisionSpeed() or 1.0
    local speed = (IsControlPressed(0, 21) and 0.04 or 0.015) * precisionSpeed
    local rotSpeed = (IsControlPressed(0, 21) and 3.0 or 1.0) * precisionSpeed
    local right, forward = GetEntityMatrix(entity)
    local moved = false
    local rotated = false

    if IsDisabledControlPressed(0, 32) then editPos = editPos + forward * speed; moved = true end
    if IsDisabledControlPressed(0, 31) then editPos = editPos - forward * speed; moved = true end
    if IsDisabledControlPressed(0, 34) then editPos = editPos - right * speed; moved = true end
    if IsDisabledControlPressed(0, 35) then editPos = editPos + right * speed; moved = true end
    if IsDisabledControlPressed(0, 241) then editPos = editPos + vector3(0.0, 0.0, speed); moved = true end
    if IsDisabledControlPressed(0, 242) then editPos = editPos - vector3(0.0, 0.0, speed); moved = true end

    if IsDisabledControlPressed(0, 44) then editRot = vector3(editRot.x, editRot.y, editRot.z + rotSpeed); rotated = true end
    if IsDisabledControlPressed(0, 38) then editRot = vector3(editRot.x, editRot.y, editRot.z - rotSpeed); rotated = true end
    if IsDisabledControlPressed(0, 174) then editRot = vector3(editRot.x, editRot.y - rotSpeed, editRot.z); rotated = true end
    if IsDisabledControlPressed(0, 175) then editRot = vector3(editRot.x, editRot.y + rotSpeed, editRot.z); rotated = true end
    if IsDisabledControlPressed(0, 172) then editRot = vector3(editRot.x - rotSpeed, editRot.y, editRot.z); rotated = true end
    if IsDisabledControlPressed(0, 173) then editRot = vector3(editRot.x + rotSpeed, editRot.y, editRot.z); rotated = true end

    if moved then SetEntityCoordsNoOffset(entity, editPos.x, editPos.y, editPos.z, false, false, false) end
    if rotated then SetEntityRotation(entity, editRot.x, editRot.y, editRot.z, 2, true) end

    return editPos, editRot
end

local function cleanupEditor(entity, deleteEntity)
    if pr_lib and pr_lib.fivem then
        if pr_lib.fivem.gizmo and pr_lib.fivem.gizmo.stop then pr_lib.fivem.gizmo.stop() end
        if pr_lib.fivem.editorCamera and pr_lib.fivem.editorCamera.stop then pr_lib.fivem.editorCamera.stop() end
    end

    if pr_lib and pr_lib.target and pr_lib.target.disableTargeting then
        pr_lib.target.disableTargeting(false)
    end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if deleteEntity and entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    Objects.editorActive = false
end

local function startGizmoEditor(entity, title, onDone, deleteOnCancel)
    if Objects.editorActive then
        notify(t('notify.objects.editor_busy'), 'error')
        return false
    end

    if not pr_lib or not pr_lib.fivem or not pr_lib.fivem.gizmo or not pr_lib.fivem.editorCamera then
        notify(t('notify.objects.gizmo_unavailable'), 'error')
        return false
    end

    Objects.editorActive = true
    local editPos = GetEntityCoords(entity)
    local editRot = GetEntityRotation(entity, 2)

    if pr_lib.target and pr_lib.target.disableTargeting then
        pr_lib.target.disableTargeting(true)
    end

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)

    pr_lib.fivem.editorCamera.start(entity)
    if pr_lib.fivem.editorCamera.smoothTransitionToEntity then
        pr_lib.fivem.editorCamera.smoothTransitionToEntity(entity, 2.0)
    end

    pr_lib.fivem.gizmo.start(entity, function(newPos)
        editPos = newPos
        editRot = GetEntityRotation(entity, 2)
        return true
    end, vector3(0.0, 0.0, 0.0), {
        showPreview = true,
        previewTitle = title,
        handlePrecisionToggle = true,
        allowFreeCameraToggle = false,
        freeCameraMode = false,
        useEditorCamera = true,
        editorCameraRadius = 2.0,
        onPrecisionModeChange = function(enabled)
            editPos = GetEntityCoords(entity)
            editRot = GetEntityRotation(entity, 2)
            SetNuiFocus(not enabled, not enabled)
            SetNuiFocusKeepInput(true)
        end,
    })

    notify(t('notify.objects.gizmo_started'), 'inform')

    CreateThread(function()
        while Objects.editorActive and DoesEntityExist(entity) do
            Wait(0)
            disableEditorControls()

            if pr_lib.fivem.gizmo.isPrecisionMode and pr_lib.fivem.gizmo.isPrecisionMode() then
                editPos, editRot = applyPrecisionControls(entity, editPos, editRot)
            else
                editPos = GetEntityCoords(entity)
                editRot = GetEntityRotation(entity, 2)
            end

            local confirm = IsDisabledControlJustPressed(0, 201) or IsControlJustPressed(0, 201)
                or IsDisabledControlJustPressed(0, 191) or IsControlJustPressed(0, 191)
            local rightMousePressed = IsDisabledControlPressed(0, 25) or IsControlPressed(0, 25)
            local leftMousePressed = IsDisabledControlPressed(0, 24) or IsControlPressed(0, 24)
            local cancel = not leftMousePressed and not rightMousePressed
                and (IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 177))

            if confirm or cancel then
                local finalCoords = GetEntityCoords(entity)
                local finalRot = GetEntityRotation(entity, 2)
                cleanupEditor(entity, cancel and deleteOnCancel == true)

                if confirm and type(onDone) == 'function' then
                    onDone(finalCoords, finalRot)
                elseif cancel then
                    notify(t('notify.objects.gizmo_cancelled'), 'inform')
                end

                break
            end
        end

        if Objects.editorActive then
            cleanupEditor(entity, deleteOnCancel == true)
        end
    end)

    return true
end

function Objects.createPreview(model, sceneId, onCreated)
    if not pr_lib or not pr_lib.fivem or not pr_lib.fivem.streaming then return false, 'streaming_unavailable' end

    local ped = PlayerPedId()
    local spawnCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
    local entity = pr_lib.fivem.streaming.createObject(model, spawnCoords, {
        networked = false,
        missionEntity = true,
        freeze = true,
        collision = false,
        alpha = 200,
        noOffset = true,
        timeout = 5000,
    })

    if not entity or entity == 0 then return false, 'create_failed' end

    SetEntityHeading(entity, GetEntityHeading(ped))
    configureSpawned(entity)
    SetEntityCollision(entity, false, false)

    startGizmoEditor(entity, t('menu.objects.gizmo_create'), function(coords, rotation)
        local ok, objectId = pr_lib.callback.await(PR.Objects.Callbacks.createObject, 10000, {
            sceneId = sceneId,
            model = model,
            coords = serialVector(coords),
            rotation = serialVector(rotation),
            heading = GetEntityHeading(entity),
        })

        DeleteEntity(entity)

        if ok and objectId then
            if type(onCreated) == 'function' then onCreated(objectId) end
        else
            notify(t('notify.objects.create_failed', { error = tostring(objectId or 'unknown') }), 'error')
        end
    end, true)

    return true
end

function Objects.edit(objectId, onUpdated)
    local entry = Objects.get(objectId)
    if not entry then return false, 'object_not_found' end

    local entity = spawnEntry(entry)
    if not entity then return false, 'spawn_failed' end

    SetEntityDrawOutline(entity, false)
    SetEntityCollision(entity, false, false)

    local originalCoords = GetEntityCoords(entity)
    local originalRotation = GetEntityRotation(entity, 2)

    startGizmoEditor(entity, t('menu.objects.gizmo_edit'), function(coords, rotation)
        SetEntityCollision(entity, true, false)
        FreezeEntityPosition(entity, true)

        local ok, response = pr_lib.callback.await(PR.Objects.Callbacks.updateObject, 10000, objectId, {
            coords = serialVector(coords),
            rotation = serialVector(rotation),
            heading = GetEntityHeading(entity),
        })

        if ok then
            if type(onUpdated) == 'function' then onUpdated(response) end
        else
            SetEntityCoordsNoOffset(entity, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
            SetEntityRotation(entity, originalRotation.x, originalRotation.y, originalRotation.z, 2, true)
            notify(t('notify.objects.update_failed', { error = tostring(response or 'unknown') }), 'error')
        end
    end, false)

    return true
end

function Objects.teleportTo(objectId)
    local entry = Objects.get(objectId)
    if not entry then return false end

    local coords = vec3(entry.coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    return true
end

function Objects.setOutline(objectId, enabled, r, g, b)
    local entry = Objects.get(objectId)
    if not entry or not entry.handle or not DoesEntityExist(entry.handle) then return false end

    SetEntityDrawOutline(entry.handle, enabled == true)
    if enabled then SetEntityDrawOutlineColor(r or 255, g or 0, b or 0, 255) end
    return true
end

AddStateBagChangeHandler('forgeObjects', 'global', function(_, _, value)
    applyPayload(value)
end)

CreateThread(function()
    local ok, payload = pr_lib.callback.await(PR.Objects.Callbacks.getAll, 10000)
    if ok and payload then applyPayload(payload) else applyPayload(currentPayload()) end

    while true do
        local payload = currentPayload()
        if payload.enabled ~= false then
            local pedCoords = GetEntityCoords(PlayerPedId())
            local spawnDistance = tonumber(payload.spawnDistance) or PR.Objects.Defaults.spawnDistance

            for _, entry in pairs(Objects.entries) do
                local distance = #(pedCoords - vec3(entry.coords))

                if distance <= spawnDistance then
                    spawnEntry(entry)
                else
                    deleteEntry(entry)
                end
            end
        else
            deleteAll()
        end

        Wait(1200)
    end
end)

CreateThread(function()
    while true do
        if Objects.debugIds then
            local pedCoords = GetEntityCoords(PlayerPedId())

            for _, entry in pairs(Objects.entries) do
                if entry.handle and DoesEntityExist(entry.handle) then
                    local coords = GetEntityCoords(entry.handle)
                    local distance = #(pedCoords - coords)
                    local nearby = distance < 15.0
                    SetEntityDrawOutline(entry.handle, nearby)
                    if nearby then
                        SetEntityDrawOutlineColor(0, 120, 255, 255)
                        if SetEntityDrawOutlineShader then SetEntityDrawOutlineShader(1) end
                        DrawMarker(0, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.10, 0.10, 0.10, 0, 120, 255, 190, false, false, 2, false, nil, nil, false)
                        drawDebugLabel(entry, coords, distance)
                    end
                end
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteAll()
    cleanupEditor(nil, false)
end)
