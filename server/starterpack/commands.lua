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
    if source <= 0 then
        print(('[forge-core] %s'):format(description))
        return
    end

    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = ForgeCore.t('starterpack.title'),
        description = description,
        type = notifyType or 'inform',
        position = PR.NotifyPos,
    })
end

registerCommand('teststartpack', {
    help = ForgeCore.t('commands.test_starterpack_help'),
    params = {
        {
            name = 'id',
            type = 'number',
            help = ForgeCore.t('inputs.target_source'),
            optional = true,
        },
    },
    canAccess = function(source)
        return ForgeCore.StarterpackService and ForgeCore.StarterpackService.canManage(source)
    end,
}, function(source, args)
    local target = tonumber(args and (args.id or args[1])) or source
    if target <= 0 then
        notify(source, ForgeCore.t('notify.starterpack.invalid_player'), 'error')
        return
    end

    local ok, response = ForgeCore.StarterpackService.startPrologueTest(source, target)
    if not ok then
        notify(source, ForgeCore.t('notify.starterpack.give_failed', { error = tostring(response or 'unknown') }), 'error')
        return
    end

    if source ~= target then
        notify(source, ForgeCore.t('notify.starterpack.test_started_for_player', { id = tostring(target) }), 'success')
    end
end)
