-- Whole installed service; no automatic start, JSON load, listener or worker.
return function(ports)
    local PR,library,native=assert(ports.config),assert(ports.library),assert(ports.native)
    local services,translate=assert(ports.services),assert(ports.translate)
    local api={Events={}}
    local function listen(name,handler)api.Events[#api.Events+1]={name=name,handler=handler,network=false}end
    local GetCurrentResourceName=assert(native.GetCurrentResourceName,'GetCurrentResourceName port required')
    local IsPlayerAceAllowed=assert(native.IsPlayerAceAllowed,'IsPlayerAceAllowed port required')
    local Wait=assert(native.Wait,'Wait port required')
local Service = {
    settings = {},
}

local resourceName = GetCurrentResourceName()

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
        title = data.title or translate('password.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function readJson(path, fallback)
    return library.loadJsonRecovery(path) or fallback
end

local function writeJson(path, data)
    return library.saveJsonRecovery(path, data)
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function normalizeSettings(settings)
    settings = type(settings) == 'table' and settings or {}

    return {
        enabled = boolValue(settings.enabled, PR.Password.Defaults.enabled),
        password = tostring(settings.password or PR.Password.Defaults.password or ''),
        supportLink = tostring(settings.supportLink or settings.support_link or PR.Password.Defaults.supportLink or ''),
        cardTitle = tostring(settings.cardTitle or settings.card_title or PR.Password.Defaults.cardTitle or ''),
        cardDescription = tostring(settings.cardDescription or settings.card_description or PR.Password.Defaults.cardDescription or ''),
        placeholder = tostring(settings.placeholder or PR.Password.Defaults.placeholder or ''),
        submitText = tostring(settings.submitText or settings.submit_text or PR.Password.Defaults.submitText or ''),
    }
end

local function canManage(source)
    if services.JobService and services.JobService.canManage then
        return services.JobService.canManage(source)
    end

    if source == 0 then return true end
    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function escapeCardText(value)
    value = tostring(value or '')
    value = value:gsub('\\', '\\\\')
    value = value:gsub('"', '\\"')
    value = value:gsub('\r', '')
    value = value:gsub('\n', '\\n')
    return value
end

local function buildPasswordCard()
    local settings = Service.getSettings()
    local cardTitle = settings.cardTitle ~= '' and settings.cardTitle or translate('password.card_title')
    local cardDescription = settings.cardDescription ~= '' and settings.cardDescription or translate('password.card_description')
    local placeholder = settings.placeholder ~= '' and settings.placeholder or translate('password.placeholder')
    local submitText = settings.submitText ~= '' and settings.submitText or translate('password.submit')

    return ([[
{
    "type": "AdaptiveCard",
    "body": [
        {
            "type": "TextBlock",
            "text": "%s",
            "weight": "bolder",
            "size": "medium"
        },
        {
            "type": "TextBlock",
            "text": "%s",
            "wrap": true
        },
        {
            "type": "Input.Text",
            "id": "password",
            "placeholder": "%s",
            "style": "password"
        }
    ],
    "actions": [
        {
            "type": "Action.Submit",
            "title": "%s"
        }
    ],
    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
    "version": "1.0"
}
]]):format(
        escapeCardText(cardTitle),
        escapeCardText(cardDescription),
        escapeCardText(placeholder),
        escapeCardText(submitText)
    )
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getSettings()
    return normalizeSettings(Service.settings)
end

function Service.getSafeSettings()
    local settings = Service.getSettings()

    return {
        enabled = settings.enabled,
        password = settings.password ~= '' and '********' or '',
        supportLink = settings.supportLink,
        cardTitle = settings.cardTitle,
        cardDescription = settings.cardDescription,
        placeholder = settings.placeholder,
        submitText = settings.submitText,
    }
end

function Service.load()
    Service.settings = normalizeSettings(readJson(PR.Password.Storage.file, PR.Password.Defaults))
    return Service.getSettings()
end

function Service.save(source, settings)
    if not canManage(source) then return false, 'no_permission' end

    local normalized = normalizeSettings(settings)
    if normalized.password == '********' then
        normalized.password = tostring(Service.settings.password or '')
    end

    if normalized.enabled and normalized.password == '' then
        return false, 'empty_password'
    end

    local saved = writeJson(PR.Password.Storage.file, normalized)
    if not saved then return false, 'save_failed' end
    Service.settings = normalized

    notify(source, {
        description = translate('notify.password.saved'),
        type = 'success',
    })

    return true, Service.getSettings()
end

function Service.start()
    Service.load()
    debug('success', translate('debug.password.started'))
    return true
end

listen('playerConnecting', function(_, _, deferrals)
    local settings = Service.getSettings()
    if not settings.enabled then return end
    if settings.password == '' then return end

    deferrals.defer()
    Wait(0)
    deferrals.update(translate('password.deferral_update'))
    Wait(1000)

    deferrals.presentCard(buildPasswordCard(), function(data)
        data = type(data) == 'table' and data or {}

        if tostring(data.password or '') == settings.password then
            deferrals.done()
            return
        end

        deferrals.done(translate('password.wrong_password', {
            support = settings.supportLink ~= '' and settings.supportLink or translate('password.no_support_link'),
        }))
    end)
end)

library.wrapJsonMutations(PR.Password.Storage.file, Service, { 'save' })

api.Service = Service

    return api
end
