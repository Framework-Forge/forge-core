ForgeCore = ForgeCore or {}

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
    local debugApi = pr_lib and pr_lib.debug
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

    if ForgeCore.StaffService and ForgeCore.StaffService.canManage then
        return ForgeCore.StaffService.canManage(source) == true
    end

    return ForgeCore.JobService and ForgeCore.JobService.canManage
        and ForgeCore.JobService.canManage(source) == true
end

local function saveHistory(draft)
    return pr_lib.saveJsonRecovery(PR.DatabaseBackup.Storage.historyFile, draft) == true
end

local function addHistory(entry)
    local draft = pr_lib.jsonDraft(Service.history, {})
    table.insert(draft, 1, entry)

    local limit = math.max(1, tonumber(PR.DatabaseBackup.Storage.maxHistory) or 50)
    while #draft > limit do
        table.remove(draft)
    end

    if not saveHistory(draft) then
        debug('warn', ForgeCore.t('debug.database_backup.history_save_failed'))
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

    local stored = pr_lib.loadJsonRecovery(PR.DatabaseBackup.Storage.historyFile)
    Service.history = normalizeHistory(stored)
    Service.started = true

    debug('success', ForgeCore.t('debug.database_backup.started'))
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
    if not pr_lib.database or not pr_lib.database.backup or type(pr_lib.database.backup.create) ~= 'function' then
        return false, 'backup_unavailable'
    end

    Service.running = true

    local timestamp = os.time()
    local filename = ('database_%s_%s.sql'):format(os.date('%Y%m%d_%H%M%S', timestamp), mode)
    local path = ('%s/%s'):format(PR.DatabaseBackup.Storage.directory, filename)
    local called, ok, result = pcall(function()
        return pr_lib.database.backup.create({
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
        createdAt = os.date('%Y-%m-%d %H:%M:%S', timestamp),
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
        debug('error', ForgeCore.t('debug.database_backup.failed', {
            admin = entry.adminName,
            mode = mode,
            error = entry.error,
        }))
        return false, entry.error
    end

    debug('success', ForgeCore.t('debug.database_backup.created', {
        admin = entry.adminName,
        mode = mode,
        path = entry.path,
        tables = tostring(entry.tables),
        rows = tostring(entry.rows),
    }))

    return true, entry
end

ForgeCore.DatabaseBackupService = Service
