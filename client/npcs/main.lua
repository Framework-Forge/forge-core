ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Npcs = {
    entries = {},
    debugIds = false,
    placementActive = false,
}

ForgeCore.Client.Npcs = Npcs

local unpackArgs = table.unpack or unpack

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function notify(description, notifyType)
    if pr_lib and pr_lib.notify and pr_lib.notify.Notify then
        pr_lib.notify.Notify({
            title = t('npcs.title'),
            description = description,
            type = notifyType or 'inform',
            position = PR.NotifyPos,
        })
    end
end

local function setTargetingDisabled(disabled)
    if pr_lib and pr_lib.target and pr_lib.target.disableTargeting then
        pr_lib.target.disableTargeting(disabled == true)
    end
end

local function vec3(value)
    if type(value) == 'vector3' then return value end
    value = type(value) == 'table' and value or {}
    return vector3(tonumber(value.x or value[1]) or 0.0, tonumber(value.y or value[2]) or 0.0, tonumber(value.z or value[3]) or 0.0)
end

local function entryHeading(entry)
    entry = type(entry) == 'table' and entry or {}

    local heading = tonumber(entry.heading)
    if heading == nil and type(entry.rotation) == 'table' then
        heading = tonumber(entry.rotation.z or entry.rotation[3])
    end

    return (heading or 0.0) % 360.0
end

local function serialVector(value)
    value = vec3(value)
    return {
        x = tonumber(('%0.3f'):format(value.x)),
        y = tonumber(('%0.3f'):format(value.y)),
        z = tonumber(('%0.3f'):format(value.z)),
    }
end

local function placementCoords(value)
    value = type(value) == 'table' and value or {}
    return vector3(tonumber(value.x) or 0.0, tonumber(value.y) or 0.0, tonumber(value.z) or 0.0)
end

local function getCurrentJob()
    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)

    if ok and type(data) == 'table' then
        local job = data and data.job
        if type(job) == 'table' then
            return tostring(job.name or ''), tonumber(job.grade and (job.grade.level or job.grade) or 0) or 0
        end
    end

    local state = LocalPlayer and LocalPlayer.state
    local job = state and (state.job or state.PlayerData and state.PlayerData.job)
    if type(job) == 'table' then
        return tostring(job.name or ''), tonumber(job.grade and (job.grade.level or job.grade) or 0) or 0
    end

    return '', 0
end

local function getCurrentGang()
    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)

    if ok and type(data) == 'table' then
        local gang = data and data.gang
        if type(gang) == 'table' then
            return tostring(gang.name or ''), tonumber(gang.grade and (gang.grade.level or gang.grade) or 0) or 0
        end
    end

    local state = LocalPlayer and LocalPlayer.state
    local gang = state and (state.gang or state.PlayerData and state.PlayerData.gang)
    if type(gang) == 'table' then
        return tostring(gang.name or ''), tonumber(gang.grade and (gang.grade.level or gang.grade) or 0) or 0
    end

    return '', 0
end

local function canInteract(npc)
    local access = npc and npc.interaction and npc.interaction.access
    local requiredJob = access and tostring(access.job or '') or ''
    local requiredGang = access and tostring(access.gang or '') or ''
    if requiredJob == '' and requiredGang == '' then return true end

    if requiredJob ~= '' then
        local jobName, grade = getCurrentJob()
        if jobName == requiredJob and grade >= (tonumber(access.grade or access.jobGrade) or 0) then
            return true
        end
    end

    if requiredGang ~= '' then
        local gangName, grade = getCurrentGang()
        if gangName == requiredGang and grade >= (tonumber(access.gangGrade) or 0) then
            return true
        end
    end

    return false
end

local function clearTarget(entry)
    if entry and entry.targetName and entry.handle and DoesEntityExist(entry.handle) and pr_lib and pr_lib.target and pr_lib.target.removeLocalEntity then
        pr_lib.target.removeLocalEntity(entry.handle, entry.targetName)
    end

    if entry then entry.targetName = nil end
end

local function deleteEntry(entry)
    clearTarget(entry)

    if entry and entry.handle and DoesEntityExist(entry.handle) then
        SetEntityAsMissionEntity(entry.handle, true, true)
        DeleteEntity(entry.handle)
    end

    if entry then entry.handle = nil end
end

local function deleteAll()
    for _, entry in pairs(Npcs.entries) do
        deleteEntry(entry)
    end
end

