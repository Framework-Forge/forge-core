ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local alertDialog = Shared.alertDialog
local awaitServer = Shared.awaitServer
local notify = Shared.notify
local notifyFailure = Shared.notifyFailure
local boolValue = Shared.boolValue
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions

local afkActionLocked = false
local passwordActionLocked = false
local backupActionLocked = false

local function databaseBackupModeLabel(mode)
    if mode == 'schema' then return t('menu.database_backup.schema') end
    if mode == 'data' then return t('menu.database_backup.data') end
    return t('menu.database_backup.both')
end

local function createDatabaseBackup(mode)
    local confirmed = alertDialog({
        header = t('dialogs.database_backup_header'),
        content = t('dialogs.database_backup_content', { mode = databaseBackupModeLabel(mode) }),
        centered = true,
        cancel = true,
    })

    if confirmed ~= 'confirm' then
        Menu.openDatabaseBackupMenu()
        return
    end

    if backupActionLocked then return end
    backupActionLocked = true

    local ok, result = pr_lib.callback.await(PR.DatabaseBackup.Callbacks.create, 300000, mode)
    if ok then
        notify({
            title = t('menu.database_backup.title'),
            description = t('notify.database_backup.created', {
                path = tostring(result.path or ''),
                tables = tostring(result.tables or 0),
                rows = tostring(result.rows or 0),
            }),
            type = 'success',
        })
    else
        notifyFailure('notify.database_backup.failed', result)
    end

    SetTimeout(500, function()
        Menu.openDatabaseBackupMenu()
    end)

    SetTimeout(1000, function()
        backupActionLocked = false
    end)
