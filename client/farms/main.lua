ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Farms = {
    zones = {},
    routeZones = {},
    blips = {},
    payload = nil,
    active = nil,
    busy = false,
}

ForgeCore.Client.Farms = Farms

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function notify(data)
    if not pr_lib or not pr_lib.Notify then return end
    pr_lib.Notify({
        title = data.title or t('farms.title'),
        description = data.description,
        type = data.type,
        position = PR.NotifyPos,
    })
end

local function coordsVector(coords)
    if type(coords) ~= 'table' then return nil end
    if pr_lib and pr_lib.math and pr_lib.math.toVector then
        local ok, vector = pcall(pr_lib.math.toVector, coords)
        if ok and type(vector) == 'vector3' then return vector end
    end
    return vector3(tonumber(coords.x) or tonumber(coords[1]) or 0.0, tonumber(coords.y) or tonumber(coords[2]) or 0.0, tonumber(coords.z) or tonumber(coords[3]) or 0.0)
end

local function clearZones()
    if pr_lib and pr_lib.target and pr_lib.target.removeZone then
        for i = 1, #Farms.zones do
            pr_lib.target.removeZone(Farms.zones[i])
        end
    end
    Farms.zones = {}
end

local function clearBlips()
    for i = 1, #Farms.blips do
        if DoesBlipExist(Farms.blips[i]) then RemoveBlip(Farms.blips[i]) end
    end
    Farms.blips = {}
end

local function clearRouteZones()
    if pr_lib and pr_lib.target and pr_lib.target.removeZone then
        for i = 1, #Farms.routeZones do
            pr_lib.target.removeZone(Farms.routeZones[i])
        end
    end
    Farms.routeZones = {}
end

local function getPlayerData()
    if pr_lib and pr_lib.framework and pr_lib.framework.GetPlayerData then
        local data = pr_lib.framework.GetPlayerData()
        if type(data) == 'table' then return data end
    end
    return {}
end

local function gradeLevel(group)
    local grade = group and group.grade
    if type(grade) == 'table' then return tonumber(grade.level or grade.grade or grade.value) or 0 end
    return tonumber(grade) or 0
end

local function canAccess(farm)
    if farm.public == true then return true end
    local data = getPlayerData()
    local group = farm.groupType == 'gang' and data.gang or data.job
    local activeName = tostring(group and group.name or ''):lower()
    local requiredName = tostring(farm.groupName or ''):lower()
    return requiredName ~= '' and activeName == requiredName and gradeLevel(group) >= (tonumber(farm.minGrade) or 0)
end

local function itemLabel(itemName)
    if pr_lib and pr_lib.inventory and pr_lib.inventory.GetItemLabel then
        local label = pr_lib.inventory.GetItemLabel(itemName)
        if label and label ~= '' then return label end
    end
    return itemName
end

local function findFarm(farmId)
    farmId = tonumber(farmId)
    for _, farm in ipairs(type(Farms.payload) == 'table' and type(Farms.payload.farms) == 'table' and Farms.payload.farms or {}) do
        if tonumber(farm.id) == farmId then return farm end
    end
end

local function findItem(farm, itemId)
    for _, item in ipairs(type(farm.items) == 'table' and farm.items or {}) do
        if tostring(item.id) == tostring(itemId) then return item end
    end
end

