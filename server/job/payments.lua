ForgeCore = ForgeCore or {}

local Payments = {
    started = false,
    nextPaymentAt = 0,
    settings = {},
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

local function notify(source, data)
    if not source or source <= 0 then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('core.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function clampInterval(value)
    value = tonumber(value) or PR.Job.Payments.intervalMinutes or 10
    value = math.floor(value)

    if value < 1 then return 1 end
    if value > 1440 then return 1440 end

    return value
end

local function normalizeAccount(value)
    value = tostring(value or PR.Job.Payments.account or 'bank'):lower()

    if value ~= 'cash' and value ~= 'bank' and value ~= 'crypto' then
        return 'bank'
    end

    return value
end

local function normalizeSocietyAccount(value)
    value = tostring(value or PR.Job.Mei.governmentAccount or 'government'):lower()
    value = value:gsub('^%s+', ''):gsub('%s+$', '')

    if value == '' then return 'government' end

    return value
end

local function defaultSettings()
    return {
        enabled = PR.Job.Payments.enabled == true,
        intervalMinutes = clampInterval(PR.Job.Payments.intervalMinutes),
        account = normalizeAccount(PR.Job.Payments.account),
        payOffDuty = PR.Job.Payments.payOffDuty == true,
        useSociety = PR.Job.Payments.useSociety == true,
        notify = PR.Job.Payments.notify ~= false,
        mei = {
            enabled = PR.Job.Mei.enabled == true,
            openingCost = math.max(0, tonumber(PR.Job.Mei.openingCost) or 0),
            monthlyCost = math.max(0, tonumber(PR.Job.Mei.monthlyCost) or 0),
            governmentAccount = normalizeSocietyAccount(PR.Job.Mei.governmentAccount),
            paymentAccount = normalizeAccount(PR.Job.Mei.paymentAccount),
        },
    }
end

local function normalizeSettings(raw)
    local defaults = defaultSettings()
    raw = type(raw) == 'table' and raw or {}
    local useSociety = raw.useSociety
    if useSociety == nil then useSociety = raw.society end

    local rawMei = type(raw.mei) == 'table' and raw.mei or raw

    return {
        enabled = boolValue(raw.enabled, defaults.enabled),
        intervalMinutes = clampInterval(raw.intervalMinutes or raw.interval),
        account = normalizeAccount(raw.account),
        payOffDuty = boolValue(raw.payOffDuty, defaults.payOffDuty),
        useSociety = boolValue(useSociety, defaults.useSociety),
        notify = boolValue(raw.notify, defaults.notify),
        mei = {
            enabled = boolValue(rawMei.meiEnabled or rawMei.enabledMei or rawMei.enabled, defaults.mei.enabled),
            openingCost = math.max(0, math.floor(tonumber(rawMei.openingCost) or defaults.mei.openingCost)),
            monthlyCost = math.max(0, math.floor(tonumber(rawMei.monthlyCost) or defaults.mei.monthlyCost)),
            governmentAccount = normalizeSocietyAccount(rawMei.governmentAccount),
            paymentAccount = normalizeAccount(rawMei.paymentAccount),
        },
    }
end

local function qbxReady()
    local state = GetResourceState('qbx_core')
    return state == 'started'
end

local function getPlayers()
    if not qbxReady() then return {} end

    local ok, players = pcall(function()
        return exports.qbx_core:GetQBPlayers()
    end)

    if ok and type(players) == 'table' then return players end

    debug('warn', ForgeCore.t('debug.payments.players_failed'))
    return {}
end

local function getJob(jobName)
    if not qbxReady() then return nil end

    local ok, job = pcall(function()
        return exports.qbx_core:GetJob(jobName)
    end)

    if ok then return job end

    return nil
end

local function getGradeData(jobData, level)
    if not jobData or type(jobData.grades) ~= 'table' then return nil end

    return jobData.grades[level] or jobData.grades[tostring(level)] or jobData.grades[tonumber(level)]
end

local function isMeiJob(jobData)
    if not jobData then return false end

    return jobData.jobtype == 'mei' or jobData.type == 'mei'
end

local function isResourceStarted(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

local function getSocietyBalance(accountName)
    if not isResourceStarted('ps-banking') then return nil end

    local ok, account = pcall(function()
        return exports['ps-banking']:GetAccount(accountName)
    end)

    if not ok or not account then return nil end

    return tonumber(account.balance)
end

local function removeSocietyMoney(accountName, payment)
    if not isResourceStarted('ps-banking') then return false end

    local ok, result = pcall(function()
        return exports['ps-banking']:RemoveMoney(accountName, payment, ForgeCore.t('payments.reason'))
    end)

    return ok and result ~= false
end

local function addSocietyMoney(accountName, amount, reason)
    if not isResourceStarted('ps-banking') then return false end

    local ok, result = pcall(function()
        return exports['ps-banking']:AddMoney(accountName, amount, reason)
    end)

    return ok and result ~= false
end

local function payPlayer(player, settings)
    if not player or not player.PlayerData then return false, 'invalid_player' end

    local data = player.PlayerData
    local job = data.job
    if not job or not job.name then return false, 'missing_job' end

    local jobData = getJob(job.name)
    if not jobData then return false, 'missing_job_data' end

    local grade = job.grade
    local level = type(grade) == 'table' and grade.level or grade
    local gradeData = getGradeData(jobData, level) or {}
    local payment = tonumber(gradeData.payment or job.payment) or 0

    if payment <= 0 then return false, 'no_payment' end
    if not settings.payOffDuty and not jobData.offDutyPay and not job.onduty then return false, 'off_duty' end

    local useSociety = settings.useSociety == true or isMeiJob(jobData)

    if useSociety then
        local balance = getSocietyBalance(job.name)

        if balance == nil then
            notify(data.source, {
                title = ForgeCore.t('payments.title'),
                description = ForgeCore.t('notify.payments.society_missing'),
                type = 'error',
            })
            return false, 'society_missing'
        end

        if balance < payment then
            notify(data.source, {
                title = ForgeCore.t('payments.title'),
                description = ForgeCore.t('notify.payments.society_no_money'),
                type = 'error',
            })
            return false, 'society_no_money'
        end

        if not removeSocietyMoney(job.name, payment) then
            notify(data.source, {
                title = ForgeCore.t('payments.title'),
                description = ForgeCore.t('notify.payments.society_remove_failed'),
                type = 'error',
            })
            return false, 'society_remove_failed'
        end
    end

    local ok = player.Functions.AddMoney(settings.account, payment, ForgeCore.t('payments.reason'))
    if not ok then return false, 'add_money_failed' end

    if settings.notify then
        notify(data.source, {
            title = ForgeCore.t('payments.title'),
            description = ForgeCore.t('notify.payments.received', { payment = payment }),
            type = 'success',
        })
    end

    return true, payment
end

function Payments.getSettings()
    local settings = next(Payments.settings) and Payments.settings or defaultSettings()

    return {
        enabled = settings.enabled,
        intervalMinutes = settings.intervalMinutes,
        account = settings.account,
        payOffDuty = settings.payOffDuty,
        useSociety = settings.useSociety,
        notify = settings.notify,
        mei = settings.mei or defaultSettings().mei,
        nextPaymentAt = Payments.nextPaymentAt,
    }
end

function Payments.load()
    local stored = ForgeCore.JobStorage.loadPayments()

    if not next(stored) then
        Payments.settings = defaultSettings()
    else
        Payments.settings = normalizeSettings(stored)
    end

    Payments.nextPaymentAt = os.time() + Payments.settings.intervalMinutes * 60
    return Payments.getSettings()
end

function Payments.save(settings)
    Payments.settings = normalizeSettings(settings)
    Payments.nextPaymentAt = os.time() + Payments.settings.intervalMinutes * 60

    local saved = ForgeCore.JobStorage.savePayments(Payments.settings)
    if saved then
        debug('success', ForgeCore.t('debug.payments.saved'))
    end

    return saved
end

function Payments.processAll(reason)
    local settings = Payments.settings
    if not settings.enabled and reason ~= 'force' then return 0, 0 end

    local paid = 0
    local skipped = 0
    local players = getPlayers()

    for _, player in pairs(players) do
        local ok = payPlayer(player, settings)
        if ok then
            paid = paid + 1
        else
            skipped = skipped + 1
        end
    end

    debug('info', ForgeCore.t('debug.payments.cycle_finished', {
        paid = tostring(paid),
        skipped = tostring(skipped),
        reason = tostring(reason or 'interval'),
    }))

    Payments.nextPaymentAt = os.time() + settings.intervalMinutes * 60
    return paid, skipped
end

function Payments.force(source)
    if ForgeCore.JobService and not ForgeCore.JobService.canManage(source) then
        return false, 'no_permission'
    end

    local paid, skipped = Payments.processAll('force')
    notify(source, {
        title = ForgeCore.t('payments.title'),
        description = ForgeCore.t('notify.payments.forced', { paid = paid, skipped = skipped }),
        type = 'success',
    })

    return true, { paid = paid, skipped = skipped }
end

function Payments.update(source, settings)
    if ForgeCore.JobService and not ForgeCore.JobService.canManage(source) then
        return false, 'no_permission'
    end

    local saved = Payments.save(settings)
    if not saved then return false, 'save_failed' end

    notify(source, {
        title = ForgeCore.t('payments.title'),
        description = ForgeCore.t('notify.payments.saved'),
        type = 'success',
    })

    return true, Payments.getSettings()
end

function Payments.updateMei(source, settings)
    if ForgeCore.JobService and not ForgeCore.JobService.canManage(source) then
        return false, 'no_permission'
    end

    local current = Payments.getSettings()
    current.mei = normalizeSettings({ mei = settings }).mei

    local saved = Payments.save(current)
    if not saved then return false, 'save_failed' end

    notify(source, {
        title = ForgeCore.t('mei.title'),
        description = ForgeCore.t('notify.mei.settings_saved'),
        type = 'success',
    })

    return true, Payments.getSettings()
end

function Payments.chargeMeiOpening(player, settings)
    local mei = settings and settings.mei or Payments.getSettings().mei
    if not mei or not mei.enabled then return false, 'mei_disabled' end

    local amount = math.max(0, tonumber(mei.openingCost) or 0)
    if amount <= 0 then return true end

    local account = normalizeAccount(mei.paymentAccount)
    local governmentAccount = normalizeSocietyAccount(mei.governmentAccount)

    if not player.Functions.RemoveMoney(account, amount, ForgeCore.t('mei.opening_reason')) then
        return false, 'not_enough_money'
    end

    if addSocietyMoney(governmentAccount, amount, ForgeCore.t('mei.opening_reason')) then
        return true
    end

    player.Functions.AddMoney(account, amount, ForgeCore.t('mei.refund_reason'))
    return false, 'government_account_failed'
end

function Payments.refundMeiOpening(player, settings)
    local mei = settings and settings.mei or Payments.getSettings().mei
    local amount = math.max(0, tonumber(mei and mei.openingCost) or 0)
    if amount <= 0 then return true end

    local account = normalizeAccount(mei and mei.paymentAccount)
    return player.Functions.AddMoney(account, amount, ForgeCore.t('mei.refund_reason'))
end

function Payments.start()
    if Payments.started then return true end

    Payments.started = true
    Payments.load()

    CreateThread(function()
        while Payments.started do
            Wait(5000)

            if Payments.settings.enabled then
                local now = os.time()
                if now >= Payments.nextPaymentAt then
                    Payments.processAll('interval')
                end
            else
                Payments.nextPaymentAt = os.time() + Payments.settings.intervalMinutes * 60
            end
        end
    end)

    debug('success', ForgeCore.t('debug.payments.started'))
    return true
end

ForgeCore.JobPayments = Payments
