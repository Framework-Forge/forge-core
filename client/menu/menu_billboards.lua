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

local function vectorPayload(coords)
    coords = type(coords) == 'table' and coords or {}
    return {
        x = tonumber(coords.x or coords[1]) or 0.0,
        y = tonumber(coords.y or coords[2]) or 0.0,
        z = tonumber(coords.z or coords[3]) or 0.0,
    }
end

local function billboardPayload(billboard, overrides)
    billboard = type(billboard) == 'table' and billboard or {}
    local vertices = type(billboard.vertices) == 'table' and billboard.vertices or {}

    local payload = {
        id = tonumber(billboard.id) or 0,
        groupId = tonumber(billboard.groupId or billboard.groupid) or 0,
        name = tostring(billboard.name or t('billboards.default_billboard')),
        enabled = boolValue(billboard.enabled, true),
        url = tostring(billboard.url or PR.Billboards.Defaults.url),
        width = tonumber(billboard.width) or PR.Billboards.Defaults.width,
        height = tonumber(billboard.height) or PR.Billboards.Defaults.height,
        offset = tonumber(billboard.offset) or 0.03,
        vertices = {
            vectorPayload(vertices[1]),
            vectorPayload(vertices[2]),
            vectorPayload(vertices[3]),
            vectorPayload(vertices[4]),
        },
    }

    for key, value in pairs(type(overrides) == 'table' and overrides or {}) do
        payload[key] = value
    end

    return payload
end

local function applyBillboardsPayload(payload)
    if type(payload) ~= 'table' or type(payload.billboards) ~= 'table' then return end
    if ForgeCore.Client.Billboards and ForgeCore.Client.Billboards.applyPayload then
        ForgeCore.Client.Billboards.applyPayload(payload)
    end
end

