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

local function readJson(path, fallback)
    return pr_lib.loadJsonRecovery(path) or fallback or {}
end

local function countTable(data)
    local total = 0

    for _ in pairs(data or {}) do
        total = total + 1
    end

    return total
end

local function writeJson(path, data)
    return pr_lib.saveJsonRecovery(path, data)
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
    return pr_lib.saveJsonBatch({ [cfg.jobsFile] = jobs or {}, [cfg.gangsFile] = gangs or {} })
end

function Storage.loadPayments()
    return readJson(PR.Job.Payments.file, {})
end

function Storage.savePayments(settings)
    return writeJson(PR.Job.Payments.file, settings or {})
end

ForgeCore.JobStorage = Storage
