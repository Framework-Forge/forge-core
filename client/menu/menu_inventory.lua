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

    if failureToken == 'animation' then
        local parsedOk, parsed = awaitServer(PR.Inventory.Callbacks.parseDefinition, 'animation', value)
        if parsedOk and type(parsed) == 'table' then return true, parsed end
    end

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

local function giveEntryToSelf(kind, entry)
    local result = inputDialog(t('menu.inventory.give_self'), {
        {
            type = 'number',
            label = t('menu.inventory.give_amount'),
            default = 1,
            min = 1,
            max = kind == 'weapon' and 25 or 100000,
            required = true,
        },
    })

    if not result then return false end

    return runInventoryAction(
        PR.Inventory.Callbacks.give,
        'notify.inventory.give_failed',
        GetPlayerServerId(PlayerId()),
        kind,
        entry.name,
        tonumber(result[1]) or 1
    )
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
                icon = 'box-seam-fill',
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
                icon = 'record-circle',
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

local function inventoryEntryImage(entry)
    if type(entry) ~= 'table' then return nil end

    local image = entry.imageUrl
        or (type(entry.client) == 'table' and entry.client.image)
        or entry.localImage

    if type(image) == 'string' and image ~= '' then
        if image:match('^https?://') or image:match('^nui://') or image:match('^data:') then
            return image
        end
    else
        image = type(entry.name) == 'string' and entry.name ~= '' and (entry.name .. '.png') or nil
    end

    local inventory = pr_lib and pr_lib.inventory
    local getImagePath = inventory and inventory.GetImagePath
    if type(getImagePath) ~= 'function' or not image then return nil end

    local ok, path = pcall(getImagePath, image)
    return ok and type(path) == 'string' and path ~= '' and path or nil
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
        local image = inventoryEntryImage(entry)
        options[#options + 1] = {
            title = entry.label or entry.name,
            description = t('menu.inventory.entry_description', {
                status = statusLabel(entry),
                name = entry.name or '',
                weight = tostring(entry.weight or 0),
            }),
            icon = entry.active == false and 'ban' or (kind == 'item' and 'box-seam-fill' or kind == 'ammo' and 'record-circle' or 'puzzle-fill'),
            iconColor = entry.active == false and 'red' or nil,
            image = image,
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
    local image = inventoryEntryImage(entry)

    local options = {
            {
                title = t('menu.inventory.info_status', { status = statusLabel(entry) }),
                description = t('menu.inventory.entry_description', {
                    status = statusLabel(entry),
                    name = entry.name or '',
                    weight = tostring(entry.weight or 0),
                }),
                icon = entry.active == false and 'toggle-off' or 'toggle-on',
                image = image,
                disabled = true,
            },
            {
                title = nextActive and t('menu.inventory.activate') or t('menu.inventory.deactivate'),
                icon = nextActive and 'toggle-on' or 'toggle-off',
                iconColor = nextActive and 'green' or 'yellow',
                onSelect = function()
                    runInventoryAction(activeCallback, 'notify.inventory.action_failed', entry.name, nextActive)
                    SetTimeout(400, function() Menu.openInventoryEntries(kind) end)
                end,
            },
            {
                title = t('menu.inventory.give_self'),
                description = t('menu.inventory.give_self_description'),
                icon = 'gift-fill',
                iconColor = 'green',
                disabled = entry.active == false,
                onSelect = function()
                    giveEntryToSelf(kind, entry)
                    SetTimeout(400, function() Menu.openInventoryEntryDetails(kind, entry) end)
                end,
            },
            {
                title = t('menu.actions.edit'),
                icon = 'pen',
                image = image,
                onSelect = function()
                    Menu.openInventoryEntryEditor(kind, entry)
                end,
            },
    }

    if kind == 'item' then
        options[#options + 1] = {
                title = 'Gerenciar interacao',
                description = entry.interaction and (
                    ('%s | %s | %s'):format(entry.interaction.enabled and 'Ativa' or 'Desativada', entry.interaction.category or 'sem categoria', (tonumber(entry.interaction.duration) or 0) <= 0 and 'Persistente' or (('%sms'):format(entry.interaction.duration)))
                ) or 'Criar animacao, consumo e efeitos deste item.',
                icon = 'person-walking-arrow-right',
                arrow = true,
                onSelect = function()
                    Menu.openInventoryInteractionEditor(entry)
                end,
        }
    end

    options[#options + 1] = {
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
    }

    showContext({
        id = ('forge_core_inventory_%s_%s'):format(kind, entry.name),
        title = entry.label or entry.name,
        menu = 'forge_core_inventory_' .. kind,
        options = options,
    })
end

local function effectRange(effects, key)
    local range = type(effects) == 'table' and effects[key] or nil
    range = type(range) == 'table' and range or {}
    return tonumber(range.min or range[1]) or 0, tonumber(range.max or range[2]) or 0
end

function Menu.openInventoryInteractionEditor(entry)
    entry = type(entry) == 'table' and entry or {}
    local interaction = type(entry.interaction) == 'table' and entry.interaction or {}
    local animation = type(interaction.animation) == 'table' and interaction.animation or {}
    local healthMin, healthMax = effectRange(interaction.effects, 'health')
    local armorMin, armorMax = effectRange(interaction.effects, 'armor')
    local hungerMin, hungerMax = effectRange(interaction.effects, 'hunger')
    local thirstMin, thirstMax = effectRange(interaction.effects, 'thirst')
    local stressMin, stressMax = effectRange(interaction.effects, 'stress')
    local oxygenMin, oxygenMax = effectRange(interaction.effects, 'oxygen')
    local animationJson = encodeBlock({
        dict = animation.dict,
        anim = animation.anim,
        flags = animation.flags,
        props = animation.props,
    })

    local result = inputDialog(('Interacao: %s'):format(entry.label or entry.name), {
        { type = 'select', label = 'Interacao ativa', options = boolOptions(), default = boolDefault(interaction.enabled == true), required = true },
        { type = 'select', label = 'Tipo', options = PR.Inventory.InteractionKinds, default = interaction.kind or 'consumable', required = true },
        { type = 'select', label = 'Categoria', options = PR.Inventory.ConsumableCategories, default = interaction.category or 'food', required = true },
        { type = 'input', label = 'Texto do progresso', default = interaction.label or '' },
        { type = 'number', label = 'Duracao (ms)', description = 'Use 0 para manter a animacao e os props ativos sem barra de progresso. Reutilize o item ou use a tecla de cancelamento para encerrar.', min = 0, max = 120000, default = tonumber(interaction.duration) or 5000, required = true },
        { type = 'select', label = 'Pode cancelar', description = 'Em modo persistente, permite encerrar pela tecla configuravel. O mesmo item sempre funciona como liga/desliga.', options = boolOptions(), default = boolDefault(interaction.canCancel ~= false), required = true },
        { type = 'number', label = 'Quantidade removida ao concluir', description = 'Para itens persistentes reutilizaveis, como guarda-chuva, use 0.', min = 0, max = 100, default = tonumber(interaction.remove) or 1, required = true },
        { type = 'select', label = 'Animacao corporal', options = {
            { value = 'partial', label = 'Parcial (parte superior)' },
            { value = 'full', label = 'Completa (corpo inteiro)' },
            { value = 'custom', label = 'Flags personalizadas' },
        }, default = animation.mode or 'partial', required = true },
        { type = 'textarea', label = 'Animacao e props (JSON ou Lua)', description = 'Aceita JSON ou a tabela Lua do pr_animateConfig, incluindo vec3.', default = animationJson, autosize = true },
        { type = 'number', label = 'Vida minima', min = -100, max = 100, default = healthMin },
        { type = 'number', label = 'Vida maxima', min = -100, max = 100, default = healthMax },
        { type = 'number', label = 'Colete minimo', min = -100, max = 100, default = armorMin },
        { type = 'number', label = 'Colete maximo', min = -100, max = 100, default = armorMax },
        { type = 'number', label = 'Fome minima', min = -100, max = 100, default = hungerMin },
        { type = 'number', label = 'Fome maxima', min = -100, max = 100, default = hungerMax },
        { type = 'number', label = 'Sede minima', min = -100, max = 100, default = thirstMin },
        { type = 'number', label = 'Sede maxima', min = -100, max = 100, default = thirstMax },
        { type = 'number', label = 'Estresse minimo', min = -100, max = 100, default = stressMin },
        { type = 'number', label = 'Estresse maximo', min = -100, max = 100, default = stressMax },
        { type = 'number', label = 'Oxigenio minimo', min = -100, max = 100, default = oxygenMin },
        { type = 'number', label = 'Oxigenio maximo', min = -100, max = 100, default = oxygenMax },
        { type = 'number', label = 'Nivel de alcool', min = 0, max = 10, step = 0.05, default = tonumber(interaction.alcohol) or 0 },
        { type = 'select', label = 'Efeito especial', options = PR.Inventory.SpecialEffects, default = interaction.effect or '' },
        { type = 'number', label = 'Duracao do efeito especial (ms)', min = 1000, max = 300000, default = tonumber(interaction.effectDuration) or 12000 },
        { type = 'number', label = 'Multiplicador de corrida (adrenalina)', description = '1.00 = normal; o GTA aceita no maximo 1.49.', min = 1.0, max = 1.49, step = 0.01, default = tonumber(interaction.effectStrength) or 1.15 },
    })
    if not result then return Menu.openInventoryEntryDetails('item', entry) end

    local animationOk, animationData = decodeBlock(result[9], 'animation')
    if not animationOk then return Menu.openInventoryInteractionEditor(entry) end
    animationData = animationData or {}
    animationData.mode = result[8]
    animationData.anim = animationData.anim or animationData.clip
    animationData.flags = tonumber(animationData.flags or animationData.flag) or (result[8] == 'full' and 1 or 49)

    local payload = pr_lib.table.clone(entry)
    payload.interaction = {
        enabled = boolValue(result[1]), kind = result[2], category = result[3], label = result[4],
        duration = tonumber(result[5]) or 5000, canCancel = boolValue(result[6]), remove = tonumber(result[7]) or 1,
        animation = animationData, alcohol = tonumber(result[22]) or 0, effect = result[23],
        effectDuration = tonumber(result[24]) or 12000, effectStrength = tonumber(result[25]) or 1.15,
        effects = {
            health = { min = result[10], max = result[11] }, armor = { min = result[12], max = result[13] },
            hunger = { min = result[14], max = result[15] }, thirst = { min = result[16], max = result[17] },
            stress = { min = result[18], max = result[19] }, oxygen = { min = result[20], max = result[21] },
        },
    }

    local ok = runInventoryAction(PR.Inventory.Callbacks.saveItem, 'notify.inventory.save_failed', payload)
    SetTimeout(400, function()
        if ok then Menu.openInventoryEntries('item') else Menu.openInventoryInteractionEditor(entry) end
    end)
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
        fields[#fields + 1] = { type = 'select', label = t('inputs.inventory_stack'), options = boolOptions(), default = boolDefault(entry.stack == true), required = true }
        fields[#fields + 1] = { type = 'select', label = t('inputs.inventory_close'), options = boolOptions(), default = boolDefault(entry.close ~= false), required = true }
        fields[#fields + 1] = { type = 'input', label = t('inputs.inventory_description'), default = entry.description or '' }
        fields[#fields + 1] = { type = 'input', label = t('inputs.inventory_image'), default = (entry.client and entry.client.image) or entry.imageUrl or entry.localImage or '' }
        fields[#fields + 1] = { type = 'textarea', label = t('inputs.inventory_buttons_json'), default = encodeBlock(entry.buttons), autosize = true }
        fields[#fields + 1] = { type = 'textarea', label = t('inputs.inventory_client_json'), default = encodeBlock(entry.client), autosize = true }
        fields[#fields + 1] = { type = 'textarea', label = t('inputs.inventory_server_json'), default = encodeBlock(entry.server), autosize = true }
    else
        fields[#fields + 1] = { type = 'input', label = t('inputs.inventory_description'), default = entry.description or '' }
    end

    local tiersOk, tiers = awaitServer(PR.Vip.Callbacks.getTiers)
    if not tiersOk or type(tiers) ~= 'table' then
        notifyFailure('notify.inventory.save_failed', tiers)
        return
    end
    local vipOptions, seenVips = {}, {}
    for _, tier in ipairs(tiers) do
        vipOptions[#vipOptions + 1] = { value = tier.id, label = tier.label or tier.id }
        seenVips[tier.id] = true
    end
    local selectedVips = entry.access and entry.access.vips or {}
    -- Preserve references to removed plans so editing never silently removes a restriction.
    for _, id in ipairs(selectedVips) do
        if not seenVips[id] then
            vipOptions[#vipOptions + 1] = { value = id, label = id .. ' (' .. t('inputs.inventory_access_vip_missing') .. ')' }
        end
    end
    local vipField = #fields + 1
    fields[vipField] = { type = 'multi-select', tags = true, label = t('inputs.inventory_access_vips'),
        description = t('inputs.inventory_access_vips_description'), options = vipOptions,
        default = selectedVips, searchable = true }

    local result = inputDialog(entry.name and t('menu.inventory.edit_' .. kind) or t('menu.inventory.create_' .. kind), fields)
    if not result then return Menu.openInventoryEntries(kind) end

    local payload = {
        name = entry.name or result[1],
        label = result[2],
        weight = tonumber(result[3]) or 0,
        active = boolValue(result[4]),
        access = {
            vips = type(result[vipField]) == 'table' and result[vipField] or {},
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
