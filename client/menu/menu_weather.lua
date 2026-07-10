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
local boolValue = Shared.boolValue
local boolOptions = Shared.boolOptions

local weatherActionLocked = false

local function weatherOptions()
    local options = {}

    for _, weather in ipairs(PR.Weather.Types or {}) do
        options[#options + 1] = {
            value = weather.value,
            label = weather.label,
        }
    end

    return options
end

local function weatherLabel(value)
    for _, weather in ipairs(PR.Weather.Types or {}) do
        if weather.value == value then return weather.label end
    end

    return tostring(value or t('common.none'))
end

local function weatherSnapshot(weatherEvent)
    weatherEvent = type(weatherEvent) == 'table' and weatherEvent or {}

    return {
        weather = weatherEvent.weather,
        time = weatherEvent.time,
    }
end

local function fetchWeatherState()
    local ok, payload = awaitServer(PR.Weather.Callbacks.getState)
    if not ok then
        notifyFailure('notify.weather.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.weatherList = type(payload.weatherList) == 'table' and payload.weatherList or {}
    payload.currentTime = type(payload.currentTime) == 'table' and payload.currentTime or { hour = 0, minute = 0 }
    payload.timeScale = tonumber(payload.timeScale) or 0
    payload.freezeTime = payload.freezeTime == true

    return payload
end

local function runWeatherAction(callbackName, failureLocale, ...)
    if weatherActionLocked then return false end
    weatherActionLocked = true

    local ok, response = awaitServer(callbackName, ...)
    if not ok then
        notifyFailure(failureLocale or 'notify.weather.action_failed', response)
    end

    SetTimeout(1000, function()
        weatherActionLocked = false
    end)

    return ok, response
end

function Menu.openWeatherTimeMenu()
    local state = fetchWeatherState()
    if not state then return false end

    local current = state.weatherList[1] or state.currentWeather or {}
    local timeText = ('%02d:%02d'):format(tonumber(state.currentTime.hour) or 0, tonumber(state.currentTime.minute) or 0)

    showContext({
        id = 'forge_core_weather_time',
        title = t('menu.weather.title'),
        menu = 'forge_core_server_settings',
        options = {
            {
                title = t('menu.weather.forecast'),
                description = t('menu.weather.forecast_summary', {
                    current = weatherLabel(current.weather),
                    count = tostring(#state.weatherList),
                }),
                icon = 'cloud-sun',
                arrow = true,
                onSelect = function()
                    Menu.openWeatherForecastMenu(state)
                end,
            },
            {
                title = t('menu.weather.add_next'),
                description = t('menu.weather.add_next_description'),
                icon = 'cloud-plus',
                onSelect = function()
                    Menu.openWeatherAddEditor()
                end,
            },
            {
                title = t('menu.weather.time'),
                description = t('menu.weather.time_summary', {
                    time = timeText,
                    freeze = state.freezeTime and t('common.yes') or t('common.no'),
                    scale = tostring(state.timeScale),
                }),
                icon = 'clock',
                arrow = true,
                onSelect = function()
                    Menu.openTimeSettingsMenu(state)
                end,
            },
        },
    })

    return true
end

function Menu.openWeatherForecastMenu(state)
    state = state or fetchWeatherState()
    if not state then return false end

    local options = {}
    local startsIn = 0

    for index, weatherEvent in ipairs(state.weatherList or {}) do
        local eventIndex = index
        local eventData = weatherSnapshot(weatherEvent)
        local isCurrent = eventIndex == 1
        local description = isCurrent and
            t('menu.weather.current_description', { duration = tostring(eventData.time or 0) }) or
            t('menu.weather.next_description', {
                starts = tostring(startsIn),
                duration = tostring(eventData.time or 0),
            })

        options[#options + 1] = {
            title = isCurrent and
                t('menu.weather.current_weather', { weather = weatherLabel(eventData.weather) }) or
                t('menu.weather.next_weather', { weather = weatherLabel(eventData.weather) }),
            description = description,
            icon = isCurrent and 'cloud-sun' or 'cloud',
            arrow = true,
            onSelect = function()
                Menu.openWeatherEventMenu(eventIndex, eventData)
            end,
        }

        startsIn = startsIn + (tonumber(eventData.time) or 0)
    end

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.weather.no_forecast'),
            icon = 'circle-info',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_weather_forecast',
        title = t('menu.weather.forecast'),
        menu = 'forge_core_weather_time',
        options = options,
    })

    return true