end

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
                icon = 'key-fill',
                onSelect = function()
                    Menu.openPasswordSettingsEditor(password)
                end,
            },
            {
                title = t('menu.database_backup.title'),
                description = t('menu.database_backup.description'),
                icon = 'database-lock',
                onSelect = function()
                    Menu.openDatabaseBackupMenu()
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
                icon = 'person-lock',
                onSelect = function()
                    Menu.openWhitelistMenu()
                end,
            },
            {
                title = t('menu.density.title'),
                description = t('menu.density.description'),
                icon = 'cone-striped',
                onSelect = function()
                    Menu.openDensityMenu()
                end,
            },
            {
                title = t('menu.inventory.title'),
                description = t('menu.inventory.description'),
                icon = 'boxes',
                onSelect = function()
                    Menu.openInventoryMenu()
                end,
            },
            {
                title = t('menu.vehicles.title'),
                description = t('menu.vehicles.description'),
                icon = 'car-front-fill',
                onSelect = function()
                    Menu.openVehiclesMenu()
                end,
            },
            {
                title = t('menu.vinewood.title'),
                description = t('menu.vinewood.description'),
                icon = 'bank2',
                onSelect = function()
                    Menu.openVinewoodMenu()
                end,
            },
            {
                title = t('menu.objects.title'),
                description = t('menu.objects.description'),
                icon = 'boxes',
                onSelect = function()
                    Menu.openObjectsMenu()
                end,
            },
            {
                title = t('menu.npcs.title'),
                description = t('menu.npcs.description'),
                icon = 'people-fill',
                onSelect = function()
                    Menu.openNpcsMenu()
                end,
            },
            {
                title = t('menu.spotlights.title'),
                description = t('menu.spotlights.description'),
                icon = 'lamp-fill',
                onSelect = function()
                    Menu.openSpotlightsMenu()
                end,
            },
            {
                title = t('menu.billboards.title'),
                description = t('menu.billboards.description'),
                icon = 'image',
                onSelect = function()
                    Menu.openBillboardsMenu()
                end,
            },
            {
                title = t('menu.chat.title'),
                description = t('menu.chat.description'),
                icon = 'chat-dots-fill',
                onSelect = function()
                    local resource = 'forge-chat'
                    if GetResourceState(resource) ~= 'started' then
                        notify({
                            title = t('menu.chat.title'),
                            description = t('errors.chat_resource_unavailable', { resource = resource }),
                            type = 'error',
                        })
                        return
                    end

                    local ok = pcall(function()
                        exports[resource]:OpenAdminMenu('forge_core_server_settings', GetCurrentResourceName())
                    end)
                    if not ok then
                        notify({
                            title = t('menu.chat.title'),
                            description = t('errors.chat_menu_unavailable'),
                            type = 'error',
                        })
                    end
                end,
            },
            {
                title = t('menu.safezones.title'),
                description = t('menu.safezones.description'),
                icon = 'bi bi-bounding-box-circles',
                onSelect = function()
                    local resource = 'forge-smallresources'
                    if GetResourceState(resource) ~= 'started' then
                        notify({
                            title = t('menu.safezones.title'),
                            description = t('errors.safezones_resource_unavailable', { resource = resource }),
                            type = 'error',
                        })
                        return
                    end

                    local ok = pcall(function()
                        exports[resource]:OpenAdminMenu('forge_core_server_settings', GetCurrentResourceName())
                    end)
                    if not ok then
                        notify({
                            title = t('menu.safezones.title'),
                            description = t('errors.safezones_menu_unavailable'),
                            type = 'error',
                        })
                    end
                end,
            },
            {
                title = t('menu.prison.title'),
                description = t('menu.prison.description'),
                icon = 'building-lock',
                onSelect = function()
                    local resource = 'xt-prison'
                    if GetResourceState(resource) ~= 'started' then
                        notify({
                            title = t('menu.prison.title'),
                            description = t('errors.prison_resource_unavailable', { resource = resource }),
                            type = 'error',
                        })
                        return
                    end

                    local ok = pcall(function()
                        exports[resource]:OpenAdminMenu('forge_core_server_settings', GetCurrentResourceName())
                    end)
                    if not ok then
                        notify({
                            title = t('menu.prison.title'),
                            description = t('errors.prison_menu_unavailable'),
                            type = 'error',
                        })
                    end
                end,
            },
            {
                title = 'Forge HUD',
                description = 'Gerencie limites das vias e o HUD de helicoptero.',
                icon = 'bi bi-speedometer2',
                onSelect = function()
                    local resource = 'forge-hud'
                    if GetResourceState(resource) ~= 'started' then
                        notify({
                            title = 'Forge HUD',
                            description = ('O recurso %s nao esta iniciado.'):format(resource),
                            type = 'error',
                        })
                        return
                    end

                    local ok = pcall(function()
                        exports[resource]:OpenAdminMenu('forge_core_server_settings', GetCurrentResourceName())
                    end)
                    if not ok then
                        notify({
                            title = 'Forge HUD',
                            description = 'Nao foi possivel abrir o painel administrativo do HUD.',
                            type = 'error',
                        })
                    end
                end,
            },
            {
                title = t('menu.gym.title'),
                description = t('menu.gym.description'),
                icon = 'bi bi-person-arms-up',
                onSelect = function()
                    local resource = 'forge-gym'
                    if GetResourceState(resource) ~= 'started' then
                        notify({
                            title = t('menu.gym.title'),
                            description = t('errors.gym_resource_unavailable', { resource = resource }),
                            type = 'error',
                        })
                        return
                    end

                    local ok = pcall(function()
                        exports[resource]:OpenAdminMenu('forge_core_server_settings', GetCurrentResourceName())
                    end)
                    if not ok then
                        notify({
                            title = t('menu.gym.title'),
                            description = t('errors.gym_menu_unavailable'),
                            type = 'error',
                        })
                    end
                end,
            },
            {
                title = t('menu.backpacks.title'),
                description = t('menu.backpacks.description'),
                icon = 'backpack',
                onSelect = function()
                    local resource = 'forge-backpack'
                    if GetResourceState(resource) ~= 'started' then
                        notify({
                            title = t('menu.backpacks.title'),
                            description = t('errors.backpack_resource_unavailable', { resource = resource }),
                            type = 'error',
                        })
                        return
                    end

                    local ok = pcall(function()
                        exports[resource]:OpenAdminMenu('forge_core_server_settings', GetCurrentResourceName())
                    end)
                    if not ok then
                        notify({
                            title = t('menu.backpacks.title'),
                            description = t('errors.backpack_menu_unavailable'),
                            type = 'error',
                        })
                    end
                end,
            },
            {
                title = t('menu.appearance.title'),
                description = t('menu.appearance.description'),
                icon = 'person-bounding-box',
                onSelect = function()
                    local resource = 'illenium-appearance'
                    if GetResourceState(resource) ~= 'started' then
                        notify({
                            title = t('menu.appearance.title'),
                            description = t('errors.appearance_resource_unavailable', { resource = resource }),
                            type = 'error',
                        })
                        return
                    end

                    local ok = pcall(function()
                        exports[resource]:OpenAdminMenu('forge_core_server_settings', GetCurrentResourceName())
                    end)
                    if not ok then
                        notify({
                            title = t('menu.appearance.title'),
                            description = t('errors.appearance_menu_unavailable'),
                            type = 'error',
                        })
                    end
                end,
            },
            {
                title = t('menu.stores.title'),
                description = t('menu.stores.description'),
                icon = 'shop',
                onSelect = function()
                    Menu.openStoresAdminMenu()
                end,
            },
            {
                title = t('menu.farms.title'),
                description = t('menu.farms.description'),
                icon = 'truck-front-fill',
                onSelect = function()
                    Menu.openFarmsMenu()
                end,
            },
            {
                title = t('menu.starterpack.title'),
                description = t('menu.starterpack.description'),
                icon = 'gift',
                onSelect = function()
                    Menu.openStarterpackMenu()
                end,
            },
        },
    })
