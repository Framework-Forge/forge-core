ForgeCore = ForgeCore or {}

local function canManage(source)
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end

    if source == 0 then return true end
    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function normalizeHour(value)
    value = math.floor(tonumber(value) or 0)
    if value < 0 then return 0 end
    if value > 23 then return 23 end
    return value
end

local function normalizeMinute(value)
    value = math.floor(tonumber(value) or 0)
    if value < 0 then return 0 end
    if value > 59 then return 59 end
    return value
end

local function normalizeDuration(value)
    value = math.floor(tonumber(value) or 0)
    if value < 1 then return 1 end
    if value > 1440 then return 1440 end
    return value
end

local function boolValue(value)
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function validWeatherType(value)
    for _, weather in ipairs(PR.Weather.Types or {}) do
        if weather.value == value then return true end
    end

    return false
end

local function weatherBridge(method, ...)
    local bridge = pr_lib and pr_lib.weather
    if bridge and type(bridge[method]) == 'function' then
        return bridge[method](...)
    end

    return false, 'weather_bridge_unavailable'
end

ForgeCore.WeatherService = {
    canManage = canManage,
    getState = function(source)
        if not canManage(source) then return false, 'no_permission' end

        return weatherBridge('GetState')
    end,
    setWeather = function(source, index, weatherType, weatherEvent)
        if not canManage(source) then return false, 'no_permission' end
        if not validWeatherType(weatherType) then return false, 'invalid_weather' end

        return weatherBridge('SetWeatherType', tonumber(index), weatherType, weatherEvent)
    end,
    setDuration = function(source, index, duration, weatherEvent)
        if not canManage(source) then return false, 'no_permission' end

        return weatherBridge('SetEventTime', tonumber(index), normalizeDuration(duration), weatherEvent)
    end,
    addWeather = function(source, data)
        if not canManage(source) then return false, 'no_permission' end

        data = type(data) == 'table' and data or {}
        if not validWeatherType(data.weather) then return false, 'invalid_weather' end

        return weatherBridge('AddWeatherEvent', data.weather, normalizeDuration(data.duration), tonumber(data.index))
    end,
    removeWeather = function(source, index, weatherEvent)
        if not canManage(source) then return false, 'no_permission' end

        return weatherBridge('RemoveWeatherEvent', tonumber(index), weatherEvent)
    end,
    setTime = function(source, hour, minute)
        if not canManage(source) then return false, 'no_permission' end

        return weatherBridge('SetTime', normalizeHour(hour), normalizeMinute(minute))
    end,
    setTimeScale = function(source, scale)
        if not canManage(source) then return false, 'no_permission' end

        scale = math.floor(tonumber(scale) or 0)
        if scale < 2000 then scale = 2000 end
        if scale > 60000 then scale = 60000 end

        return weatherBridge('SetTimeScale', scale)
    end,
    setFreezeTime = function(source, enabled)
        if not canManage(source) then return false, 'no_permission' end

        return weatherBridge('SetFreezeTime', boolValue(enabled))
    end,
}

ForgeCore.Callbacks.register(PR.Weather.Callbacks.getState, function(source)
    return ForgeCore.WeatherService.getState(source)
end)

ForgeCore.Callbacks.register(PR.Weather.Callbacks.setWeather, function(source, index, weatherType, weatherEvent)
    return ForgeCore.WeatherService.setWeather(source, index, weatherType, weatherEvent)
end)

ForgeCore.Callbacks.register(PR.Weather.Callbacks.setDuration, function(source, index, duration, weatherEvent)
    return ForgeCore.WeatherService.setDuration(source, index, duration, weatherEvent)
end)

ForgeCore.Callbacks.register(PR.Weather.Callbacks.addWeather, function(source, data)
    return ForgeCore.WeatherService.addWeather(source, data)
end)

ForgeCore.Callbacks.register(PR.Weather.Callbacks.removeWeather, function(source, index, weatherEvent)
    return ForgeCore.WeatherService.removeWeather(source, index, weatherEvent)
end)

ForgeCore.Callbacks.register(PR.Weather.Callbacks.setTime, function(source, hour, minute)
    return ForgeCore.WeatherService.setTime(source, hour, minute)
end)

ForgeCore.Callbacks.register(PR.Weather.Callbacks.setTimeScale, function(source, scale)
    return ForgeCore.WeatherService.setTimeScale(source, scale)
end)

ForgeCore.Callbacks.register(PR.Weather.Callbacks.setFreezeTime, function(source, enabled)
    return ForgeCore.WeatherService.setFreezeTime(source, enabled)
end)
