ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure

local function fetchPlayerInfo()
    local ok, payload = awaitServer(PR.Player.Callbacks.getInfo)
    if not ok then
        notifyFailure('notify.player.load_failed', payload)
        return nil
    end

    return type(payload) == 'table' and payload or nil
end

function Menu.openPlayerMenu()
    local info = fetchPlayerInfo()
    if not info then return false end

    showContext({
        id = 'forge_core_player_menu',
        title = t('menu.player.title'),
        options = {
            {
                title = t('menu.player.name'),
                description = ('%s %s'):format(info.firstname or '', info.lastname or ''),
                icon = 'user',
                disabled = true,
            },
            {
                title = t('menu.player.age'),
                description = tostring(info.age or t('common.none')),
                icon = 'calendar-clock',
                disabled = true,
            },
            {
                title = t('menu.player.birthdate'),
                description = tostring(info.birthdate or t('common.none')),
                icon = 'calendar-days',
                disabled = true,
            },
            {
                title = t('menu.player.nationality'),
                description = tostring(info.nationality or t('common.none')),
                icon = 'flag',
                disabled = true,
            },
            {
                title = t('menu.player.job'),
                description = tostring(info.job or t('common.none')),
                icon = 'briefcase',
                disabled = true,
            },
            {
                title = t('menu.player.gang'),
                description = tostring(info.gang or t('common.none')),
                icon = 'users',
                disabled = true,
            },
            {
                title = t('menu.skills.my_skills'),
                description = t('menu.player.skills_description'),
                icon = 'brain',
                arrow = true,
                onSelect = function()
                    Menu.openPlayerSkillsMenu('forge_core_player_menu')
                end,
            },
        },
    })

    return true
end
