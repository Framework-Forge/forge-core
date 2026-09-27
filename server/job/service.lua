ForgeCore = ForgeCore or {}

local Service = {
    started = false,
}

local ensureSocietyAccount
local debug

local function fallbackValidGrade(grades, requested)
    local nearest
    local lowest

    for key in pairs(type(grades) == 'table' and grades or {}) do
        local grade = tonumber(key)
        if grade then
            if not lowest or grade < lowest then lowest = grade end
            if grade <= requested and (not nearest or grade > nearest) then nearest = grade end
        end
    end

    return nearest or lowest
end

local function reconcilePersistedGroups()
    if GetResourceState('qbx_core') ~= 'started' or not pr_lib.database or not pr_lib.database.query or not pr_lib.database.transaction then
        return false, 'unavailable'
    end

    local ok, jobs, gangs = pcall(function()
        return exports.qbx_core:GetJobs(), exports.qbx_core:GetGangs()
    end)
    if not ok or type(jobs) ~= 'table' or type(gangs) ~= 'table' then
        return false, 'catalog_unavailable'
    end

    local rows = pr_lib.database.query('SELECT citizenid, `group`, type, grade FROM player_groups')
    if type(rows) ~= 'table' then return false, 'query_failed' end
    local queries = {}
    local removed = 0
    local adjusted = 0

    for i = 1, #rows do
        local row = rows[i]
        local catalog = row.type == 'gang' and gangs or jobs
        local group = catalog[row.group]

        if not group then
            queries[#queries + 1] = {
                query = 'DELETE FROM player_groups WHERE citizenid = ? AND `group` = ? AND type = ?',
                values = { row.citizenid, row.group, row.type },
            }
            removed = removed + 1
        else
            local grades = type(group.grades) == 'table' and group.grades or {}
            local grade = tonumber(row.grade)
            if not (grades[grade] or grades[tostring(grade)]) then
                local fallback = fallbackValidGrade(grades, grade or 0)
                if fallback then
                    queries[#queries + 1] = {
                        query = 'UPDATE player_groups SET grade = ? WHERE citizenid = ? AND `group` = ? AND type = ?',
                        values = { fallback, row.citizenid, row.group, row.type },
                    }
                    adjusted = adjusted + 1
                end
            end
        end
    end

    if #queries > 0 then
        local committed = pr_lib.database.transaction(queries)
        if not committed then return false, 'transaction_failed' end
    end

    if removed > 0 or adjusted > 0 then
        debug('info', ('Reconciled player groups: %s removed, %s grades adjusted.'):format(removed, adjusted))
    end

    return true, { removed = removed, adjusted = adjusted }
end

