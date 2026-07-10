ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local notify = Shared.notify
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local alertDialog = Shared.alertDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local clone = Shared.clone
local groupTitle = Shared.groupTitle
local countGrades = Shared.countGrades
local listGrades = Shared.listGrades
local nextGradeLevel = Shared.nextGradeLevel
local boolLabel = Shared.boolLabel
local boolValue = Shared.boolValue
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions
local accountOptions = Shared.accountOptions
local accountLabel = Shared.accountLabel
local buildJobTypeOptions = Shared.buildJobTypeOptions
local jobTypeDefault = Shared.jobTypeDefault
local gradeTitle = Shared.gradeTitle
local gradeDescription = Shared.gradeDescription
local saveGroup = Shared.saveGroup
local buildGrades = Shared.buildGrades


local paymentActionLocked = false

function Menu.openJobsMenu()
    local state = ForgeCore.Client.JobState and ForgeCore.Client.JobState.request()
    local meiSettings = state and state.payments and state.payments.mei or {}

    showContext({
        id = 'forge_core_jobs',
        title = t('menu.work.title'),
        menu = 'forge_core_main',
        options = {
            {
                title = t('menu.work.job'),
                description = t('menu.work.job_description', { count = state and #state.jobs or 0 }),
                icon = 'briefcase',
                onSelect = function()
                    Menu.openGroupList('job')
                end,
            },
            {
                title = t('menu.work.gang'),
                description = t('menu.work.gang_description', { count = state and #state.gangs or 0 }),
                icon = 'users',
                onSelect = function()
                    Menu.openGroupList('gang')
                end,
            },
            {
                title = t('menu.mei.title'),
                description = t('menu.mei.summary', {
                    status = meiSettings.enabled and t('common.active') or t('common.inactive'),
                    cost = tostring(meiSettings.openingCost or 0),
                }),
                icon = 'store',
                onSelect = function()
                    Menu.openMeiCreator()
                end,
            },
            {
                title = t('menu.payments.title'),
                description = state and state.payments and t('menu.payments.summary', {
                    status = state.payments.enabled and t('common.active') or t('common.inactive'),
                    interval = tostring(state.payments.intervalMinutes or 10),
                    account = accountLabel(state.payments.account),
                }) or nil,
                icon = 'wallet',
                onSelect = function()
                    Menu.openPaymentSettings()
                end,
            },
        },
    })
end

function Menu.openGroupList(groupType)
    local state = ForgeCore.Client.JobState and ForgeCore.Client.JobState.request()
    local groups = state and state.getGroups(groupType) or {}
    local title = groupType == 'gang' and t('menu.work.gangs') or t('menu.work.jobs')
    local options = {
        {
            title = groupType == 'gang' and t('menu.work.create_gang') or t('menu.work.create_job'),
            icon = 'plus',
            onSelect = function()
                Menu.openGroupCreator(groupType)
            end,
        },
    }

    for i = 1, #groups do
        local group = groups[i]
        options[#options + 1] = {
            title = groupTitle(group),
            description = t('menu.work.grades_count', { count = tostring(countGrades(group.grades)) }),
            icon = groupType == 'gang' and 'users' or 'briefcase',
            onSelect = function()
                Menu.openGroupDetails(groupType, group)
            end,
        }
    end

    showContext({
        id = 'forge_core_group_list_' .. groupType,
        title = title,
        menu = 'forge_core_jobs',
        options = options,
    })
end

function Menu.openPaymentSettings()
    local state = ForgeCore.Client.JobState and ForgeCore.Client.JobState.request()
    local settings = state and state.payments or {}

    showContext({
        id = 'forge_core_payment_settings',
        title = t('menu.payments.title'),
        menu = 'forge_core_jobs',
        options = {
            {
                title = t('menu.payments.edit'),
                description = t('menu.payments.edit_description', {
                    enabled = boolLabel(settings.enabled),
                    interval = tostring(settings.intervalMinutes or 10),
                    account = accountLabel(settings.account),
                }),
                icon = 'settings',
                onSelect = function()
                    Menu.openPaymentEditor(settings)
                end,
            },
            {
                title = t('menu.payments.force_now'),
                description = t('menu.payments.force_description'),
                icon = 'circle-dollar-sign',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.force_payment_header'),
                        content = t('dialogs.force_payment_content'),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        if paymentActionLocked then return end
                        paymentActionLocked = true
                        local ok, result = awaitServer(PR.Job.Callbacks.forcePayment)
                        if not ok then
                            notifyFailure('notify.payments.force_failed', result)
                        end
                        SetTimeout(1000, function()
                            paymentActionLocked = false
                        end)
                    end

                    SetTimeout(500, function()
                        Menu.openPaymentSettings()
                    end)
                end,
            },
            {
                title = t('menu.payments.current_params'),
                description = t('menu.payments.current_params_description', {
                    offDuty = boolLabel(settings.payOffDuty),
                    society = boolLabel(settings.useSociety),
                    notify = boolLabel(settings.notify),
                }),
                icon = 'list-checks',
                disabled = true,
            },
            {
                title = t('menu.mei.settings'),
                description = settings.mei and t('menu.mei.settings_summary', {
                    status = settings.mei.enabled and t('common.active') or t('common.inactive'),
                    opening = tostring(settings.mei.openingCost or 0),
                    monthly = tostring(settings.mei.monthlyCost or 0),
                    account = tostring(settings.mei.governmentAccount or 'government'),
                }) or nil,
                icon = 'store',
                onSelect = function()
                    Menu.openMeiSettingsEditor(settings.mei or {})
                end,
            },
        },
    })
end

-- Camada 4: acoes de criacao e edicao.
function Menu.openPaymentEditor(settings)
    settings = settings or {}

    local result = inputDialog(t('menu.payments.title'), {
        {
            type = 'select',
            label = t('inputs.payment_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled),
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.payment_interval'),
            default = tonumber(settings.intervalMinutes) or 10,
            required = true,
            min = 1,
            max = 1440,
        },
        {
            type = 'select',
            label = t('inputs.payment_account'),
            options = accountOptions(),
            default = settings.account or 'bank',
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.pay_off_duty'),
            options = boolOptions(),
            default = boolDefault(settings.payOffDuty),
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.use_society'),
            options = boolOptions(),
            default = boolDefault(settings.useSociety),
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.notify_payment'),
            options = boolOptions(),
            default = boolDefault(settings.notify ~= false),
            required = true,
        },
    })

    if not result then return Menu.openPaymentSettings() end
    if paymentActionLocked then return Menu.openPaymentSettings() end

    paymentActionLocked = true

    local ok, result = awaitServer(PR.Job.Callbacks.savePaymentSettings, {
        enabled = boolValue(result[1]),
        intervalMinutes = tonumber(result[2]) or 10,
        account = result[3] or 'bank',
        payOffDuty = boolValue(result[4]),
        useSociety = boolValue(result[5]),
        notify = boolValue(result[6]),
    })

    if not ok then
        notifyFailure('notify.payments.save_failed', result)
    end

    SetTimeout(500, function()
        Menu.openPaymentSettings()
    end)

    SetTimeout(1000, function()
        paymentActionLocked = false
    end)
end

function Menu.openGroupCreator(groupType)
    local rows = {
        {
            type = 'input',
            label = t('inputs.display_name'),
            required = true,
            min = 1,
            max = 64,
        },
        {
            type = 'input',
            label = t('inputs.code'),
            description = t('inputs.code_description'),
            required = true,
            min = 1,
            max = 32,
        },
        {
            type = 'number',
            label = t('inputs.grade_count'),
            required = true,
            default = 1,
            min = 1,
            max = 30,
        },
    }

    if groupType == 'job' then
        rows[#rows + 1] = {
            type = 'select',
            label = t('inputs.job_type'),
            options = buildJobTypeOptions(),
            default = 'none',
            searchable = true,
        }
    end

    local result = inputDialog(groupType == 'gang' and t('menu.work.create_gang') or t('menu.work.create_job'), rows)
    if not result then return Menu.openGroupList(groupType) end

    local grades = buildGrades(groupType, result[3])
    if not grades then return Menu.openGroupList(groupType) end

    local group = {
        label = result[1],
        name = result[2],
        job = result[2],
        type = groupType,
        grades = grades,
        craftings = {},
        stashes = {},
    }

    if groupType == 'job' and result[4] ~= 'none' then
        group.jobtype = result[4]
    end

    local ok, response = awaitServer(PR.Job.Callbacks.saveGroup, group)
    if not ok then
        notifyFailure('notify.jobs.save_failed', response)
    end

    SetTimeout(500, function()
        Menu.openGroupList(groupType)
    end)
end

function Menu.openGroupDetails(groupType, group)
    showContext({
        id = 'forge_core_group_details_' .. groupType .. '_' .. tostring(group.name),
        title = groupTitle(group),
        menu = 'forge_core_group_list_' .. groupType,
        options = {
            {
                title = t('menu.actions.edit_data'),
                icon = 'pen',
                onSelect = function()
                    Menu.openGroupEditor(groupType, group)
                end,
            },
            {
                title = t('menu.grades.title'),
                description = t('menu.work.grades_count', { count = tostring(countGrades(group.grades)) }),
                icon = 'layers',
                onSelect = function()
                    Menu.openGradeList(groupType, group)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_group_header'),
                        content = t('dialogs.remove_group_content', { group = groupTitle(group) }),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        local ok, response = awaitServer(PR.Job.Callbacks.deleteGroup, groupType, group.name)
                        if not ok then
                            notifyFailure('notify.jobs.remove_failed', response)
                        end
                    end

                    SetTimeout(500, function()
                        Menu.openGroupList(groupType)
                    end)
                end,
            },
        },
    })
end

function Menu.openGroupEditor(groupType, group)
    local rows = {
        {
            type = 'input',
            label = t('inputs.display_name'),
            required = true,
            default = group.label,
            min = 1,
            max = 64,
        },
    }

    if groupType == 'job' then
        rows[#rows + 1] = {
            type = 'select',
            label = t('inputs.job_type'),
            options = buildJobTypeOptions(),
            default = jobTypeDefault(group.jobtype),
            searchable = true,
        }
        rows[#rows + 1] = {
            type = 'select',
            label = t('inputs.default_duty'),
            options = boolOptions(),
            default = boolDefault(group.defaultDuty ~= false),
            required = true,
        }
        rows[#rows + 1] = {
            type = 'select',
            label = t('inputs.off_duty_pay'),
            options = boolOptions(),
            default = boolDefault(group.offDutyPay == true),
            required = true,
        }
    end

    local result = inputDialog(t('dialogs.edit_group'), rows)
    if not result then return Menu.openGroupDetails(groupType, group) end

    local updated = clone(group)
    updated.label = result[1]

    if groupType == 'job' then
        updated.jobtype = result[2] ~= 'none' and result[2] or nil
        updated.defaultDuty = boolValue(result[3])
        updated.offDutyPay = boolValue(result[4])
    end

    saveGroup(updated)

    SetTimeout(500, function()
        Menu.openGroupList(groupType)
    end)
end

function Menu.openGradeList(groupType, group)
    local grades = listGrades(group.grades)
    local options = {
        {
            title = t('menu.grades.create'),
            icon = 'plus',
            onSelect = function()
                Menu.openGradeEditor(groupType, group, nextGradeLevel(group.grades), nil, true)
            end,
        },
    }

    for i = 1, #grades do
        local grade = grades[i]
        options[#options + 1] = {
            title = gradeTitle(grade.level, grade.data),
            description = gradeDescription(groupType, grade.data),
            icon = grade.data.isboss and 'crown' or 'user',
            onSelect = function()
                Menu.openGradeDetails(groupType, group, grade.level, grade.key, grade.data)
            end,
        }
    end

    showContext({
        id = 'forge_core_grade_list_' .. groupType .. '_' .. tostring(group.name),
        title = t('menu.grades.title'),
        menu = 'forge_core_group_details_' .. groupType .. '_' .. tostring(group.name),
        options = options,
    })
end

function Menu.openGradeDetails(groupType, group, level, gradeKey, grade)
    showContext({
        id = 'forge_core_grade_details_' .. groupType .. '_' .. tostring(group.name) .. '_' .. tostring(level),
        title = gradeTitle(level, grade),
        menu = 'forge_core_grade_list_' .. groupType .. '_' .. tostring(group.name),
        options = {
            {
                title = t('menu.actions.edit'),
                description = gradeDescription(groupType, grade),
                icon = 'pen',
                onSelect = function()
                    Menu.openGradeEditor(groupType, group, level, gradeKey, false)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    Menu.removeGrade(groupType, group, gradeKey or level)
                end,
            },
        },
    })
end

function Menu.openGradeEditor(groupType, group, level, gradeKey, isNew)
    local grade = not isNew and group.grades and group.grades[gradeKey or level] or {}
    grade = grade or {}

    local rows = {
        {
            type = 'number',
            label = t('inputs.grade_level'),
            required = true,
            default = tonumber(level) or 0,
            min = 0,
            max = 99,
            disabled = not isNew,
        },
        {
            type = 'input',
            label = t('inputs.grade_name_plain'),
            required = true,
            default = grade.name or t('jobs.defaults.member'),
            min = 1,
            max = 64,
        },
    }

    if groupType == 'job' then
        rows[#rows + 1] = {
            type = 'number',
            label = t('inputs.salary'),
            required = true,
            default = tonumber(grade.payment) or 0,
            min = 0,
        }
    end

    rows[#rows + 1] = {
        type = 'select',
        label = t('inputs.is_boss'),
        options = boolOptions(),
        default = boolDefault(grade.isboss == true),
        required = true,
    }
    rows[#rows + 1] = {
        type = 'select',
        label = t('inputs.bank_auth'),
        options = boolOptions(),
        default = boolDefault(grade.bankAuth == true),
        required = true,
    }

    local result = inputDialog(isNew and t('dialogs.create_grade_simple') or t('dialogs.edit_grade'), rows)
    if not result then return Menu.openGradeList(groupType, group) end

    local updated = clone(group)
    updated.grades = updated.grades or {}

    local resultIndex = 1
    local newLevel = tonumber(result[resultIndex]) or tonumber(level) or 0
    resultIndex = resultIndex + 1

    local gradeData = {
        name = result[resultIndex],
    }
    resultIndex = resultIndex + 1

    if groupType == 'job' then
        gradeData.payment = tonumber(result[resultIndex]) or 0
        resultIndex = resultIndex + 1
    end

    gradeData.isboss = boolValue(result[resultIndex])
    resultIndex = resultIndex + 1
    gradeData.bankAuth = boolValue(result[resultIndex])

    if not isNew and gradeKey ~= nil and tostring(gradeKey) ~= tostring(newLevel) then
        updated.grades[gradeKey] = nil
    end

    updated.grades[newLevel] = gradeData
    saveGroup(updated)

    SetTimeout(500, function()
        Menu.openGradeList(groupType, updated)
    end)
end

function Menu.removeGrade(groupType, group, gradeKey)
    if countGrades(group.grades) <= 1 then
        notify({
            title = t('core.title'),
            description = t('notify.jobs.last_grade'),
            type = 'error',
        })
        return Menu.openGradeList(groupType, group)
    end

    local confirmed = alertDialog({
        header = t('dialogs.remove_grade_header'),
        content = t('dialogs.remove_grade_content'),
        centered = true,
        cancel = true,
    })

    if confirmed ~= 'confirm' then return Menu.openGradeList(groupType, group) end

    local updated = clone(group)
    updated.grades = updated.grades or {}
    updated.grades[gradeKey] = nil
    updated.grades[tostring(gradeKey)] = nil

    saveGroup(updated)

    SetTimeout(500, function()
        Menu.openGradeList(groupType, updated)
    end)
end

ForgeCore.Client.Menu = Menu

