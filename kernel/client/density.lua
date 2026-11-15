-- Two unstarted workers; exact installed frame and long-interval behavior.
return function(ports)
    local PR,native,world=assert(ports.config),assert(ports.native),assert(ports.world)
    local api={Threads={}}
    local function describeThread(handler)api.Threads[#api.Threads+1]=handler end
    local EnableDispatchService=assert(native.EnableDispatchService)
    local SetPedPopulationBudget=assert(native.SetPedPopulationBudget)
    local SetVehiclePopulationBudget=assert(native.SetVehiclePopulationBudget)
    local RemoveVehiclesFromGeneratorsInArea=assert(native.RemoveVehiclesFromGeneratorsInArea)
    local SetScenarioTypeEnabled=assert(native.SetScenarioTypeEnabled)
    local SetVehicleModelIsSuppressed=assert(native.SetVehicleModelIsSuppressed)
    local joaat=assert(native.joaat)
    local SetScenarioGroupEnabled=assert(native.SetScenarioGroupEnabled)
    local SetParkedVehicleDensityMultiplierThisFrame=assert(native.SetParkedVehicleDensityMultiplierThisFrame)
    local SetVehicleDensityMultiplierThisFrame=assert(native.SetVehicleDensityMultiplierThisFrame)
    local SetRandomVehicleDensityMultiplierThisFrame=assert(native.SetRandomVehicleDensityMultiplierThisFrame)
    local SetPedDensityMultiplierThisFrame=assert(native.SetPedDensityMultiplierThisFrame)
    local SetScenarioPedDensityMultiplierThisFrame=assert(native.SetScenarioPedDensityMultiplierThisFrame)
    local Wait=assert(native.Wait)
local lastRevision = nil

local function currentSettings()
    local settings = world.peek('density')
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

describeThread(function()
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

describeThread(function()
    while true do
        applyLongIntervalSettings(currentSettings())
        Wait(10000)
    end
end)
    return api
end
