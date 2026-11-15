-- Complete installed command bodies; only descriptors are collected.
return function(ports)
    local library,service,translate=assert(ports.library),assert(ports.service),assert(ports.translate)
    local PR,native={Staff=assert(ports.config),NotifyPos=ports.notifyPosition},assert(ports.native)
    local api={Commands={}}
    local function describeCommand(name,options,handler)api.Commands[#api.Commands+1]={name=name,options=options,handler=handler,mode='library'}end
    local function describeNativeCommand(name,handler,restricted)api.Commands[#api.Commands+1]={name=name,handler=handler,restricted=restricted,mode='native'}end
local function registerCommand(commandName, properties, callback)
    if library and library.command then
        return describeCommand(commandName, properties, callback)
    end

    describeNativeCommand(commandName, function(source, args, raw)
        callback(source, args, raw, {})
    end, false)

    return true
end

local function notify(source, description, notifyType)
    if not library or not library.notify or not library.notify.NotifyPlayer or source <= 0 then
        if library and library.debug and library.debug.info then
            library.debug.info(description)
        end

        return
    end

    library.notify.NotifyPlayer(source, {
        title = translate('staff.title'),
        description = description,
        type = notifyType or 'info',
        position = PR.NotifyPos,
    })
end

local function openStaffMenu(source)
    if not service.canManage(source) then return end
    if source <= 0 then
        notify(source, translate('debug.commands.client_only'), 'error')
        return
    end

    library.callback.awaitClient(source, PR.Staff.Callbacks.openMenu, 5000)
end

registerCommand(PR.Staff.Commands.menu, {
    help = translate('commands.staff_help'),
    canAccess = function(source)
        return service.canManage(source)
    end,
}, function(source)
    openStaffMenu(source)
end)

registerCommand(PR.Staff.Commands.direct, {
    help = translate('commands.staff_direct_help'),
    params = {
        { name = 'id', type = 'playerId', help = translate('inputs.player_id') },
        { name = 'action', type = 'string', help = 'add/rem' },
        { name = 'role', type = 'string', help = translate('inputs.staff_role'), optional = true },
    },
    canAccess = function(source)
        return service.canManage(source)
    end,
}, function(source, params)
    local targetSource = tonumber(params.id and params.id.value)
    local action = tostring(params.action and params.action.value or ''):lower()
    local role = params.role and params.role.value

    if action == 'add' then
        local ok, result = service.add(source, {
            source = targetSource,
            role = role,
        })

        if not ok then
            notify(source, translate('notify.staff.action_failed', { error = tostring(result) }), 'error')
        end

        return
    end

    if action == 'rem' or action == 'remove' then
        local ok, result = service.remove(source, {
            source = targetSource,
        })

        if not ok then
            notify(source, translate('notify.staff.action_failed', { error = tostring(result) }), 'error')
        end

        return
    end

    notify(source, translate('notify.staff.invalid_action'), 'error')
end)

describeNativeCommand('forgeace', function(source, args)
    if source > 0 and not service.canManage(source) then
        notify(source, 'Sem permissao para diagnosticar ACE.', 'error')
        return
    end

    local action = tostring(args[1] or 'status'):lower()
    if action ~= 'status' then
        notify(source, 'forgeace e somente leitura. Use: forgeace status [id].', 'error')
        return
    end

    local targetSource = tonumber(args[2]) or source
    local status = service.permissionDiagnostics
        and service.permissionDiagnostics(targetSource)
        or service.permissionStatus(targetSource)
    local lines = {}
    local compactLines = {}
    local compactAces = {
        ['forge-core.admin'] = true,
        admin = true,
        ['group.admin'] = true,
        ['group.mod'] = true,
        ['group.staff'] = true,
        ['pr_bridge.developer'] = true,
    }

    for _, item in ipairs(status) do
        local allowed = item.allowed and 'sim' or 'nao'
        local entry = ('%s=%s metadata=%s parent=%s parentAce=%s'):format(
            item.ace, allowed, item.stored and 'sim' or 'nao',
            item.parent or '-', item.parentAllowed and 'sim' or 'nao'
        )
        lines[#lines + 1] = entry
        if compactAces[item.ace] then
            compactLines[#compactLines + 1] = ('%s=%s'):format(item.ace, allowed)
        end
    end

    local message = table.concat(lines, ' | ')

    if source > 0 then
        notify(source, table.concat(compactLines, ' | '), 'info')
        native.print(('[forge-core] ACE status %s requested by %s: %s'):format(targetSource, source, message))
    else
        native.print(('[forge-core] ACE status %s: %s'):format(targetSource, message))
    end
end, false)
    return api
end