local function createRouteBlip(coords, label)
    clearBlips()
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 465)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 0.8)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    Farms.blips[#Farms.blips + 1] = blip
end

local function pickNextPoint()
    local active = Farms.active
    if not active then return end
    local item = active.item
    local points = type(item.points) == 'table' and item.points or {}
    if #points == 0 then
        notify({ description = t('notify.farms.no_points'), type = 'error' })
        Farms.active = nil
        return
    end

    if item.randomRoute == true then
        active.pointIndex = math.random(1, #points)
    else
        active.pointIndex = (active.pointIndex or 0) + 1
        if active.pointIndex > #points then
            if item.unlimited == true then
                active.pointIndex = 1
            else
                notify({ description = t('notify.farms.route_finished'), type = 'success' })
                if active.farm and active.item then
                    pr_lib.callback.await(PR.Farms.Callbacks.finishRoute, 5000, active.farm.id, active.item.id)
                end
                Farms.active = nil
                clearRouteZones()
                clearBlips()
                return
            end
        end
    end

    local coords = coordsVector(points[active.pointIndex])
    if coords then createRouteBlip(coords, t('menu.farms.farm_point')) end
end

local function stopFarm()
    local active = Farms.active
    if active and active.farm and active.item then
        pr_lib.callback.await(PR.Farms.Callbacks.finishRoute, 5000, active.farm.id, active.item.id)
    end
    Farms.active = nil
    Farms.busy = false
    clearRouteZones()
    clearBlips()
    notify({ description = t('notify.farms.cancelled'), type = 'inform' })
end

local function animationConfig(animation)
    animation = type(animation) == 'table' and animation or {}
    if animation.mode == 'manual' and tostring(animation.dict or '') ~= '' and tostring(animation.anim or '') ~= '' then
        return { dict = animation.dict, clip = animation.anim }
    end

    if animation.mode == 'scenario' and tostring(animation.scenario or '') ~= '' then
        return { scenario = animation.scenario }
    end

    for _, preset in ipairs(PR.Farms.AnimationPresets or {}) do
        if preset.value == animation.preset then
            if preset.scenario then
                return { scenario = preset.scenario }
            end
            return { dict = preset.animDict or 'pickup_object', clip = preset.animName or 'pickup_low' }
        end
    end

    return { dict = 'pickup_object', clip = 'pickup_low' }
end

local function doFarmProgress(duration, label, animation)
    local anim = animationConfig(animation)
    local ped = PlayerPedId()
    local running = true

    if anim.dict and anim.clip then
        RequestAnimDict(anim.dict)
        local timeout = GetGameTimer() + 5000
        while not HasAnimDictLoaded(anim.dict) and GetGameTimer() < timeout do
            Wait(0)
        end
    end

    CreateThread(function()
        while running do
            if anim.scenario then
                if not IsPedUsingScenario(ped, anim.scenario) then
                    TaskStartScenarioInPlace(ped, anim.scenario, 0, true)
                end
            elseif anim.dict and anim.clip and HasAnimDictLoaded(anim.dict) and not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
                TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
            end

            Wait(750)
        end
    end)

    local result = pr_lib and pr_lib.progressBar and pr_lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
    }) == true
    running = false
    ClearPedTasks(ped)
    return result
end

local function routeLimitReached(active)
    local limits = type(active.item.limits) == 'table' and active.item.limits or {}
    return limits.enabled == true and (tonumber(limits.maxPerRoute) or 0) > 0 and (tonumber(active.collected) or 0) >= tonumber(limits.maxPerRoute)
end

local function canUsePoint(pointIndex)
    local active = Farms.active
    if not active then return false end
    if Farms.busy then return false end
    return tonumber(active.pointIndex) == tonumber(pointIndex)
end

local function collectPoint(pointIndex)
    local active = Farms.active
    if not active or not canUsePoint(pointIndex) then
        notify({ description = t('notify.farms.wrong_point'), type = 'error' })
        return
    end

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        notify({ description = t('notify.farms.in_vehicle'), type = 'error' })
        return
    end

    local required = type(active.item.required) == 'table' and active.item.required or {}
    if tostring(required.vehicle or '') ~= '' then
        local lastVehicle = GetVehiclePedIsIn(PlayerPedId(), true)
        if lastVehicle == 0 or not IsVehicleModel(lastVehicle, joaat(required.vehicle)) then
            notify({ description = t('notify.farms.vehicle_required', { vehicle = required.vehicle }), type = 'error' })
            return
        end
    end

    Farms.busy = true
    local progressed = doFarmProgress(
        tonumber(active.item.collectTime) or PR.Farms.Defaults.collectTime,
        t('menu.farms.collect_progress', { item = active.item.label or itemLabel(active.item.reward) }),
        active.item.animation
    )
    ClearPedTasks(PlayerPedId())

    if not progressed then
        Farms.busy = false
        notify({ description = t('notify.farms.cancelled'), type = 'error' })
        return
    end

    local ok, result = pr_lib.callback.await(PR.Farms.Callbacks.collect, 10000, active.farm.id, active.item.id)
    Farms.busy = false

    if not ok then
        notify({ description = t('notify.farms.collect_failed', { error = tostring(result or 'unknown') }), type = 'error' })
        return
    end

    result = type(result) == 'table' and result or {}
    active.collected = (tonumber(active.collected) or 0) + 1
    notify({ description = t('notify.farms.collected', { count = tostring(result.count or 0), item = result.label or result.item or '' }), type = 'success' })

    if routeLimitReached(active) then
        notify({ description = t('notify.farms.route_limit_reached'), type = 'success' })
        pr_lib.callback.await(PR.Farms.Callbacks.finishRoute, 5000, active.farm.id, active.item.id)
        Farms.active = nil
        Farms.busy = false
        clearRouteZones()
        clearBlips()
        return
    end

    pickNextPoint()
end

