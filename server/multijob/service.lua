ForgeCore = ForgeCore or {}

local Service = {
    settings = {},
}

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

local function notify(source, data)
    if not source or source <= 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('multijob.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function clone(value, seen)
    if type(value) ~= 'table' then return value end

    seen = seen or {}
    if seen[value] then return seen[value] end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[clone(key, seen)] = clone(item, seen)
    end

    return copy
end

local function readJson(path, fallback)
    return pr_lib.loadJsonRecovery(path) or fallback
end

local function writeJson(path, data)
    return pr_lib.saveJsonRecovery(path, data)
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function normalizeJobName(value)
    value = tostring(value or ''):lower()
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    value = value:gsub('%s+', '_')
    value = value:gsub('[^%w_%-]', '')
    return value
end

local function normalizeStringList(list)
    local result = {}
    local seen = {}

    for _, value in ipairs(type(list) == 'table' and list or {}) do
        local name = normalizeJobName(value)
        if name ~= '' and not seen[name] then
            result[#result + 1] = name
            seen[name] = true
        end
    end

    return result
end

local function normalizeSettings(settings)
    local defaults = PR.MultiJob.Defaults
    settings = type(settings) == 'table' and settings or {}

    local maxJobs = math.floor(tonumber(settings.maxJobs) or defaults.maxJobs or 3)
    if maxJobs < -1 then maxJobs = -1 end
    if maxJobs == 0 then maxJobs = 1 end
    if maxJobs > 50 then maxJobs = 50 end

    return {
        enabled = boolValue(settings.enabled, defaults.enabled),
        maxJobs = maxJobs,
        allowPlayerRemove = boolValue(settings.allowPlayerRemove, defaults.allowPlayerRemove),
        includeCurrentJob = boolValue(settings.includeCurrentJob, defaults.includeCurrentJob),
        blockedJobs = normalizeStringList(settings.blockedJobs or defaults.blockedJobs),
    }
end

local function blockedMap(settings)
    local map = {}
    for _, name in ipairs((settings or Service.getSettings()).blockedJobs or {}) do
        map[name] = true
    end
    return map
end

local function isBlocked(jobName)
    return blockedMap()[normalizeJobName(jobName)] == true
end

local function player(source)
    if not pr_lib or not pr_lib.framework or not pr_lib.framework.GetPlayer then return nil end
    return pr_lib.framework.GetPlayer(source)
end

local function jobData(jobName)
    jobName = normalizeJobName(jobName)
    if jobName == '' then return nil end

    local ok, job = pcall(function()
        return exports.qbx_core:GetJob(jobName)
    end)

    if ok and type(job) == 'table' then return job end

    if ForgeCore.JobRegistry and ForgeCore.JobRegistry.getJobs then
        return ForgeCore.JobRegistry.getJobs()[jobName]
    end
end

local function gradeData(job, grade)
    job = type(job) == 'table' and job or {}
    local grades = type(job.grades) == 'table' and job.grades or {}
    return grades[tostring(grade)] or grades[tonumber(grade)] or {}
end

local function validGrade(job, requested)
    job = type(job) == 'table' and job or {}
    local grades = type(job.grades) == 'table' and job.grades or {}
    local grade = math.max(0, math.floor(tonumber(requested) or 0))

    if grades[grade] or grades[tostring(grade)] then return grade end

    local highest = 0
    for key in pairs(grades) do
        local level = tonumber(key)
        if level and level > highest then highest = level end
    end

    return highest
end

local function currentJobEntry(source)
    local playerData = pr_lib.framework.GetPlayerData(source)
    if not playerData then return nil end

    local job = type(playerData.job) == 'table' and playerData.job or {}
    local name = normalizeJobName(job.name)
    if name == '' or isBlocked(name) then return nil end

    local grade = job.grade
    local level = type(grade) == 'table' and (grade.level or grade.grade) or grade

    return {
        name = name,
        grade = tonumber(level) or 0,
        label = job.label,
        onDuty = job.onduty == true,
    }
end

local function jobHasDutyPoint(jobName)
    local job = jobData(jobName)
    local stashes = type(job) == 'table' and type(job.stashes) == 'table' and job.stashes or {}

    for i = 1, #stashes do
        local point = stashes[i]
        local duty = type(point) == 'table' and type(point.duty) == 'table' and point.duty or nil
        if point and point.enabled ~= false and duty and duty.enabled == true then
            return true
        end
    end

    return false
end

local function metadataJobs(source)
    local jobs = pr_lib.framework.GetPlayerMetadata(source, 'multijob')
    return type(jobs) == 'table' and jobs or {}
end

local function setMetadataJobs(source, jobs)
    if not player(source) then return false, 'invalid_player' end

    local saved = pr_lib.framework.SetPlayerMetadata(source, 'multijob', jobs or {})
    if saved == false then return false, 'metadata_failed' end
    return true
end

local function normalizeJobsList(list)
    local result = {}
    local seen = {}

    for _, entry in ipairs(type(list) == 'table' and list or {}) do
        entry = type(entry) == 'table' and entry or {}
        local name = normalizeJobName(entry.name)
        local job = jobData(name)
        if name ~= '' and not isBlocked(name) and not seen[name] and job then
            result[#result + 1] = {
                name = name,
                grade = validGrade(job, entry.grade),
                label = tostring(entry.label or ''),
                addedAt = tonumber(entry.addedAt) or os.time(),
                stored = true,
            }
            seen[name] = true
        end
    end

    return result
end

local function hasJob(source, jobName)
    jobName = normalizeJobName(jobName)
    for _, entry in ipairs(normalizeJobsList(metadataJobs(source))) do
        if entry.name == jobName then return true, entry end
    end

    local current = currentJobEntry(source)
    if current and current.name == jobName then return true, current end

    return false
end

local function enrichJob(source, entry)
    local job = jobData(entry.name) or {}
    local grade = validGrade(job, entry.grade)
    local gradeInfo = gradeData(job, grade)
    local current = currentJobEntry(source)
    local active = current and current.name == entry.name

    return {
        name = entry.name,
        label = entry.label ~= '' and entry.label or job.label or entry.name,
        grade = grade,
        gradeLabel = gradeInfo.name or gradeInfo.label or tostring(grade),
        payment = tonumber(gradeInfo.payment) or 0,
        active = active == true,
        onDuty = active == true and current and current.onDuty == true or false,
        removable = Service.getSettings().allowPlayerRemove == true and entry.stored == true and active ~= true,
    }
end

function Service.canManage(source)
    return ForgeCore.JobService and ForgeCore.JobService.canManage(source)
end

function Service.getSettings()
    return normalizeSettings(next(Service.settings) and Service.settings or PR.MultiJob.Defaults)
end

function Service.load()
    Service.settings = normalizeSettings(readJson(PR.MultiJob.Storage.file, PR.MultiJob.Defaults))
    return Service.getSettings()
end

function Service.saveSettings(source, settings)
    if not Service.canManage(source) then return false, 'no_permission' end

    local draft = normalizeSettings(settings)
    if not writeJson(PR.MultiJob.Storage.file, draft) then return false, 'save_failed' end
    Service.settings = draft

    notify(source, {
        description = ForgeCore.t('notify.multijob.settings_saved'),
        type = 'success',
    })

    return true, Service.getSettings()
end

function Service.getPlayerJobs(source)
    local settings = Service.getSettings()
    if not settings.enabled then return false, 'disabled' end
    if not player(source) then return false, 'invalid_player' end

    local jobs = normalizeJobsList(metadataJobs(source))
    local current = settings.includeCurrentJob and currentJobEntry(source) or nil

    if current then
        local found = false
        for _, entry in ipairs(jobs) do
            if entry.name == current.name then
                found = true
                break
            end
        end

        if not found then table.insert(jobs, 1, current) end
    end

    local enriched = {}
    for _, entry in ipairs(jobs) do
        enriched[#enriched + 1] = enrichJob(source, entry)
    end

    return true, {
        settings = settings,
        jobs = enriched,
    }
end

function Service.addJob(source, target, jobName, grade)
    if source ~= target and not Service.canManage(source) then return false, 'no_permission' end
    local settings = Service.getSettings()
    if not settings.enabled then return false, 'disabled' end

    target = tonumber(target) or 0
    if target <= 0 or not player(target) then return false, 'invalid_player' end

    jobName = normalizeJobName(jobName)
    if jobName == '' or isBlocked(jobName) then return false, 'blocked_job' end

    local job = jobData(jobName)
    if not job then return false, 'invalid_job' end

    grade = validGrade(job, grade)
    local list = normalizeJobsList(metadataJobs(target))
    local updated = false

    for _, entry in ipairs(list) do
        if entry.name == jobName then
            entry.grade = grade
            entry.label = job.label or jobName
            updated = true
            break
        end
    end

    if not updated then
        if settings.maxJobs > 0 and #list >= settings.maxJobs then return false, 'max_jobs' end
        list[#list + 1] = {
            name = jobName,
            grade = grade,
            label = job.label or jobName,
            addedAt = os.time(),
        }
    end

    local ok, err = setMetadataJobs(target, list)
    if not ok then return false, err end

    notify(target, {
        description = ForgeCore.t('notify.multijob.added', { job = job.label or jobName }),
        type = 'success',
    })

    return true, select(2, Service.getPlayerJobs(target))
end

function Service.removeJob(source, target, jobName, selfRemove)
    if selfRemove then
        local settings = Service.getSettings()
        if not settings.allowPlayerRemove then return false, 'remove_disabled' end
        target = source
    elseif source ~= target and not Service.canManage(source) then
        return false, 'no_permission'
    end

    local settings = Service.getSettings()
    if not settings.enabled then return false, 'disabled' end

    target = tonumber(target) or 0
    if target <= 0 or not player(target) then return false, 'invalid_player' end

    jobName = normalizeJobName(jobName)
    local list = normalizeJobsList(metadataJobs(target))
    local removed

    for index = #list, 1, -1 do
        if list[index].name == jobName then
            removed = list[index]
            table.remove(list, index)
            break
        end
    end

    if not removed then return false, 'not_found' end

    local ok, err = setMetadataJobs(target, list)
    if not ok then return false, err end

    notify(target, {
        description = ForgeCore.t('notify.multijob.removed', { job = removed.label or removed.name }),
        type = 'primary',
    })

    return true, select(2, Service.getPlayerJobs(target))
end

function Service.setActiveJob(source, jobName)
    local settings = Service.getSettings()
    if not settings.enabled then return false, 'disabled' end

    jobName = normalizeJobName(jobName)
    if jobName == '' or isBlocked(jobName) then return false, 'blocked_job' end

    local has, entry = hasJob(source, jobName)
    if not has then return false, 'not_owned' end

    if not player(source) then return false, 'invalid_player' end

    if not ForgeCore.PrisonService.canChangeJobs(source) then
        return false, ForgeCore.t('prison.jobs_locked')
    end
    local ok, result = pr_lib.framework.SetPlayerJob(source, jobName, tonumber(entry.grade) or 0)
    if not ok then
        local reason = type(result) == 'table' and (result.code or result.message) or result
        return false, reason or 'set_job_failed'
    end

    if jobHasDutyPoint(jobName) and pr_lib.framework.SetPlayerDuty then
        pr_lib.framework.SetPlayerDuty(source, false)
    end

    notify(source, {
        description = ForgeCore.t('notify.multijob.active', { job = entry.label or jobName }),
        type = 'success',
    })

    TriggerClientEvent('forge-core:client:jobPoints:refresh', source)

    return true, select(2, Service.getPlayerJobs(source))
end

function Service.start()
    Service.load()
    debug('success', ForgeCore.t('debug.multijob.started'))
    return true
end

pr_lib.wrapJsonMutations(PR.MultiJob.Storage.file, Service, { 'saveSettings' })

ForgeCore.MultiJobService = Service
