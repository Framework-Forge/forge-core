ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    settings = {},
    previousCoords = {},
    remainingSeconds = {},
    lastNotify = {},
    warnedSeconds = {},
}

local resourceName = GetCurrentResourceName()
local warningTimes = {
    [900] = true,
    [600] = true,
    [300] = true,
    [150] = true,
    [60] = true,
    [30] = true,
    [20] = true,
    [10] = true,
}

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

    local description = data.description or ''
    local key = ('%s:%s:%s'):format(source, data.type or 'inform', description)
    local now = GetGameTimer()
    local lastSent = Service.lastNotify[key] or 0
    local cooldown = tonumber(data.cooldown) or 1500

    if now - lastSent < cooldown then return end
    Service.lastNotify[key] = now

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('afk.title'),
        description = description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function readJson(path, fallback)
    local content = LoadResourceFile(resourceName, path)
    if type(content) ~= 'string' or content == '' then return fallback end

    local ok, decoded = pcall(json.decode, content)
    if ok and type(decoded) == 'table' then return decoded end

    debug('warn', ForgeCore.t('debug.storage.invalid_json', { path = path }))
    return fallback
end

local function writeJson(path, data)
    local ok, encoded = pcall(json.encode, data or {})
    if not ok or not encoded then
        debug('error', ForgeCore.t('debug.storage.encode_failed', { error = tostring(encoded) }))
        return false
    end

    local saved = SaveResourceFile(resourceName, path, encoded, -1)
    if not saved then
        debug('error', ForgeCore.t('debug.storage.save_failed', { path = path }))
    end

    return saved ~= false and saved ~= nil
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function normalizeSettings(settings)
    settings = type(settings) == 'table' and settings or {}

    local minutes = math.floor(tonumber(settings.minutes) or PR.Afk.Defaults.minutes)
    if minutes < 1 then minutes = 1 end
    if minutes > 1440 then minutes = 1440 end

    return {
        enabled = boolValue(settings.enabled, PR.Afk.Defaults.enabled),
        minutes = minutes,
    }
end

local function canManage(source)
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end

    if source == 0 then return true end
    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function resetPlayer(source)
    Service.previousCoords[source] = nil
    Service.remainingSeconds[source] = nil
    Service.warnedSeconds[source] = nil
end

local function isPlayerLoggedIn(source)
    local state = Player(source) and Player(source).state
    if state and state.isLoggedIn == false then return false end

    return true
end

local function isSamePosition(left, right)
    if not left or not right then return false end

    return #(left - right) <= 0.05
end

local function formatWarning(seconds)
    if seconds >= 60 then
        return ForgeCore.t('notify.afk.warning_minutes', {
            minutes = tostring(math.ceil(seconds / 60)),
        })
    end

    return ForgeCore.t('notify.afk.warning_seconds', {
        seconds = tostring(seconds),
    })
end

local function processPlayer(source)
    if not isPlayerLoggedIn(source) then
        resetPlayer(source)
        return
    end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        resetPlayer(source)
        return
    end

    local currentCoords = GetEntityCoords(ped)
    local maxSeconds = Service.settings.minutes * 60

    if not Service.remainingSeconds[source] then
        Service.remainingSeconds[source] = maxSeconds
    end

    if isSamePosition(currentCoords, Service.previousCoords[source]) then
        local remaining = Service.remainingSeconds[source]

        if remaining <= 0 then
            DropPlayer(source, ForgeCore.t('notify.afk.kicked'))
            resetPlayer(source)
            return
        end

        Service.warnedSeconds[source] = Service.warnedSeconds[source] or {}

        if remaining < maxSeconds and warningTimes[remaining] and not Service.warnedSeconds[source][remaining] then
            Service.warnedSeconds[source][remaining] = true

            notify(source, {
                description = formatWarning(remaining),
                type = 'error',
                cooldown = 2500,
            })
        end

        Service.remainingSeconds[source] = remaining - 1
    else
        Service.remainingSeconds[source] = maxSeconds
        Service.warnedSeconds[source] = {}
    end

    Service.previousCoords[source] = currentCoords
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getSettings()
    return normalizeSettings(Service.settings)
end

function Service.load()
    Service.settings = normalizeSettings(readJson(PR.Afk.Storage.file, PR.Afk.Defaults))
    return Service.getSettings()
end

function Service.save(source, settings)
    if not canManage(source) then return false, 'no_permission' end

    Service.settings = normalizeSettings(settings)
    local saved = writeJson(PR.Afk.Storage.file, Service.settings)
    if not saved then return false, 'save_failed' end

    Service.previousCoords = {}
    Service.remainingSeconds = {}
    Service.warnedSeconds = {}

    notify(source, {
        description = ForgeCore.t('notify.afk.saved'),
        type = 'success',
        cooldown = 2500,
    })

    return true, Service.getSettings()
end

function Service.start()
    if Service.started then return true end

    Service.started = true
    Service.load()

    CreateThread(function()
        while Service.started do
            Wait(1000)

            if Service.settings.enabled then
                for _, rawSource in ipairs(GetPlayers()) do
                    processPlayer(tonumber(rawSource))
                end
            else
                Service.previousCoords = {}
                Service.remainingSeconds = {}
            end
        end
    end)

    debug('success', ForgeCore.t('debug.afk.started'))
    return true
end

AddEventHandler('playerDropped', function()
    resetPlayer(source)
end)

ForgeCore.AfkService = Service
