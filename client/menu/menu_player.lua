ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure

local function displayScalar(value)
    if type(value) ~= 'string' and type(value) ~= 'number' and type(value) ~= 'boolean' then
        return t('common.none')
    end

    local text = tostring(value)
    if text == '' or text:match('^table:%s*0?x?[%x]+$') then
        return t('common.none')
    end

    return text
end

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
    info = info or {}

    showContext({
        id = 'forge_core_player_menu',
        title = t('menu.player.title'),
        options = {
            {
                title = 'Logout',
                description = 'Salva o personagem atual e volta para a seleção de personagens.',
                icon = 'person-switch',
                onSelect = function()
                    local ok, reason = awaitServer(PR.CharacterSlots.playerCallbacks.logout)
                    if not ok then notifyFailure('notify.player.load_failed', reason) end
                end,
            },
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
                icon = 'person-fill',
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
                    displayScalar(info.extra)
                ),
                icon = 'briefcase',
                iconColor = '#ffffff',
            },
            {
                title = 'VIP',
                description = ('Classe: %s\\nValidade: %s'):format(tostring(info.vip or 'Standard'), tostring(info.vipExpiresAtFormatted or 'Sem VIP')),
                icon = 'star-fill',
                iconColor = info.vip and info.vip ~= 'Standard' and '#f5c542' or '#ffffff',
            },
            {
                title = t('menu.multijob.title'),
                description = t('menu.multijob.player_description'),
                icon = 'briefcase-fill',
                arrow = true,
                onSelect = function()
                    Menu.openMultiJobMenu('forge_core_player_menu')
                end,
            },
            {
                title = t('menu.skills.my_skills'),
                description = t('menu.player.skills_description'),
                icon = 'activity',
                arrow = true,
                onSelect = function()
                    Menu.openPlayerSkillsMenu('forge_core_player_menu')
                end,
            },
        },
    })

    return true
end
