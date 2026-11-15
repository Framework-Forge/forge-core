-- Complete installed Forge client bootstrap, retained as an inert thread descriptor.
return function(ports)
    local library,client,translate=assert(ports.library),assert(ports.client),assert(ports.translate)
    local wait=assert(ports.wait)
    local PR={Debug=ports.debugEnabled}
    local threads={}
    local function thread(handler)threads[#threads+1]=handler end
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

thread(function()
    wait(1500)

    if library and library.debug and library.debug.setEnabled then
        library.debug.setEnabled(PR.Debug == true)
    end

    if client.JobState then
        client.JobState.request()
    end

    debug('info', translate('debug.client.started'))
end)

    return {Threads=threads}
end
