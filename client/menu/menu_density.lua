ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local clone = Shared.clone
local boolDefault = Shared.boolDefault
local boolValue = Shared.boolValue
local boolOptions = Shared.boolOptions

local densityActionLocked = false

local function fetchDensitySettings()
    local ok, payload = awaitServer(PR.Density.Callbacks.getSettings)
    if not ok then
        notifyFailure('notify.density.load_failed', payload)
        return nil
    end

    return type(payload) == 'table' and payload or clone(PR.Density.Defaults)
end

local function saveDensitySettings(settings, reopen)
    if densityActionLocked then return false end
    densityActionLocked = true

    local ok, response = awaitServer(PR.Density.Callbacks.saveSettings, settings)
    if not ok then
        notifyFailure('notify.density.save_failed', response)
    end

    SetTimeout(500, function()
        if reopen then reopen() end
    end)

    SetTimeout(1000, function()
        densityActionLocked = false
    end)

    return ok
end

local function densityText(settings, key)
    if settings.disableAll then return t('common.inactive') end
    return tostring(settings.values and settings.values[key] or 0.0)
end

function Menu.openDensityMenu()
    local settings = fetchDensitySettings()
    if not settings then return false end

    showContext({
        id = 'forge_core_density',
        title = t('menu.density.title'),
        menu = 'forge_core_server_settings',
        options = {
            {
                title = t('menu.density.general'),
                description = t('menu.density.general_summary', {
                    status = settings.enabled and t('common.active') or t('common.inactive'),
                    all = settings.disableAll and t('common.no') or t('common.yes'),
                }),
                icon = 'gear-fill',
                onSelect = function()
                    Menu.openDensityGeneralEditor(settings)
                end,
            },
            {
                title = t('menu.density.values'),
                description = t('menu.density.values_summary', {
                    parked = densityText(settings, 'parked'),
                    vehicle = densityText(settings, 'vehicle'),
                    peds = densityText(settings, 'peds'),
                }),
                icon = 'sliders',
                onSelect = function()
                    Menu.openDensityValuesEditor(settings)
                end,
            },
            {
                title = t('menu.density.population'),
                description = t('menu.density.population_summary', {
                    peds = tostring(settings.pedPopulationBudget or 0),
                    vehicles = tostring(settings.vehiclePopulationBudget or 0),
                }),
                icon = 'speedometer2',
                onSelect = function()
                    Menu.openDensityPopulationEditor(settings)
                end,
            },
            {
                title = t('menu.density.blacklist'),
                description = t('menu.density.blacklist_summary', {
                    status = settings.blacklist and settings.blacklist.enabled and t('common.active') or t('common.inactive'),
                    models = tostring(settings.blacklist and #(settings.blacklist.models or {}) or 0),
                }),
                icon = 'ban',
                onSelect = function()
                    Menu.openDensityBlacklistEditor(settings)
                end,
            },
        },
    })

    return true
end

function Menu.openDensityGeneralEditor(settings)
    settings = type(settings) == 'table' and settings or fetchDensitySettings()
    if not settings then return false end

    local result = inputDialog(t('menu.density.general'), {
        { type = 'select', label = t('inputs.density_enabled'), options = boolOptions(), default = boolDefault(settings.enabled), required = true },
        { type = 'select', label = t('inputs.density_disable_all'), options = boolOptions(), default = boolDefault(settings.disableAll), required = true },
        { type = 'select', label = t('inputs.density_disable_dispatch'), options = boolOptions(), default = boolDefault(settings.disableDispatchServices), required = true },
    })

    if not result then return Menu.openDensityMenu() end

    settings.enabled = boolValue(result[1])
    settings.disableAll = boolValue(result[2])
    settings.disableDispatchServices = boolValue(result[3])

    saveDensitySettings(settings, function()
        Menu.openDensityMenu()
    end)
end

function Menu.openDensityValuesEditor(settings)
    settings = type(settings) == 'table' and settings or fetchDensitySettings()
    if not settings then return false end

    settings.values = type(settings.values) == 'table' and settings.values or {}

    local result = inputDialog(t('menu.density.values'), {
        { type = 'slider', label = t('inputs.density_parked'), default = tonumber(settings.values.parked) or 0.0, min = 0.0, max = 1.0, step = 0.1, required = true },
        { type = 'slider', label = t('inputs.density_vehicle'), default = tonumber(settings.values.vehicle) or 0.0, min = 0.0, max = 1.0, step = 0.1, required = true },
        { type = 'slider', label = t('inputs.density_multiplier'), default = tonumber(settings.values.multiplier) or 0.0, min = 0.0, max = 1.0, step = 0.1, required = true },
        { type = 'slider', label = t('inputs.density_peds'), default = tonumber(settings.values.peds) or 0.0, min = 0.0, max = 1.0, step = 0.1, required = true },
        { type = 'slider', label = t('inputs.density_scenario'), default = tonumber(settings.values.scenario) or 0.0, min = 0.0, max = 1.0, step = 0.1, required = true },
    })

    if not result then return Menu.openDensityMenu() end

    settings.values.parked = tonumber(result[1]) or 0.0
    settings.values.vehicle = tonumber(result[2]) or 0.0
    settings.values.multiplier = tonumber(result[3]) or 0.0
    settings.values.peds = tonumber(result[4]) or 0.0
    settings.values.scenario = tonumber(result[5]) or 0.0

    saveDensitySettings(settings, function()
        Menu.openDensityMenu()
    end)
end

function Menu.openDensityPopulationEditor(settings)
    settings = type(settings) == 'table' and settings or fetchDensitySettings()
    if not settings then return false end

    local result = inputDialog(t('menu.density.population'), {
        { type = 'number', label = t('inputs.density_ped_budget'), default = tonumber(settings.pedPopulationBudget) or 3, min = 0, max = 3, required = true },
        { type = 'number', label = t('inputs.density_vehicle_budget'), default = tonumber(settings.vehiclePopulationBudget) or 3, min = 0, max = 3, required = true },
    })

    if not result then return Menu.openDensityMenu() end

    settings.pedPopulationBudget = tonumber(result[1]) or 0
    settings.vehiclePopulationBudget = tonumber(result[2]) or 0

    saveDensitySettings(settings, function()
        Menu.openDensityMenu()
    end)
end

function Menu.openDensityBlacklistEditor(settings)
    settings = type(settings) == 'table' and settings or fetchDensitySettings()
    if not settings then return false end

    settings.blacklist = type(settings.blacklist) == 'table' and settings.blacklist or {}

    local result = inputDialog(t('menu.density.blacklist'), {
        { type = 'select', label = t('inputs.density_blacklist_enabled'), options = boolOptions(), default = boolDefault(settings.blacklist.enabled), required = true },
    })

    if not result then return Menu.openDensityMenu() end

    settings.blacklist.enabled = boolValue(result[1])

    saveDensitySettings(settings, function()
        Menu.openDensityMenu()
    end)
end
