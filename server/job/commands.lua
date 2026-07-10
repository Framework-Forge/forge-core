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

local function openMenu(source)
    if not ForgeCore.JobService.canManage(source) then return end
    if source == 0 then
        if pr_lib and pr_lib.debug and pr_lib.debug.info then
            pr_lib.debug.info(ForgeCore.t('debug.commands.client_only'))
        end

        return
    end

    ForgeCore.JobService.sendTo(source)
    pr_lib.callback.await(source, PR.Job.Callbacks.openMenu, 5000)
end

local function notify(source, data)
    if source <= 0 then
        if pr_lib and pr_lib.debug and pr_lib.debug.info then
            pr_lib.debug.info(data.description or data.title or ForgeCore.t('core.title'))
        end

        return
    end

    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('core.title'),
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
        label = ('MEI Teste %s %s'):format(source, os.time())
    end

    return label, count
end

local function testMei(source, args)
    if source <= 0 then
        notify(source, {
            title = ForgeCore.t('mei.title'),
            description = ForgeCore.t('debug.commands.client_only'),
            type = 'error',
        })
        return
    end

    local label, count = parseTestMeiArgs(source, args)
    local ok, result = ForgeCore.JobService.createMei(source, {
        label = label,
        grades = buildTestMeiGrades(count),
    })

    if not ok then
        notify(source, {
            title = ForgeCore.t('mei.title'),
            description = ForgeCore.t('notify.mei.create_failed', { error = tostring(result or 'unknown') }),
            type = 'error',
        })
        return
    end

    ForgeCore.JobService.broadcast(-1)
end

registerCommand(PR.Job.Commands.open, {
    help = ForgeCore.t('commands.open_help'),
    canAccess = function(source)
        return ForgeCore.JobService.canManage(source)
    end,
}, function(source)
    openMenu(source)
end)

registerCommand(PR.Job.Commands.testMei, {
    help = ForgeCore.t('commands.test_mei_help'),
}, function(source, args)
    testMei(source, args)
end)

registerCommand(PR.Job.Commands.jobs, {
    help = ForgeCore.t('commands.jobs_help'),
    canAccess = function(source)
        return ForgeCore.JobService.canManage(source)
    end,
}, function(source)
    openMenu(source)
end)
