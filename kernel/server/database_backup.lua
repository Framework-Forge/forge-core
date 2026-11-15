-- Whole installed service; no automatic start, JSON load, listener or worker.
return function(ports)
    local PR,library,native=assert(ports.config),assert(ports.library),assert(ports.native)
    local services,translate=assert(ports.services),assert(ports.translate)
    local api={Events={}}
    local function listen(name,handler)api.Events[#api.Events+1]={name=name,handler=handler,network=false}end
    local GetCurrentResourceName=assert(native.GetCurrentResourceName,'GetCurrentResourceName port required')
    local GetPlayerName=assert(native.GetPlayerName,'GetPlayerName port required')
local Service = {
    history = {},
    running = false,
    started = false,
}

local validModes = {
    schema = true,
    data = true,
    both = true,
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

local function canManage(source)
    if source == 0 then return true end

    if services.StaffService and services.StaffService.canManage then
        return services.StaffService.canManage(source) == true
    end

    return services.JobService and services.JobService.canManage
        and services.JobService.canManage(source) == true
end

local function saveHistory(draft)
    return library.saveJsonRecovery(PR.DatabaseBackup.Storage.historyFile, draft) == true
end

local function addHistory(entry)
    local draft = library.jsonDraft(Service.history, {})
    table.insert(draft, 1, entry)

    local limit = math.max(1, tonumber(PR.DatabaseBackup.Storage.maxHistory) or 50)
    while #draft > limit do
        table.remove(draft)
    end

    if not saveHistory(draft) then
        debug('warn', translate('debug.database_backup.history_save_failed'))
        return false
    end
    Service.history = draft
    return true
end

local function normalizeHistory(value)
    if type(value) ~= 'table' then return {} end

    local history = {}
    local limit = math.max(1, tonumber(PR.DatabaseBackup.Storage.maxHistory) or 50)

    for i = 1, math.min(#value, limit) do
        if type(value[i]) == 'table' then
            history[#history + 1] = value[i]
        end
    end

    return history
end

function Service.canManage(source)
    return canManage(source)
end

function Service.start()
    if Service.started then return true end

    local stored = library.loadJsonRecovery(PR.DatabaseBackup.Storage.historyFile)
    Service.history = normalizeHistory(stored)
    Service.started = true

    debug('success', translate('debug.database_backup.started'))
    return true
end

function Service.getHistory(source)
    if not canManage(source) then return false, 'no_permission' end
    if not Service.started then Service.start() end

    return true, {
        running = Service.running,
        entries = Service.history,
    }
end

function Service.create(source, mode)
    if not canManage(source) then return false, 'no_permission' end
    if Service.running then return false, 'backup_running' end

    mode = tostring(mode or ''):lower()
    if not validModes[mode] then return false, 'invalid_mode' end
    if not library.database or not library.database.backup or type(library.database.backup.create) ~= 'function' then
        return false, 'backup_unavailable'
    end

    Service.running = true

    local timestamp = native.time()
    local filename = ('database_%s_%s.sql'):format(native.date('%Y%m%d_%H%M%S', timestamp), mode)
    local path = ('%s/%s'):format(PR.DatabaseBackup.Storage.directory, filename)
    local called, ok, result = pcall(function()
        return library.database.backup.create({
            mode = mode,
            resource = GetCurrentResourceName(),
            path = path,
            rowsPerInsert = 100,
            dropTable = true,
        })
    end)

    Service.running = false

    if not called then
        result = tostring(ok)
        ok = false
    elseif ok == true and type(result) ~= 'table' then
        ok = false
        result = 'invalid_backup_result'
    end

    local entry = {
        timestamp = timestamp,
        createdAt = native.date('%Y-%m-%d %H:%M:%S', timestamp),
        adminSource = source,
        adminName = source > 0 and (GetPlayerName(source) or tostring(source)) or 'console',
        mode = mode,
        success = ok == true,
        path = ok and result.path or path,
        tables = ok and tonumber(result.tables) or 0,
        rows = ok and tonumber(result.rows) or 0,
        bytes = ok and tonumber(result.bytes) or 0,
        error = ok and nil or tostring(result or 'backup_failed'),
    }

    addHistory(entry)

    if not ok then
        debug('error', translate('debug.database_backup.failed', {
            admin = entry.adminName,
            mode = mode,
            error = entry.error,
        }))
        return false, entry.error
    end

    debug('success', translate('debug.database_backup.created', {
        admin = entry.adminName,
        mode = mode,
        path = entry.path,
        tables = tostring(entry.tables),
        rows = tostring(entry.rows),
    }))

    return true, entry
end

api.Service = Service

    return api
end
