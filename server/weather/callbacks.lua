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

local renewedResourceName = PR.Weather.Resource or 'Renewed-Weathersync'

local function isRenewedStarted()
    return GetResourceState(renewedResourceName) == 'started'
end

local function renewedExport(name, ...)
    if not isRenewedStarted() then return false, 'weather_resource_stopped' end

    local ok, result = pcall(function(...)
        return exports[renewedResourceName][name](...)
    end, ...)

    if not ok then return false, result end
    return true, result
end

local function setCurrentWeather(weatherType, duration)
    GlobalState.weather = {
        weather = weatherType,
        time = normalizeDuration(duration or (GlobalState.weather and GlobalState.weather.time) or 10),
    }

    return true, weatherType
end

local function resolveWeatherIndex(index, match)
    index = math.floor(tonumber(index) or 0)

    local ok, weatherList = renewedExport('GetWeatherList')
    if not ok then return false, weatherList end

    weatherList = type(weatherList) == 'table' and weatherList or {}
    if index >= 1 and weatherList[index] then return true, index end

    if type(match) == 'table' then
        for candidateIndex, event in ipairs(weatherList) do
            if event.weather == match.weather and tonumber(event.time) == tonumber(match.time) then
                return true, candidateIndex
            end
        end

        for candidateIndex, event in ipairs(weatherList) do
            if event.weather == match.weather then
                return true, candidateIndex
            end
        end
    end

    return false, 'weather_not_found'
end

local function renewedFallback(method, ...)
    if method == 'GetState' then
        local ok, weatherList = renewedExport('GetWeatherList')
        if not ok then return false, weatherList end

        return true, {
            weatherList = type(weatherList) == 'table' and weatherList or {},
            currentWeather = GlobalState.weather,
            currentTime = GlobalState.currentTime or { hour = 0, minute = 0 },
            timeScale = tonumber(GlobalState.timeScale) or 0,
            freezeTime = GlobalState.freezeTime == true,
        }
    end

    if method == 'SetWeatherType' then
        local index, weatherType, match = ...
        if tonumber(index) == 1 then
            return setCurrentWeather(weatherType, type(match) == 'table' and match.time or nil)
        end

        local ok, resolvedIndex = resolveWeatherIndex(index, match)
        if not ok then
            local duration = type(match) == 'table' and normalizeDuration(match.time) or 10
            local addOk, added = renewedExport('AddWeatherEvent', weatherType, duration, tonumber(index))
            if not addOk then return false, added end
            if not added then return false, 'add_failed' end
            return true, weatherType
        end

        local exportOk, result = renewedExport('SetWeatherType', resolvedIndex, weatherType)
        if not exportOk then return false, result end
        if not result then
            local duration = type(match) == 'table' and normalizeDuration(match.time) or 10
            local addOk, added = renewedExport('AddWeatherEvent', weatherType, duration, resolvedIndex)
            if not addOk then return false, added end
            if not added then return false, 'add_failed' end
            return true, weatherType
        end
        return true, result
    end

    if method == 'SetEventTime' then
        local index, duration, match = ...
        if tonumber(index) == 1 then
            local currentWeather = type(match) == 'table' and match.weather or (GlobalState.weather and GlobalState.weather.weather)
            if currentWeather then
                return setCurrentWeather(currentWeather, duration)
            end
        end

        local ok, resolvedIndex = resolveWeatherIndex(index, match)
        if not ok then
            if type(match) == 'table' and match.weather then
                local addOk, added = renewedExport('AddWeatherEvent', match.weather, normalizeDuration(duration), tonumber(index))
                if not addOk then return false, added end
                if not added then return false, 'add_failed' end
                return true, normalizeDuration(duration)
            end

            return false, resolvedIndex
        end

        local exportOk, result = renewedExport('SetEventTime', resolvedIndex, normalizeDuration(duration))
        if not exportOk then return false, result end
        if not result then
            if type(match) == 'table' and match.weather then
                local addOk, added = renewedExport('AddWeatherEvent', match.weather, normalizeDuration(duration), resolvedIndex)
                if not addOk then return false, added end
                if not added then return false, 'add_failed' end
                return true, normalizeDuration(duration)
            end

            return false, 'weather_not_found'
        end
        return true, result
    end

    if method == 'AddWeatherEvent' then
        local weatherType, duration, index = ...
        local exportOk, result = renewedExport('AddWeatherEvent', weatherType, normalizeDuration(duration), tonumber(index))
        if not exportOk then return false, result end
        if not result then return false, 'add_failed' end
        return true, result
    end

    if method == 'RemoveWeatherEvent' then
        local index, match = ...
        local ok, resolvedIndex = resolveWeatherIndex(index, match)
        if not ok then return true, 'already_removed' end

        local exportOk, result = renewedExport('RemoveWeatherEvent', resolvedIndex)
        if not exportOk then return false, result end
        if not result then return true, 'already_removed' end
        return true, result
    end

    if method == 'SetTime' then
        local hour, minute = ...
        GlobalState.currentTime = {
            hour = normalizeHour(hour),
            minute = normalizeMinute(minute),
        }

        return true, GlobalState.currentTime
    end

    if method == 'SetTimeScale' then
        local scale = math.floor(tonumber((...)) or 0)
        if scale < 2000 then scale = 2000 end
        if scale > 60000 then scale = 60000 end

        GlobalState.timeScale = scale
        return true, scale
    end

    if method == 'SetFreezeTime' then
        GlobalState.freezeTime = boolValue((...))
        return true, GlobalState.freezeTime
    end

    return false, 'weather_bridge_unavailable'
end

local function weatherBridge(method, ...)
    local bridge = pr_lib and pr_lib.weather
    if bridge and type(bridge[method]) == 'function' then
        return bridge[method](...)
    end

    return renewedFallback(method, ...)
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