local function setPedEditMode(entry, enabled)
    if not entry or not entry.handle or not DoesEntityExist(entry.handle) then return end

    if enabled then
        clearTarget(entry)
        SetEntityCollision(entry.handle, false, false)
        SetEntityAlpha(entry.handle, 90, false)
        FreezeEntityPosition(entry.handle, true)
        return
    end

    ResetEntityAlpha(entry.handle)
    SetEntityCollision(entry.handle, true, true)
    FreezeEntityPosition(entry.handle, true)
end

local function applyStoredHeading(entry)
    if not entry or not entry.handle or not DoesEntityExist(entry.handle) then return end

    SetEntityHeading(entry.handle, entryHeading(entry))
    FreezeEntityPosition(entry.handle, true)
end

local function applyAnimation(entry)
    local npc = entry.handle
    if not npc or not DoesEntityExist(npc) then return end

    ClearPedTasksImmediately(npc)
    applyStoredHeading(entry)

    local animation = entry.animation or {}
    local scenario = tostring(animation.scenario or '')
    if scenario ~= '' then
        TaskStartScenarioInPlace(npc, scenario, 0, true)
        SetTimeout(150, function() applyStoredHeading(entry) end)
        SetTimeout(750, function() applyStoredHeading(entry) end)
        SetTimeout(1500, function() applyStoredHeading(entry) end)
        return
    end

    local animDict = tostring(animation.animDict or '')
    local animName = tostring(animation.animName or '')
    if animDict == '' or animName == '' then
        applyStoredHeading(entry)
        return
    end

    if pr_lib and pr_lib.fivem and pr_lib.fivem.streaming and pr_lib.fivem.streaming.requestAnimDict then
        pr_lib.fivem.streaming.requestAnimDict(animDict, 5000)
    else
        RequestAnimDict(animDict)
        local timeout = GetGameTimer() + 5000
        while not HasAnimDictLoaded(animDict) and GetGameTimer() < timeout do Wait(0) end
    end

    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(npc, animDict, animName, 8.0, -8.0, -1, 1, 0.0, false, false, false)
        SetTimeout(150, function() applyStoredHeading(entry) end)
        SetTimeout(750, function() applyStoredHeading(entry) end)
    end
end

local function parseExportArg(rawArg, entry)
    rawArg = tostring(rawArg or ''):gsub('^%s+', ''):gsub('%s+$', '')

    if rawArg == '' then return nil end
    if rawArg == '$id' or rawArg == 'id' then return entry and entry.id end
    if rawArg == '$npc' or rawArg == 'npc' or rawArg == '$entry' or rawArg == 'entry' then return entry end
    if rawArg == 'true' then return true end
    if rawArg == 'false' then return false end
    if rawArg == 'nil' or rawArg == 'null' then return nil end

    local quoted = rawArg:match([[^'(.*)'$]]) or rawArg:match('^"(.*)"$')
    if quoted ~= nil then return quoted end

    local numeric = tonumber(rawArg)
    if numeric ~= nil then return numeric end

    return rawArg
end

