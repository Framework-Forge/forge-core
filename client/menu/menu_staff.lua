ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local alertDialog = Shared.alertDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local clone = Shared.clone
local staffRoleOptions = Shared.staffRoleOptions
local nearbyServerIds = Shared.nearbyServerIds


local staffActionLocked = false

function Menu.openStaffMenu()
    showContext({
        id = 'forge_core_staff',
        title = t('menu.staff.title'),
        menu = 'forge_core_main',
        options = {
            {
                title = t('menu.staff.add_by_id'),
                description = t('menu.staff.add_by_id_description'),
                icon = 'user-plus',
                onSelect = function()
                    Menu.openStaffAddById()
                end,
            },
            {
                title = t('menu.staff.add_nearby'),
                description = t('menu.staff.add_nearby_description'),
                icon = 'scan',
                onSelect = function()
                    Menu.openStaffNearbyList()
                end,
            },
            {
                title = t('menu.staff.members'),
                description = t('menu.staff.members_description'),
                icon = 'list',
                onSelect = function()
                    Menu.openStaffList()
                end,
            },
        },
    })
end

function Menu.openStaffAddById(staffData)
    local result = inputDialog(t('menu.staff.add_staff'), {
        {
            type = 'number',
            label = t('inputs.player_id'),
            default = staffData and staffData.source,
            disabled = staffData and staffData.source ~= nil,
            required = true,
            min = 1,
        },
        {
            type = 'select',
            label = t('inputs.staff_role'),
            options = staffRoleOptions(),
            required = true,
            searchable = true,
        },
    })

    if not result then return Menu.openStaffMenu() end
    if staffActionLocked then return Menu.openStaffMenu() end

    staffActionLocked = true

    local ok, response = awaitServer(PR.Staff.Callbacks.add, {
        source = tonumber(result[1]),
        role = result[2],
    })

    if not ok then
        notifyFailure('notify.staff.action_failed', response)
    end

    SetTimeout(500, function()
        Menu.openStaffList()
    end)

    SetTimeout(1000, function()
        staffActionLocked = false
    end)
end

function Menu.openStaffNearbyList()
    local ids = nearbyServerIds(10.0)
    local ok, players = awaitServer(PR.Staff.Callbacks.getPlayers, ids)
    if not ok then
        notifyFailure('notify.staff.action_failed', players)
        return Menu.openStaffMenu()
    end

    players = type(players) == 'table' and players or {}
    local options = {}

    for _, player in ipairs(players) do
        options[#options + 1] = {
            title = player.name,
            description = t('menu.staff.player_description', {
                source = tostring(player.source or ''),
                citizenid = tostring(player.citizenId or player.citizenid or ''),
            }),
            icon = 'user-plus',
            onSelect = function()
                Menu.openStaffAddById(player)
            end,
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.staff.no_nearby'),
            icon = 'circle-info',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_staff_nearby',
        title = t('menu.staff.add_nearby'),
        menu = 'forge_core_staff',
        options = options,
    })
end

function Menu.openStaffList()
    local ok, payload = awaitServer(PR.Staff.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.staff.action_failed', payload)
        return Menu.openStaffMenu()
    end

    payload = type(payload) == 'table' and payload or {}
    local staff = type(payload.staff) == 'table' and payload.staff or {}
    local options = {}

    for _, member in ipairs(staff) do
        options[#options + 1] = {
            title = member.displayName or member.name,
            description = t('menu.staff.member_description', {
                source = tostring(member.source or t('common.offline')),
                role = tostring(member.roleLabel or member.role or ''),
            }),
            icon = member.offline and 'user-x' or 'user-check',
            onSelect = function()
                Menu.openStaffDetails(member)
            end,
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.staff.no_members'),
            icon = 'circle-info',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_staff_list',
        title = t('menu.staff.members'),
        description = t('menu.staff.counts', {
            online = tostring(payload.onlineStaff or 0),
            total = tostring((payload.onlineStaff or 0) + (payload.offlineStaff or 0)),
        }),
        menu = 'forge_core_staff',
        options = options,
    })
end

function Menu.openStaffDetails(member)
    showContext({
        id = 'forge_core_staff_details_' .. tostring(member.citizenId or member.source),
        title = member.name or member.displayName,
        menu = 'forge_core_staff_list',
        options = {
            {
                title = t('menu.staff.change_role'),
                description = t('menu.staff.change_role_description'),
                icon = 'refresh-cw',
                onSelect = function()
                    Menu.openStaffChangeRole(member)
                end,
            },
            {
                title = t('menu.staff.remove'),
                description = t('menu.staff.remove_description'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_staff_header'),
                        content = t('dialogs.remove_staff_content', { name = member.name or member.displayName }),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        local ok, response = awaitServer(PR.Staff.Callbacks.remove, member)
                        if not ok then
                            notifyFailure('notify.staff.action_failed', response)
                        end
                    end

                    SetTimeout(500, function()
                        Menu.openStaffList()
                    end)
                end,
            },
        },
    })
end

function Menu.openStaffChangeRole(member)
    local result = inputDialog(t('menu.staff.change_role'), {
        {
            type = 'select',
            label = t('inputs.staff_role'),
            options = staffRoleOptions(),
            default = tostring(member.role or ''):gsub('^group%.', ''),
            required = true,
            searchable = true,
        },
    })

    if not result then return Menu.openStaffDetails(member) end
    if staffActionLocked then return Menu.openStaffDetails(member) end

    staffActionLocked = true

    local data = clone(member)
    data.role = result[1]

    local ok, response = awaitServer(PR.Staff.Callbacks.add, data)
    if not ok then
        notifyFailure('notify.staff.action_failed', response)
    end

    SetTimeout(500, function()
        Menu.openStaffList()
    end)

    SetTimeout(1000, function()
        staffActionLocked = false
    end)
end

pr_lib.callback.register(PR.Staff.Callbacks.openMenu, function()
    Menu.openStaffMenu()
    return true
end)

