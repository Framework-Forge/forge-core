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
                title = t('menu.player.personal_data'),
                description = ('%s: %s %s\n%s: %s\n%s: %s\n%s: %s'):format(
                    t('menu.player.name'),
                    info.firstname or '',
                    info.lastname or '',
                    t('menu.player.age'),
                    tostring(info.age or t('common.none')),
                    t('menu.player.birthdate_short'),
                    tostring(info.birthdate or t('common.none')),
                    t('menu.player.nationality'),
                    tostring(info.nationality or t('common.none'))
                ),
                icon = 'user',
                iconColor = '#ffffff',
            },
            {
                title = t('menu.player.roles'),
                description = ('%s: %s\n%s: %s\n%s: %s'):format(
                    t('menu.player.job'),
                    tostring(info.job or t('common.none')),
                    t('menu.player.gang'),
                    tostring(info.gang or t('common.none')),
                    t('menu.player.extra'),
                    tostring(info.extra or t('common.none'))
                ),
                icon = 'briefcase',
                iconColor = '#ffffff',
            },
            {
                title = t('menu.multijob.title'),
                description = t('menu.multijob.player_description'),
                icon = 'briefcase-business',
                arrow = true,
                onSelect = function()
                    Menu.openMultiJobMenu('forge_core_player_menu')
                end,
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
