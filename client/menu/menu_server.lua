ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local boolValue = Shared.boolValue
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions

local afkActionLocked = false
local passwordActionLocked = false

local function fetchAfkSettings()
    local ok, payload = awaitServer(PR.Afk.Callbacks.getSettings)
    if not ok then
        notifyFailure('notify.afk.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.enabled = payload.enabled == true
    payload.minutes = tonumber(payload.minutes) or PR.Afk.Defaults.minutes

    return payload
end

local function fetchPasswordSettings()
    local ok, payload = awaitServer(PR.Password.Callbacks.getSettings)
    if not ok then
        notifyFailure('notify.password.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.enabled = payload.enabled == true
    payload.password = tostring(payload.password or '')
    payload.supportLink = tostring(payload.supportLink or '')
    payload.cardTitle = tostring(payload.cardTitle or '')
    payload.cardDescription = tostring(payload.cardDescription or '')
    payload.placeholder = tostring(payload.placeholder or '')
    payload.submitText = tostring(payload.submitText or '')

    return payload
end

function Menu.openServerSettingsMenu()
    local afk = fetchAfkSettings() or {
        enabled = PR.Afk.Defaults.enabled,
        minutes = PR.Afk.Defaults.minutes,
    }
    local password = fetchPasswordSettings() or {
        enabled = PR.Password.Defaults.enabled,
        password = PR.Password.Defaults.password,
        supportLink = PR.Password.Defaults.supportLink,
        cardTitle = PR.Password.Defaults.cardTitle,
        cardDescription = PR.Password.Defaults.cardDescription,
        placeholder = PR.Password.Defaults.placeholder,
        submitText = PR.Password.Defaults.submitText,
    }

    showContext({
        id = 'forge_core_server_settings',
        title = t('menu.server.title'),
        menu = 'forge_core_main',
        options = {
            {
                title = t('menu.afk.title'),
                description = t('menu.afk.summary', {
                    status = afk.enabled and t('common.active') or t('common.inactive'),
                    minutes = tostring(afk.minutes),
                }),
                icon = 'clock',
                onSelect = function()
                    Menu.openAfkSettingsEditor(afk)
                end,
            },
            {
                title = t('menu.password.title'),
                description = t('menu.password.summary', {
                    status = password.enabled and t('common.active') or t('common.inactive'),
                    support = password.supportLink ~= '' and password.supportLink or t('common.none'),
                }),
                icon = 'key-round',
                onSelect = function()
                    Menu.openPasswordSettingsEditor(password)
                end,
            },
            {
                title = t('menu.weather.title'),
                description = t('menu.weather.description'),
                icon = 'cloud-sun',
                onSelect = function()
                    Menu.openWeatherTimeMenu()
                end,
            },
            {
                title = t('menu.whitelist.title'),
                description = t('menu.whitelist.description'),
                icon = 'user-lock',
                onSelect = function()
                    Menu.openWhitelistMenu()
                end,
            },
            {
                title = t('menu.density.title'),
                description = t('menu.density.description'),
                icon = 'traffic-cone',
                onSelect = function()
                    Menu.openDensityMenu()
                end,
            },
            {
                title = t('menu.weapons.title'),
                description = t('menu.weapons.description'),
                icon = 'crosshair',
                onSelect = function()
                    Menu.openWeaponsMenu()
                end,
            },
        },
    })
end

function Menu.openAfkSettingsEditor(settings)
    settings = type(settings) == 'table' and settings or {}

    local result = inputDialog(t('menu.afk.title'), {
        {
            type = 'select',
            label = t('inputs.afk_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled),
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.afk_minutes'),
            default = tonumber(settings.minutes) or PR.Afk.Defaults.minutes,
            required = true,
            min = 1,
            max = 1440,
        },
    })

    if not result then
        Menu.openServerSettingsMenu()
        return
    end

    if afkActionLocked then return end
    afkActionLocked = true

    local ok, response = awaitServer(PR.Afk.Callbacks.saveSettings, {
        enabled = boolValue(result[1]),
        minutes = tonumber(result[2]) or PR.Afk.Defaults.minutes,
    })

    if not ok then
        notifyFailure('notify.afk.save_failed', response)
    end

    SetTimeout(500, function()
        Menu.openServerSettingsMenu()
    end)

    SetTimeout(1000, function()
        afkActionLocked = false
    end)
end

function Menu.openPasswordSettingsEditor(settings)
    settings = type(settings) == 'table' and settings or {}

    local result = inputDialog(t('menu.password.title'), {
        {
            type = 'select',
            label = t('inputs.password_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled),
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.server_password'),
            default = settings.password or '',
            required = false,
        },
        {
            type = 'input',
            label = t('inputs.password_support_link'),
            default = settings.supportLink or '',
            required = false,
        },
        {
            type = 'input',
            label = t('inputs.password_card_title'),
            default = settings.cardTitle or '',
            required = false,
        },
        {
            type = 'textarea',
            label = t('inputs.password_card_description'),
            default = settings.cardDescription or '',
            required = false,
        },
        {
            type = 'input',
            label = t('inputs.password_placeholder'),
            default = settings.placeholder or '',
            required = false,
        },
        {
            type = 'input',
            label = t('inputs.password_submit_text'),
            default = settings.submitText or '',
            required = false,
        },
    })

    if not result then
        Menu.openServerSettingsMenu()
        return
    end

    if passwordActionLocked then return end
    passwordActionLocked = true

    local ok, response = awaitServer(PR.Password.Callbacks.saveSettings, {
        enabled = boolValue(result[1]),
        password = tostring(result[2] or ''),
        supportLink = tostring(result[3] or ''),
        cardTitle = tostring(result[4] or ''),
        cardDescription = tostring(result[5] or ''),
        placeholder = tostring(result[6] or ''),
        submitText = tostring(result[7] or ''),
    })

    if not ok then
        notifyFailure('notify.password.save_failed', response)
    end

    SetTimeout(500, function()
        Menu.openServerSettingsMenu()
    end)

    SetTimeout(1000, function()
        passwordActionLocked = false
    end)
end
