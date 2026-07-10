ForgeCore = ForgeCore or {}

local function registerCommand(commandName, properties, callback)
    if pr_lib and pr_lib.command then
        return pr_lib.command(commandName, properties, callback)
    end

    RegisterCommand(commandName, function(source, args, raw)
        callback(source, args, raw, {})
    end, false)

    return true
end

local function notify(source, description, notifyType)
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer or source <= 0 then
        if pr_lib and pr_lib.debug and pr_lib.debug.info then
            pr_lib.debug.info(description)
        end

        return
    end

    pr_lib.notify.NotifyPlayer(source, {
        title = ForgeCore.t('staff.title'),
        description = description,
        type = notifyType or 'info',
        position = PR.NotifyPos,
    })
end

local function openStaffMenu(source)
    if not ForgeCore.StaffService.canManage(source) then return end
    if source <= 0 then
        notify(source, ForgeCore.t('debug.commands.client_only'), 'error')
        return
    end

    pr_lib.callback.await(source, PR.Staff.Callbacks.openMenu, 5000)
end

registerCommand(PR.Staff.Commands.menu, {
    help = ForgeCore.t('commands.staff_help'),
    canAccess = function(source)
        return ForgeCore.StaffService.canManage(source)
    end,
}, function(source)
    openStaffMenu(source)
end)

registerCommand(PR.Staff.Commands.direct, {
    help = ForgeCore.t('commands.staff_direct_help'),
    params = {
        { name = 'id', type = 'playerId', help = ForgeCore.t('inputs.player_id') },
        { name = 'action', type = 'string', help = 'add/rem' },
        { name = 'role', type = 'string', help = ForgeCore.t('inputs.staff_role'), optional = true },
    },
    canAccess = function(source)
        return ForgeCore.StaffService.canManage(source)
    end,
}, function(source, params)
    local targetSource = tonumber(params.id and params.id.value)
    local action = tostring(params.action and params.action.value or ''):lower()
    local role = params.role and params.role.value

    if action == 'add' then
        local ok, result = ForgeCore.StaffService.add(source, {
            source = targetSource,
            role = role,
        })

        if not ok then
            notify(source, ForgeCore.t('notify.staff.action_failed', { error = tostring(result) }), 'error')
        end

        return
    end

    if action == 'rem' or action == 'remove' then
        local ok, result = ForgeCore.StaffService.remove(source, {
            source = targetSource,
        })

        if not ok then
            notify(source, ForgeCore.t('notify.staff.action_failed', { error = tostring(result) }), 'error')
        end

        return
    end

    notify(source, ForgeCore.t('notify.staff.invalid_action'), 'error')
end)

RegisterCommand('forgeace', function(source, args)
    if source > 0 and not ForgeCore.StaffService.canManage(source) then
        notify(source, 'Sem permissao para diagnosticar ACE.', 'error')
        return
    end

    local action = tostring(args[1] or 'status'):lower()
    local targetSource = tonumber(args[2]) or source

    if action == 'apply' or action == 'fix' then
        if targetSource <= 0 then
            print('[forge-core] Use: forgeace apply <id>')
            return
        end

        ForgeCore.StaffService.forceApply(targetSource, 'group.admin')
        notify(targetSource, 'Permissoes admin reaplicadas pelo Forge Core.', 'success')
    end

    local status = ForgeCore.StaffService.permissionStatus(targetSource)
    local lines = {}

    for _, item in ipairs(status) do
        lines[#lines + 1] = ('%s=%s'):format(item.ace, item.allowed and 'sim' or 'nao')
    end

    local message = table.concat(lines, ' | ')

    if source > 0 then
        notify(source, message, 'info')
    else
        print(('[forge-core] ACE status %s: %s'):format(targetSource, message))
    end
end, false)
