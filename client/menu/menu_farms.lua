ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local alertDialog = Shared.alertDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local boolValue = Shared.boolValue
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions
local farmDevLaserActive = false

local function playerCoords()
    local coords = GetEntityCoords(PlayerPedId())
    return {
        x = tonumber(('%0.3f'):format(coords.x)),
        y = tonumber(('%0.3f'):format(coords.y)),
        z = tonumber(('%0.3f'):format(coords.z)),
    }
end

local function normalizePoint(coords)
    if not coords or coords.x == nil or coords.y == nil or coords.z == nil then return nil end

    return {
        x = tonumber(('%0.3f'):format(tonumber(coords.x) or 0.0)),
        y = tonumber(('%0.3f'):format(tonumber(coords.y) or 0.0)),
        z = tonumber(('%0.3f'):format(tonumber(coords.z) or 0.0)),
    }
end

local function showDevLaserText()
    if pr_lib and pr_lib.ShowTextUI then
        pr_lib.ShowTextUI(t('menu.farms.devlaser_instructions'))
    end
end

local function hideDevLaserText()
    if pr_lib and pr_lib.HideTextUI then pr_lib.HideTextUI() end
end

local function capturePointWithDevLaser(onCapture, onCancel)
    local devlaser = pr_lib and (pr_lib.devlaser or pr_lib.devLaser or (pr_lib.fivem and (pr_lib.fivem.devlaser or pr_lib.fivem.devLaser)))
    if not devlaser or not devlaser.start or not devlaser.getTarget then
        notifyFailure('notify.farms.devlaser_failed', 'devlaser_unavailable')
        if onCancel then onCancel() end
        return false
    end

    if farmDevLaserActive then return false end
    farmDevLaserActive = true
    showDevLaserText()

    devlaser.start({
        distance = 1000.0,
        flags = -1,
        onStop = function()
            if not farmDevLaserActive then return end

            farmDevLaserActive = false
            hideDevLaserText()
            if onCancel then onCancel() end
        end,
    })

    CreateThread(function()
        while farmDevLaserActive and devlaser.isActive and devlaser.isActive() do
            Wait(0)

            if IsControlJustReleased(0, 201) or IsDisabledControlJustReleased(0, 201) then
                local target = devlaser.getTarget()
                local point = target and normalizePoint(target.coords)

                if point then
                    farmDevLaserActive = false
                    hideDevLaserText()
                    devlaser.stop(true)
                    if onCapture then onCapture(point) end
                else
                    notifyFailure('notify.farms.devlaser_failed', 'target_not_found')
                end
            elseif IsControlJustReleased(0, 177) or IsDisabledControlJustReleased(0, 177) or IsControlJustReleased(0, 202) or IsDisabledControlJustReleased(0, 202) then
                farmDevLaserActive = false
                hideDevLaserText()
                devlaser.stop(true)
                if onCancel then onCancel() end
            end
        end

        if farmDevLaserActive then
            farmDevLaserActive = false
            hideDevLaserText()
            if onCancel then onCancel() end
        end
    end)

    return true
end

local function playerHeading()
    return tonumber(('%0.2f'):format(GetEntityHeading(PlayerPedId())))
end

local function teleport(coords)
    coords = type(coords) == 'table' and coords or {}
    SetEntityCoords(PlayerPedId(), tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0, false, false, false, false)
end

