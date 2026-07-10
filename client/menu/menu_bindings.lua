ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local debug = Shared.debug

local function openMainMenu()
    if Menu and Menu.openMain then
        Menu.openMain()
        return true
    end

    debug('warn', '[forge-core] Menu.openMain indisponivel.')
    return false
end

local function openPlayerMenu()
    if Menu and Menu.openPlayerMenu then
        Menu.openPlayerMenu()
        return true
    end

    debug('warn', '[forge-core] Menu.openPlayerMenu indisponivel.')
    return false
end

local function registerOpenCommand()
    local commandName = PR.Command or 'forgecore'

    if pr_lib and pr_lib.command then
        return pr_lib.command(commandName, {
            help = t('commands.open_help'),
        }, function()
            openMainMenu()
        end)
    end

    RegisterCommand(commandName, function()
        openMainMenu()
    end, false)

    return true
end

registerOpenCommand()

if pr_lib and pr_lib.addKeybind then
    pr_lib.addKeybind({
        name = 'forge_core_open_menu',
        description = t('keybind.open_menu'),
        key = PR.Keybind,
        keys = PR.Keybind,
        defaultKey = PR.Keybind,
        onPressed = function(self)
            local combo = self and self.currentKey or table.concat(PR.Keybind or {}, ' + ')
            debug('info', t('debug.keybind.executed', { combo = combo }))
            openMainMenu()
        end,
    })

    pr_lib.addKeybind({
        name = 'forge_core_open_player_menu',
        description = t('keybind.open_player_menu'),
        key = PR.PlayerKeybind,
        keys = PR.PlayerKeybind,
        defaultKey = PR.PlayerKeybind,
        onPressed = function(self)
            local combo = self and self.currentKey or table.concat(PR.PlayerKeybind or {}, ' + ')
            debug('info', t('debug.keybind.executed', { combo = combo }))
            openPlayerMenu()
        end,
    })
else
    debug('warn', t('debug.keybind.unavailable'))
end