end

function Menu.openDatabaseBackupMenu()
    local ok, payload = awaitServer(PR.DatabaseBackup.Callbacks.getHistory)
    if not ok then
        notifyFailure('notify.database_backup.load_failed', payload)
        Menu.openServerSettingsMenu()
        return
    end

    payload = type(payload) == 'table' and payload or {}
    local options = {
        {
            title = t('menu.database_backup.schema'),
            description = t('menu.database_backup.schema_description'),
            icon = 'table',
            disabled = payload.running == true,
            onSelect = function()
                createDatabaseBackup('schema')
            end,
        },
        {
            title = t('menu.database_backup.data'),
            description = t('menu.database_backup.data_description'),
            icon = 'file-earmark-code',
            disabled = payload.running == true,
            onSelect = function()
                createDatabaseBackup('data')
            end,
        },
        {
            title = t('menu.database_backup.both'),
            description = t('menu.database_backup.both_description'),
            icon = 'database-fill-down',
            disabled = payload.running == true,
            onSelect = function()
                createDatabaseBackup('both')
            end,
        },
    }

    local history = type(payload.entries) == 'table' and payload.entries or {}
    for i = 1, #history do
        local entry = history[i]
        options[#options + 1] = {
            title = t('menu.database_backup.history_entry', {
                date = tostring(entry.createdAt or ''),
                mode = databaseBackupModeLabel(entry.mode),
            }),
            description = entry.success and t('menu.database_backup.history_success', {
                admin = tostring(entry.adminName or entry.adminSource or ''),
                tables = tostring(entry.tables or 0),
                rows = tostring(entry.rows or 0),
                path = tostring(entry.path or ''),
            }) or t('menu.database_backup.history_failed', {
                admin = tostring(entry.adminName or entry.adminSource or ''),
                error = tostring(entry.error or 'unknown'),
            }),
            icon = entry.success and 'check-circle-fill' or 'x-circle-fill',
            iconColor = entry.success and '#22c55e' or '#ef4444',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_database_backups',
        title = t('menu.database_backup.title'),
        menu = 'forge_core_server_settings',
        options = options,
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
