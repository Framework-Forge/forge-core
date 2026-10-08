ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu or {}
ForgeCore.Client.Menu = Menu
local Shared = ForgeCore.Client.MenuShared or {}
ForgeCore.Client.MenuShared = Shared

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function debug(level, message)
    local debugApi = pr_lib and pr_lib.debug
    if not debugApi then return end

    local fn = debugApi[level]
    if type(fn) == 'function' then
        fn(message)
    elseif type(debugApi) == 'function' then
        debugApi(level, message)
    end
end

local function notify(data)
    if pr_lib and pr_lib.Notify then
        pr_lib.Notify({
            title = data.title or t('core.title'),
            description = data.description,
            type = data.type,
            position = PR.NotifyPos,
        })
    end
end

local function showContext(context)
    if not pr_lib or not pr_lib.menus or not pr_lib.menus.RegisterContext or not pr_lib.menus.ShowContext then
        notify({
            title = t('core.title'),
            description = t('errors.no_menu_system'),
            type = 'error',
        })
        return false
    end

    pr_lib.menus.RegisterContext(context)
    pr_lib.menus.ShowContext(context.id)
    return true
end

local function inputDialog(title, rows, options)
    if not pr_lib or not pr_lib.menus or not pr_lib.menus.InputDialog then
        notify({
            title = t('core.title'),
            description = t('errors.no_input_dialog'),
            type = 'error',
        })
        return nil
    end

    return pr_lib.menus.InputDialog(title, rows, options)
end

local function alertDialog(data)
    if not pr_lib or not pr_lib.menus or not pr_lib.menus.AlertDialog then return nil end
    return pr_lib.menus.AlertDialog(data)
end

local function awaitServer(callbackName, ...)
    if not pr_lib or not pr_lib.callback or not pr_lib.callback.await then
        return false, 'callback_unavailable'
    end

    return pr_lib.callback.await(callbackName, 10000, ...)
end

local function notifyFailure(localeKey, error)
    notify({
        title = t('core.title'),
        description = t(localeKey, { error = tostring(error or 'unknown') }),
        type = 'error',
    })
end

local function openGarageAdminMenu()
    local config = PR.Garage and PR.Garage.AdminMenu or {}
    if config.enabled == false then return false end

    local resource = config.resource or 'forge-garage'
    if GetResourceState(resource) ~= 'started' then
        notify({
            title = t('garage.title'),
            description = t('errors.garage_resource_unavailable', { resource = resource }),
            type = 'error',
        })
        return false
    end

    TriggerEvent(
        config.event or 'forge_garage:client:garagelist',
        'forge_core_main',
        GetCurrentResourceName()
    )
    return true
end

local function openRentalAdminMenu()
    local config = PR.Rental and PR.Rental.AdminMenu or {}
    if config.enabled == false then return false end

    local resource = config.resource or 'forge-rental'
    if GetResourceState(resource) ~= 'started' then
        notify({
            title = t('rental.title'),
            description = t('errors.rental_resource_unavailable', { resource = resource }),
            type = 'error',
        })
        return false
    end

    TriggerServerEvent(config.event or 'forge-rental:server:openAdminMenu', 'forge-core')
    return true
end

local function openDocumentsAdminMenu()
    local resource = 'forge-dk'
    if GetResourceState(resource) ~= 'started' then
        notify({ title = t('panels.documents.title'), description = t('panels.unavailable', { resource = resource }), type = 'error' })
        return false
    end
    -- The export calls DK's server-side admin permission check before opening NUI.
    local called, result = pcall(function() return exports[resource]:OpenAdminPanel() end)
    if not called or type(result) ~= 'table' or result.ok ~= true then
        notify({ title = t('panels.documents.title'), description = t('panels.failed'), type = 'error' })
        return false
    end
    return true
end

local function openInterfaceAdminMenu()
    if not pr_lib or type(pr_lib.openVisualAdminMenu) ~= 'function' then
        notify({
            title = t('menu.interface.title'),
            description = t('errors.no_menu_system'),
            type = 'error',
        })
        return false
    end

    pr_lib.openVisualAdminMenu('forge_core_main')
    return true
