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

local weaponActionLocked = false

local function weaponStatus(weapon)
    return weapon.active == false and t('menu.weapons.status_inactive') or t('menu.weapons.status_active')
end

local function optionList(items)
    local options = {}

    for _, item in ipairs(items or {}) do
        options[#options + 1] = {
            value = item.value,
            label = item.label,
        }
    end

    return options
end

local function fetchWeaponsPayload()
    local ok, payload = awaitServer(PR.Weapons.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.weapons.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.weapons = type(payload.weapons) == 'table' and payload.weapons or {}

    return payload
end

local function runWeaponAction(callbackName, failureLocale, ...)
    if weaponActionLocked then return false end
    weaponActionLocked = true

    local ok, response = awaitServer(callbackName, ...)
    if not ok then
        notifyFailure(failureLocale or 'notify.weapons.action_failed', response)
    end

    SetTimeout(1000, function()
        weaponActionLocked = false
    end)

    return ok, response
end

local function giveWeaponToSelf(weapon)
    local result = inputDialog(t('menu.inventory.give_self'), {
        {
            type = 'number',
            label = t('menu.inventory.give_amount'),
            default = 1,
            min = 1,
            max = 25,
            required = true,
        },
    })

    if not result then return false end

    return runWeaponAction(
        PR.Inventory.Callbacks.give,
        'notify.inventory.give_failed',
        GetPlayerServerId(PlayerId()),
        'weapon',
        weapon.name,
        tonumber(result[1]) or 1
    )
end

local function saveParsedWeapons(parsed)
    local entries = type(parsed) == 'table' and parsed.entries
    if type(entries) ~= 'table' then return false end

    local saved = 0
    local failed = 0

    for index = 1, #entries do
        local weapon = entries[index]
        weapon.active = weapon.active ~= false

        local ok = awaitServer(PR.Weapons.Callbacks.save, weapon)
        if ok then
            saved = saved + 1
        else
            failed = failed + 1
        end
    end

    if failed > 0 then
        notifyFailure('notify.weapons.save_failed', ('%s/%s'):format(tostring(failed), tostring(#entries)))
    end

    return saved > 0
end

function Menu.openWeaponsMenu(parentMenu)
    local payload = fetchWeaponsPayload()
    if not payload then return Menu.openServerSettingsMenu() end

    local options = {
        {
            title = t('menu.weapons.create'),
            description = t('menu.weapons.create_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openWeaponEditor()
            end,
        },
        {
            title = t('menu.inventory.paste_weapon'),
            description = t('menu.inventory.paste_description'),
            icon = 'clipboard',
            onSelect = function()
                local result = inputDialog(t('menu.inventory.paste_weapon'), {
                    { type = 'textarea', label = t('inputs.inventory_paste'), required = true, autosize = true },
                })

                if not result then return Menu.openWeaponsMenu(parentMenu) end

                local ok, parsed = awaitServer(PR.Inventory.Callbacks.parseDefinition, 'weapon', result[1])
                if not ok then
                    notifyFailure('notify.inventory.parse_failed', parsed)
                    return Menu.openWeaponsMenu(parentMenu)
                end

                if saveParsedWeapons(parsed) then
                    SetTimeout(400, function() Menu.openWeaponsMenu(parentMenu) end)
                else
                    Menu.openWeaponEditor(parsed)
                end
            end,
        },
    }

    for _, weapon in ipairs(payload.weapons or {}) do
        options[#options + 1] = {
            title = weapon.label or weapon.name,
            description = t('menu.weapons.weapon_description', {
                name = weapon.name,
                category = weapon.weapontype or '',
                ammo = weapon.ammotype or t('common.none'),
                status = weaponStatus(weapon),
            }),
            icon = weapon.active == false and 'ban' or 'crosshair',
            iconColor = weapon.active == false and 'red' or nil,
            arrow = true,
            onSelect = function()
                Menu.openWeaponDetails(weapon)
            end,
        }
    end

    if #(payload.weapons or {}) == 0 then
        options[#options + 1] = {
            title = t('menu.weapons.no_weapons'),
            icon = 'info-circle-fill',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_weapons',
        title = t('menu.weapons.title'),
        description = t('menu.weapons.summary', { count = tostring(#(payload.weapons or {})) }),
        menu = parentMenu or 'forge_core_inventory',
        options = options,
    })
end

function Menu.openWeaponDetails(weapon)
    local nextActive = weapon.active == false

    showContext({
        id = 'forge_core_weapon_' .. tostring(weapon.name),
        title = weapon.label or weapon.name,
        description = t('menu.weapons.weapon_description', {
            name = weapon.name,
            category = weapon.weapontype or '',
            ammo = weapon.ammotype or t('common.none'),
            status = weaponStatus(weapon),
        }),
        menu = 'forge_core_weapons',
        options = {
            {
                title = t('menu.weapons.info_status', { status = weaponStatus(weapon) }),
                description = t('menu.weapons.info_status_description'),
                icon = weapon.active == false and 'toggle-off' or 'toggle-on',
                disabled = true,
            },
            {
                title = t('menu.weapons.info_name', { name = weapon.name }),
                description = t('menu.weapons.info_category', {
                    category = weapon.weapontype or '',
                    ammo = weapon.ammotype or t('common.none'),
                }),
                icon = 'info-circle-fill',
                disabled = true,
            },
            {
                title = t('menu.weapons.info_damage'),
                description = weapon.damagereason or PR.Weapons.Defaults.damagereason,
                icon = 'emoji-dizzy-fill',
                disabled = true,
            },
            {
                title = nextActive and t('menu.weapons.activate') or t('menu.weapons.deactivate'),
                description = nextActive and t('menu.weapons.activate_description') or t('menu.weapons.deactivate_description'),
                icon = nextActive and 'toggle-on' or 'toggle-off',
                iconColor = nextActive and 'green' or 'yellow',
                onSelect = function()
                    runWeaponAction(PR.Weapons.Callbacks.setActive, 'notify.weapons.action_failed', weapon.name, nextActive)

                    SetTimeout(500, function()
                        Menu.openWeaponsMenu()
                    end)
                end,
            },
            {
                title = t('menu.inventory.give_self'),
                description = t('menu.inventory.give_self_description'),
                icon = 'gift-fill',
                iconColor = 'green',
                disabled = weapon.active == false,
                onSelect = function()
                    giveWeaponToSelf(weapon)
                    SetTimeout(400, function() Menu.openWeaponDetails(weapon) end)
                end,
            },
            {
                title = t('menu.actions.edit'),
                icon = 'pen',
                onSelect = function()
                    Menu.openWeaponEditor(weapon)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_weapon_header'),
                        content = t('dialogs.remove_weapon_content', { weapon = weapon.label or weapon.name }),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        runWeaponAction(PR.Weapons.Callbacks.delete, 'notify.weapons.remove_failed', weapon.name)
                    end

                    SetTimeout(500, function()
                        Menu.openWeaponsMenu()
                    end)
                end,
            },
        },
    })
end

function Menu.openWeaponEditor(weapon)
    weapon = type(weapon) == 'table' and weapon or {}

    local result = inputDialog(weapon.name and t('menu.weapons.edit') or t('menu.weapons.create'), {
        {
            type = 'input',
            label = t('inputs.weapon_name'),
            default = weapon.name,
            disabled = weapon.name ~= nil,
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.weapon_label'),
            default = weapon.label,
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.weapon_category'),
            options = optionList(PR.Weapons.Categories),
            default = weapon.weapontype or PR.Weapons.Defaults.weapontype,
            required = true,
            searchable = true,
        },
        {
            type = 'select',
            label = t('inputs.weapon_ammo'),
            options = optionList(PR.Weapons.AmmoTypes),
            default = weapon.ammotype or 'none',
            required = true,
            searchable = true,
        },
        {
            type = 'input',
            label = t('inputs.weapon_damage_reason'),
            default = weapon.damagereason or PR.Weapons.Defaults.damagereason,
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.inventory_ammoname'),
            default = weapon.ammoname or '',
        },
        {
            type = 'number',
            label = t('inputs.inventory_weight'),
            min = 0,
            default = tonumber(weapon.weight) or 1000,
        },
        {
            type = 'number',
            label = t('inputs.inventory_durability'),
            min = 0,
            max = 1,
            step = 0.01,
            default = tonumber(weapon.durability) or 0.05,
        },
        {
            type = 'select',
            label = t('inputs.inventory_access_mode'),
            options = PR.Inventory.AccessModes,
            default = weapon.access and weapon.access.mode or 'free',
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.inventory_access_name'),
            default = weapon.access and weapon.access.name or '',
        },
        {
            type = 'number',
            label = t('inputs.inventory_access_grade'),
            min = 0,
            default = weapon.access and tonumber(weapon.access.grade) or 0,
        },
    })

    if not result then
        return weapon.name and Menu.openWeaponDetails(weapon) or Menu.openWeaponsMenu()
    end

    local ok = runWeaponAction(PR.Weapons.Callbacks.save, 'notify.weapons.save_failed', {
        name = weapon.name or result[1],
        label = result[2],
        weapontype = result[3],
        throwable = result[3] == 'Throwable',
        ammotype = result[4],
        damagereason = result[5],
        ammoname = tostring(result[6] or '') ~= '' and result[6] or nil,
        weight = tonumber(result[7]) or weapon.weight,
        durability = tonumber(result[8]) or weapon.durability,
        access = {
            mode = result[9] or 'free',
            name = result[10] or '',
            grade = tonumber(result[11]) or 0,
        },
        active = weapon.active ~= false,
    })

    SetTimeout(500, function()
        if ok then Menu.openWeaponsMenu() else Menu.openWeaponEditor(weapon) end
    end)
end
