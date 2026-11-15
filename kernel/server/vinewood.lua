-- Same installed policy and PR persistence; never auto-starts or owns another world state.
return function(ports)
    local PR,library,native=assert(ports.config),assert(ports.library),assert(ports.native)
    local services,translate,world=assert(ports.services),assert(ports.translate),assert(ports.world)
    local IsPlayerAceAllowed=assert(native.IsPlayerAceAllowed)
    local GetGameTimer=assert(native.GetGameTimer)
local Service = {
    started = false,
    settings = {},
}

local function debug(level, message)
    local debugApi = library and library.debug
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
    if not library or not library.notify or not library.notify.NotifyPlayer then return end

    library.notify.NotifyPlayer(source, {
        title = data.title or translate('vinewood.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if services.JobService and services.JobService.canManage then
        return services.JobService.canManage(source)
    end

    if source == 0 then return true end
    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function clone(value)
    return library and library.table and library.table.clone and library.table.clone(value) or value
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
    value = library and library.utils and library.utils.trim and library.utils.trim(value) or tostring(value or '')
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
    local loaded = library.loadJsonRecovery(PR.Vinewood.Storage.file, true)
    if type(loaded) ~= 'table' then return clone(PR.Vinewood.Defaults) end
    return loaded
end

local function writeSettings(settings)
    local saved = library.saveJsonRecovery(PR.Vinewood.Storage.file, settings, { indent = true })
    return saved == true or type(saved) == 'table'
end

local function publish()
    local settings = Service.getSettings()
    world.publish('vinewood',settings)
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

    local draft = normalizeSettings(settings)
    if not writeSettings(draft) then return false, 'save_failed' end

    Service.settings = draft
    publish()
    notify(source, {
        description = translate('notify.vinewood.saved'),
        type = 'success',
    })

    return true, Service.getSettings()
end

function Service.start()
    if Service.started then return true end
    Service.started = true

    Service.load()
    debug('success', translate('debug.vinewood.started'))

    return true
end

library.wrapJsonMutations(PR.Vinewood.Storage.file, Service, {
    'save',
})

return Service
end
