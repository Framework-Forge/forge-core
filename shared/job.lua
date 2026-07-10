PR = PR or {}
PR.Job = PR.Job or {}

PR.Job.Storage = {
    type = 'json',
    jobsFile = 'data/jobs.json',
    gangsFile = 'data/gangs.json',
}

PR.Job.Events = {
    sync = 'forge-core:client:job:sync',
    openMenu = 'forge-core:client:menu:open',
}

PR.Job.Callbacks = {
    getAll = 'forge-core:server:job:getAll',
    openMenu = 'forge-core:client:menu:open',
    openMei = 'forge-core:client:mei:open',
    saveGroup = 'forge-core:server:job:save',
    deleteGroup = 'forge-core:server:job:delete',
    savePaymentSettings = 'forge-core:server:job:payments:save',
    forcePayment = 'forge-core:server:job:payments:force',
    saveMeiSettings = 'forge-core:server:job:mei:settings:save',
    createMei = 'forge-core:server:job:mei:create',
}

PR.Job.Commands = {
    open = PR.Command or 'forgecore',
    jobs = 'forgejobs',
    testMei = 'forgemeitest',
}

PR.Job.Permissions = {
    ace = PR.AdminAce or 'forge-core.admin',
    legacyAce = 'jobsystem',
}

PR.Job.Protected = {
    jobs = {
        unemployed = true,
    },
    gangs = {
        none = true,
    },
}

PR.Job.Types = {
    { value = 'leo', label = ForgeCore.t('jobs.types.leo') },
    { value = 'ems', label = ForgeCore.t('jobs.types.ems') },
    { value = 'mechanic', label = ForgeCore.t('jobs.types.mechanic') },
    { value = 'realestate', label = ForgeCore.t('jobs.types.realestate') },
    { value = 'mei', label = ForgeCore.t('jobs.types.mei') },
    { value = 'none', label = ForgeCore.t('jobs.types.none') },
}

local function getForgeConvar(name, fallback)
    local sentinel = '__forge_core_unset__'
    local value = GetConvar(('forge:%s'):format(name), sentinel)
    if value ~= sentinel then return value end

    return GetConvar(('pinel:%s'):format(name), fallback)
end

local function getForgeConvarInt(name, fallback)
    return tonumber(getForgeConvar(name, tostring(fallback))) or fallback
end

PR.Job.Payments = {
    enabled = getForgeConvar('paycheck:enabled', 'true') == 'true',
    intervalMinutes = getForgeConvarInt('paycheck:interval', 10),
    account = getForgeConvar('paycheck:account', 'bank'),
    payOffDuty = getForgeConvar('paycheck:payOffDuty', 'false') == 'true',
    useSociety = getForgeConvar('paycheck:society', 'false') == 'true',
    notify = getForgeConvar('paycheck:notify', 'true') == 'true',
    file = 'data/payments.json',
}

PR.Job.Mei = {
    enabled = getForgeConvar('mei:enabled', 'true') == 'true',
    openingCost = getForgeConvarInt('mei:openingCost', 5000),
    monthlyCost = getForgeConvarInt('mei:monthlyCost', 1000),
    governmentAccount = getForgeConvar('mei:governmentAccount', 'government'),
    paymentAccount = getForgeConvar('mei:paymentAccount', 'bank'),
}

PR.Job.Defaults = {
    job = {
        label = '',
        name = '',
        type = 'job',
        jobtype = nil,
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = ForgeCore.t('jobs.defaults.member'),
                payment = 0,
            },
        },
        craftings = {},
        stashes = {},
    },
    gang = {
        label = '',
        name = '',
        type = 'gang',
        grades = {
            [0] = {
                name = ForgeCore.t('jobs.defaults.member'),
            },
        },
        craftings = {},
        stashes = {},
    },
}