local function fetchPayload()
    local ok, payload = awaitServer(PR.Farms.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.farms.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.settings = type(payload.settings) == 'table' and payload.settings or {}
    payload.farms = type(payload.farms) == 'table' and payload.farms or {}
    return payload
end

local function refreshClient(payload)
    if ForgeCore.Client.Farms and ForgeCore.Client.Farms.refresh then
        ForgeCore.Client.Farms.refresh(payload)
    end
end

local function saveFarm(farm, back)
    local ok, response
    if tonumber(farm.id) and tonumber(farm.id) > 0 then
        ok, response = awaitServer(PR.Farms.Callbacks.updateFarm, farm.id, farm)
    else
        ok, response = awaitServer(PR.Farms.Callbacks.createFarm, farm)
    end

    if not ok then
        notifyFailure('notify.farms.save_failed', response)
        return false
    end

    refreshClient(response)
    if back then SetTimeout(250, back) end
    return true
end

local function findFarm(farmId)
    local payload = fetchPayload()
    if not payload then return nil end
    for _, farm in ipairs(payload.farms) do
        if tonumber(farm.id) == tonumber(farmId) then return farm, payload end
    end
end

local function findItem(farm, itemId)
    for index, item in ipairs(type(farm.items) == 'table' and farm.items or {}) do
        if tostring(item.id) == tostring(itemId) then return item, index end
    end
end

local function farmDescription(farm)
    return t('menu.farms.farm_description', {
        status = farm.enabled == false and t('common.inactive') or t('common.active'),
        access = farm.public == true and t('menu.farms.public') or ((farm.groupType or 'job') .. ':' .. (farm.groupName or '')),
        items = tostring(#(farm.items or {})),
    })
end

local function animationOptions()
    local options = {}
    for _, preset in ipairs(PR.Farms.AnimationPresets or {}) do
        options[#options + 1] = {
            label = preset.label,
            value = preset.value,
        }
    end
    return options
end

local function fetchGroups(groupType)
    local ok, groups = awaitServer(PR.Farms.Callbacks.getGroups, groupType)
    if not ok then
        notifyFailure('notify.farms.load_failed', groups)
        return {}
    end
    return type(groups) == 'table' and groups or {}
end

local function fetchItems()
    local ok, items = awaitServer(PR.Farms.Callbacks.getItems)
    if not ok then
        notifyFailure('notify.farms.load_failed', items)
        return {}
    end
    return type(items) == 'table' and items or {}
end

local function itemOptions(includeNone)
    local options = {}
    if includeNone then
        options[#options + 1] = { label = t('common.none'), value = '' }
    end

    for _, item in ipairs(fetchItems()) do
        local name = tostring(item.name or '')
        if name ~= '' then
            options[#options + 1] = {
                label = ('%s (%s)'):format(tostring(item.label or name), name),
                value = name,
            }
        end
    end

    return options
end

local function vehicleOptions(includeNone)
    local options = {}
    if includeNone then
        options[#options + 1] = { label = t('common.none'), value = '' }
    end

    local ok, vehicles = awaitServer(PR.Farms.Callbacks.getVehicles)
    if not ok then
        notifyFailure('notify.farms.load_failed', vehicles)
        return options
    end

    for _, vehicle in ipairs(type(vehicles) == 'table' and vehicles or {}) do
        local model = tostring(vehicle.model or '')
        if model ~= '' then
            local label = tostring(vehicle.label or model)
            options[#options + 1] = {
                label = ('%s (%s)'):format(label, model),
                value = model,
            }
        end
    end

    return options
end

function Menu.openFarmsMenu()
    local payload = fetchPayload()
    if not payload then return end

    local options = {
        {
            title = t('menu.farms.settings'),
            description = t('menu.farms.settings_description', {
                status = payload.settings.enabled == false and t('common.inactive') or t('common.active'),
            }),
            icon = 'sliders',
            onSelect = function()
                Menu.openFarmSettings(payload.settings)
            end,
        },
        {
            title = t('menu.farms.create_farm'),
            description = t('menu.farms.create_farm_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openFarmCreate()
            end,
        },
    }

    for _, farm in ipairs(payload.farms) do
        options[#options + 1] = {
            title = farm.name,
            description = farmDescription(farm),
            icon = farm.enabled == false and 'truck-front-fill' or 'flower1',
            onSelect = function()
                Menu.openFarmAdmin(farm.id)
            end,
        }
    end

    showContext({
        id = 'forge_core_farms_admin',
        title = t('menu.farms.title'),
        menu = 'forge_core_server_settings',
        options = options,
    })
end

function Menu.openFarmSettings(settings)
    settings = type(settings) == 'table' and settings or {}
    local result = inputDialog(t('menu.farms.settings'), {
        {
            type = 'select',
            label = t('inputs.farms_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled ~= false),
            required = true,
        },
    })

    if not result then return Menu.openFarmsMenu() end

    local ok, response = awaitServer(PR.Farms.Callbacks.saveSettings, {
        enabled = boolValue(result[1]),
    })

    if not ok then notifyFailure('notify.farms.save_failed', response) else refreshClient(response) end
    SetTimeout(250, Menu.openFarmsMenu)
end

function Menu.openFarmCreate()
    local result = inputDialog(t('menu.farms.create_farm'), {
        { type = 'input', label = t('inputs.farm_name'), required = true },
        { type = 'select', label = t('inputs.farm_enabled'), options = boolOptions(), default = 'true', required = true },
        { type = 'select', label = t('inputs.farm_public'), options = boolOptions(), default = 'true', required = true },
    })

    if not result then return Menu.openFarmsMenu() end

    local farm = {
        name = result[1],
        enabled = boolValue(result[2]),
        public = boolValue(result[3]),
        groupType = 'job',
        groupName = '',
        minGrade = 0,
        start = {
            coords = playerCoords(),
            rotation = playerHeading(),
            label = t('menu.farms.open_target'),
        },
        items = {},
    }

    saveFarm(farm, Menu.openFarmsMenu)
end

function Menu.openFarmAdmin(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    showContext({
        id = 'forge_core_farm_admin_' .. tostring(farm.id),
        title = farm.name,
        menu = 'forge_core_farms_admin',
        options = {
            {
                title = t('menu.farms.edit_farm'),
                description = t('menu.farms.edit_farm_description'),
                icon = 'pen',
                onSelect = function() Menu.openFarmEdit(farm.id) end,
            },
            {
                title = t('menu.farms.access'),
                description = t('menu.farms.access_description', {
                    access = farm.public == true and t('menu.farms.public') or ((farm.groupType or 'job') .. ':' .. (farm.groupName or '')),
                }),
                icon = 'person-lock',
                onSelect = function() Menu.openFarmAccessMenu(farm.id) end,
            },
            {
                title = t('menu.farms.entrance'),
                description = t('menu.farms.entrance_description'),
                icon = 'crosshair',
                onSelect = function() Menu.openFarmEntranceMenu(farm.id) end,
            },
            {
                title = t('menu.farms.items'),
                description = t('menu.farms.items_description', { count = tostring(#(farm.items or {})) }),
                icon = 'flower1',
                onSelect = function() Menu.openFarmItems(farm.id) end,
            },
            {
                title = t('menu.farms.delete_farm'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function() Menu.deleteFarm(farm.id) end,
            },
        },
    })
end

function Menu.openFarmEdit(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    local result = inputDialog(t('menu.farms.edit_farm'), {
        { type = 'input', label = t('inputs.farm_name'), default = farm.name, required = true },
        { type = 'select', label = t('inputs.farm_enabled'), options = boolOptions(), default = boolDefault(farm.enabled ~= false), required = true },
    })

    if not result then return Menu.openFarmAdmin(farm.id) end

    farm.name = result[1]
    farm.enabled = boolValue(result[2])

    saveFarm(farm, function() Menu.openFarmAdmin(farm.id) end)
end

function Menu.openFarmAccessMenu(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    showContext({
        id = 'forge_core_farm_access_' .. tostring(farm.id),
        title = t('menu.farms.access'),
        menu = 'forge_core_farm_admin_' .. tostring(farm.id),
        options = {
            {
                title = t('menu.farms.access_public'),
                description = t('menu.farms.access_public_description'),
                icon = 'people-fill',
                onSelect = function()
                    farm.public = true
                    farm.groupType = 'job'
                    farm.groupName = ''
                    farm.minGrade = 0
                    saveFarm(farm, function() Menu.openFarmAdmin(farm.id) end)
                end,
            },
            {
                title = t('menu.farms.access_job'),
                description = t('menu.farms.access_job_description'),
                icon = 'briefcase',
                onSelect = function()
                    Menu.openFarmGroupList(farm.id, 'job')
                end,
            },
            {
                title = t('menu.farms.access_gang'),
                description = t('menu.farms.access_gang_description'),
                icon = 'people-fill',
                onSelect = function()
                    Menu.openFarmGroupList(farm.id, 'gang')
                end,
            },
        },
    })
end

function Menu.openFarmGroupList(farmId, groupType)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    local options = {}
    for _, group in ipairs(fetchGroups(groupType)) do
        options[#options + 1] = {
            title = group.label or group.name,
            description = group.name,
            icon = groupType == 'gang' and 'people-fill' or 'briefcase-fill',
            onSelect = function()
                Menu.openFarmGroupGrade(farm.id, groupType, group)
            end,
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.farms.no_groups'),
            icon = 'info-circle-fill',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_farm_group_list_' .. tostring(farm.id) .. '_' .. groupType,
        title = groupType == 'gang' and t('common.gang') or t('common.job'),
        menu = 'forge_core_farm_access_' .. tostring(farm.id),
        options = options,
    })
end

function Menu.openFarmGroupGrade(farmId, groupType, group)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    local result = inputDialog(group.label or group.name, {
        { type = 'number', label = t('inputs.farm_min_grade'), default = tonumber(farm.minGrade) or 0, min = 0, required = true },
    })

    if not result then return Menu.openFarmGroupList(farm.id, groupType) end

    farm.public = false
    farm.groupType = groupType
    farm.groupName = group.name
    farm.minGrade = tonumber(result[1]) or 0
    saveFarm(farm, function() Menu.openFarmAdmin(farm.id) end)
end

function Menu.openFarmEntranceMenu(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    showContext({
        id = 'forge_core_farm_entrance_' .. tostring(farm.id),
        title = t('menu.farms.entrance'),
        menu = 'forge_core_farm_admin_' .. tostring(farm.id),
        options = {
            {
                title = t('menu.farms.mark_position'),
                description = t('menu.farms.mark_start_description'),
                icon = 'crosshair',
                onSelect = function() Menu.markFarmStart(farm.id) end,
            },
            {
                title = t('menu.farms.mark_devlaser'),
                description = t('menu.farms.mark_devlaser_description'),
                icon = 'crosshair',
                onSelect = function() Menu.markFarmStartWithDevLaser(farm.id) end,
            },
            {
                title = t('menu.farms.edit_target'),
                description = farm.start and farm.start.label or t('menu.farms.open_target'),
                icon = 'tag',
                onSelect = function() Menu.openFarmTargetEdit(farm.id) end,
            },
            {
                title = t('menu.farms.teleport_start'),
                icon = 'cursor-fill',
                onSelect = function()
                    teleport(farm.start and farm.start.coords)
                    Menu.openFarmEntranceMenu(farm.id)
                end,
            },
        },
    })
end

function Menu.openFarmTargetEdit(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    local result = inputDialog(t('menu.farms.edit_target'), {
        { type = 'input', label = t('inputs.farm_target_label'), default = farm.start and farm.start.label or t('menu.farms.open_target'), required = true },
    })

    if not result then return Menu.openFarmEntranceMenu(farm.id) end

    farm.start = type(farm.start) == 'table' and farm.start or {}
    farm.start.label = result[1]
    saveFarm(farm, function() Menu.openFarmEntranceMenu(farm.id) end)
end

function Menu.markFarmStart(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    farm.start = type(farm.start) == 'table' and farm.start or {}
    farm.start.coords = playerCoords()
    farm.start.rotation = playerHeading()
    farm.start.label = farm.start.label or t('menu.farms.open_target')
    saveFarm(farm, function() Menu.openFarmEntranceMenu(farm.id) end)
end

function Menu.markFarmStartWithDevLaser(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    capturePointWithDevLaser(function(point)
        farm.start = type(farm.start) == 'table' and farm.start or {}
        farm.start.coords = point
        farm.start.rotation = farm.start.rotation or playerHeading()
        farm.start.label = farm.start.label or t('menu.farms.open_target')
        saveFarm(farm, function() Menu.openFarmEntranceMenu(farm.id) end)
    end, function()
        Menu.openFarmEntranceMenu(farm.id)
    end)
end

function Menu.deleteFarm(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    local confirm = alertDialog({
        header = t('dialogs.remove_farm_header'),
        content = t('dialogs.remove_farm_content', { name = farm.name }),
        centered = true,
        cancel = true,
    })

    if confirm ~= 'confirm' then return Menu.openFarmAdmin(farm.id) end

    local ok, response = awaitServer(PR.Farms.Callbacks.deleteFarm, farm.id)
    if not ok then notifyFailure('notify.farms.farm_delete_failed', response) else refreshClient(response) end
    SetTimeout(250, Menu.openFarmsMenu)
end

function Menu.openFarmItems(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    local options = {
        {
            title = t('menu.farms.add_item'),
            icon = 'plus',
            onSelect = function() Menu.openFarmItemCreateSelect(farm.id) end,
        },
    }

    for _, item in ipairs(type(farm.items) == 'table' and farm.items or {}) do
        options[#options + 1] = {
            title = item.label,
            description = t('menu.farms.item_description', { min = tostring(item.min), max = tostring(item.max), points = tostring(#(item.points or {})) }),
            icon = item.enabled == false and 'ban' or 'flower1',
            onSelect = function() Menu.openFarmItemMenu(farm.id, item.id) end,
        }
    end

    showContext({
        id = 'forge_core_farm_items_' .. tostring(farm.id),
        title = t('menu.farms.items'),
        menu = 'forge_core_farm_admin_' .. tostring(farm.id),
        options = options,
    })
end

function Menu.openFarmItemCreateSelect(farmId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    local options = {}
    for _, option in ipairs(itemOptions(false)) do
        options[#options + 1] = {
            title = option.label,
            icon = 'box',
            onSelect = function()
                Menu.openFarmItemCreateDetails(farm.id, option.value, option.label)
            end,
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.farms.no_items'),
            icon = 'info-circle-fill',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_farm_item_select_' .. tostring(farm.id),
        title = t('menu.farms.select_item'),
        menu = 'forge_core_farm_items_' .. tostring(farm.id),
        options = options,
    })
end

function Menu.openFarmItemCreateDetails(farmId, itemName, itemLabel)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end

    local result = inputDialog(t('menu.farms.add_item'), {
        { type = 'input', label = t('inputs.farm_item_label'), default = itemLabel or itemName, required = true },
        { type = 'select', label = t('inputs.farm_item_enabled'), options = boolOptions(), default = 'true', required = true },
        { type = 'number', label = t('inputs.farm_min_reward'), default = 1, min = 0, required = true },
        { type = 'number', label = t('inputs.farm_max_reward'), default = 1, min = 0, required = true },
        { type = 'number', label = t('inputs.farm_collect_time'), default = PR.Farms.Defaults.collectTime, min = 1000, required = true },
    })

    if not result then return Menu.openFarmItemCreateSelect(farm.id) end

    farm.items = type(farm.items) == 'table' and farm.items or {}
    farm.items[#farm.items + 1] = {
        id = itemName,
        label = result[1],
        reward = itemName,
        enabled = boolValue(result[2]),
        min = tonumber(result[3]) or 1,
        max = tonumber(result[4]) or tonumber(result[3]) or 1,
        collectTime = tonumber(result[5]) or PR.Farms.Defaults.collectTime,
        randomRoute = false,
        unlimited = false,
        required = {},
        animation = { mode = 'preset', preset = 'pickup' },
        limits = {},
        points = {},
        extraItems = {},
    }

    saveFarm(farm, function() Menu.openFarmItems(farm.id) end)
end

function Menu.openFarmItemMenu(farmId, itemId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end

    showContext({
        id = 'forge_core_farm_item_' .. tostring(farm.id) .. '_' .. item.id,
        title = item.label,
        menu = 'forge_core_farm_items_' .. tostring(farm.id),
        options = {
            { title = t('menu.farms.edit_item'), description = t('menu.farms.edit_item_description'), icon = 'pen', onSelect = function() Menu.openFarmItemEdit(farm.id, item.id) end },
            { title = t('menu.farms.required_item'), description = t('menu.farms.required_item_description'), icon = 'tools', onSelect = function() Menu.openFarmItemRequired(farm.id, item.id) end },
            { title = t('menu.farms.limits'), description = t('menu.farms.limits_description'), icon = 'hourglass-split', onSelect = function() Menu.openFarmItemLimits(farm.id, item.id) end },
            { title = t('menu.farms.animation'), description = t('menu.farms.animation_description'), icon = 'person-walking', onSelect = function() Menu.openFarmItemAnimation(farm.id, item.id) end },
            { title = t('menu.farms.points'), description = t('menu.farms.points_description', { count = tostring(#(item.points or {})) }), icon = 'geo-alt-fill', onSelect = function() Menu.openFarmItemPoints(farm.id, item.id) end },
            { title = t('menu.farms.extra_rewards'), description = t('menu.farms.extra_rewards_description', { count = tostring(#(item.extraItems or {})) }), icon = 'gift', onSelect = function() Menu.openFarmItemExtras(farm.id, item.id) end },
            { title = t('menu.farms.delete_item'), icon = 'trash', iconColor = 'red', onSelect = function() Menu.deleteFarmItem(farm.id, item.id) end },
        },
    })
end

function Menu.openFarmItemEdit(farmId, itemId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = itemId and findItem(farm, itemId) or {
        enabled = true,
        min = 1,
        max = 1,
        collectTime = PR.Farms.Defaults.collectTime,
        randomRoute = false,
        unlimited = false,
        required = {},
        animation = { mode = 'preset', preset = 'pickup' },
        points = {},
        extraItems = {},
        limits = {},
    }

    local result = inputDialog(itemId and t('menu.farms.edit_item') or t('menu.farms.add_item'), {
        { type = 'input', label = t('inputs.farm_item_label'), default = item.label or '', required = true },
        { type = 'select', label = t('inputs.farm_item_enabled'), options = boolOptions(), default = boolDefault(item.enabled ~= false), required = true },
        { type = 'number', label = t('inputs.farm_min_reward'), default = tonumber(item.min) or 1, min = 0, required = true },
        { type = 'number', label = t('inputs.farm_max_reward'), default = tonumber(item.max) or 1, min = 0, required = true },
        { type = 'number', label = t('inputs.farm_collect_time'), default = tonumber(item.collectTime) or PR.Farms.Defaults.collectTime, min = 1000, required = true },
        { type = 'select', label = t('inputs.farm_random_route'), options = boolOptions(), default = boolDefault(item.randomRoute == true), required = true },
        { type = 'select', label = t('inputs.farm_unlimited'), options = boolOptions(), default = boolDefault(item.unlimited == true), required = true },
    })

    if not result then
        if itemId then return Menu.openFarmItemMenu(farm.id, item.id) end
        return Menu.openFarmItems(farm.id)
    end

    item.label = result[1]
    item.enabled = boolValue(result[2])
    item.min = tonumber(result[3]) or 1
    item.max = tonumber(result[4]) or item.min
    item.collectTime = tonumber(result[5]) or PR.Farms.Defaults.collectTime
    item.randomRoute = boolValue(result[6])
    item.unlimited = boolValue(result[7])

    farm.items = type(farm.items) == 'table' and farm.items or {}
    if not itemId then farm.items[#farm.items + 1] = item end
    saveFarm(farm, function() Menu.openFarmItems(farm.id) end)
end

function Menu.openFarmItemRequired(farmId, itemId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end
    item.required = type(item.required) == 'table' and item.required or {}
    local requiredOptions = itemOptions(true)

    local result = inputDialog(t('menu.farms.required_item'), {
        { type = 'select', label = t('inputs.farm_required_item'), options = requiredOptions, default = item.required.item or '' },
        { type = 'number', label = t('inputs.farm_required_durability'), default = tonumber(item.required.durability) or 0, min = 0 },
        { type = 'select', label = t('inputs.farm_required_vehicle'), options = vehicleOptions(true), default = item.required.vehicle or '' },
    })

    if not result then return Menu.openFarmItemMenu(farm.id, item.id) end
    item.required.item = result[1]
    item.required.durability = tonumber(result[2]) or 0
    item.required.vehicle = result[3]
    saveFarm(farm, function() Menu.openFarmItemMenu(farm.id, item.id) end)
end

function Menu.openFarmItemLimits(farmId, itemId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end
    item.limits = type(item.limits) == 'table' and item.limits or {}

    local result = inputDialog(t('menu.farms.limits'), {
        { type = 'select', label = t('inputs.farm_limit_enabled'), options = boolOptions(), default = boolDefault(item.limits.enabled == true), required = true },
        {
            type = 'select',
            label = t('inputs.farm_limit_scope'),
            options = {
                { label = t('menu.farms.limit_scope_item'), value = 'item' },
                { label = t('menu.farms.limit_scope_farm'), value = 'farm' },
            },
            default = item.limits.scope == 'farm' and 'farm' or 'item',
            required = true,
        },
        { type = 'number', label = t('inputs.farm_limit_max_route'), default = tonumber(item.limits.maxPerRoute) or 0, min = 0, required = true },
        { type = 'number', label = t('inputs.farm_cooldown_minutes'), default = tonumber(item.limits.cooldownMinutes) or 0, min = 0, required = true },
        { type = 'select', label = t('inputs.farm_once_daily'), options = boolOptions(), default = boolDefault(item.limits.onceDaily == true), required = true },
    })

    if not result then return Menu.openFarmItemMenu(farm.id, item.id) end

    item.limits.enabled = boolValue(result[1])
    item.limits.scope = result[2] == 'farm' and 'farm' or 'item'
    item.limits.maxPerRoute = tonumber(result[3]) or 0
    item.limits.cooldownMinutes = tonumber(result[4]) or 0
    item.limits.onceDaily = boolValue(result[5])
    saveFarm(farm, function() Menu.openFarmItemMenu(farm.id, item.id) end)
end

function Menu.openFarmItemAnimation(farmId, itemId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end
    item.animation = type(item.animation) == 'table' and item.animation or {}

    local result = inputDialog(t('menu.farms.animation'), {
        { type = 'select', label = t('inputs.farm_animation_preset'), options = animationOptions(), default = item.animation.preset or item.animation.mode or 'pickup', required = true },
        { type = 'input', label = t('inputs.farm_animation_scenario'), default = item.animation.scenario or '' },
        { type = 'input', label = t('inputs.farm_animation_dict'), default = item.animation.dict or '' },
        { type = 'input', label = t('inputs.farm_animation_anim'), default = item.animation.anim or '' },
    })

    if not result then return Menu.openFarmItemMenu(farm.id, item.id) end

    item.animation = {
        mode = result[1] == 'manual' and 'manual' or (tostring(result[2] or '') ~= '' and 'scenario' or 'preset'),
        preset = result[1],
        scenario = result[2],
        dict = result[3],
        anim = result[4],
    }
    saveFarm(farm, function() Menu.openFarmItemMenu(farm.id, item.id) end)
end

function Menu.openFarmItemPoints(farmId, itemId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end

    local options = {
        {
            title = t('menu.farms.add_point'),
            description = t('menu.farms.add_point_description'),
            icon = 'plus',
            onSelect = function() Menu.openFarmPointCaptureMenu(farm.id, item.id) end,
        },
    }

    for index, point in ipairs(type(item.points) == 'table' and item.points or {}) do
        options[#options + 1] = {
            title = t('menu.farms.point_title', { index = tostring(index) }),
            description = t('menu.farms.point_description', { x = tostring(point.x), y = tostring(point.y), z = tostring(point.z) }),
            icon = 'geo-alt-fill',
            onSelect = function()
                Menu.openFarmPointMenu(farm.id, item.id, index)
            end,
        }
    end

    showContext({
        id = 'forge_core_farm_points_' .. tostring(farm.id) .. '_' .. item.id,
        title = t('menu.farms.points'),
        menu = 'forge_core_farm_item_' .. tostring(farm.id) .. '_' .. item.id,
        options = options,
    })
end

function Menu.openFarmPointCaptureMenu(farmId, itemId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end

    showContext({
        id = 'forge_core_farm_point_capture_' .. tostring(farm.id) .. '_' .. item.id,
        title = t('menu.farms.add_point'),
        menu = 'forge_core_farm_points_' .. tostring(farm.id) .. '_' .. item.id,
        options = {
            {
                title = t('menu.farms.mark_position'),
                description = t('menu.farms.add_point_current_description'),
                icon = 'geo-alt-fill',
                onSelect = function()
                    item.points = type(item.points) == 'table' and item.points or {}
                    item.points[#item.points + 1] = playerCoords()
                    saveFarm(farm, function() Menu.openFarmItemPoints(farm.id, item.id) end)
                end,
            },
            {
                title = t('menu.farms.mark_devlaser'),
                description = t('menu.farms.add_point_devlaser_description'),
                icon = 'crosshair',
                onSelect = function()
                    capturePointWithDevLaser(function(point)
                        item.points = type(item.points) == 'table' and item.points or {}
                        item.points[#item.points + 1] = point
                        saveFarm(farm, function() Menu.openFarmItemPoints(farm.id, item.id) end)
                    end, function()
                        Menu.openFarmPointCaptureMenu(farm.id, item.id)
                    end)
                end,
            },
        },
    })
end

function Menu.openFarmPointMenu(farmId, itemId, pointIndex)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end
    local point = type(item.points) == 'table' and item.points[pointIndex]
    if not point then return Menu.openFarmItemPoints(farm.id, item.id) end

    showContext({
        id = 'forge_core_farm_point_' .. tostring(farm.id) .. '_' .. item.id .. '_' .. tostring(pointIndex),
        title = t('menu.farms.point_title', { index = tostring(pointIndex) }),
        menu = 'forge_core_farm_points_' .. tostring(farm.id) .. '_' .. item.id,
        options = {
            { title = t('menu.farms.teleport_point'), icon = 'cursor-fill', onSelect = function() teleport(point) Menu.openFarmPointMenu(farm.id, item.id, pointIndex) end },
            {
                title = t('menu.farms.replace_point'),
                icon = 'crosshair',
                onSelect = function() Menu.openFarmPointReplaceMenu(farm.id, item.id, pointIndex) end,
            },
            {
                title = t('menu.farms.delete_point'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    table.remove(item.points, pointIndex)
                    saveFarm(farm, function() Menu.openFarmItemPoints(farm.id, item.id) end)
                end,
            },
        },
    })
end

function Menu.openFarmPointReplaceMenu(farmId, itemId, pointIndex)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end

    showContext({
        id = 'forge_core_farm_point_replace_' .. tostring(farm.id) .. '_' .. item.id .. '_' .. tostring(pointIndex),
        title = t('menu.farms.replace_point'),
        menu = 'forge_core_farm_point_' .. tostring(farm.id) .. '_' .. item.id .. '_' .. tostring(pointIndex),
        options = {
            {
                title = t('menu.farms.mark_position'),
                icon = 'geo-alt-fill',
                onSelect = function()
                    item.points[pointIndex] = playerCoords()
                    saveFarm(farm, function() Menu.openFarmItemPoints(farm.id, item.id) end)
                end,
            },
            {
                title = t('menu.farms.mark_devlaser'),
                icon = 'crosshair',
                onSelect = function()
                    capturePointWithDevLaser(function(point)
                        item.points[pointIndex] = point
                        saveFarm(farm, function() Menu.openFarmItemPoints(farm.id, item.id) end)
                    end, function()
                        Menu.openFarmPointMenu(farm.id, item.id, pointIndex)
                    end)
                end,
            },
        },
    })
end

function Menu.openFarmItemExtras(farmId, itemId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end

    local options = {
        { title = t('menu.farms.add_extra'), icon = 'plus', onSelect = function() Menu.openFarmExtraEdit(farm.id, item.id) end },
    }

    for index, extra in ipairs(type(item.extraItems) == 'table' and item.extraItems or {}) do
        options[#options + 1] = {
            title = extra.item,
            description = t('menu.farms.extra_description', { min = tostring(extra.min), max = tostring(extra.max) }),
            icon = 'gift',
            onSelect = function() Menu.openFarmExtraEdit(farm.id, item.id, index) end,
        }
    end

    showContext({
        id = 'forge_core_farm_extras_' .. tostring(farm.id) .. '_' .. item.id,
        title = t('menu.farms.extra_rewards'),
        menu = 'forge_core_farm_item_' .. tostring(farm.id) .. '_' .. item.id,
        options = options,
    })
end

function Menu.openFarmExtraEdit(farmId, itemId, extraIndex)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item = findItem(farm, itemId)
    if not item then return Menu.openFarmItems(farm.id) end
    item.extraItems = type(item.extraItems) == 'table' and item.extraItems or {}
    local extra = extraIndex and item.extraItems[extraIndex] or { min = 0, max = 1 }
    local extraOptions = itemOptions(false)
    if #extraOptions == 0 then
        notifyFailure('notify.farms.load_failed', 'items_unavailable')
        return Menu.openFarmItemExtras(farm.id, item.id)
    end

    local result = inputDialog(extraIndex and t('menu.farms.edit_extra') or t('menu.farms.add_extra'), {
        { type = 'select', label = t('inputs.farm_extra_item'), options = extraOptions, default = extra.item, required = true },
        { type = 'number', label = t('inputs.farm_extra_min'), default = tonumber(extra.min) or 0, min = 0, required = true },
        { type = 'number', label = t('inputs.farm_extra_max'), default = tonumber(extra.max) or 1, min = 0, required = true },
    })

    if not result then return Menu.openFarmItemExtras(farm.id, item.id) end
    extra.item = result[1]
    extra.min = tonumber(result[2]) or 0
    extra.max = tonumber(result[3]) or extra.min
    if not extraIndex then item.extraItems[#item.extraItems + 1] = extra end
    saveFarm(farm, function() Menu.openFarmItemExtras(farm.id, item.id) end)
end

function Menu.deleteFarmItem(farmId, itemId)
    local farm = findFarm(farmId)
    if not farm then return Menu.openFarmsMenu() end
    local item, index = findItem(farm, itemId)
    if not item or not index then return Menu.openFarmItems(farm.id) end

    local confirm = alertDialog({
        header = t('dialogs.remove_farm_item_header'),
        content = t('dialogs.remove_farm_item_content', { name = item.label }),
        centered = true,
        cancel = true,
    })

    if confirm ~= 'confirm' then return Menu.openFarmItemMenu(farm.id, item.id) end
    table.remove(farm.items, index)
    saveFarm(farm, function() Menu.openFarmItems(farm.id) end)
end
