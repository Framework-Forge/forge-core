ForgeCore = ForgeCore or {}

local Sync = {
    registeredJobs = {},
    registeredGangs = {},
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

local function qbxReady()
    return GetResourceState('qbx_core'):find('start') ~= nil
end

local function qbxCall(method, ...)
    if not qbxReady() then
        debug('warn', ForgeCore.t('debug.qbx.unavailable', { method = method }))
        return false
    end

    local args = { ... }
    local ok, result = pcall(function()
        if method == 'CreateJobs' then
            return exports.qbx_core:CreateJobs(args[1], args[2])
        elseif method == 'CreateGangs' then
            return exports.qbx_core:CreateGangs(args[1], args[2])
        elseif method == 'RemoveJob' then
            return exports.qbx_core:RemoveJob(args[1], args[2])
        elseif method == 'RemoveGang' then
            return exports.qbx_core:RemoveGang(args[1], args[2])
        end

        return false, 'unknown_method'
    end)

    if not ok then
        debug('error', ForgeCore.t('debug.qbx.method_failed', { method = method, error = tostring(result) }))
        return false
    end

    return result ~= false
end

local function cloneGrade(grade)
    local out = {}

    for key, value in pairs(grade or {}) do
        out[key] = value
    end

    return out
end

local function qbxGrades(grades)
    local out = {}
    local highestGrade = -1

    for key, grade in pairs(grades or {}) do
        local level = tonumber(key) or key
        out[level] = cloneGrade(grade)

        if type(level) == 'number' and level > highestGrade then
            highestGrade = level
        end
    end

    if highestGrade >= 0 and out[highestGrade] then
        out[highestGrade].isboss = out[highestGrade].isboss ~= false
        out[highestGrade].bankAuth = out[highestGrade].bankAuth ~= false
    end

    return out
end

local function buildJobPayload(jobs)
    local payload = {}

    for name, job in pairs(jobs or {}) do
        payload[name] = {
            label = job.label or name,
            type = job.jobtype,
            defaultDuty = job.defaultDuty ~= false,
            offDutyPay = job.offDutyPay == true,
            grades = qbxGrades(job.grades),
        }
    end

    return payload
end

local function buildGangPayload(gangs)
    local payload = {}

    for name, gang in pairs(gangs or {}) do
        payload[name] = {
            label = gang.label or name,
            grades = qbxGrades(gang.grades),
        }
    end

    return payload
end

local function removeMissing(previous, current, protected, method)
    for name in pairs(previous) do
        if not current[name] and not protected[name] then
            qbxCall(method, name)
        end
    end
end

function Sync.syncAll()
    local registry = ForgeCore.JobRegistry
    if not registry then return false end

    local jobs = registry.getJobs()
    local gangs = registry.getGangs()
    local jobPayload = buildJobPayload(jobs)
    local gangPayload = buildGangPayload(gangs)

    if next(jobPayload) then
        qbxCall('CreateJobs', jobPayload)
    end

    if next(gangPayload) then
        qbxCall('CreateGangs', gangPayload)
    end

    removeMissing(Sync.registeredJobs, jobPayload, PR.Job.Protected.jobs, 'RemoveJob')
    removeMissing(Sync.registeredGangs, gangPayload, PR.Job.Protected.gangs, 'RemoveGang')

    Sync.registeredJobs = {}
    Sync.registeredGangs = {}

    for name in pairs(jobPayload) do
        Sync.registeredJobs[name] = true
    end

    for name in pairs(gangPayload) do
        Sync.registeredGangs[name] = true
    end

    debug('info', ForgeCore.t('debug.qbx.synced', {
        jobs = tostring(#registry.list('job')),
        gangs = tostring(#registry.list('gang')),
    }))

    return true
end

ForgeCore.JobQbxSync = Sync
