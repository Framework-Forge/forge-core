ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    settings = {},
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

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('vinewood.title'),
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

local function clone(value)
    return pr_lib and pr_lib.table and pr_lib.table.clone and pr_lib.table.clone(value) or value
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function normalizeHexColor(value)
    value = tostring(value or PR.Vinewood.Defaults.color):upper():gsub('%s+', '')
    if value:sub(1, 1) ~= '#' then value = '#' .. value end

    local hex = value:sub(2)
    if #hex == 3 then
        hex = hex:gsub('.', '%0%0')
    end

    if #hex ~= 6 or hex:find('[^0-9A-F]') then
        return PR.Vinewood.Defaults.color
    end

    return '#' .. hex
end

local function normalizeText(value)
    value = pr_lib and pr_lib.utils and pr_lib.utils.trim and pr_lib.utils.trim(value) or tostring(value or '')
    value = tostring(value or ''):upper()
    value = value:gsub('[^A-Z ]', '')

    local maxLength = #(PR.Vinewood.Coords or {})
    if #value > maxLength then
        value = value:sub(1, maxLength)
    end

    if value == '' then value = PR.Vinewood.Defaults.text end
    return value
end

local function normalizeSettings(settings)
    settings = type(settings) == 'table' and settings or {}

    return {
        enabled = boolValue(settings.enabled, PR.Vinewood.Defaults.enabled),
        text = normalizeText(settings.text),
        color = normalizeHexColor(settings.color),
        revision = GetGameTimer(),
    }
end

local function readSettings()
    local loaded = pr_lib.loadJson(PR.Vinewood.Storage.file, true)
    if type(loaded) ~= 'table' then return clone(PR.Vinewood.Defaults) end
    return loaded
end

local function writeSettings(settings)
    local saved = pr_lib.saveJson(PR.Vinewood.Storage.file, settings, { indent = true })
    return saved == true or type(saved) == 'table'
end

local function publish()
    local settings = Service.getSettings()
    GlobalState.forgeVinewood = settings
    GlobalState.pinelVinewood = settings
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getSettings()
    return normalizeSettings(Service.settings)
end

function Service.load()
    Service.settings = normalizeSettings(readSettings())
    publish()
    return Service.getSettings()
end

function Service.save(source, settings)
    if not canManage(source) then return false, 'no_permission' end

    Service.settings = normalizeSettings(settings)
    if not writeSettings(Service.settings) then return false, 'save_failed' end

    publish()
    notify(source, {
        description = ForgeCore.t('notify.vinewood.saved'),
        type = 'success',
    })

    return true, Service.getSettings()
end

function Service.start()
    if Service.started then return true end
    Service.started = true

    Service.load()
    debug('success', ForgeCore.t('debug.vinewood.started'))

    return true
end

ForgeCore.VinewoodService = Service