end

local function groupTitle(group)
    return ('%s - %s'):format(group.label or group.name, group.name or group.job)
end

local clone = pr_lib.table.clone

local countGrades = pr_lib.table.count

local function listGrades(grades)
    local list = {}

    for key, grade in pairs(grades or {}) do
        list[#list + 1] = {
            level = tonumber(key) or key,
            key = key,
            data = grade,
        }
    end

    table.sort(list, function(left, right)
        if type(left.level) == 'number' and type(right.level) == 'number' then
            return left.level < right.level
        end

        return tostring(left.level) < tostring(right.level)
    end)

    return list
end

local function nextGradeLevel(grades)
    local highest = -1

    for key in pairs(grades or {}) do
        local level = tonumber(key)
        if level and level > highest then
            highest = level
        end
    end

    return highest + 1
end

local function boolLabel(value)
    return value and t('common.yes') or t('common.no')
end

local function boolValue(value)
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'sim'
end

local function boolDefault(value)
    return value and 'true' or 'false'
end

local function boolOptions()
    return {
        { value = 'true', label = t('common.yes') },
        { value = 'false', label = t('common.no') },
    }
end

local function accountOptions()
    return {
        { value = 'bank', label = t('payments.accounts.bank') },
        { value = 'cash', label = t('payments.accounts.cash') },
        { value = 'crypto', label = t('payments.accounts.crypto') },
    }
end

local function accountLabel(account)
    if account == 'cash' then return t('payments.accounts.cash') end
    if account == 'crypto' then return t('payments.accounts.crypto') end
    return t('payments.accounts.bank')
end

local function buildJobTypeOptions()
    local options = {}

    for i = 1, #(PR.Job.Types or {}) do
        options[#options + 1] = {
            value = PR.Job.Types[i].value,
            label = PR.Job.Types[i].label,
        }
    end

    return options
end

local function skillCalculationOptions()
    return {
        { value = PR.Skills.Calculation.direct, label = t('skills.calculation.direct') },
        { value = PR.Skills.Calculation.sumReputations, label = t('skills.calculation.sum_reputations') },
    }
end

local function calculationLabel(value)
    if value == PR.Skills.Calculation.sumReputations then
        return t('skills.calculation.sum_reputations')
    end

    return t('skills.calculation.direct')
end

local function fetchSkillsPayload()
    local payload = awaitServer(PR.Skills.Callbacks.getAll)
    if type(payload) ~= 'table' then return { skills = {}, reputations = {} } end

    payload.skills = type(payload.skills) == 'table' and payload.skills or {}
    payload.reputations = type(payload.reputations) == 'table' and payload.reputations or {}

    return payload
end

local function countLinkedReputations(payload, skillName)
    local total = 0

    for _, reputation in ipairs(payload.reputations or {}) do
        if reputation.skill == skillName or reputation.linkedSkill == skillName then
            total = total + 1
        end
    end

    return total
end

local function skillSelectOptions(payload)
    local options = {}

    for _, skill in ipairs(payload.skills or {}) do
        options[#options + 1] = {
            value = skill.name,
            label = ('%s - %s'):format(skill.label or skill.name, skill.name),
        }
    end

    return options
end

local function levelCount(item)
    return type(item.levels) == 'table' and #item.levels or 0
end

local function saveSkillDefinition(kind, item)
    local callback = kind == 'rep' and PR.Skills.Callbacks.saveReputation or PR.Skills.Callbacks.saveSkill
    local ok, response = awaitServer(callback, item)
    if not ok then
        notifyFailure('notify.skills.save_failed', response)
        return false
    end

    return true, response
end

local function staffRoleOptions()
    local options = {}

    for _, role in ipairs(PR.Staff.Roles or {}) do
        options[#options + 1] = {
            value = role.value,
            label = role.label,
        }
    end

    return options
end