end

function Menu.openWeatherEventMenu(index, weatherEvent)
    weatherEvent = type(weatherEvent) == 'table' and weatherEvent or {}

    showContext({
        id = 'forge_core_weather_event_' .. tostring(index),
        title = index == 1 and t('menu.weather.current') or t('menu.weather.queued'),
        menu = 'forge_core_weather_forecast',
        options = {
            {
                title = t('menu.weather.event_info'),
                description = t('menu.weather.event_description', {
                    weather = weatherLabel(weatherEvent.weather),
                    duration = tostring(weatherEvent.time or 0),
                }),
                icon = 'circle-info',
                disabled = true,
            },
            {
                title = t('menu.weather.change_weather'),
                icon = 'cloud',
                onSelect = function()
                    Menu.openWeatherTypeEditor(index, weatherEvent)
                end,
            },
            {
                title = t('menu.weather.change_duration'),
                icon = 'hourglass',
                onSelect = function()
                    Menu.openWeatherDurationEditor(index, weatherEvent)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_weather_header'),
                        content = t('dialogs.remove_weather_content'),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        runWeatherAction(PR.Weather.Callbacks.removeWeather, 'notify.weather.remove_failed', index, weatherEvent)
                    end

                    SetTimeout(500, function()
                        Menu.openWeatherTimeMenu()
                    end)
                end,
            },
        },
    })
end

function Menu.openWeatherTypeEditor(index, weatherEvent)
    local result = inputDialog(t('menu.weather.change_weather'), {
        {
            type = 'select',
            label = t('inputs.weather_type'),
            options = weatherOptions(),
            default = weatherEvent and weatherEvent.weather,
            required = true,
            searchable = true,
        },
    })

    if not result then return Menu.openWeatherEventMenu(index, weatherEvent) end

    runWeatherAction(PR.Weather.Callbacks.setWeather, 'notify.weather.save_failed', index, result[1], weatherEvent)

    SetTimeout(500, function()
        Menu.openWeatherTimeMenu()
    end)
end

function Menu.openWeatherDurationEditor(index, weatherEvent)
    local result = inputDialog(t('menu.weather.change_duration'), {
        {
            type = 'number',
            label = t('inputs.weather_duration'),
            default = tonumber(weatherEvent and weatherEvent.time) or 10,
            required = true,
            min = 1,
            max = 1440,
        },
    })

    if not result then return Menu.openWeatherEventMenu(index, weatherEvent) end

    runWeatherAction(PR.Weather.Callbacks.setDuration, 'notify.weather.save_failed', index, tonumber(result[1]) or 1, weatherEvent)

    SetTimeout(500, function()
        Menu.openWeatherTimeMenu()
    end)
end

function Menu.openWeatherAddEditor()
    local result = inputDialog(t('menu.weather.add_next'), {
        {
            type = 'select',
            label = t('inputs.weather_type'),
            options = weatherOptions(),
            default = 'CLEAR',
            required = true,
            searchable = true,
        },
        {
            type = 'number',
            label = t('inputs.weather_duration'),
            default = 10,
            required = true,
            min = 1,
            max = 1440,
        },
    })

    if not result then return Menu.openWeatherTimeMenu() end

    runWeatherAction(PR.Weather.Callbacks.addWeather, 'notify.weather.save_failed', {
        weather = result[1],
        duration = tonumber(result[2]) or 10,
        index = 2,
    })

    SetTimeout(500, function()
        Menu.openWeatherTimeMenu()
    end)
end

