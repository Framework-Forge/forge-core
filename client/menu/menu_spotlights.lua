ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local alertDialog = Shared.alertDialog

local function boolOptions()
    return {
        { value = 'true', label = t('common.yes') },
        { value = 'false', label = t('common.no') },
    }
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function boolDefault(value)
    return boolValue(value, false) and 'true' or 'false'
end

local function rgbString(color)
    return PR.Spotlights.ColorToHex(color)
end

local function colorFromRgb(value)
    return PR.Spotlights.NormalizeColor(value)
end

local function vectorPayload(coords)
    coords = type(coords) == 'table' and coords or {}
    return {
        x = tonumber(coords.x or coords[1]) or 0.0,
        y = tonumber(coords.y or coords[2]) or 0.0,
        z = tonumber(coords.z or coords[3]) or 0.0,
    }
end

local function lightPayload(light, overrides)
    light = type(light) == 'table' and light or {}

    local payload = {
        id = tonumber(light.id) or 0,
        groupId = tonumber(light.groupId or light.groupid) or 0,
        name = tostring(light.name or t('spotlights.default_light')),
        enabled = boolValue(light.enabled, true),
        origin = vectorPayload(light.origin),
        target = vectorPayload(light.target),
        color = type(light.color) == 'table' and {
            r = tonumber(light.color.r or light.color.x or light.color[1]) or 255,
            g = tonumber(light.color.g or light.color.y or light.color[2]) or 255,
            b = tonumber(light.color.b or light.color.z or light.color[3]) or 255,
        } or { r = 255, g = 255, b = 255 },
        distance = tonumber(light.distance) or 50.0,
        brightness = tonumber(light.brightness) or 1.0,
        hardness = tonumber(light.hardness) or 0.0,
        radius = tonumber(light.radius) or 20.0,
    }

    for key, value in pairs(type(overrides) == 'table' and overrides or {}) do
        payload[key] = value
    end

    return payload
end

local function applySpotlightsPayload(payload)
    if type(payload) ~= 'table' or type(payload.lights) ~= 'table' then return end
    if ForgeCore.Client.Spotlights and ForgeCore.Client.Spotlights.applyPayload then
        ForgeCore.Client.Spotlights.applyPayload(payload)
    end
end

