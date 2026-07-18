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
        if pr_lib and pr_lib.debug and pr_lib.debug.info then
            pr_lib.debug.info(description)
        end

        return
    end

    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = ForgeCore.t('npcs.title'),
        description = description,
        type = notifyType or 'inform',
        position = PR.NotifyPos,
    })
end

registerCommand(PR.Npcs.DeleteCommand or 'npcdelete', {
    help = ForgeCore.t('commands.npc_delete_help'),
    params = {
        {
            name = 'id',
            type = 'number',
            help = ForgeCore.t('inputs.npc_id'),
        },
    },
    canAccess = function(source)
        return ForgeCore.NpcsService.canManage(source)
    end,
}, function(source, args)
    local npcId = tonumber(args and (args.id or args[1]))
    local ok, response = ForgeCore.NpcsService.deleteNpc(source, npcId)

    if not ok then
        notify(source, ForgeCore.t('notify.npcs.delete_failed', { error = tostring(response or 'unknown') }), 'error')
        return
    end

    if source <= 0 then
        notify(source, ForgeCore.t('notify.npcs.npc_deleted'), 'success')
    end
end)
