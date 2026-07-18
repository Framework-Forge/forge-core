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
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions
local boolValue = Shared.boolValue

local inventoryActionLocked = false

local function encodeBlock(value)
    if type(value) ~= 'table' or next(value) == nil then return '' end

    local ok, encoded = pcall(json.encode, value)
    return ok and encoded or ''
end

local function decodeBlock(value, failureToken)
    value = tostring(value or '')
    if value == '' then return true, nil end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then return true, decoded end

    notifyFailure('notify.inventory.parse_failed', failureToken or 'json')
    return false, nil
end

local function ensureOption(options, value, label)
    if tostring(value or '') == '' then return end

    for index = 1, #options do
        if options[index].value == value then return end
    end

    options[#options + 1] = { value = value, label = label or value }
end

local function fetchQbxGroups()
    local groups = {
        job = {},
        gang = {},
    }

    if GetResourceState('qbx_core') ~= 'started' then return groups end

    local okJobs, jobs = pcall(function()
        return exports.qbx_core:GetJobs()
    end)

    if okJobs and type(jobs) == 'table' then
        groups.job = jobs
    end

    local okGangs, gangs = pcall(function()
        return exports.qbx_core:GetGangs()
    end)

    if okGangs and type(gangs) == 'table' then
        groups.gang = gangs
    end

    return groups
end

local function addGroupOptions(options, groups)
    local names = {}

    for name in pairs(groups or {}) do
        names[#names + 1] = name
    end

    table.sort(names, function(left, right)
        local leftGroup = groups[left] or {}
        local rightGroup = groups[right] or {}
        return tostring(leftGroup.label or left) < tostring(rightGroup.label or right)
    end)

    for index = 1, #names do
        local name = names[index]
        local group = groups[name] or {}

        options[#options + 1] = {
            value = name,
            label = group.label or name,
        }
    end
end

local function accessEntry(access, groupType)
    access = type(access) == 'table' and access or {}

    local list = access[groupType == 'gang' and 'gangs' or 'jobs']
    if type(list) == 'table' and type(list[1]) == 'table' then
        return tostring(list[1].name or ''), tonumber(list[1].grade) or 0
    end

    local direct = access[groupType]
    if type(direct) == 'table' then
        return tostring(direct.name or ''), tonumber(direct.grade) or 0
    end

    if access.mode == groupType then
        return tostring(access.name or ''), tonumber(access.grade) or 0
    end

    if access.mode == 'admin' and groupType == 'job' then
        return 'admin', tonumber(access.grade) or 0
    end

    return '', 0
end

local function accessGroupOptions(groupType, currentValue)
    local options = {
        { value = '', label = t('common.none') },
        { value = 'admin', label = 'Admin' },
        { value = 'mod', label = 'Mod' },
        { value = 'staff', label = 'Staff' },
    }

    local groups = fetchQbxGroups()
    addGroupOptions(options, groups[groupType] or {})

    ensureOption(options, currentValue)

    return options
end

local function fetchInventoryPayload()
    local ok, payload = awaitServer(PR.Inventory.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.inventory.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.items = type(payload.items) == 'table' and payload.items or {}
    payload.ammo = type(payload.ammo) == 'table' and payload.ammo or {}
    payload.components = type(payload.components) == 'table' and payload.components or {}

    return payload
end

local function runInventoryAction(callbackName, failureLocale, ...)
    if inventoryActionLocked then return false end
    inventoryActionLocked = true

    local ok, response = awaitServer(callbackName, ...)
    if not ok then
        notifyFailure(failureLocale or 'notify.inventory.action_failed', response)
    end

    SetTimeout(650, function()
        inventoryActionLocked = false
    end)

    return ok, response
end

local function statusLabel(entry)
    return entry.active == false and t('menu.inventory.status_inactive') or t('menu.inventory.status_active')
end

local function parsePaste(kind)
    local result = inputDialog(t('menu.inventory.paste_' .. kind), {
        {
            type = 'textarea',
            label = t('inputs.inventory_paste'),
            required = true,
            autosize = true,
        },
    })

    if not result then return nil end

    local ok, parsed = awaitServer(PR.Inventory.Callbacks.parseDefinition, kind, result[1])
    if not ok then
        notifyFailure('notify.inventory.parse_failed', parsed)
        return nil
    end

    return parsed
end

function Menu.openInventoryMenu()
    local payload = fetchInventoryPayload()
    if not payload then return Menu.openServerSettingsMenu() end

    showContext({
        id = 'forge_core_inventory',
        title = t('menu.inventory.title'),
        menu = 'forge_core_server_settings',
        options = {
            {
                title = t('menu.inventory.items'),
                description = t('menu.inventory.items_description', { count = tostring(#payload.items) }),
                icon = 'package',
                arrow = true,
                onSelect = function()
                    Menu.openInventoryEntries('item')
                end,
            },
            {
                title = t('menu.inventory.weapons'),
                description = t('menu.inventory.weapons_description'),
                icon = 'crosshair',
                arrow = true,
                onSelect = function()
                    Menu.openWeaponsMenu('forge_core_inventory')
                end,
            },
            {
                title = t('menu.inventory.ammo'),
                description = t('menu.inventory.ammo_description', { count = tostring(#payload.ammo) }),
                icon = 'circle-dot',
                arrow = true,
                onSelect = function()
                    Menu.openInventoryEntries('ammo')
                end,
            },
            {
                title = t('menu.inventory.components'),
                description = t('menu.inventory.components_description', { count = tostring(#payload.components) }),
                icon = 'puzzle',
                arrow = true,
                onSelect = function()
                    Menu.openInventoryEntries('component')
                end,
            },
        },
    })
end

local function callbacksForKind(kind)
    if kind == 'item' then
        return PR.Inventory.Callbacks.saveItem, PR.Inventory.Callbacks.deleteItem, PR.Inventory.Callbacks.setItemActive
    elseif kind == 'ammo' then
        return PR.Inventory.Callbacks.saveAmmo, PR.Inventory.Callbacks.deleteAmmo, PR.Inventory.Callbacks.setAmmoActive
    end

    return PR.Inventory.Callbacks.saveComponent, PR.Inventory.Callbacks.deleteComponent, PR.Inventory.Callbacks.setComponentActive
end

local function saveParsedEntries(kind, parsed)
    local entries = type(parsed) == 'table' and parsed.entries
    if type(entries) ~= 'table' then return false end

    local saveCallback = callbacksForKind(kind)
    local saved = 0
    local failed = 0

    for index = 1, #entries do
        local ok = awaitServer(saveCallback, entries[index])
        if ok then
            saved = saved + 1
        else
            failed = failed + 1
        end
    end

    if failed > 0 then
        notifyFailure('notify.inventory.save_failed', ('%s/%s'):format(tostring(failed), tostring(#entries)))
    end

    return saved > 0
end

local function listForKind(payload, kind)
    if kind == 'item' then return payload.items end
    if kind == 'ammo' then return payload.ammo end
    return payload.components
end

function Menu.openInventoryEntries(kind)
    local payload = fetchInventoryPayload()
    if not payload then return Menu.openInventoryMenu() end

    local entries = listForKind(payload, kind)
    local titleKey = kind == 'item' and 'items' or kind == 'ammo' and 'ammo' or 'components'
    local options = {
        {
            title = t('menu.inventory.create_' .. kind),
            description = t('menu.inventory.create_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openInventoryEntryEditor(kind)
            end,
        },
        {
            title = t('menu.inventory.paste_' .. kind),
            description = t('menu.inventory.paste_description'),
            icon = 'clipboard',
            onSelect = function()
                local parsed = parsePaste(kind)
                if parsed then
                    if saveParsedEntries(kind, parsed) then
                        SetTimeout(400, function() Menu.openInventoryEntries(kind) end)
                    else
                        Menu.openInventoryEntryEditor(kind, parsed)
                    end
                else
                    Menu.openInventoryEntries(kind)
                end
            end,
        },
    }

    for _, entry in ipairs(entries or {}) do
        options[#options + 1] = {
            title = entry.label or entry.name,
            description = t('menu.inventory.entry_description', {
                status = statusLabel(entry),
                name = entry.name or '',
                weight = tostring(entry.weight or 0),
            }),
            icon = entry.active == false and 'ban' or (kind == 'item' and 'package' or kind == 'ammo' and 'circle-dot' or 'puzzle'),
            iconColor = entry.active == false and 'red' or nil,
            arrow = true,
            onSelect = function()
                Menu.openInventoryEntryDetails(kind, entry)
            end,
        }
    end

    showContext({
        id = 'forge_core_inventory_' .. kind,
        title = t('menu.inventory.' .. titleKey),
        menu = 'forge_core_inventory',
        options = options,
    })
end

function Menu.openInventoryEntryDetails(kind, entry)
    local nextActive = entry.active == false
    local _, deleteCallback, activeCallback = callbacksForKind(kind)

    showContext({
        id = ('forge_core_inventory_%s_%s'):format(kind, entry.name),
        title = entry.label or entry.name,
        menu = 'forge_core_inventory_' .. kind,
        options = {
            {
                title = t('menu.inventory.info_status', { status = statusLabel(entry) }),
                description = t('menu.inventory.entry_description', {
                    status = statusLabel(entry),
                    name = entry.name or '',
                    weight = tostring(entry.weight or 0),
                }),
                icon = entry.active == false and 'toggle-left' or 'toggle-right',
                disabled = true,
            },
            {
                title = nextActive and t('menu.inventory.activate') or t('menu.inventory.deactivate'),
                icon = nextActive and 'toggle-right' or 'toggle-left',
                iconColor = nextActive and 'green' or 'yellow',
                onSelect = function()
                    runInventoryAction(activeCallback, 'notify.inventory.action_failed', entry.name, nextActive)
                    SetTimeout(400, function() Menu.openInventoryEntries(kind) end)
                end,
            },
            {
                title = t('menu.actions.edit'),
                icon = 'pen',
                onSelect = function()
                    Menu.openInventoryEntryEditor(kind, entry)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_inventory_header'),
                        content = t('dialogs.remove_inventory_content', { item = entry.label or entry.name }),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        runInventoryAction(deleteCallback, 'notify.inventory.remove_failed', entry.name)
                    end

                    SetTimeout(400, function() Menu.openInventoryEntries(kind) end)
                end,
            },
        },
    })
end

function Menu.openInventoryEntryEditor(kind, entry)
    entry = type(entry) == 'table' and entry or {}
    local saveCallback = callbacksForKind(kind)
    local isItem = kind == 'item'
    local currentJob, currentJobGrade = accessEntry(entry.access, 'job')
    local currentGang, currentGangGrade = accessEntry(entry.access, 'gang')

    local fields = {
        { type = 'input', label = t('inputs.inventory_name'), default = entry.name, disabled = entry.name ~= nil, required = true },
        { type = 'input', label = t('inputs.inventory_label'), default = entry.label, required = true },
        { type = 'number', label = t('inputs.inventory_weight'), min = 0, default = tonumber(entry.weight) or 0, required = true },
        { type = 'select', label = t('inputs.inventory_active'), options = boolOptions(), default = boolDefault(entry.active ~= false), required = true },
        { type = 'select', label = t('inputs.inventory_access_job'), options = accessGroupOptions('job', currentJob), default = currentJob, searchable = true },
        { type = 'number', label = t('inputs.inventory_access_job_grade'), min = 0, default = currentJobGrade },
        { type = 'select', label = t('inputs.inventory_access_gang'), options = accessGroupOptions('gang', currentGang), default = currentGang, searchable = true },
        { type = 'number', label = t('inputs.inventory_access_gang_grade'), min = 0, default = currentGangGrade },
    }

    if isItem then
        fields[#fields + 1] = { type = 'select', label = t('inputs.inventory_stack'), options = boolOptions(), default = boolDefault(entry.stack ~= false), required = true }
        fields[#fields + 1] = { type = 'select', label = t('inputs.inventory_close'), options = boolOptions(), default = boolDefault(entry.close ~= false), required = true }
        fields[#fields + 1] = { type = 'input', label = t('inputs.inventory_description'), default = entry.description or '' }
        fields[#fields + 1] = { type = 'input', label = t('inputs.inventory_image'), default = (entry.client and entry.client.image) or entry.imageUrl or entry.localImage or '' }
        fields[#fields + 1] = { type = 'textarea', label = t('inputs.inventory_buttons_json'), default = encodeBlock(entry.buttons), autosize = true }
        fields[#fields + 1] = { type = 'textarea', label = t('inputs.inventory_client_json'), default = encodeBlock(entry.client), autosize = true }
        fields[#fields + 1] = { type = 'textarea', label = t('inputs.inventory_server_json'), default = encodeBlock(entry.server), autosize = true }
    else
        fields[#fields + 1] = { type = 'input', label = t('inputs.inventory_description'), default = entry.description or '' }
    end

    local result = inputDialog(entry.name and t('menu.inventory.edit_' .. kind) or t('menu.inventory.create_' .. kind), fields)
    if not result then return Menu.openInventoryEntries(kind) end

    local payload = {
        name = entry.name or result[1],
        label = result[2],
        weight = tonumber(result[3]) or 0,
        active = boolValue(result[4]),
        access = {
            jobs = tostring(result[5] or '') ~= '' and {
                {
                    name = result[5],
                    grade = tonumber(result[6]) or 0,
                },
            } or {},
            gangs = tostring(result[7] or '') ~= '' and {
                {
                    name = result[7],
                    grade = tonumber(result[8]) or 0,
                },
            } or {},
        },
    }

    if isItem then
        local buttonsOk, buttons = decodeBlock(result[13], 'buttons')
        local clientOk, clientData = decodeBlock(result[14], 'client')
        local serverOk, serverData = decodeBlock(result[15], 'server')

        if not buttonsOk or not clientOk or not serverOk then
            return Menu.openInventoryEntryEditor(kind, entry)
        end

        payload.stack = boolValue(result[9])
        payload.close = boolValue(result[10])
        payload.description = result[11]
        payload.client = clientData
        if tostring(result[12] or '') ~= '' then
            payload.client = payload.client or {}
            payload.client.image = result[12]
        end
        payload.buttons = buttons
        payload.server = serverData
    else
        payload.description = result[9]
    end

    local ok = runInventoryAction(saveCallback, 'notify.inventory.save_failed', payload)
    SetTimeout(400, function()
        if ok then Menu.openInventoryEntries(kind) else Menu.openInventoryEntryEditor(kind, entry) end
    end)
end
