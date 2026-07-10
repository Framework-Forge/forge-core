ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local lastRevision = nil

local function currentSettings()
    local settings = GlobalState.forgeDensity or GlobalState.pinelDensity
    if type(settings) ~= 'table' then return PR.Density.Defaults end
    return settings
end

local function densityValue(settings, key)
    if not settings.enabled or settings.disableAll then return 0.0 end

    local values = type(settings.values) == 'table' and settings.values or {}
    return tonumber(values[key]) or 0.0
end

local function applyDispatch(settings)
    if not settings.enabled or not settings.disableDispatchServices then return end

    for index = 1, 15 do
        EnableDispatchService(index, false)
    end
end

local function applyBudgets(settings)
    if not settings.enabled then return end

    SetPedPopulationBudget(tonumber(settings.pedPopulationBudget) or 0)
    SetVehiclePopulationBudget(tonumber(settings.vehiclePopulationBudget) or 0)
end

local function applyGeneratorAreas(settings)
    if not settings.enabled then return end

    for _, area in ipairs(type(settings.generatorAreas) == 'table' and settings.generatorAreas or {}) do
        local coords = type(area.coords) == 'table' and area.coords or {}
        local distance = tonumber(area.distance) or 0.0

        if distance > 0.0 then
            RemoveVehiclesFromGeneratorsInArea(
                (tonumber(coords.x) or 0.0) - distance,
                (tonumber(coords.y) or 0.0) - distance,
                (tonumber(coords.z) or 0.0) - distance,
                (tonumber(coords.x) or 0.0) + distance,
                (tonumber(coords.y) or 0.0) + distance,
                (tonumber(coords.z) or 0.0) + distance
            )
        end
    end
end

local function applyBlacklist(settings)
    if not settings.enabled then return end

    local blacklist = type(settings.blacklist) == 'table' and settings.blacklist or {}
    if not blacklist.enabled then return end

    for _, scenarioType in ipairs(blacklist.scenarioTypes or {}) do
        SetScenarioTypeEnabled(scenarioType, false)
    end

    for _, model in ipairs(blacklist.models or {}) do
        SetVehicleModelIsSuppressed(joaat(model), true)
    end

    for _, scenarioGroup in ipairs(blacklist.scenarioGroups or {}) do
        SetScenarioGroupEnabled(scenarioGroup, false)
    end
end

local function applyLongIntervalSettings(settings)
    applyDispatch(settings)
    applyBudgets(settings)
    applyGeneratorAreas(settings)
    applyBlacklist(settings)
end

CreateThread(function()
    while true do
        local settings = currentSettings()
        local revision = settings.revision

        if revision ~= lastRevision then
            lastRevision = revision
            applyLongIntervalSettings(settings)
        end

        SetParkedVehicleDensityMultiplierThisFrame(densityValue(settings, 'parked'))
        SetVehicleDensityMultiplierThisFrame(densityValue(settings, 'vehicle'))
        SetRandomVehicleDensityMultiplierThisFrame(densityValue(settings, 'multiplier'))
        SetPedDensityMultiplierThisFrame(densityValue(settings, 'peds'))
        SetScenarioPedDensityMultiplierThisFrame(densityValue(settings, 'scenario'), densityValue(settings, 'scenario'))

        Wait(0)
    end
end)

CreateThread(function()
    while true do
        applyLongIntervalSettings(currentSettings())
        Wait(10000)
    end
end)
