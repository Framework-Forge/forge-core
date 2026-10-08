ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    settings = {},
    blockedModels = {},
}

local resourceName = GetCurrentResourceName()

local function debug(level, message)
    local debugApi = pr_lib and pr_lib.debug
    if not debugApi then return end

    local fn = debugApi[level]
    if type(fn) == 'function' then
        fn(message)
    elseif type(debugApi) == 'function' then
        debugApi(level, message)
    end
end

local function notify(source, data)
    if not source or source <= 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('density.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end

    if source == 0 then return true end
    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function clone(value, seen)
    if type(value) ~= 'table' then return value end

    seen = seen or {}
    if seen[value] then return seen[value] end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[clone(key, seen)] = clone(item, seen)
    end

    return copy
end

local function mergeDefaults(defaults, value)
    local result = clone(defaults)
    value = type(value) == 'table' and value or {}

    for key, item in pairs(value) do
        if type(item) == 'table' and type(result[key]) == 'table' then
            result[key] = mergeDefaults(result[key], item)
        else
            result[key] = item
        end
    end

    return result
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function densityValue(value)
    value = tonumber(value) or 0.0
    if value < 0.0 then return 0.0 end
    if value > 1.0 then return 1.0 end
    return math.floor((value * 10) + 0.5) / 10
end

local function budgetValue(value)
    value = math.floor(tonumber(value) or 0)
    if value < 0 then return 0 end
    if value > 3 then return 3 end
    return value
end

local function normalizeList(list)
    local normalized = {}

    for _, value in ipairs(type(list) == 'table' and list or {}) do
        value = tostring(value or '')
        if value ~= '' then
            normalized[#normalized + 1] = value
        end
    end

    return normalized
end

local function normalizeAreas(areas)
    local normalized = {}

    for _, area in ipairs(type(areas) == 'table' and areas or {}) do
        area = type(area) == 'table' and area or {}
        local coords = type(area.coords) == 'table' and area.coords or {}
        local distance = tonumber(area.distance) or 0.0

        if distance > 0 then
            normalized[#normalized + 1] = {
                coords = {
                    x = tonumber(coords.x) or 0.0,
                    y = tonumber(coords.y) or 0.0,
                    z = tonumber(coords.z) or 0.0,
                },
                distance = distance,
            }
        end
    end

    return normalized
end

local function normalizeSettings(settings)
    settings = mergeDefaults(PR.Density.Defaults, settings)
    settings.values = type(settings.values) == 'table' and settings.values or {}
    settings.blacklist = type(settings.blacklist) == 'table' and settings.blacklist or {}

    return {
        enabled = boolValue(settings.enabled, PR.Density.Defaults.enabled),
        disableAll = boolValue(settings.disableAll, PR.Density.Defaults.disableAll),
        values = {
            parked = densityValue(settings.values.parked),
            vehicle = densityValue(settings.values.vehicle),
            multiplier = densityValue(settings.values.multiplier),
            peds = densityValue(settings.values.peds),
            scenario = densityValue(settings.values.scenario),
        },
        pedPopulationBudget = budgetValue(settings.pedPopulationBudget),
        vehiclePopulationBudget = budgetValue(settings.vehiclePopulationBudget),
        disableDispatchServices = boolValue(settings.disableDispatchServices, PR.Density.Defaults.disableDispatchServices),
        blacklist = {
            enabled = boolValue(settings.blacklist.enabled, PR.Density.Defaults.blacklist.enabled),
            models = normalizeList(settings.blacklist.models),
            scenarioTypes = normalizeList(settings.blacklist.scenarioTypes),
            scenarioGroups = normalizeList(settings.blacklist.scenarioGroups),
        },
        generatorAreas = normalizeAreas(settings.generatorAreas),
        revision = GetGameTimer(),
    }
end

local function readJson(path, fallback)
    return pr_lib.loadJsonRecovery(path) or fallback
end

local function writeJson(path, data)
    return pr_lib.saveJsonRecovery(path, data)
end

local function updateBlockedModels()
    Service.blockedModels = {}

    local blacklist = Service.settings.blacklist or {}
    if not blacklist.enabled then return end

    for _, model in ipairs(blacklist.models or {}) do
        Service.blockedModels[joaat(model)] = true
    end
end

local function publish()
    local settings = Service.getSettings()
    ForgeCore.State.publish('density',settings)
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getSettings()
    return normalizeSettings(Service.settings)
end

function Service.load()
    Service.settings = normalizeSettings(readJson(PR.Density.Storage.file, PR.Density.Defaults))
    updateBlockedModels()
    publish()
    return Service.getSettings()
end

function Service.save(source, settings)
    if not canManage(source) then return false, 'no_permission' end

    local draft = normalizeSettings(settings)
    local saved = writeJson(PR.Density.Storage.file, draft)
    if not saved then return false, 'save_failed' end

    Service.settings = draft
    updateBlockedModels()
    publish()

    notify(source, {
        description = ForgeCore.t('notify.density.saved'),
        type = 'success',
    })

    return true, Service.getSettings()
end

function Service.start()
    if Service.started then return true end
    Service.started = true

    Service.load()
    debug('success', ForgeCore.t('debug.density.started'))

    return true
end

AddEventHandler('entityCreating', function(handle)
    if not Service.started then return end
    if not Service.settings.enabled then return end

    local blacklist = Service.settings.blacklist or {}
    if not blacklist.enabled then return end

    if Service.blockedModels[GetEntityModel(handle)] then
        CancelEvent()
    end
end)

pr_lib.wrapJsonMutations(PR.Density.Storage.file, Service, {
    'save',
})

ForgeCore.DensityService = Service
