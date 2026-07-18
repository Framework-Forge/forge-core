ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local State = {
    jobs = {},
    gangs = {},
    payments = {},
    revision = 0,
    canManage = false,
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

function State.set(payload, canManage)
    if type(payload) ~= 'table' then return false end

    State.jobs = type(payload.jobs) == 'table' and payload.jobs or {}
    State.gangs = type(payload.gangs) == 'table' and payload.gangs or {}
    State.payments = type(payload.payments) == 'table' and payload.payments or State.payments
    State.revision = tonumber(payload.revision) or State.revision

    if canManage ~= nil then
        State.canManage = canManage == true
    end

    debug('info', ForgeCore.t('debug.client.sync_received', {
        jobs = tostring(#State.jobs),
        gangs = tostring(#State.gangs),
        revision = tostring(State.revision),
    }))

    if ForgeCore.Client.JobPoints then
        ForgeCore.Client.JobPoints.refresh({
            jobs = State.jobs,
            gangs = State.gangs,
        })
    end

    if ForgeCore.Client.JobBusiness then
        ForgeCore.Client.JobBusiness.refresh({
            jobs = State.jobs,
            gangs = State.gangs,
        })
    end

    return true
end

function State.request()
    if pr_lib and pr_lib.callback and pr_lib.callback.await then
        local payload, canManage = pr_lib.callback.await(PR.Job.Callbacks.getAll, 10000)
        State.set(payload, canManage)
    end

    return State
end

function State.getGroups(groupType)
    return groupType == 'gang' and State.gangs or State.jobs
end

RegisterNetEvent(PR.Job.Events.sync, function(payload)
    State.set(payload)
end)

ForgeCore.Client.JobState = State