local function formatCoords(coords)
    coords = type(coords) == 'table' and coords or {}
    return ('%.2f, %.2f, %.2f'):format(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
end

local function fetchPayload()
    local ok, payload = awaitServer(PR.Spotlights.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.spotlights.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.groups = type(payload.groups) == 'table' and payload.groups or {}
    payload.lights = type(payload.lights) == 'table' and payload.lights or {}
    applySpotlightsPayload(payload)
    return payload
end

local function groupLights(payload, groupId)
    local list = {}
    groupId = tonumber(groupId)

    for _, light in ipairs(payload.lights or {}) do
        if tonumber(light.groupId) == groupId then
            list[#list + 1] = light
        end
    end

    table.sort(list, function(left, right) return tonumber(left.id) < tonumber(right.id) end)
    return list
end

local function createGroup()
    local result = inputDialog(t('menu.spotlights.create_group'), {
        { type = 'input', label = t('inputs.spotlight_group_name'), required = true },
    })

    if not result then return Menu.openSpotlightsMenu() end

    local ok, response = awaitServer(PR.Spotlights.Callbacks.createGroup, tostring(result[1] or ''))
    if not ok then notifyFailure('notify.spotlights.group_create_failed', response) end

    SetTimeout(400, function()
        Menu.openSpotlightsMenu()
    end)
end

local function renameGroup(group)
    local result = inputDialog(t('menu.spotlights.rename_group'), {
        { type = 'input', label = t('inputs.spotlight_group_name'), default = group.name, required = true },
    })

    if not result then return Menu.openSpotlightsGroup(group.id, group.name) end

    local ok, response = awaitServer(PR.Spotlights.Callbacks.renameGroup, group.id, tostring(result[1] or ''))
    if not ok then notifyFailure('notify.spotlights.group_rename_failed', response) end

    SetTimeout(400, function()
        Menu.openSpotlightsMenu()
    end)
end

local function deleteGroup(group)
    local confirmed = true
    if alertDialog then
        local result = alertDialog({
            header = t('dialogs.remove_spotlight_group_header'),
            content = t('dialogs.remove_spotlight_group_content', { group = group.name }),
            centered = true,
            cancel = true,
        })
        confirmed = result == 'confirm'
    end

    if not confirmed then return Menu.openSpotlightsGroup(group.id, group.name) end

    local ok, response = awaitServer(PR.Spotlights.Callbacks.deleteGroup, group.id)
    if not ok then notifyFailure('notify.spotlights.group_delete_failed', response) end

    SetTimeout(400, function()
        Menu.openSpotlightsMenu()
    end)
end

local function createLight(group)
    local created, error = ForgeCore.Client.Spotlights.createLight(group.id, nil, function(light)
        local ok, lightId, response = awaitServer(PR.Spotlights.Callbacks.createLight, light)
        if not ok then
            notifyFailure('notify.spotlights.light_create_failed', lightId)
            return
        end

        applySpotlightsPayload(response)
    end)

    if not created and error ~= 'cancelled' then
        notifyFailure('notify.spotlights.light_create_failed', error)
    end

    SetTimeout(500, function()
        Menu.openSpotlightsGroup(group.id, group.name)
    end)
end

local function editLightData(light)
    local result = inputDialog(t('menu.spotlights.edit_light'), {
        { type = 'input', label = t('inputs.spotlight_name'), default = light.name, required = true },
        { type = 'select', label = t('inputs.spotlight_enabled'), options = boolOptions(), default = boolDefault(boolValue(light.enabled, true)), required = true },
        { type = 'color', label = t('inputs.spotlight_color'), format = 'hex', default = rgbString(light.color), required = true },
        { type = 'number', label = t('inputs.spotlight_distance'), default = tonumber(light.distance) or 50.0, min = 0.1, required = true },
        { type = 'number', label = t('inputs.spotlight_brightness'), default = tonumber(light.brightness) or 1.0, min = 0.0, required = true },
        { type = 'number', label = t('inputs.spotlight_hardness'), default = tonumber(light.hardness) or 0.0, min = 0.0, required = true },
        { type = 'number', label = t('inputs.spotlight_radius'), default = tonumber(light.radius) or 20.0, min = 0.0, required = true },
    })

    if not result then return Menu.openSpotlightActions(light.id) end

    local payload = lightPayload(light, {
        name = tostring(result[1] or light.name),
        enabled = boolValue(result[2], true),
        color = colorFromRgb(result[3]),
        distance = tonumber(result[4]) or tonumber(light.distance) or 50.0,
        brightness = tonumber(result[5]) or tonumber(light.brightness) or 1.0,
        hardness = tonumber(result[6]) or tonumber(light.hardness) or 0.0,
        radius = tonumber(result[7]) or tonumber(light.radius) or 20.0,
    })

    local ok, response = awaitServer(PR.Spotlights.Callbacks.updateLight, payload.id, payload)
    if not ok then notifyFailure('notify.spotlights.light_update_failed', response) end
    applySpotlightsPayload(response)

    SetTimeout(400, function()
        Menu.openSpotlightActions(payload.id)
    end)
end

local function fineTuneLight(light)
    local edited, error = ForgeCore.Client.Spotlights.editLight(light, function(changes)
        local payload = lightPayload(light, changes)
        local ok, response = awaitServer(PR.Spotlights.Callbacks.updateLight, payload.id, payload)
        if not ok then notifyFailure('notify.spotlights.light_update_failed', response) end
        applySpotlightsPayload(response)
    end)

    if not edited and error ~= 'cancelled' then
        notifyFailure('notify.spotlights.light_update_failed', error)
    end

    SetTimeout(500, function()
        Menu.openSpotlightActions(light.id)
    end)
end

local function deleteLight(light)
    local confirmed = true
    if alertDialog then
        local result = alertDialog({
            header = t('dialogs.remove_spotlight_header'),
            content = t('dialogs.remove_spotlight_content', { light = light.name }),
            centered = true,
            cancel = true,
        })
        confirmed = result == 'confirm'
    end

    if not confirmed then return Menu.openSpotlightActions(light.id) end

    local ok, response = awaitServer(PR.Spotlights.Callbacks.deleteLight, light.id)
    if not ok then notifyFailure('notify.spotlights.light_delete_failed', response) end

    SetTimeout(400, function()
        Menu.openSpotlightsGroup(light.groupId, t('menu.spotlights.group_title', { id = tostring(light.groupId) }))
    end)
end

function Menu.openSpotlightsMenu()
    local payload = fetchPayload()
    if not payload then return end

    local options = {
        {
            title = t('menu.spotlights.create_group'),
            description = t('menu.spotlights.create_group_description'),
            icon = 'folder-plus',
            onSelect = createGroup,
        },
        {
            title = t('menu.spotlights.total_groups', { count = tostring(#payload.groups) }),
            icon = 'lamp-fill',
            disabled = true,
        },
    }

    for _, group in ipairs(payload.groups) do
        options[#options + 1] = {
            title = group.name,
            description = t('menu.spotlights.group_description', { count = tostring(group.count or 0) }),
            icon = 'folder',
            arrow = true,
            onSelect = function()
                Menu.openSpotlightsGroup(group.id, group.name)
            end,
        }
    end

    showContext({
        id = 'forge_core_spotlights',
        title = t('menu.spotlights.title'),
        menu = 'forge_core_server_settings',
        icon = 'lamp-fill',
        options = options,
    })
end

function Menu.openSpotlightsGroup(groupId, groupName)
    local payload = fetchPayload()
    if not payload then return end

    local group = { id = groupId, name = groupName }
    for _, item in ipairs(payload.groups) do
        if tonumber(item.id) == tonumber(groupId) then group = item break end
    end

    local options = {
        {
            title = t('menu.spotlights.create_light'),
            description = t('menu.spotlights.create_light_description'),
            icon = 'plus',
            onSelect = function()
                createLight(group)
            end,
        },
        {
            title = t('menu.spotlights.rename_group'),
            icon = 'pen',
            onSelect = function()
                renameGroup(group)
            end,
        },
        {
            title = t('menu.spotlights.delete_group'),
            icon = 'trash',
            iconColor = 'red',
            disabled = (tonumber(group.count) or 0) > 0,
            onSelect = function()
                deleteGroup(group)
            end,
        },
        {
            title = t('menu.spotlights.total_lights', { count = tostring(group.count or 0) }),
            icon = 'lamp-fill',
            disabled = true,
        },
    }

    for _, light in ipairs(groupLights(payload, group.id)) do
        options[#options + 1] = {
            title = ('[%s] %s'):format(tostring(light.id), light.name),
            description = t('menu.spotlights.light_description', {
                status = boolValue(light.enabled, true) and t('common.active') or t('common.inactive'),
                coords = formatCoords(light.origin),
            }),
            icon = 'lightbulb',
            iconColor = boolValue(light.enabled, true) and 'yellow' or 'gray',
            arrow = true,
            onSelect = function()
                Menu.openSpotlightActions(light.id)
            end,
        }
    end

    showContext({
        id = 'forge_core_spotlights_group_' .. tostring(group.id),
        title = group.name,
        menu = 'forge_core_spotlights',
        options = options,
    })
end

function Menu.openSpotlightActions(lightId)
    local payload = fetchPayload()
    if not payload then return end

    local light
    for _, item in ipairs(payload.lights) do
        if tonumber(item.id) == tonumber(lightId) then light = item break end
    end

    if not light then return Menu.openSpotlightsMenu() end

    showContext({
        id = 'forge_core_spotlight_' .. tostring(light.id),
        title = light.name,
        menu = 'forge_core_spotlights_group_' .. tostring(light.groupId),
        options = {
            {
                title = t('menu.spotlights.edit_light'),
                description = t('menu.spotlights.edit_light_description'),
                icon = 'pen',
                onSelect = function()
                    editLightData(light)
                end,
            },
            {
                title = t('menu.spotlights.fine_tune'),
                description = t('menu.spotlights.fine_tune_description'),
                icon = 'sliders',
                onSelect = function()
                    fineTuneLight(light)
                end,
            },
            {
                title = boolValue(light.enabled, true) and t('menu.spotlights.disable_light') or t('menu.spotlights.enable_light'),
                icon = boolValue(light.enabled, true) and 'toggle-on' or 'toggle-off',
                iconColor = boolValue(light.enabled, true) and 'green' or 'red',
                onSelect = function()
                    local payload = lightPayload(light, { enabled = not boolValue(light.enabled, true) })
                    local ok, response = awaitServer(PR.Spotlights.Callbacks.updateLight, payload.id, payload)
                    if not ok then notifyFailure('notify.spotlights.light_update_failed', response) end
                    applySpotlightsPayload(response)
                    SetTimeout(400, function() Menu.openSpotlightActions(payload.id) end)
                end,
            },
            {
                title = t('menu.spotlights.delete_light'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    deleteLight(light)
                end,
            },
        },
    })
end
