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

local function listPoints(group)
    local points = {}

    for i = 1, #(group.stashes or {}) do
        points[#points + 1] = group.stashes[i]
    end

    table.sort(points, function(left, right)
        return tostring(left.title or left.id) < tostring(right.title or right.id)
    end)

    return points
end

local function countPoints(group)
    return pr_lib.table.count(group.stashes or {})
end

local function normalizePointId(value)
    value = (pr_lib.utils.trim(value) or ''):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    value = value:gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')

    if value == '' then
        value = ('posto_%s'):format(GetGameTimer())
    end

    return value
end

local function plainCoords(coords)
    if not coords then return nil end

    return {
        x = tonumber(coords.x) or 0.0,
        y = tonumber(coords.y) or 0.0,
        z = tonumber(coords.z) or 0.0,
    }
end

local function coordsText(coords)
    if type(coords) ~= 'table' then return t('common.none') end

    local ok, vector = pcall(pr_lib.math.toVector, coords)
    if ok and vector then coords = vector end

    return ('%.2f, %.2f, %.2f'):format(
        tonumber(coords.x) or 0.0,
        tonumber(coords.y) or 0.0,
        tonumber(coords.z) or 0.0
    )
end

local function captureRaycastPoint(title)
    if not pr_lib or not pr_lib.raycast or not pr_lib.raycast.FromCamera then
        notify({
            title = t('core.title'),
            description = t('notify.stashes.raycast_unavailable'),
            type = 'error',
        })
        return nil
    end

    while true do
        local _, _, endCoords = pr_lib.raycast.FromCamera(20.0, 1 | 16, 4, PlayerPedId())
        if endCoords then
            if pr_lib.textuiAdapter and pr_lib.textuiAdapter.Show then
                pr_lib.textuiAdapter.Show(t('menu.stashes.raycast_help', {
                    title = title,
                    x = ('%.2f'):format(endCoords.x),
                    y = ('%.2f'):format(endCoords.y),
                    z = ('%.2f'):format(endCoords.z),
                }))
            end

            DrawMarker(28, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.18, 0.18, 0.18, 0, 180, 90, 120, false, false, 0, true, false, false, false)
        end

        if IsControlJustReleased(0, 38) then
            if pr_lib.textuiAdapter and pr_lib.textuiAdapter.Hide then pr_lib.textuiAdapter.Hide() end
            return plainCoords(endCoords)
        end

        if IsControlJustReleased(0, 178) then
            if pr_lib.textuiAdapter and pr_lib.textuiAdapter.Hide then pr_lib.textuiAdapter.Hide() end
            return nil
        end

        Wait(0)
    end
end

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
                icon = 'people-fill',
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
                icon = 'shop',
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
            {
                title = t('menu.multijob.admin_title'),
                description = t('menu.multijob.admin_description'),
                icon = 'briefcase-fill',
                onSelect = function()
                    Menu.openMultiJobAdminMenu()
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
            icon = groupType == 'gang' and 'people-fill' or 'briefcase-fill',
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
                icon = 'gear-fill',
                onSelect = function()
                    Menu.openPaymentEditor(settings)
                end,
            },
            {
                title = t('menu.payments.force_now'),
                description = t('menu.payments.force_description'),
                icon = 'currency-dollar',
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
                    percent = tostring(tonumber(settings.societySalaryPercent) or 100),
                    notify = boolLabel(settings.notify),
                }),
                icon = 'list-check',
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
                icon = 'shop',
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
            type = 'number',
            label = t('inputs.society_salary_percent'),
            description = t('inputs.society_salary_percent_description'),
            default = tonumber(settings.societySalaryPercent) or 100,
            required = true,
            min = 0,
            max = 100,
            step = 1,
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
        societySalaryPercent = tonumber(result[6]) or 100,
        notify = boolValue(result[7]),
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
                title = t('menu.stashes.title'),
                description = t('menu.stashes.count_description', { count = tostring(countPoints(group)) }),
                icon = 'buildings-fill',
                onSelect = function()
                    Menu.openGroupPointList(groupType, group)
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

