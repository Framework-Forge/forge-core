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

local function openSkillsMenu(source)
    if not ForgeCore.SkillService.canManage(source) then return end
    if source == 0 then
        if pr_lib and pr_lib.debug and pr_lib.debug.info then
            pr_lib.debug.info(ForgeCore.t('debug.commands.client_only'))
        end

        return
    end

    pr_lib.callback.await(source, PR.Skills.Callbacks.openAdmin, 5000)
end

registerCommand(PR.Skills.Commands.admin, {
    help = ForgeCore.t('commands.skills_help'),
    canAccess = function(source)
        return ForgeCore.SkillService.canManage(source)
    end,
}, function(source)
    openSkillsMenu(source)
end)