local function nearbyServerIds(radius)
    local ids = {}
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    radius = tonumber(radius) or 10.0

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if targetPed and targetPed ~= 0 then
                local distance = #(coords - GetEntityCoords(targetPed))
                if distance <= radius then
                    ids[#ids + 1] = GetPlayerServerId(playerId)
                end
            end
        end
    end

    return ids
end

local function fetchPlayerSkillsPayload()
    local ok, payload = awaitServer(PR.Skills.Callbacks.fetchPlayer)
    if not ok then
        notifyFailure('notify.skills.fetch_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.skills = type(payload.skills) == 'table' and payload.skills or {}
    payload.reputations = type(payload.reputations) == 'table' and payload.reputations or {}

    return payload
end

local function levelProgress(level)
    if type(level) ~= 'table' then return 0 end

    local from = tonumber(level.from) or 0
    local to = tonumber(level.to) or from
    local xp = tonumber(level.progress) or from
    if to <= from then return 100 end

    local progress = (xp - from) / (to - from) * 100
    if progress < 0 then return 0 end
    if progress > 100 then return 100 end

    return math.floor(progress)
end

local function levelXpText(entry)
    local level = entry.level or {}
    local xp = tonumber(entry.xp) or 0
    local to = tonumber(level.to) or 0

    if to <= 0 or to <= xp then
        return t('menu.skills.player_xp_mastery', { xp = tostring(xp) })
    end

    return t('menu.skills.player_xp', {
        xp = tostring(xp),
        next = tostring(to),
    })
end

local function playerSkillDescription(entry)
    return t('menu.skills.player_skill_description', {
        level = tostring(entry.level and entry.level.title or '0'),
        xp = levelXpText(entry),
    })
end

local function linkedPlayerReputations(payload, skillName)
    local linked = {}

    for _, reputation in ipairs(payload and payload.reputations or {}) do
        if reputation.skill == skillName then
            linked[#linked + 1] = reputation
        end
    end

    return linked
end

local function jobTypeDefault(value)
    return value or 'none'
end

local function gradeTitle(level, grade)
    return ('%s - %s'):format(t('menu.grades.grade_level', { level = tostring(level) }), grade.name or t('jobs.defaults.member'))
end

local function gradeDescription(groupType, grade)
    local description = t('menu.grades.flags', {
        boss = boolLabel(grade.isboss == true),
        bank = boolLabel(grade.bankAuth == true),
    })

    if groupType == 'job' then
        description = ('%s | %s'):format(
            t('menu.grades.salary', { salary = tostring(tonumber(grade.payment) or 0) }),
            description
        )
    end

    return description
end

local function saveGroup(group, failureLocale)
    local ok, response = awaitServer(PR.Job.Callbacks.saveGroup, group)
    if not ok then
        notifyFailure(failureLocale or 'notify.jobs.save_failed', response)
        return false
    end

    return true, response
end

local function buildGrades(groupType, count)
    local grades = {}
    count = tonumber(count) or 1

    for index = 0, count - 1 do
        local rows = {
            {
                type = 'input',
                label = t('inputs.grade_name', { grade = index }),
                required = true,
                default = index == 0 and t('jobs.defaults.member') or nil,
            },
        }

        if groupType == 'job' then
            rows[#rows + 1] = {
                type = 'number',
                label = t('inputs.salary'),
                required = true,
                default = 0,
                min = 0,
            }
        end

        local result = inputDialog(t('dialogs.create_grade', { grade = index }), rows)
        if not result then return nil end

        grades[index] = {
            name = result[1],
        }

        if groupType == 'job' then
            grades[index].payment = tonumber(result[2]) or 0
        end

        if index == count - 1 then
            grades[index].isboss = true
            grades[index].bankAuth = true
        end
    end

    return grades
end

-- Camada 1: menu central.

Shared.t = t
Shared.debug = debug
Shared.notify = notify
Shared.showContext = showContext
Shared.inputDialog = inputDialog
Shared.alertDialog = alertDialog
Shared.awaitServer = awaitServer
Shared.notifyFailure = notifyFailure
Shared.groupTitle = groupTitle
Shared.clone = clone
Shared.countGrades = countGrades
Shared.listGrades = listGrades
Shared.nextGradeLevel = nextGradeLevel
Shared.boolLabel = boolLabel
Shared.boolValue = boolValue
Shared.boolDefault = boolDefault
Shared.boolOptions = boolOptions
Shared.accountOptions = accountOptions
Shared.accountLabel = accountLabel
Shared.buildJobTypeOptions = buildJobTypeOptions
Shared.skillCalculationOptions = skillCalculationOptions
Shared.calculationLabel = calculationLabel
Shared.fetchSkillsPayload = fetchSkillsPayload
Shared.countLinkedReputations = countLinkedReputations
Shared.skillSelectOptions = skillSelectOptions
Shared.levelCount = levelCount
Shared.saveSkillDefinition = saveSkillDefinition
Shared.staffRoleOptions = staffRoleOptions
Shared.nearbyServerIds = nearbyServerIds
Shared.fetchPlayerSkillsPayload = fetchPlayerSkillsPayload
Shared.levelProgress = levelProgress
Shared.levelXpText = levelXpText
Shared.playerSkillDescription = playerSkillDescription
Shared.linkedPlayerReputations = linkedPlayerReputations
Shared.jobTypeDefault = jobTypeDefault
Shared.gradeTitle = gradeTitle
Shared.gradeDescription = gradeDescription
Shared.saveGroup = saveGroup
Shared.buildGrades = buildGrades

function Menu.openMain()
    local state = ForgeCore.Client.JobState and ForgeCore.Client.JobState.request()

    showContext({
        id = 'forge_core_main',
        title = t('core.title'),
        options = {
            {
                title = t('menu.work.title'),
                description = t('menu.work.description', {
                    jobs = state and #state.jobs or 0,
                    gangs = state and #state.gangs or 0,
                }),
                icon = 'briefcase',
                onSelect = function()
                    Menu.openJobsMenu()
                end,
            },
            {
                title = t('menu.skills.title'),
                description = t('menu.skills.description'),
                icon = 'graph-up-arrow',
                onSelect = function()
                    Menu.openSkillsMenu()
                end,
            },
            {
                title = t('menu.staff.title'),
                description = t('menu.staff.description'),
                icon = 'people-fill',
                onSelect = function()
                    Menu.openStaffMenu()
                end,
            },
            {
                title = t('menu.server.title'),
                description = t('menu.server.description'),
                icon = 'server',
                onSelect = function()
                    Menu.openServerSettingsMenu()
                end,
            },
            {
                title = t('menu.garage.title'),
                description = t('menu.garage.description'),
                icon = 'building-fill',
                disabled = not (PR.Garage and PR.Garage.AdminMenu and PR.Garage.AdminMenu.enabled ~= false),
                onSelect = function()
                    openGarageAdminMenu()
                end,
            },
            {
                title = t('menu.rental.title'),
                description = t('menu.rental.description'),
                icon = 'car-front',
                disabled = not (PR.Rental and PR.Rental.AdminMenu and PR.Rental.AdminMenu.enabled ~= false),
                onSelect = function()
                    openRentalAdminMenu()
                end,
            },
            {
                title = t('menu.interface.title'),
                description = t('menu.interface.description'),
                icon = 'palette-fill',
                onSelect = function()
                    openInterfaceAdminMenu()
                end,
            },
            {
                title = t('panels.documents.title'),
                description = t('panels.documents.description'),
                icon = 'person-vcard-fill',
                disabled = GetResourceState('forge-dk') ~= 'started',
                onSelect = openDocumentsAdminMenu,
            },
            {
                title = 'Gestão de Players',
                description = 'Perfis, whitelist, empregos, VIP e metadata dos jogadores.',
                icon = 'people-fill',
                onSelect = function() Menu.openPlayersManagement() end,
            },
            {
                title = 'Auto Atendimento Medico',
                description = 'Configurar NPC medico, cooldown e perda de inventario.',
                icon = 'heart-pulse-fill',
                onSelect = function()
                    Menu.openAutoMedicMenu()
                end,
            },
        },
    })
end

AddEventHandler('forge-core:client:openAdminMenu', function()
    Menu.openMain()
end)