local function fetchPayload()
    local ok, payload = awaitServer(PR.Billboards.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.billboards.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.groups = type(payload.groups) == 'table' and payload.groups or {}
    payload.billboards = type(payload.billboards) == 'table' and payload.billboards or {}
    applyBillboardsPayload(payload)
    return payload
end

local function groupBillboards(payload, groupId)
    local list = {}
    groupId = tonumber(groupId)

    for _, billboard in ipairs(payload.billboards or {}) do
        if tonumber(billboard.groupId) == groupId then
            list[#list + 1] = billboard
        end
    end

    table.sort(list, function(left, right) return tonumber(left.id) < tonumber(right.id) end)
    return list
end

local function formatCoords(coords)
    coords = type(coords) == 'table' and coords or {}
    return ('%.2f, %.2f, %.2f'):format(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
end

local function createGroup()
    local result = inputDialog(t('menu.billboards.create_group'), {
        { type = 'input', label = t('inputs.billboard_group_name'), required = true },
    })

    if not result then return Menu.openBillboardsMenu() end

    local ok, response = awaitServer(PR.Billboards.Callbacks.createGroup, tostring(result[1] or ''))
    if not ok then notifyFailure('notify.billboards.group_create_failed', response) end
    applyBillboardsPayload(response)

    SetTimeout(400, function()
        Menu.openBillboardsMenu()
    end)
end

local function renameGroup(group)
    local result = inputDialog(t('menu.billboards.rename_group'), {
        { type = 'input', label = t('inputs.billboard_group_name'), default = group.name, required = true },
    })

    if not result then return Menu.openBillboardsGroup(group.id, group.name) end

    local ok, response = awaitServer(PR.Billboards.Callbacks.renameGroup, group.id, tostring(result[1] or ''))
    if not ok then notifyFailure('notify.billboards.group_rename_failed', response) end
    applyBillboardsPayload(response)

    SetTimeout(400, function()
        Menu.openBillboardsMenu()
    end)
end

local function deleteGroup(group)
    local confirmed = true
    if alertDialog then
        local result = alertDialog({
            header = t('dialogs.remove_billboard_group_header'),
            content = t('dialogs.remove_billboard_group_content', { group = group.name }),
            centered = true,
            cancel = true,
        })
        confirmed = result == 'confirm'
    end

    if not confirmed then return Menu.openBillboardsGroup(group.id, group.name) end

    local ok, response = awaitServer(PR.Billboards.Callbacks.deleteGroup, group.id)
    if not ok then notifyFailure('notify.billboards.group_delete_failed', response) end
    applyBillboardsPayload(response)

    SetTimeout(400, function()
        Menu.openBillboardsMenu()
    end)
end

local function editBillboardData(billboard)
    local result = inputDialog(t('menu.billboards.edit_billboard'), {
        { type = 'input', label = t('inputs.billboard_name'), default = billboard.name, required = true },
        { type = 'select', label = t('inputs.billboard_enabled'), options = boolOptions(), default = boolDefault(boolValue(billboard.enabled, true)), required = true },
        { type = 'input', label = t('inputs.billboard_url'), default = billboard.url, required = true },
        { type = 'number', label = t('inputs.billboard_width'), default = tonumber(billboard.width) or PR.Billboards.Defaults.width, min = 1, required = true },
        { type = 'number', label = t('inputs.billboard_height'), default = tonumber(billboard.height) or PR.Billboards.Defaults.height, min = 1, required = true },
        { type = 'number', label = t('inputs.billboard_offset'), default = tonumber(billboard.offset) or 0.03, min = -2.0, max = 2.0, required = true },
    })

    if not result then return Menu.openBillboardActions(billboard.id) end

    local payload = billboardPayload(billboard, {
        name = tostring(result[1] or billboard.name),
        enabled = boolValue(result[2], true),
        url = tostring(result[3] or billboard.url),
        width = tonumber(result[4]) or PR.Billboards.Defaults.width,
        height = tonumber(result[5]) or PR.Billboards.Defaults.height,
        offset = tonumber(result[6]) or 0.03,
    })

    local ok, response = awaitServer(PR.Billboards.Callbacks.updateBillboard, payload.id, payload)
    if not ok then notifyFailure('notify.billboards.billboard_update_failed', response) end
    applyBillboardsPayload(response)

    SetTimeout(400, function()
        Menu.openBillboardActions(payload.id)
    end)
end

local function createBillboard(group)
    local ok, verticesOrError = ForgeCore.Client.Billboards.captureVertices()
    if not ok then
        if verticesOrError ~= 'cancelled' then
            notifyFailure('notify.billboards.billboard_create_failed', verticesOrError)
        end
        return Menu.openBillboardsGroup(group.id, group.name)
    end

    local result = inputDialog(t('menu.billboards.create_billboard'), {
        { type = 'input', label = t('inputs.billboard_name'), default = t('billboards.default_billboard'), required = true },
        { type = 'select', label = t('inputs.billboard_enabled'), options = boolOptions(), default = 'true', required = true },
        { type = 'input', label = t('inputs.billboard_url'), default = PR.Billboards.Defaults.url, required = true },
        { type = 'number', label = t('inputs.billboard_width'), default = PR.Billboards.Defaults.width, min = 1, required = true },
        { type = 'number', label = t('inputs.billboard_height'), default = PR.Billboards.Defaults.height, min = 1, required = true },
        { type = 'number', label = t('inputs.billboard_offset'), default = 0.03, min = -2.0, max = 2.0, required = true },
    })

    if not result then return Menu.openBillboardsGroup(group.id, group.name) end

    local payload = {
        groupId = group.id,
        name = tostring(result[1] or t('billboards.default_billboard')),
        enabled = boolValue(result[2], true),
        url = tostring(result[3] or PR.Billboards.Defaults.url),
        width = tonumber(result[4]) or PR.Billboards.Defaults.width,
        height = tonumber(result[5]) or PR.Billboards.Defaults.height,
        offset = tonumber(result[6]) or 0.03,
        vertices = verticesOrError,
    }

    local saved, idOrError, response = awaitServer(PR.Billboards.Callbacks.createBillboard, payload)
    if not saved then notifyFailure('notify.billboards.billboard_create_failed', idOrError) end
    applyBillboardsPayload(response)

    SetTimeout(500, function()
        Menu.openBillboardsGroup(group.id, group.name)
    end)
end

local function recaptureBillboard(billboard)
    local ok, verticesOrError = ForgeCore.Client.Billboards.captureVertices()
    if not ok then
        if verticesOrError ~= 'cancelled' then
            notifyFailure('notify.billboards.billboard_update_failed', verticesOrError)
        end
        return Menu.openBillboardActions(billboard.id)
    end

    local payload = billboardPayload(billboard, { vertices = verticesOrError })
    local saved, response = awaitServer(PR.Billboards.Callbacks.updateBillboard, payload.id, payload)
    if not saved then notifyFailure('notify.billboards.billboard_update_failed', response) end
    applyBillboardsPayload(response)

    SetTimeout(400, function()
        Menu.openBillboardActions(payload.id)
    end)
end

local function fineTuneBillboard(billboard)
    local ok, offsetOrError = ForgeCore.Client.Billboards.fineTuneOffset(billboard)
    if not ok then
        if offsetOrError ~= 'cancelled' then
            notifyFailure('notify.billboards.billboard_update_failed', offsetOrError)
        end
        return Menu.openBillboardActions(billboard.id)
    end

    local payload = billboardPayload(billboard, { offset = offsetOrError })
    local saved, response = awaitServer(PR.Billboards.Callbacks.updateBillboard, payload.id, payload)
    if not saved then notifyFailure('notify.billboards.billboard_update_failed', response) end
    applyBillboardsPayload(response)

    SetTimeout(400, function()
        Menu.openBillboardActions(payload.id)
    end)
end

local function deleteBillboard(billboard)
    local confirmed = true
    if alertDialog then
        local result = alertDialog({
            header = t('dialogs.remove_billboard_header'),
            content = t('dialogs.remove_billboard_content', { billboard = billboard.name }),
            centered = true,
            cancel = true,
        })
        confirmed = result == 'confirm'
    end

    if not confirmed then return Menu.openBillboardActions(billboard.id) end

    local ok, response = awaitServer(PR.Billboards.Callbacks.deleteBillboard, billboard.id)
    if not ok then notifyFailure('notify.billboards.billboard_delete_failed', response) end
    applyBillboardsPayload(response)

    SetTimeout(400, function()
        Menu.openBillboardsGroup(billboard.groupId, t('menu.billboards.group_title', { id = tostring(billboard.groupId) }))
    end)
end

function Menu.openBillboardsMenu()
    local payload = fetchPayload()
    if not payload then return end

    local options = {
        {
            title = t('menu.billboards.create_group'),
            description = t('menu.billboards.create_group_description'),
            icon = 'folder-plus',
            onSelect = createGroup,
        },
        {
            title = t('menu.billboards.total_groups', { count = tostring(#payload.groups) }),
            icon = 'image',
            disabled = true,
        },
    }

    for _, group in ipairs(payload.groups) do
        options[#options + 1] = {
            title = group.name,
            description = t('menu.billboards.group_description', { count = tostring(group.count or 0) }),
            icon = 'folder',
            arrow = true,
            onSelect = function()
                Menu.openBillboardsGroup(group.id, group.name)
            end,
        }
    end

    showContext({
        id = 'forge_core_billboards',
        title = t('menu.billboards.title'),
        menu = 'forge_core_server_settings',
        options = options,
    })
end

function Menu.openBillboardsGroup(groupId, groupName)
    local payload = fetchPayload()
    if not payload then return end

    local group = { id = groupId, name = groupName }
    for _, item in ipairs(payload.groups) do
        if tonumber(item.id) == tonumber(groupId) then group = item break end
    end

    local options = {
        {
            title = t('menu.billboards.create_billboard'),
            description = t('menu.billboards.create_billboard_description'),
            icon = 'plus',
            onSelect = function()
                createBillboard(group)
            end,
        },
        {
            title = t('menu.billboards.rename_group'),
            icon = 'pen',
            onSelect = function()
                renameGroup(group)
            end,
        },
        {
            title = t('menu.billboards.delete_group'),
            icon = 'trash',
            iconColor = 'red',
            disabled = (tonumber(group.count) or 0) > 0,
            onSelect = function()
                deleteGroup(group)
            end,
        },
        {
            title = t('menu.billboards.total_billboards', { count = tostring(group.count or 0) }),
            icon = 'image',
            disabled = true,
        },
    }

    for _, billboard in ipairs(groupBillboards(payload, group.id)) do
        local vertices = type(billboard.vertices) == 'table' and billboard.vertices or {}
        options[#options + 1] = {
            title = ('[%s] %s'):format(tostring(billboard.id), billboard.name),
            description = t('menu.billboards.billboard_description', {
                status = boolValue(billboard.enabled, true) and t('common.active') or t('common.inactive'),
                coords = formatCoords(vertices[1]),
            }),
            icon = 'image',
            iconColor = boolValue(billboard.enabled, true) and 'green' or 'gray',
            arrow = true,
            onSelect = function()
                Menu.openBillboardActions(billboard.id)
            end,
        }
    end

    showContext({
        id = 'forge_core_billboards_group_' .. tostring(group.id),
        title = group.name,
        menu = 'forge_core_billboards',
        options = options,
    })
end

function Menu.openBillboardActions(billboardId)
    local payload = fetchPayload()
    if not payload then return end

    local billboard
    for _, item in ipairs(payload.billboards) do
        if tonumber(item.id) == tonumber(billboardId) then billboard = item break end
    end

    if not billboard then return Menu.openBillboardsMenu() end

    showContext({
        id = 'forge_core_billboard_' .. tostring(billboard.id),
        title = billboard.name,
        menu = 'forge_core_billboards_group_' .. tostring(billboard.groupId),
        options = {
            {
                title = t('menu.billboards.edit_billboard'),
                description = t('menu.billboards.edit_billboard_description'),
                icon = 'pen',
                onSelect = function()
                    editBillboardData(billboard)
                end,
            },
            {
                title = t('menu.billboards.recapture_billboard'),
                description = t('menu.billboards.recapture_billboard_description'),
                icon = 'crosshair',
                onSelect = function()
                    recaptureBillboard(billboard)
                end,
            },
            {
                title = t('menu.billboards.fine_tune_billboard'),
                description = t('menu.billboards.fine_tune_billboard_description'),
                icon = 'sliders',
                onSelect = function()
                    fineTuneBillboard(billboard)
                end,
            },
            {
                title = boolValue(billboard.enabled, true) and t('menu.billboards.disable_billboard') or t('menu.billboards.enable_billboard'),
                icon = boolValue(billboard.enabled, true) and 'toggle-on' or 'toggle-off',
                iconColor = boolValue(billboard.enabled, true) and 'green' or 'red',
                onSelect = function()
                    local nextEnabled = not boolValue(billboard.enabled, true)
                    local item = billboardPayload(billboard, { enabled = nextEnabled })

                    if ForgeCore.Client.Billboards and ForgeCore.Client.Billboards.setBillboardEnabled then
                        ForgeCore.Client.Billboards.setBillboardEnabled(item.id, nextEnabled)
                    end

                    local ok, response = awaitServer(PR.Billboards.Callbacks.updateBillboard, item.id, item)
                    if not ok then notifyFailure('notify.billboards.billboard_update_failed', response) end
                    applyBillboardsPayload(response)
                    SetTimeout(400, function() Menu.openBillboardActions(item.id) end)
                end,
            },
            {
                title = t('menu.billboards.delete_billboard'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    deleteBillboard(billboard)
                end,
            },
        },
    })
end