function Menu.openTimeSettingsMenu(state)
    state = state or fetchWeatherState()
    if not state then return false end

    local currentTime = state.currentTime or { hour = 0, minute = 0 }

    showContext({
        id = 'forge_core_time_settings',
        title = t('menu.weather.time'),
        menu = 'forge_core_weather_time',
        options = {
            {
                title = t('menu.weather.set_time'),
                description = ('%02d:%02d'):format(tonumber(currentTime.hour) or 0, tonumber(currentTime.minute) or 0),
                icon = 'clock',
                onSelect = function()
                    Menu.openSetTimeEditor(currentTime)
                end,
            },
            {
                title = t('menu.weather.presets'),
                description = t('menu.weather.presets_description'),
                icon = 'sun',
                arrow = true,
                onSelect = function()
                    Menu.openTimePresetMenu()
                end,
            },
            {
                title = t('menu.weather.freeze_time'),
                description = state.freezeTime and t('common.active') or t('common.inactive'),
                icon = 'snowflake',
                onSelect = function()
                    Menu.openFreezeTimeEditor(state.freezeTime)
                end,
            },
            {
                title = t('menu.weather.time_scale'),
                description = t('menu.weather.time_scale_summary', { scale = tostring(state.timeScale) }),
                icon = 'gauge',
                onSelect = function()
                    Menu.openTimeScaleEditor(state.timeScale)
                end,
            },
        },
    })

    return true
end

function Menu.openSetTimeEditor(currentTime)
    currentTime = type(currentTime) == 'table' and currentTime or {}

    local result = inputDialog(t('menu.weather.set_time'), {
        {
            type = 'number',
            label = t('inputs.time_hour'),
            default = tonumber(currentTime.hour) or 12,
            required = true,
            min = 0,
            max = 23,
        },
        {
            type = 'number',
            label = t('inputs.time_minute'),
            default = tonumber(currentTime.minute) or 0,
            required = true,
            min = 0,
            max = 59,
        },
    })

    if not result then return Menu.openTimeSettingsMenu() end

    runWeatherAction(PR.Weather.Callbacks.setTime, 'notify.weather.time_failed', tonumber(result[1]) or 0, tonumber(result[2]) or 0)

    SetTimeout(500, function()
        Menu.openTimeSettingsMenu()
    end)
end

function Menu.openTimePresetMenu()
    local presets = {
        { title = t('menu.weather.morning'), icon = 'sunrise', hour = 9, minute = 0 },
        { title = t('menu.weather.noon'), icon = 'sun', hour = 12, minute = 0 },
        { title = t('menu.weather.evening'), icon = 'sunset', hour = 18, minute = 0 },
        { title = t('menu.weather.night'), icon = 'moon', hour = 23, minute = 0 },
    }
    local options = {}

    for _, preset in ipairs(presets) do
        options[#options + 1] = {
            title = preset.title,
            description = ('%02d:%02d'):format(preset.hour, preset.minute),
            icon = preset.icon,
            onSelect = function()
                runWeatherAction(PR.Weather.Callbacks.setTime, 'notify.weather.time_failed', preset.hour, preset.minute)

                SetTimeout(500, function()
                    Menu.openTimeSettingsMenu()
                end)
            end,
        }
    end

    showContext({
        id = 'forge_core_time_presets',
        title = t('menu.weather.presets'),
        menu = 'forge_core_time_settings',
        options = options,
    })
end

function Menu.openFreezeTimeEditor(currentValue)
    local result = inputDialog(t('menu.weather.freeze_time'), {
        {
            type = 'select',
            label = t('inputs.freeze_time'),
            options = boolOptions(),
            default = boolDefault(currentValue),
            required = true,
        },
    })

    if not result then return Menu.openTimeSettingsMenu() end

    runWeatherAction(PR.Weather.Callbacks.setFreezeTime, 'notify.weather.time_failed', boolValue(result[1]))

    SetTimeout(500, function()
        Menu.openTimeSettingsMenu()
    end)
end

function Menu.openTimeScaleEditor(currentScale)
    local result = inputDialog(t('menu.weather.time_scale'), {
        {
            type = 'number',
            label = t('inputs.time_scale'),
            default = tonumber(currentScale) or 4000,
            required = true,
            min = 2000,
            max = 60000,
        },
    })

    if not result then return Menu.openTimeSettingsMenu() end

    runWeatherAction(PR.Weather.Callbacks.setTimeScale, 'notify.weather.time_failed', tonumber(result[1]) or 4000)

    SetTimeout(500, function()
        Menu.openTimeSettingsMenu()
    end)
end