local function addPointTargets(farm, item)
    for index, point in ipairs(type(item.points) == 'table' and item.points or {}) do
        local coords = coordsVector(point)
        if coords and pr_lib and pr_lib.target and pr_lib.target.addBoxZone then
            local zoneId = pr_lib.target.addBoxZone({
                coords = coords,
                size = PR.Farms.Defaults.targetSize,
                rotation = 0.0,
                debug = PR.Debug == true,
                options = {
                    {
                        name = ('forge_core_farm_collect_%s_%s_%s'):format(farm.id, item.id, index),
                        icon = 'flower1',
                        label = t('menu.farms.collect_target', { item = item.label or itemLabel(item.reward) }),
                        distance = PR.Farms.Defaults.targetDistance,
                        canInteract = function()
                            return canUsePoint(index)
                        end,
                        onSelect = function()
                            collectPoint(index)
                        end,
                    },
                },
            })
            if zoneId then Farms.routeZones[#Farms.routeZones + 1] = zoneId end
        end
    end
end

local function startFarm(farm, item)
    if Farms.active then
        notify({ description = t('notify.farms.already_active'), type = 'error' })
        return
    end
    if #item.points == 0 then
        notify({ description = t('notify.farms.no_points'), type = 'error' })
        return
    end

    local ok, response = pr_lib.callback.await(PR.Farms.Callbacks.startRoute, 10000, farm.id, item.id)
    if not ok then
        notify({ description = t('notify.farms.start_failed', { error = tostring(response or 'unknown') }), type = 'error' })
        return
    end

    Farms.active = { farm = farm, item = item, pointIndex = 0, collected = 0 }
    addPointTargets(farm, item)
    notify({ description = t('notify.farms.started', { item = item.label or itemLabel(item.reward) }), type = 'success' })
    pickNextPoint()
end

local function openFarmMenu(farm)
    local options = {}

    for _, item in ipairs(type(farm.items) == 'table' and farm.items or {}) do
        if item.enabled ~= false then
            options[#options + 1] = {
                title = item.label or itemLabel(item.reward),
                description = t('menu.farms.item_description', { min = tostring(item.min), max = tostring(item.max), points = tostring(#(item.points or {})) }),
                icon = 'flower1',
                disabled = Farms.active ~= nil,
                onSelect = function()
                    startFarm(farm, item)
                end,
            }
        end
    end

    if Farms.active then
        options[#options + 1] = {
            title = t('menu.farms.stop_farm'),
            icon = 'ban',
            iconColor = 'red',
            onSelect = stopFarm,
        }
    end

    pr_lib.menus.RegisterContext({
        id = 'forge_core_farm_player_' .. tostring(farm.id),
        title = farm.name,
        options = options,
    })
    pr_lib.menus.ShowContext('forge_core_farm_player_' .. tostring(farm.id))
end

local function addStartZone(farm)
    if farm.enabled == false or not canAccess(farm) then return end
    if not pr_lib or not pr_lib.target or not pr_lib.target.addBoxZone then return end

    local coords = coordsVector(farm.start and farm.start.coords)
    if not coords then return end

    local zoneId = pr_lib.target.addBoxZone({
        coords = coords,
        size = PR.Farms.Defaults.targetSize,
        rotation = farm.start.rotation or 0.0,
        debug = PR.Debug == true,
        options = {
            {
                name = ('forge_core_farm_start_%s'):format(farm.id),
                icon = 'truck-front-fill',
                label = farm.start.label or t('menu.farms.open_target'),
                distance = PR.Farms.Defaults.targetDistance,
                onSelect = function()
                    openFarmMenu(farm)
                end,
            },
        },
    })

    if zoneId then Farms.zones[#Farms.zones + 1] = zoneId end
end

function Farms.refresh(payload)
    local active = Farms.active
    if active and active.farm and active.item and pr_lib and pr_lib.callback then
        pr_lib.callback.await(PR.Farms.Callbacks.finishRoute, 5000, active.farm.id, active.item.id)
    end

    clearRouteZones()
    clearZones()
    clearBlips()
    Farms.active = nil
    Farms.busy = false
    Farms.payload = type(payload) == 'table' and payload or {}

    local settings = type(Farms.payload.settings) == 'table' and Farms.payload.settings or {}
    if settings.enabled == false then return end

    for _, farm in ipairs(type(Farms.payload.farms) == 'table' and Farms.payload.farms or {}) do
        addStartZone(farm)
    end
end

AddStateBagChangeHandler('forgeFarms', 'global', function(_, _, value)
    Farms.refresh(value)
end)

CreateThread(function()
    Wait(2000)
    local ok, payload = pr_lib.callback.await(PR.Farms.Callbacks.getAll, 10000)
    if ok and payload then Farms.refresh(payload) else Farms.refresh(GlobalState.forgeFarms) end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    Farms.refresh(Farms.payload)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function()
    Farms.refresh(Farms.payload)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearZones()
    clearBlips()
end)
