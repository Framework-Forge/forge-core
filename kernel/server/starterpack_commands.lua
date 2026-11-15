return function(ports)
    local PR,library,service,translate=assert(ports.config),assert(ports.library),assert(ports.service),assert(ports.translate)
    local print=assert(ports.print)
    local commands={}
    local function describeCommand(name,properties,handler)commands[#commands+1]={name=name,properties=properties,handler=handler,provider='pr'};return true end
    local function describeNativeCommand(name,handler,restricted)commands[#commands+1]={name=name,handler=handler,restricted=restricted,provider='native'}end
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
    if source <= 0 then
        print(('[forge-core] %s'):format(description))
        return
    end

    if not library or not library.notify or not library.notify.NotifyPlayer then return end

    library.notify.NotifyPlayer(source, {
        title = translate('starterpack.title'),
        description = description,
        type = notifyType or 'inform',
        position = PR.NotifyPos,
    })
end

registerCommand('teststartpack', {
    help = translate('commands.test_starterpack_help'),
    params = {
        {
            name = 'id',
            type = 'number',
            help = translate('inputs.target_source'),
            optional = true,
        },
    },
    canAccess = function(source)
        return service and service.canManage(source)
    end,
}, function(source, args)
    local target = tonumber(args and (args.id or args[1])) or source
    if target <= 0 then
        notify(source, translate('notify.starterpack.invalid_player'), 'error')
        return
    end

    local ok, response = service.startPrologueTest(source, target)
    if not ok then
        notify(source, translate('notify.starterpack.give_failed', { error = tostring(response or 'unknown') }), 'error')
        return
    end

    if source ~= target then
        notify(source, translate('notify.starterpack.test_started_for_player', { id = tostring(target) }), 'success')
    end
end)
    return commands
end
