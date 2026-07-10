ForgeCore = ForgeCore or {}

local Storage = {}
local resourceName = GetCurrentResourceName()

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

local function encodeJson(data)
    local ok, encoded = pcall(json.encode, data or {})
    if ok and encoded then return encoded end

    debug('error', ForgeCore.t('debug.storage.encode_failed', { error = tostring(encoded) }))
    return '{}'
end

local function decodeJson(content, fallback, path)
    if type(content) ~= 'string' or content == '' then return fallback end

    local ok, decoded = pcall(json.decode, content)
    if ok and type(decoded) == 'table' then return decoded end

    debug('warn', ForgeCore.t('debug.storage.invalid_json', { path = path }))
    return fallback
end

local function readJson(path, fallback)
    return decodeJson(LoadResourceFile(resourceName, path), fallback or {}, path)
end

local function countTable(data)
    local total = 0

    for _ in pairs(data or {}) do
        total = total + 1
    end

    return total
end

local function writeJson(path, data)
    local saved = SaveResourceFile(resourceName, path, encodeJson(data), -1)
    if not saved then
        debug('error', ForgeCore.t('debug.storage.save_failed', { path = path }))
    end

    return saved ~= false and saved ~= nil
end

function Storage.load()
    local cfg = PR.Job.Storage
    local jobs = readJson(cfg.jobsFile, {})
    local gangs = readJson(cfg.gangsFile, {})

    debug('info', ForgeCore.t('debug.storage.loaded', {
        jobs = tostring(type(jobs) == 'table' and countTable(jobs) or 0),
        gangs = tostring(type(gangs) == 'table' and countTable(gangs) or 0),
    }))

    return jobs, gangs
end

function Storage.save(jobs, gangs)
    local cfg = PR.Job.Storage
    local jobsSaved = writeJson(cfg.jobsFile, jobs or {})
    local gangsSaved = writeJson(cfg.gangsFile, gangs or {})

    return jobsSaved and gangsSaved
end

function Storage.loadPayments()
    return readJson(PR.Job.Payments.file, {})
end

function Storage.savePayments(settings)
    return writeJson(PR.Job.Payments.file, settings or {})
end

ForgeCore.JobStorage = Storage
