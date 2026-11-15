-- Complete installed administrative replica, not another PlayerData or native Groups authority.
return function(ports)
    local library,client,translate=assert(ports.library),assert(ports.client),assert(ports.translate)
    local PR={Job=assert(ports.config)}
    local events={}
    local function network(name,handler)events[#events+1]={name=name,handler=handler,network=true}end
local State = {
    jobs = {},
    gangs = {},
    payments = {},
    revision = 0,
    canManage = false,
}

local function debug(level, message)
    local debugApi = library and library.debug
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

    debug('info', translate('debug.client.sync_received', {
        jobs = tostring(#State.jobs),
        gangs = tostring(#State.gangs),
        revision = tostring(State.revision),
    }))

    if client.JobPoints then
        client.JobPoints.refresh({
            jobs = State.jobs,
            gangs = State.gangs,
        })
    end

    if client.JobBusiness then
        client.JobBusiness.refresh({
            jobs = State.jobs,
            gangs = State.gangs,
        })
    end

    return true
end

function State.request()
    if library and library.callback and library.callback.await then
        local payload, canManage = library.callback.await(PR.Job.Callbacks.getAll, 10000)
        State.set(payload, canManage)
    end

    return State
end

function State.getGroups(groupType)
    return groupType == 'gang' and State.gangs or State.jobs
end

network(PR.Job.Events.sync, function(payload)
    State.set(payload)
end)


    return {State=State,Events=events}
end