debug = function(level, message)
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
    if source == 0 then
        debug('info', data.description or data.title or ForgeCore.t('core.title'))
        return
    end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('core.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function groupHasDutyPoint(group)
    if type(group) ~= 'table' or group.type ~= 'job' or type(group.stashes) ~= 'table' then return false end

    for i = 1, #group.stashes do
        local point = group.stashes[i]
        local duty = type(point) == 'table' and type(point.duty) == 'table' and point.duty or nil
        if point and point.enabled ~= false and duty and duty.enabled == true then
            return true
        end
    end

    return false
end

local function applyDutyDefaultRules()
    local changed = false
    local jobs = ForgeCore.JobRegistry.getJobs()

    for _, job in pairs(jobs or {}) do
        if groupHasDutyPoint(job) and job.defaultDuty ~= false then
            job.defaultDuty = false
            changed = true
        end
    end

    return changed
end

local function forceOnlineJobOffDuty(jobName)
    if not pr_lib or not pr_lib.framework or not pr_lib.framework.SetPlayerDuty then return end
    if not pr_lib.framework.GetAllPlayers or not pr_lib.framework.GetPlayerJob then return end

    for _, playerSource in ipairs(pr_lib.framework.GetAllPlayers()) do
        local job = pr_lib.framework.GetPlayerJob(playerSource)
        if type(job) == 'table' and tostring(job.name or ''):lower() == tostring(jobName or ''):lower() then
            pr_lib.framework.SetPlayerDuty(playerSource, false)
        end
    end
end

local function forceSourceOffDutyForDutyJob(source)
    if not source or source <= 0 then return end
    if not pr_lib or not pr_lib.framework or not pr_lib.framework.GetPlayerJob or not pr_lib.framework.SetPlayerDuty then return end

    local job = pr_lib.framework.GetPlayerJob(source)
    local jobName = type(job) == 'table' and job.name or nil
    local group = jobName and ForgeCore.JobRegistry.get('job', jobName) or nil

    if groupHasDutyPoint(group) then
        pr_lib.framework.SetPlayerDuty(source, false)
    end
end

function Service.canManage(source)
    if source == 0 then return true end

    local permissions = PR.Job.Permissions or {}
    local ace = permissions.ace or PR.AdminAce

    if ace and IsPlayerAceAllowed(source, ace) then return true end
    if PR.Command and IsPlayerAceAllowed(source, ('command.%s'):format(PR.Command)) then return true end
    if IsPlayerAceAllowed(source, 'admin') then return true end

    if GetResourceState('qbx_core'):find('start') then
        local ok, hasPermission = pcall(function()
            return exports.qbx_core:HasPermission(source, { 'god', 'admin' })
        end)

        if ok and hasPermission then return true end
    end

    return false
end

function Service.getPayload()
    local payload = ForgeCore.JobRegistry.payload()

    if ForgeCore.JobPayments then
        payload.payments = ForgeCore.JobPayments.getSettings()
    end

    return payload
end

function Service.broadcast(target)
    TriggerClientEvent(PR.Job.Events.sync, target or -1, Service.getPayload())
end

function Service.sendTo(source)
    Service.broadcast(source)
end

function Service.save()
    local saved = ForgeCore.JobStorage.save(
        ForgeCore.JobRegistry.getJobs(),
        ForgeCore.JobRegistry.getGangs()
    )

    if saved then
        debug('success', ForgeCore.t('debug.jobs.saved'))
    end

    return saved
end

function Service.reload()
    local jobs, gangs = ForgeCore.JobStorage.load()
    ForgeCore.JobRegistry.setAll(jobs, gangs)
    if applyDutyDefaultRules() then
        Service.save()
    end
    ForgeCore.JobQbxSync.syncAll()
    reconcilePersistedGroups()
    if ForgeCore.JobPoints then
        ForgeCore.JobPoints.registerAll()
    end
    if ForgeCore.JobBusiness then
        ForgeCore.JobBusiness.registerAll()
    end
    Service.broadcast(-1)

    return true
end

function Service.saveAndSync()
    applyDutyDefaultRules()
    local saved = Service.save()
    ForgeCore.JobQbxSync.syncAll()
    reconcilePersistedGroups()
    if ForgeCore.JobPoints then
        ForgeCore.JobPoints.registerAll()
    end
    if ForgeCore.JobBusiness then
        ForgeCore.JobBusiness.registerAll()
    end
    Service.broadcast(-1)
    return saved
end

function Service.upsert(source, groupData, forcedType)
    if not Service.canManage(source) then
        return false, 'no_permission'
    end

    local normalized, normalizeErr = ForgeCore.JobRegistry.normalizeGroup(groupData, forcedType)
    if not normalized then return false, normalizeErr end
    if groupHasDutyPoint(normalized) then
        normalized.defaultDuty = false
    end

    local isNewJob = normalized.type == 'job' and not ForgeCore.JobRegistry.exists('job', normalized.name)

    if isNewJob then
        local societyOk, societyErr = ensureSocietyAccount(normalized.name, normalized.label)
        if not societyOk and societyErr ~= 'banking_unavailable' then return false, societyErr end
    end

    local ok, result = ForgeCore.JobRegistry.upsert(normalized, forcedType)
    if not ok then return false, result end

    Service.saveAndSync()

    if groupHasDutyPoint(normalized) then
        forceOnlineJobOffDuty(normalized.name)
    end

    notify(source, {
        title = ForgeCore.t('core.title'),
        description = ForgeCore.t('notify.jobs.saved', { group = result.label or result.name }),
        type = 'success',
    })

    return true, result
end

function Service.delete(source, groupType, name)
    if not Service.canManage(source) then
        return false, 'no_permission'
    end

    local protected = groupType == 'gang' and PR.Job.Protected.gangs or PR.Job.Protected.jobs
    local normalizedName = tostring(name or ''):lower():gsub('%s+', '_'):gsub('[^%w_%-]', '')
    if protected and protected[normalizedName] then
        return false, 'protected'
    end

    local ok, err = ForgeCore.JobRegistry.remove(groupType, name)
    if not ok then return false, err end

    Service.saveAndSync()

    notify(source, {
        title = ForgeCore.t('core.title'),
        description = ForgeCore.t('notify.jobs.removed', { group = name }),
        type = 'success',
    })

    return true
end

local accentMap = {
    ['á'] = 'a', ['à'] = 'a', ['ã'] = 'a', ['â'] = 'a', ['ä'] = 'a',
    ['é'] = 'e', ['è'] = 'e', ['ê'] = 'e', ['ë'] = 'e',
    ['í'] = 'i', ['ì'] = 'i', ['î'] = 'i', ['ï'] = 'i',
    ['ó'] = 'o', ['ò'] = 'o', ['õ'] = 'o', ['ô'] = 'o', ['ö'] = 'o',
    ['ú'] = 'u', ['ù'] = 'u', ['û'] = 'u', ['ü'] = 'u',
    ['ç'] = 'c', ['ñ'] = 'n',
    ['Á'] = 'a', ['À'] = 'a', ['Ã'] = 'a', ['Â'] = 'a', ['Ä'] = 'a',
    ['É'] = 'e', ['È'] = 'e', ['Ê'] = 'e', ['Ë'] = 'e',
    ['Í'] = 'i', ['Ì'] = 'i', ['Î'] = 'i', ['Ï'] = 'i',
    ['Ó'] = 'o', ['Ò'] = 'o', ['Õ'] = 'o', ['Ô'] = 'o', ['Ö'] = 'o',
    ['Ú'] = 'u', ['Ù'] = 'u', ['Û'] = 'u', ['Ü'] = 'u',
    ['Ç'] = 'c', ['Ñ'] = 'n',
}

local function normalizeMeiCode(label)
    local normalized = tostring(label or '')

    for from, to in pairs(accentMap) do
        normalized = normalized:gsub(from, to)
    end

    normalized = normalized:lower()
    normalized = normalized:gsub('%s+', '_')
    normalized = normalized:gsub('[^%w_%-]', '')
    normalized = normalized:gsub('_+', '_')
    normalized = normalized:gsub('^_+', ''):gsub('_+$', '')

    return normalized
end

local function getQbxPlayer(source)
    if GetResourceState('qbx_core') ~= 'started' then return nil end

    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)

    if ok then return player end
