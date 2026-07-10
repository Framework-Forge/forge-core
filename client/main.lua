ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

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

CreateThread(function()
    Wait(1500)

    if pr_lib and pr_lib.debug and pr_lib.debug.setEnabled then
        pr_lib.debug.setEnabled(PR.Debug == true)
    end

    if ForgeCore.Client.JobState then
        ForgeCore.Client.JobState.request()
    end

    debug('info', ForgeCore.t('debug.client.started'))
end)
