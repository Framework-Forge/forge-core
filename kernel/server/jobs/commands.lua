-- Inactive complete job commands; declarations preserve PR/native modes, no command registration.
return function(ports)
    local services, PR, library = assert(ports.services), assert(ports.config), assert(ports.library)
    local translate, clock = assert(ports.translate), assert(ports.time)
    local api = {Commands={}}
    local function describeCommand(name, options, handler)
        api.Commands[#api.Commands+1] = {name=name,options=options,handler=handler,mode='library'}
    end
    local function describeNativeCommand(name, handler, restricted)
        api.Commands[#api.Commands+1] = {name=name,handler=handler,restricted=restricted,mode='native'}
    end
local function registerCommand(commandName, properties, callback)
    if library and library.command then
        return describeCommand(commandName, properties, callback)
    end

    describeNativeCommand(commandName, function(source, args, raw)
        callback(source, args, raw, {})
    end, false)

    return true
end

local function openMenu(source)
    if not services.JobService.canManage(source) then return end
    if source == 0 then
        if library and library.debug and library.debug.info then
            library.debug.info(translate('debug.commands.client_only'))
        end

        return
    end

    services.JobService.sendTo(source)
    library.callback.awaitClient(source, PR.Job.Callbacks.openMenu, 5000)
end

local function notify(source, data)
    if source <= 0 then
        if library and library.debug and library.debug.info then
            library.debug.info(data.description or data.title or translate('core.title'))
        end

        return
    end

    if not library or not library.notify or not library.notify.NotifyPlayer then return end

    library.notify.NotifyPlayer(source, {
        title = data.title or translate('core.title'),
        description = data.description,
        type = data.type,
        position = PR.NotifyPos,
    })
end

local function buildTestMeiGrades(count)
    local grades = {}
    count = math.max(1, math.min(10, math.floor(tonumber(count) or 3)))

    for grade = 0, count - 1 do
        grades[grade] = {
            name = grade == count - 1 and 'Proprietario' or ('Cargo %s'):format(grade),
            payment = 0,
            isboss = grade == count - 1,
            bankAuth = grade == count - 1,
        }
    end

    return grades
end

local function parseTestMeiArgs(source, args)
    local first = tonumber(args and args[1])
    local count = first or 3
    local startIndex = first and 2 or 1
    local parts = {}

    for index = startIndex, #(args or {}) do
        parts[#parts + 1] = args[index]
    end

    local label = table.concat(parts, ' ')
    if label == '' then
        label = ('MEI Teste %s %s'):format(source, clock())
    end

    return label, count
end

local function testMei(source, args)
    if source <= 0 then
        notify(source, {
            title = translate('mei.title'),
            description = translate('debug.commands.client_only'),
            type = 'error',
        })
        return
    end

    local label, count = parseTestMeiArgs(source, args)
    local ok, result = services.JobService.createMei(source, {
        label = label,
        grades = buildTestMeiGrades(count),
    })

    if not ok then
        notify(source, {
            title = translate('mei.title'),
            description = translate('notify.mei.create_failed', { error = tostring(result or 'unknown') }),
            type = 'error',
        })
        return
    end

    services.JobService.broadcast(-1)
end

registerCommand(PR.Job.Commands.open, {
    help = translate('commands.open_help'),
    canAccess = function(source)
        return services.JobService.canManage(source)
    end,
}, function(source)
    openMenu(source)
end)

registerCommand(PR.Job.Commands.testMei, {
    help = translate('commands.test_mei_help'),
}, function(source, args)
    testMei(source, args)
end)

registerCommand(PR.Job.Commands.jobs, {
    help = translate('commands.jobs_help'),
    canAccess = function(source)
        return services.JobService.canManage(source)
    end,
}, function(source)
    openMenu(source)
end)


return api
end