end

function ensureSocietyAccount(accountName, accountLabel)
    if not pr_lib.banking or type(pr_lib.banking.EnsureJobAccount) ~= 'function' then
        return false, 'banking_unavailable'
    end

    local ok, ensured, status = pcall(
        pr_lib.banking.EnsureJobAccount,
        accountName,
        accountLabel or accountName,
        0
    )

    if not ok or ensured ~= true then return false, status or 'society_create_failed' end

    if status == 'created' then
        debug('success', ForgeCore.t('debug.jobs.society_created', { account = accountName }))
    end

    return true, status or 'exists'
end

local function highestGrade(grades)
    local highest = 0

    for key in pairs(grades or {}) do
        local level = tonumber(key)
        if level and level > highest then
            highest = level
        end
    end

    return highest
end

local function setPlayerMeiJob(source, jobName, grades)
    local grade = highestGrade(grades)

    pcall(function()
        exports.qbx_core:SetJob(source, jobName, grade)
    end)
end

function Service.createMei(source, data)
    if source <= 0 then return false, 'invalid_source' end

    local settings = ForgeCore.JobPayments and ForgeCore.JobPayments.getSettings()
    if not settings or not settings.mei or not settings.mei.enabled then
        return false, 'mei_disabled'
    end

    local label = tostring(data and data.label or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if label == '' then return false, 'missing_name' end

    local code = normalizeMeiCode(label)
    if code == '' then return false, 'invalid_name' end
    if ForgeCore.JobRegistry.exists('job', code) then return false, 'already_exists' end

    local player = getQbxPlayer(source)
    if not player then return false, 'invalid_player' end

    local group = {
        label = label,
        name = code,
        job = code,
        type = 'job',
        jobtype = 'mei',
        defaultDuty = true,
        offDutyPay = false,
        grades = data and data.grades or {},
        stashes = {},
        owner = player.PlayerData and player.PlayerData.citizenid,
    }

    local normalized, normalizeErr = ForgeCore.JobRegistry.normalizeGroup(group, 'job')
    if not normalized then return false, normalizeErr end

    local societyOk, societyErr = ensureSocietyAccount(normalized.name, normalized.label)
    if not societyOk then return false, societyErr end

    local charged, chargeErr = ForgeCore.JobPayments.chargeMeiOpening(player, settings)
    if not charged then return false, chargeErr end

    local ok, result = ForgeCore.JobRegistry.upsert(normalized, 'job')
    if not ok then
        ForgeCore.JobPayments.refundMeiOpening(player, settings)
        return false, result
    end

    if not Service.saveAndSync() then
        ForgeCore.JobRegistry.remove('job', normalized.name)
        ForgeCore.JobQbxSync.syncAll()
        Service.broadcast(-1)
        ForgeCore.JobPayments.refundMeiOpening(player, settings)
        return false, 'save_failed'
    end

    setPlayerMeiJob(source, normalized.name, normalized.grades)

    notify(source, {
        title = ForgeCore.t('mei.title'),
        description = ForgeCore.t('notify.mei.created', { company = normalized.label }),
        type = 'success',
    })

    return true, normalized
end

function Service.start()
    if Service.started then return true end

    Service.started = true
    Service.reload()
    debug('success', ForgeCore.t('debug.jobs.started'))

    return true
end

ForgeCore.JobService = Service

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    SetTimeout(1500, function()
        forceSourceOffDutyForDutyJob(src)
    end)
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function(source)
    SetTimeout(500, function()
        forceSourceOffDutyForDutyJob(source)
    end)
end)