local function splitExportArgs(rawArgs, entry)
    local args = {}
    rawArgs = tostring(rawArgs or '')
    if rawArgs:gsub('%s+', '') == '' then return args end

    local current = ''
    local quote

    for index = 1, #rawArgs do
        local char = rawArgs:sub(index, index)

        if quote then
            current = current .. char
            if char == quote and rawArgs:sub(index - 1, index - 1) ~= '\\' then quote = nil end
        elseif char == '"' or char == "'" then
            quote = char
            current = current .. char
        elseif char == ',' then
            args[#args + 1] = parseExportArg(current, entry)
            current = ''
        else
            current = current .. char
        end
    end

    if current ~= '' then
        args[#args + 1] = parseExportArg(current, entry)
    end

    return args
end

local function runExportAction(action, entry)
    local resource, exportName, rawArgs = action:match([[^exports%[['"]([^'"]+)['"]%]:([%w_]+)%((.*)%)$]])

    if not resource then
        resource, exportName, rawArgs = action:match([[^exports%.([%w_%-]+):([%w_]+)%((.*)%)$]])
    end

    if not resource or not exportName then return false end
    if GetResourceState(resource) ~= 'started' then return false, 'resource_not_started' end

    local resourceExports = exports[resource]
    if not resourceExports or type(resourceExports[exportName]) ~= 'function' then
        return false, 'export_not_found'
    end

    local args = splitExportArgs(rawArgs, entry)
    local ok, err = pcall(resourceExports[exportName], unpackArgs(args))
    if not ok then return false, err end

    return true
end

local function runInteraction(entry)
    local action = entry and entry.interaction and tostring(entry.interaction.event or '') or ''
    action = action:gsub('^%s+', ''):gsub('%s+$', '')

    if action == '' then
        notify(t('notify.npcs.event_missing'), 'error')
        return
    end

    if action:sub(1, 1) == '/' then
        ExecuteCommand(action:sub(2))
        return
    end

    if action:sub(1, 7) == 'exports' then
        local ok, err = runExportAction(action, entry)
        if not ok then
            notify(t('notify.npcs.event_failed', { error = tostring(err or 'unknown') }), 'error')
        end
        return
    end

    TriggerEvent(action, entry.id, entry)
end

local function addTarget(entry)
    local interaction = entry.interaction or {}
    if interaction.mode ~= 'target' and interaction.mode ~= 'both' then return end
    if not pr_lib or not pr_lib.target or not pr_lib.target.addLocalEntity then return end
    if not entry.handle or not DoesEntityExist(entry.handle) then return end

    local targetName = ('forge_core_npc_%s'):format(entry.id)
    clearTarget(entry)

    pr_lib.target.addLocalEntity(entry.handle, {
        {
            name = targetName,
            label = interaction.label ~= '' and interaction.label or entry.name,
            icon = 'fa-solid fa-user',
            distance = tonumber(interaction.distance) or PR.Npcs.Defaults.interactionDistance,
            canInteract = function()
                return canInteract(entry)
            end,
            onSelect = function()
                runInteraction(entry)
            end,
        },
    })

    entry.targetName = targetName
end

local function configurePed(entity)
    SetEntityAsMissionEntity(entity, true, true)
    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, true)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetPedCanRagdoll(entity, false)
    SetEntityDynamic(entity, false)
end

local function spawnEntry(entry)
    if entry.enabled == false then return nil end
    if entry.handle and DoesEntityExist(entry.handle) then return entry.handle end
    if not pr_lib or not pr_lib.fivem or not pr_lib.fivem.streaming then return nil end

    entry.heading = entryHeading(entry)

    local entity = pr_lib.fivem.streaming.createPed(entry.model, vec3(entry.coords), entry.heading, {
        networked = false,
        missionEntity = true,
        freeze = true,
        invincible = true,
        collision = true,
        timeout = 5000,
    })

    if not entity or entity == 0 then return nil end

    configurePed(entity)
    entry.handle = entity
    applyStoredHeading(entry)

    applyAnimation(entry)
    addTarget(entry)

    return entity
end

local function applyPayload(payload)
    payload = type(payload) == 'table' and payload or {}
    local nextEntries = {}

    for _, npc in ipairs(type(payload.npcs) == 'table' and payload.npcs or {}) do
        local id = tonumber(npc.id)
        if id then
            local existing = Npcs.entries[id] or {}
            local modelChanged = existing.model and existing.model ~= tostring(npc.model or '')
            local previousCoords = existing.coords
            local previousHeading = existing.heading

            existing.id = id
            existing.groupId = tonumber(npc.groupId or npc.groupid) or 0
            existing.model = tostring(npc.model or '')
            existing.name = tostring(npc.name or '')
            existing.description = tostring(npc.description or '')
            existing.enabled = npc.enabled ~= false
            existing.coords = vec3(npc.coords)
            existing.rotation = vec3(npc.rotation)
            existing.heading = entryHeading(npc)
            existing.interaction = type(npc.interaction) == 'table' and npc.interaction or {}
            existing.animation = type(npc.animation) == 'table' and npc.animation or {}

            if modelChanged then
                deleteEntry(existing)
            elseif existing.handle and DoesEntityExist(existing.handle) then
                clearTarget(existing)
                local transformChanged = true

                if previousCoords then
                    transformChanged = #(previousCoords - existing.coords) > 0.02 or math.abs((tonumber(previousHeading) or 0.0) - existing.heading) > 0.02
                end

                if transformChanged then
                    SetEntityCoords(existing.handle, existing.coords.x, existing.coords.y, existing.coords.z, false, false, false, false)
                    SetEntityHeading(existing.handle, existing.heading)
                else
                    applyStoredHeading(existing)
                end

                FreezeEntityPosition(existing.handle, true)
                applyAnimation(existing)
                SetTimeout(500, function()
                    if existing.handle and DoesEntityExist(existing.handle) then
                        addTarget(existing)
                    end
                end)
            end

            nextEntries[id] = existing
        end
    end

    for id, entry in pairs(Npcs.entries) do
        if not nextEntries[id] then
            deleteEntry(entry)
        end
    end

    Npcs.entries = nextEntries
end

local function currentPayload()
    local payload = GlobalState.forgeNpcs
    return type(payload) == 'table' and payload or { enabled = false, npcs = {}, spawnDistance = PR.Npcs.Defaults.spawnDistance }
end

function Npcs.get(npcId)
    return Npcs.entries[tonumber(npcId)]
end

function Npcs.getByGroup(groupId)
    local items = {}
    groupId = tonumber(groupId)

    for _, entry in pairs(Npcs.entries) do
        if tonumber(entry.groupId) == groupId then
            items[#items + 1] = entry
        end
    end

    table.sort(items, function(left, right) return tonumber(left.id) < tonumber(right.id) end)
    return items
end

function Npcs.toggleDebug()
    Npcs.debugIds = not Npcs.debugIds

    if not Npcs.debugIds then
        for _, entry in pairs(Npcs.entries) do
            entry.highlighted = false
        end
    end

    notify(Npcs.debugIds and t('notify.npcs.debug_on') or t('notify.npcs.debug_off'), 'inform')
    return Npcs.debugIds
end

local function drawDebugLabel(entry, coords, distance)
    local text = ('ID: %s\n%s\n%s\n%.2fm'):format(
        tostring(entry.id),
        tostring(entry.name),
        tostring(entry.model),
        tonumber(distance) or 0.0
    )

    if pr_lib and pr_lib.fivem and pr_lib.fivem.drawtext and pr_lib.fivem.drawtext.drawText3d then
        pr_lib.fivem.drawtext.drawText3d({
            text = text,
            coords = vector3(coords.x, coords.y, coords.z + 1.0),
            scale = vec2(0.28, 0.28),
            font = 4,
            color = vec4(0, 200, 120, 255),
            enableOutline = true,
            drawRect = true,
            rectAlpha = 115,
        })
    end

    if pr_lib and pr_lib.devtools and pr_lib.devtools.drawPedBox then
        pr_lib.devtools.drawPedBox(coords, entry.heading, entry.model, {
            r = 0,
            g = 220,
            b = 120,
            a = 210,
        })
    end
end

function Npcs.createPreview(model, groupId, name, description, onCreated)
    if not pr_lib or not pr_lib.devtools or not pr_lib.devtools.placePed then return false, 'devtools_unavailable' end

    Npcs.placementActive = true
    setTargetingDisabled(true)

    local started = pr_lib.devtools.placePed(model, 1, function(placement)
        if not placement then
            Npcs.placementActive = false
            SetTimeout(250, function() setTargetingDisabled(false) end)
            notify(t('notify.npcs.placement_cancelled'), 'inform')
            return
        end

        local coords = placementCoords(placement)
        local ok, npcId = pr_lib.callback.await(PR.Npcs.Callbacks.createNpc, 10000, {
            groupId = groupId,
            model = model,
            name = name,
            description = description,
            enabled = true,
            coords = serialVector(coords),
            rotation = serialVector(vector3(0.0, 0.0, tonumber(placement.heading) or 0.0)),
            heading = tonumber(placement.heading) or 0.0,
        })

        if ok and npcId then
            if type(onCreated) == 'function' then onCreated(npcId) end
        else
            notify(t('notify.npcs.create_failed', { error = tostring(npcId or 'unknown') }), 'error')
        end

        SetTimeout(500, function()
            Npcs.placementActive = false
            setTargetingDisabled(false)
        end)
    end, {
        preview = true,
        freezePlayer = true,
        heightOffset = 0.0,
        heightStep = 0.01,
        modelTimeout = 5000,
    })

    if started ~= true then
        Npcs.placementActive = false
        setTargetingDisabled(false)
    end

    return started == true, started == true and nil or 'devtools_failed'
end

function Npcs.edit(npcId, onUpdated)
    local entry = Npcs.get(npcId)
    if not entry then return false, 'npc_not_found' end
    if not pr_lib or not pr_lib.devtools or not pr_lib.devtools.placePed then return false, 'devtools_unavailable' end

    Npcs.placementActive = true
    setTargetingDisabled(true)
    setPedEditMode(entry, true)

    local started = pr_lib.devtools.placePed(entry.model, 1, function(placement)
        if not placement then
            Npcs.placementActive = false
            setPedEditMode(entry, false)
            SetTimeout(250, function() setTargetingDisabled(false) end)
            notify(t('notify.npcs.placement_cancelled'), 'inform')
            return
        end

        local coords = placementCoords(placement)
        local ok, response = pr_lib.callback.await(PR.Npcs.Callbacks.updateNpc, 10000, npcId, {
            coords = serialVector(coords),
            rotation = serialVector(vector3(0.0, 0.0, tonumber(placement.heading) or 0.0)),
            heading = tonumber(placement.heading) or 0.0,
        })

        if ok then
            if type(onUpdated) == 'function' then onUpdated(response) end
        else
            notify(t('notify.npcs.update_failed', { error = tostring(response or 'unknown') }), 'error')
        end

        SetTimeout(500, function()
            setPedEditMode(entry, false)
            Npcs.placementActive = false
            setTargetingDisabled(false)
        end)
    end, {
        preview = true,
        freezePlayer = true,
        heading = entry.heading,
        ignoreEntity = entry.handle,
        heightOffset = 0.0,
        heightStep = 0.01,
        modelTimeout = 5000,
    })

    if started ~= true then
        Npcs.placementActive = false
        setPedEditMode(entry, false)
        setTargetingDisabled(false)
    end

    return started == true, started == true and nil or 'devtools_failed'
end

function Npcs.teleportTo(npcId)
    local entry = Npcs.get(npcId)
    if not entry then return false end

    local coords = vec3(entry.coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    return true
end

function Npcs.setOutline(npcId, enabled)
    local entry = Npcs.get(npcId)
    if not entry or not entry.handle or not DoesEntityExist(entry.handle) then return false end

    entry.highlighted = false
    return true
end

AddStateBagChangeHandler('forgeNpcs', 'global', function(_, _, value)
    applyPayload(value)
end)

CreateThread(function()
    local ok, payload = pr_lib.callback.await(PR.Npcs.Callbacks.getAll, 10000)
    if ok and payload then applyPayload(payload) else applyPayload(currentPayload()) end

    while true do
        local payload = currentPayload()
        if payload.enabled ~= false and not Npcs.placementActive then
            local pedCoords = GetEntityCoords(PlayerPedId())
            local spawnDistance = tonumber(payload.spawnDistance) or PR.Npcs.Defaults.spawnDistance

            for _, entry in pairs(Npcs.entries) do
                local distance = #(pedCoords - vec3(entry.coords))

                if distance <= spawnDistance then
                    spawnEntry(entry)
                else
                    deleteEntry(entry)
                end
            end
        elseif payload.enabled == false then
            deleteAll()
        end

        Wait(1200)
    end
end)

CreateThread(function()
    while true do
        local sleep = 600
        local pedCoords = GetEntityCoords(PlayerPedId())

        for _, entry in pairs(Npcs.entries) do
            if entry.handle and DoesEntityExist(entry.handle) then
                local coords = GetEntityCoords(entry.handle)
                local distance = #(pedCoords - coords)
                local interaction = entry.interaction or {}

                if (Npcs.debugIds or entry.highlighted) and distance < 15.0 then
                    sleep = 0
                    drawDebugLabel(entry, coords, distance)
                end

                if (interaction.mode == 'drawtext' or interaction.mode == 'both') and distance <= (tonumber(interaction.distance) or PR.Npcs.Defaults.interactionDistance) and canInteract(entry) then
                    sleep = 0
                    local label = interaction.label ~= '' and interaction.label or entry.name
                    if pr_lib and pr_lib.fivem and pr_lib.fivem.drawtext and pr_lib.fivem.drawtext.drawText3d then
                        pr_lib.fivem.drawtext.drawText3d({
                            text = ('[E] %s'):format(label),
                            coords = vector3(coords.x, coords.y, coords.z + 1.0),
                            scale = vec2(0.32, 0.32),
                            font = 4,
                            color = vec4(255, 255, 255, 255),
                            enableOutline = true,
                            drawRect = true,
                            rectAlpha = 110,
                        })
                    end

                    if IsControlJustPressed(0, PR.Npcs.Defaults.drawTextKey or 38) then
                        runInteraction(entry)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    deleteAll()
end)
