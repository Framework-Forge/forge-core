ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local boolValue = Shared.boolValue
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions

local actionLocked = false

local function fetchSettings()
    local ok, payload = awaitServer(PR.Vinewood.Callbacks.getSettings)
    if not ok then
        notifyFailure('notify.vinewood.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.enabled = payload.enabled == true
    payload.text = tostring(payload.text or PR.Vinewood.Defaults.text)
    payload.color = tostring(payload.color or PR.Vinewood.Defaults.color)

    return payload
end

function Menu.openVinewoodMenu()
    local settings = fetchSettings()
    if not settings then return end

    showContext({
        id = 'forge_core_vinewood',
        title = t('menu.vinewood.title'),
        menu = 'forge_core_server_settings',
        options = {
            {
                title = t('menu.vinewood.edit'),
                description = t('menu.vinewood.summary', {
                    status = settings.enabled and t('common.active') or t('common.inactive'),
                    text = settings.text,
                    color = settings.color,
                }),
                icon = 'landmark',
                onSelect = function()
                    Menu.openVinewoodEditor(settings)
                end,
            },
        },
    })
end

function Menu.openVinewoodEditor(settings)
    settings = type(settings) == 'table' and settings or {}

    local result = inputDialog(t('menu.vinewood.title'), {
        {
            type = 'select',
            label = t('inputs.vinewood_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled),
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.vinewood_text'),
            default = settings.text or PR.Vinewood.Defaults.text,
            required = true,
            min = 1,
            max = #(PR.Vinewood.Coords or {}),
        },
        {
            type = 'color',
            label = t('inputs.vinewood_color'),
            default = settings.color or PR.Vinewood.Defaults.color,
            required = true,
        },
    })

    if not result then
        Menu.openVinewoodMenu()
        return
    end

    if actionLocked then return end
    actionLocked = true

    local ok, response = awaitServer(PR.Vinewood.Callbacks.saveSettings, {
        enabled = boolValue(result[1]),
        text = tostring(result[2] or ''),
        color = tostring(result[3] or PR.Vinewood.Defaults.color),
    })

    if not ok then
        notifyFailure('notify.vinewood.save_failed', response)
    end

    SetTimeout(500, function()
        Menu.openVinewoodMenu()
    end)

    SetTimeout(1000, function()
        actionLocked = false
    end)
end

if pr_lib and pr_lib.command then
    pr_lib.command(PR.Vinewood.Command or 'vinewood', {
        help = t('commands.vinewood_help'),
    }, function()
        Menu.openVinewoodMenu()
    end)
else
    RegisterCommand(PR.Vinewood.Command or 'vinewood', function()
        Menu.openVinewoodMenu()
    end, false)
end