function Menu.openGroupPointList(groupType, group)
    local points = listPoints(group)
    local options = {
        {
            title = t('menu.stashes.create'),
            description = t('menu.stashes.create_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openGroupPointEditor(groupType, group, nil, true)
            end,
        },
    }

    for i = 1, #points do
        local point = points[i]
        local stash = type(point.stash) == 'table' and point.stash or {}
        local duty = type(point.duty) == 'table' and point.duty or {}
        local enabled = point.enabled ~= false

        options[#options + 1] = {
            title = point.title or point.id,
            description = t('menu.stashes.point_description', {
                status = enabled and t('common.active') or t('common.inactive'),
                stash = stash.enabled ~= false and t('common.yes') or t('common.no'),
                duty = groupType == 'job' and duty.enabled == true and t('common.yes') or t('common.no'),
            }),
            icon = enabled and 'geo-alt-fill' or 'geo-alt',
            iconColor = enabled and 'green' or 'red',
            onSelect = function()
                Menu.openGroupPointDetails(groupType, group, point)
            end,
        }
    end

    showContext({
        id = 'forge_core_group_points_' .. groupType .. '_' .. tostring(group.name),
        title = t('menu.stashes.title'),
        menu = 'forge_core_group_details_' .. groupType .. '_' .. tostring(group.name),
        options = options,
    })
end


function Menu.openGroupPointDetails(groupType, group, point)
    local stash = type(point.stash) == 'table' and point.stash or {}
    local duty = type(point.duty) == 'table' and point.duty or {}
    local options = {
        {
            title = t('menu.stashes.edit_base', { title = point.title or point.id }),
            description = point.enabled == false and t('common.inactive') or t('common.active'),
            icon = 'pen',
            onSelect = function()
                Menu.openGroupPointEditor(groupType, group, point, false)
            end,
        },
        {
            title = t('menu.stashes.stash_title'),
            description = t('menu.stashes.resource_description', {
                status = stash.enabled == true and t('common.active') or t('common.inactive'),
                coords = coordsText(stash.coords or point.coords),
            }),
            icon = 'archive',
            onSelect = function()
                Menu.openGroupStashEditor(groupType, group, point)
            end,
        },
    }

    if groupType == 'job' then
        options[#options + 1] = {
            title = t('menu.stashes.duty_title'),
            description = t('menu.stashes.resource_description', {
                status = duty.enabled == true and t('common.active') or t('common.inactive'),
                coords = coordsText(duty.coords),
            }),
            icon = 'clock',
            onSelect = function()
                Menu.openGroupDutyEditor(groupType, group, point)
            end,
        }
    end

    options[#options + 1] = {
        title = t('menu.business.boss_panel'),
        description = t('menu.business.boss_panel_description'),
        icon = 'award-fill',
        onSelect = function()
            Menu.openBossPanel(groupType, group)
        end,
    }

    local resources = {
        { key = 'bossMenus', icon = 'award-fill', title = 'menu.business.boss_menus' },
        { key = 'registers', icon = 'safe2-fill', title = 'menu.business.registers' },
        { key = 'shops', icon = 'shop', title = 'menu.business.shops' },
        { key = 'applications', icon = 'file-earmark-text-fill', title = 'menu.business.applications' },
        { key = 'alarms', icon = 'bell', title = 'menu.business.alarms' },
    }

    for i = 1, #resources do
        local item = resources[i]
        options[#options + 1] = {
            title = t(item.title),
            description = t('menu.business.category_count', { count = tostring(#(point[item.key] or {})) }),
            icon = item.icon,
            onSelect = function()
                Menu.openStationBusinessList(groupType, group, point, item.key)
            end,
        }
    end

    options[#options + 1] = {
        title = point.enabled == false and t('menu.stashes.activate') or t('menu.stashes.deactivate'),
        icon = point.enabled == false and 'toggle-on' or 'toggle-off',
        iconColor = point.enabled == false and 'green' or 'red',
        onSelect = function()
            local updated = clone(group)
            updated.stashes = updated.stashes or {}

            for i = 1, #updated.stashes do
                if tostring(updated.stashes[i].id) == tostring(point.id) then
                    updated.stashes[i].enabled = point.enabled == false
                    break
                end
            end

            if not saveGroup(updated) then return Menu.openGroupPointDetails(groupType, group, point) end

            SetTimeout(500, function()
                Menu.openGroupPointList(groupType, updated)
            end)
        end,
    }

    options[#options + 1] = {
        title = t('menu.actions.remove'),
        icon = 'trash',
        iconColor = 'red',
        onSelect = function()
            Menu.removeGroupPoint(groupType, group, point)
        end,
    }

    showContext({
        id = 'forge_core_group_point_details_' .. groupType .. '_' .. tostring(group.name) .. '_' .. tostring(point.id),
        title = point.title or point.id,
        menu = 'forge_core_group_points_' .. groupType .. '_' .. tostring(group.name),
        options = options,
    })
end

function Menu.openGroupPointEditor(groupType, group, point, isNew)
    point = point or {}

    local result = inputDialog(isNew and t('menu.stashes.create') or t('menu.stashes.edit'), {
        {
            type = 'input',
            label = t('inputs.stash_point_title'),
            required = true,
            default = point.title or '',
            min = 1,
            max = 64,
        },
        {
            type = 'select',
            label = t('inputs.stash_point_enabled'),
            options = boolOptions(),
            default = boolDefault(point.enabled ~= false),
            required = true,
        },
    })

    if not result then return Menu.openGroupPointList(groupType, group) end

    local title = result[1]
    local pointId = point.id or normalizePointId(title)
    local updatedPoint = clone(point)
    updatedPoint.id = pointId
    updatedPoint.title = title
    updatedPoint.enabled = boolValue(result[2])
    updatedPoint.stash = type(updatedPoint.stash) == 'table' and updatedPoint.stash or { enabled = false }
    updatedPoint.duty = type(updatedPoint.duty) == 'table' and updatedPoint.duty or { enabled = false }

    local updated = clone(group)
    updated.stashes = updated.stashes or {}

    local replaced = false
    for i = 1, #updated.stashes do
        if tostring(updated.stashes[i].id) == tostring(pointId) then
            updated.stashes[i] = updatedPoint
            replaced = true
            break
        end
    end

    if not replaced then
        updated.stashes[#updated.stashes + 1] = updatedPoint
    end

    if not saveGroup(updated) then return Menu.openGroupPointList(groupType, group) end

    SetTimeout(500, function()
        Menu.openGroupPointList(groupType, updated)
    end)
end

function Menu.openGroupStashEditor(groupType, group, point)
    local stash = type(point.stash) == 'table' and point.stash or {}
    local result = inputDialog(t('menu.stashes.stash_title'), {
        { type = 'select', label = t('inputs.stash_enabled'), options = boolOptions(), default = boolDefault(stash.enabled == true), required = true },
        { type = 'number', label = t('inputs.stash_min_grade'), default = tonumber(stash.minGrade) or PR.Job.Points.defaultMinGrade or 0, min = 0, required = true },
        { type = 'number', label = t('inputs.stash_slots'), default = tonumber(stash.slots) or PR.Job.Points.defaultSlots or 50, min = 1, required = true },
        { type = 'number', label = t('inputs.stash_weight_kg'), default = math.floor((tonumber(stash.weight) or PR.Job.Points.defaultWeight or 1000000) / 1000), min = 1, required = true },
        { type = 'input', label = t('inputs.stash_item'), default = stash.item or '' },
        { type = 'number', label = t('inputs.stash_item_amount'), default = tonumber(stash.itemAmount) or 1, min = 1 },
        { type = 'input', label = t('inputs.stash_password'), default = stash.password or '' },
        { type = 'input', label = t('inputs.stash_target_label'), default = stash.label or '' },
        { type = 'input', label = t('inputs.stash_webhook'), default = stash.webhook or '' },
        { type = 'select', label = t('inputs.capture_coords'), options = boolOptions(), default = boolDefault(not stash.coords), required = true },
    })

    if not result then return Menu.openGroupPointDetails(groupType, group, point) end

    local updatedStash = {
        enabled = boolValue(result[1]),
        minGrade = tonumber(result[2]) or 0,
        slots = tonumber(result[3]) or PR.Job.Points.defaultSlots or 50,
        weight = (tonumber(result[4]) or 1) * 1000,
        item = result[5] or '',
        itemAmount = tonumber(result[6]) or 1,
        password = result[7] or '',
        label = result[8] or '',
        webhook = result[9] or '',
        coords = stash.coords or point.coords,
    }

    if updatedStash.enabled and boolValue(result[10]) then
        updatedStash.coords = captureRaycastPoint(t('menu.stashes.raycast_stash', { title = point.title or point.id }))
        if not updatedStash.coords then return Menu.openGroupPointDetails(groupType, group, point) end
    end

    local updated = clone(group)
    for i = 1, #(updated.stashes or {}) do
        if tostring(updated.stashes[i].id) == tostring(point.id) then
            updated.stashes[i].stash = updatedStash
            break
        end
    end

    if not saveGroup(updated) then return Menu.openGroupPointDetails(groupType, group, point) end

    SetTimeout(500, function()
        Menu.openGroupPointList(groupType, updated)
    end)
end

function Menu.openGroupDutyEditor(groupType, group, point)
    local duty = type(point.duty) == 'table' and point.duty or {}
    local result = inputDialog(t('menu.stashes.duty_title'), {
        { type = 'select', label = t('inputs.duty_enabled'), options = boolOptions(), default = boolDefault(duty.enabled == true), required = true },
        { type = 'number', label = t('inputs.duty_min_grade'), default = tonumber(duty.minGrade) or 0, min = 0, required = true },
        { type = 'input', label = t('inputs.duty_target_label'), default = duty.label or '' },
        { type = 'select', label = t('inputs.capture_coords'), options = boolOptions(), default = boolDefault(not duty.coords), required = true },
    })

    if not result then return Menu.openGroupPointDetails(groupType, group, point) end

    local updatedDuty = {
        enabled = boolValue(result[1]),
        minGrade = tonumber(result[2]) or 0,
        label = result[3] or '',
        coords = duty.coords,
    }

    if updatedDuty.enabled and boolValue(result[4]) then
        updatedDuty.coords = captureRaycastPoint(t('menu.stashes.raycast_duty', { title = point.title or point.id }))
        if not updatedDuty.coords then return Menu.openGroupPointDetails(groupType, group, point) end
    end

    local updated = clone(group)
    for i = 1, #(updated.stashes or {}) do
        if tostring(updated.stashes[i].id) == tostring(point.id) then
            updated.stashes[i].duty = updatedDuty
            break
        end
    end

    if not saveGroup(updated) then return Menu.openGroupPointDetails(groupType, group, point) end

    SetTimeout(500, function()
        Menu.openGroupPointList(groupType, updated)
    end)
end

function Menu.removeGroupPoint(groupType, group, point)
    local confirmed = alertDialog({
        header = t('dialogs.remove_stash_point_header'),
        content = t('dialogs.remove_stash_point_content', { point = point.title or point.id }),
        centered = true,
        cancel = true,
    })

    if confirmed ~= 'confirm' then return Menu.openGroupPointDetails(groupType, group, point) end

    local updated = clone(group)
    updated.stashes = {}

    for i = 1, #(group.stashes or {}) do
        if tostring(group.stashes[i].id) ~= tostring(point.id) then
            updated.stashes[#updated.stashes + 1] = group.stashes[i]
        end
    end

    local saved = saveGroup(updated)
    if not saved then return Menu.openGroupPointDetails(groupType, group, point) end

    SetTimeout(500, function()
        Menu.openGroupPointList(groupType, updated)
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
            icon = grade.data.isboss and 'award-fill' or 'person-fill',
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

