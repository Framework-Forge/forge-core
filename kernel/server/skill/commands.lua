-- Complete command body; descriptors only, no public registration.
return function(ports)
    local PR,service={Skills=assert(ports.config)},assert(ports.service)
    local library,translate=ports.library,assert(ports.translate)
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

local function openSkillsMenu(source)
    if not service.canManage(source) then return end
    if source == 0 then
        if library and library.debug and library.debug.info then
            library.debug.info(translate('debug.commands.client_only'))
        end

        return
    end

    library.callback.awaitClient(source, PR.Skills.Callbacks.openAdmin, 5000)
end

registerCommand(PR.Skills.Commands.admin, {
    help = translate('commands.skills_help'),
    canAccess = function(source)
        return service.canManage(source)
    end,
}, function(source)
    openSkillsMenu(source)
end)
    return api
end

