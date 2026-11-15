-- Exact installed AFK editor only; parent server settings menu remains a later port.
return function(ports)
    local Menu,Shared,PR=assert(ports.menu),assert(ports.shared),assert(ports.config)
    local inputDialog,t,awaitServer,notifyFailure=Shared.inputDialog,Shared.t,Shared.awaitServer,Shared.notifyFailure
    local boolOptions,boolDefault,boolValue=Shared.boolOptions,Shared.boolDefault,Shared.boolValue
    local SetTimeout=assert(ports.native.SetTimeout)
    local afkActionLocked=false
function Menu.openAfkSettingsEditor(settings)
    settings = type(settings) == 'table' and settings or {}

    local result = inputDialog(t('menu.afk.title'), {
        {
            type = 'select',
            label = t('inputs.afk_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled),
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.afk_minutes'),
            default = tonumber(settings.minutes) or PR.Afk.Defaults.minutes,
            required = true,
            min = 1,
            max = 1440,
        },
    })

    if not result then
        Menu.openServerSettingsMenu()
        return
    end

    if afkActionLocked then return end
    afkActionLocked = true

    local ok, response = awaitServer(PR.Afk.Callbacks.saveSettings, {
        enabled = boolValue(result[1]),
        minutes = tonumber(result[2]) or PR.Afk.Defaults.minutes,
    })

    if not ok then
        notifyFailure('notify.afk.save_failed', response)
    end

    SetTimeout(500, function()
        Menu.openServerSettingsMenu()
    end)

    SetTimeout(1000, function()
        afkActionLocked = false
    end)
end


    return {Menu=Menu,Shared=Shared}
end
