-- Complete inactive JobService port; no live lifecycle, SQL or JSON effects on attachment.
return function(ports)
    local services = assert(ports.services, 'canonical local job services required')
    local library = assert(ports.library, 'PR library ports required')
    local translate = assert(ports.translate, 'translation required')
    local kernel = assert(ports.kernel, 'internal core methods required')
    local playerAccess = assert(ports.playerAccess, 'local duty/lookup adapter required')
    local native = assert(ports.native, 'explicit transport/platform ports required')
    local isReady, isAvailable = assert(ports.isReady), assert(ports.isAvailable)
    local clock = assert(ports.time, 'time port required')
    local PR = {Job = assert(ports.config), AdminAce = ports.adminAce, Command = ports.command, NotifyPos = ports.notifyPosition}
    local events = {}
    local function listen(name, handler, remote)
        events[#events + 1] = {name = name, handler = handler, network = remote == true}
    end
    local function network(name, handler) listen(name, handler, true) end
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
    if not isReady() or not library.database or not library.database.query or not library.database.transaction then
        return false, 'unavailable'
    end

    local ok, jobs, gangs = pcall(function()
        return kernel.GetJobs(), kernel.GetGangs()
    end)
    if not ok or type(jobs) ~= 'table' or type(gangs) ~= 'table' then
        return false, 'catalog_unavailable'
    end

    local rows = library.database.query('SELECT citizenid, `group`, type, grade FROM player_groups')
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
        local committed = library.database.transaction(queries)
        if not committed then return false, 'transaction_failed' end
    end

    if removed > 0 or adjusted > 0 then
        debug('info', ('Reconciled player groups: %s removed, %s grades adjusted.'):format(removed, adjusted))
    end

    return true, { removed = removed, adjusted = adjusted }
end

debug = function(level, message)
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
    if source == 0 then
        debug('info', data.description or data.title or translate('core.title'))
        return
    end

    library.notify.NotifyPlayer(source, {
        title = data.title or translate('core.title'),
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

local function applyDutyDefaultRules(state)
    local changed = false
    local jobs = state and state.jobs or services.JobRegistry.getJobs()

    for _, job in pairs(jobs or {}) do
        if groupHasDutyPoint(job) and job.defaultDuty ~= false then
            job.defaultDuty = false
            changed = true
        end
    end

    return changed
end

local function forceOnlineJobOffDuty(jobName)
    if not library or not playerAccess or not playerAccess.SetPlayerDuty then return end
    if not playerAccess.GetAllPlayers or not playerAccess.GetPlayerJob then return end

    for _, playerSource in ipairs(playerAccess.GetAllPlayers()) do
        local job = playerAccess.GetPlayerJob(playerSource)
        if type(job) == 'table' and tostring(job.name or ''):lower() == tostring(jobName or ''):lower() then
            playerAccess.SetPlayerDuty(playerSource, false)
        end
    end
end

local function forceSourceOffDutyForDutyJob(source)
    if not source or source <= 0 then return end
    if not library or not playerAccess or not playerAccess.GetPlayerJob or not playerAccess.SetPlayerDuty then return end

    local job = playerAccess.GetPlayerJob(source)
    local jobName = type(job) == 'table' and job.name or nil
    local group = jobName and services.JobRegistry.get('job', jobName) or nil

    if groupHasDutyPoint(group) then
        playerAccess.SetPlayerDuty(source, false)
    end
end

function Service.canManage(source)
    if source == 0 then return true end

    local permissions = PR.Job.Permissions or {}
    local ace = permissions.ace or PR.AdminAce

    if ace and native.isAceAllowed(source, ace) then return true end
    if PR.Command and native.isAceAllowed(source, ('command.%s'):format(PR.Command)) then return true end
    if native.isAceAllowed(source, 'admin') then return true end

    if isAvailable() then
        local ok, hasPermission = pcall(function()
            return kernel.HasPermission(source, { 'god', 'admin' })
        end)

        if ok and hasPermission then return true end
    end

    return false
end

function Service.getPayload()
    local payload = services.JobRegistry.payload()

    if services.JobPayments then
        payload.payments = services.JobPayments.getSettings()
    end

    return payload
end

function Service.broadcast(target)
    native.emitClient(PR.Job.Events.sync, target or -1, Service.getPayload())
end

function Service.sendTo(source)
    Service.broadcast(source)
end

function Service.save(draft)
    if Service.persistenceBlocked then return false, 'reconciliation_required' end
    draft = draft or services.JobRegistry
    local saved, err = services.JobStorage.save(draft.jobs, draft.gangs)
    if err == 'reconciliation_required' then Service.persistenceBlocked = true end

    if saved then
        services.JobRegistry.jobs = draft.jobs
        services.JobRegistry.gangs = draft.gangs
        services.JobRegistry.revision = draft.revision
        debug('success', translate('debug.jobs.saved'))
    end

    return saved
end

function Service.reload()
    Service.incidents = library.loadJsonRecovery(PR.Job.Storage.jobsFile .. '.incidents.json') or {}
    if Service.incidents.batch then error('job catalogs require persistence reconciliation') end
    local jobs, gangs = services.JobStorage.load()
    services.JobRegistry.setAll(jobs, gangs)
    if applyDutyDefaultRules() then
        Service.save()
    end
    services.JobQbxSync.syncAll()
    reconcilePersistedGroups()
    if services.JobPoints then
        services.JobPoints.registerAll()
    end
    if services.JobBusiness then
        services.JobBusiness.registerAll()
    end
    Service.broadcast(-1)

    return true
end

function Service.saveAndSync(draft)
    draft = draft or library.jsonDraft(services.JobRegistry, {jobs=true,gangs=true})
    applyDutyDefaultRules(draft)
    local saved = Service.save(draft)
    if not saved then return false end
    services.JobQbxSync.syncAll()
    reconcilePersistedGroups()
    if services.JobPoints then
        services.JobPoints.registerAll()
    end
    if services.JobBusiness then
        services.JobBusiness.registerAll()
    end
    Service.broadcast(-1)
    return saved
end

function Service.upsert(source, groupData, forcedType)
    if not Service.canManage(source) then
        return false, 'no_permission'
    end

    local normalized, normalizeErr = services.JobRegistry.normalizeGroup(groupData, forcedType)
    if not normalized then return false, normalizeErr end
    if groupHasDutyPoint(normalized) then
        normalized.defaultDuty = false
    end

    local isNewJob = normalized.type == 'job' and not services.JobRegistry.exists('job', normalized.name)

    if isNewJob then
        local societyOk, societyErr = ensureSocietyAccount(normalized.name, normalized.label)
        if not societyOk and societyErr ~= 'banking_unavailable' then return false, societyErr end
    end

    local draft = library.jsonDraft(services.JobRegistry, {jobs=true,gangs=true})
    local ok, result = services.JobRegistry.upsert(normalized, forcedType, draft)
    if not ok then return false, result end

    if not Service.saveAndSync(draft) then return false, 'save_failed' end

    if groupHasDutyPoint(normalized) then
        forceOnlineJobOffDuty(normalized.name)
    end

    notify(source, {
        title = translate('core.title'),
        description = translate('notify.jobs.saved', { group = result.label or result.name }),
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

    local draft = library.jsonDraft(services.JobRegistry, {jobs=true,gangs=true})
    local ok, err = services.JobRegistry.remove(groupType, name, draft)
    if not ok then return false, err end

    if not Service.saveAndSync(draft) then return false, 'save_failed' end

    notify(source, {
        title = translate('core.title'),
        description = translate('notify.jobs.removed', { group = name }),
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
    if not isReady() then return nil end

    local ok, player = pcall(function()
        return kernel.GetPlayer(source)
    end)

    if ok then return player end
end

function ensureSocietyAccount(accountName, accountLabel)
    if not library.banking or type(library.banking.EnsureJobAccount) ~= 'function' then
        return false, 'banking_unavailable'
    end

    local ok, ensured, status = pcall(
        library.banking.EnsureJobAccount,
        accountName,
        accountLabel or accountName,
        0
    )

    if not ok or ensured ~= true then return false, status or 'society_create_failed' end

    if status == 'created' then
        debug('success', translate('debug.jobs.society_created', { account = accountName }))
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
        kernel.SetJob(source, jobName, grade)
    end)
end

function Service.createMei(source, data)
    if source <= 0 then return false, 'invalid_source' end

    local settings = services.JobPayments and services.JobPayments.getSettings()
    if not settings or not settings.mei or not settings.mei.enabled then
        return false, 'mei_disabled'
    end

    local label = tostring(data and data.label or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if label == '' then return false, 'missing_name' end

    local code = normalizeMeiCode(label)
    if code == '' then return false, 'invalid_name' end
    if services.JobRegistry.exists('job', code) then return false, 'already_exists' end

    local player = getQbxPlayer(source)
    if not player then return false, 'invalid_player' end
    local incidentKey = 'mei:' .. tostring(player.PlayerData and player.PlayerData.citizenid or '')
    Service.incidents = Service.incidents or {}
    if Service.incidents[incidentKey] then return false, 'reconciliation_required' end
    local function recordMeiIncident(reason)
        local details = { at=clock(), reason=reason, settings=settings.mei, company=code }
        Service.incidents[incidentKey] = details
        library.recordJsonIncident(PR.Job.Storage.jobsFile, incidentKey, details)
        return false, 'reconciliation_required'
    end

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

    local normalized, normalizeErr = services.JobRegistry.normalizeGroup(group, 'job')
    if not normalized then return false, normalizeErr end

    local societyOk, societyErr = ensureSocietyAccount(normalized.name, normalized.label)
    if not societyOk then return false, societyErr end

    local charged, chargeErr = services.JobPayments.chargeMeiOpening(player, settings)
    if not charged then
        if chargeErr == 'government_charge_unknown' or chargeErr == 'refund_failed' then return recordMeiIncident(chargeErr) end
        return false, chargeErr
    end

    local draft = library.jsonDraft(services.JobRegistry, {jobs=true,gangs=true})
    local ok, result = services.JobRegistry.upsert(normalized, 'job', draft)
    if not ok then
        if not services.JobPayments.refundMeiOpening(player, settings) then return recordMeiIncident('refund_failed') end
        return false, result
    end

    if not Service.saveAndSync(draft) then
        if not services.JobPayments.refundMeiOpening(player, settings) then return recordMeiIncident('refund_failed') end
        return false, 'save_failed'
    end

    setPlayerMeiJob(source, normalized.name, normalized.grades)

    notify(source, {
        title = translate('mei.title'),
        description = translate('notify.mei.created', { company = normalized.label }),
        type = 'success',
    })

    return true, normalized
end

function Service.start()
    if Service.started then return true end

    Service.started = true
    Service.reload()
    debug('success', translate('debug.jobs.started'))

    return true
end

library.wrapJsonMutations(PR.Job.Storage.jobsFile, Service, { 'upsert', 'delete', 'createMei' })


network('QBCore:Server:OnPlayerLoaded', function()
    local src = native.getSource()
    native.setTimeout(1500, function()
        forceSourceOffDutyForDutyJob(src)
    end)
end)

listen('QBCore:Server:OnJobUpdate', function(source)
    native.setTimeout(500, function()
        forceSourceOffDutyForDutyJob(source)
    end)
end)

Service.Events = events
return Service
end

