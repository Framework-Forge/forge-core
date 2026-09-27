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
local boolOptions = Shared.boolOptions
local boolDefault = Shared.boolDefault
local boolValue = Shared.boolValue
local saveGroup = Shared.saveGroup
local function normalizeId(value)
    value = (pr_lib.utils.trim(value) or ''):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    value = value:gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')

    if value == '' then
        value = ('business_%s'):format(GetGameTimer())
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
    if not pr_lib.raycast or not pr_lib.raycast.FromCamera then
        notify({ description = t('notify.stashes.raycast_unavailable'), type = 'error' })
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
function Menu.openBossPanel(groupType, group)
    showContext({
        id = ('forge_core_boss_panel_%s_%s'):format(groupType, group.name),
        title = t('menu.business.boss_panel'),
        options = {
            {
                title = t('menu.business.employees'),
                icon = 'people-fill',
                onSelect = function()
                    Menu.openBossEmployees(groupType, group)
                end,
            },
            {
                title = t('menu.business.candidates'),
                icon = 'file-earmark-text-fill',
                onSelect = function()
                    Menu.openBossApplications(groupType, group)
                end,
            },
        },
    })
end
function Menu.openBossEmployees(groupType, group)
    local ok, employees = awaitServer(PR.Job.Callbacks.getEmployees, groupType, group.name)
    if not ok then
        notifyFailure('notify.business.employees_failed', employees)
        return
    end

    local options = {
        {
            title = t('menu.business.hire_by_citizenid'),
            icon = 'person-plus-fill',
            onSelect = function()
                local result = inputDialog(t('menu.business.hire_by_citizenid'), {
                    { type = 'input', label = t('inputs.business_citizenid'), required = true },
                    { type = 'number', label = t('inputs.grade_level'), min = 0, default = 0, required = true },
                })
                if not result then return Menu.openBossEmployees(groupType, group) end
                local success, response = awaitServer(PR.Job.Callbacks.hirePlayer, groupType, group.name, result[1], result[2])
                notify({ description = success and t('notify.business.hired') or t('notify.business.hire_failed', { error = tostring(response or 'unknown') }), type = success and 'success' or 'error' })
            end,
        },
    }

    for _, employee in ipairs(employees or {}) do
        options[#options + 1] = {
            title = employee.name or employee.citizenid,
            description = t('menu.business.employee_description', { citizenid = employee.citizenid, grade = tostring(employee.grade or 0) }),
            icon = 'person-fill',
            onSelect = function()
                Menu.openBossEmployeeActions(groupType, group, employee)
            end,
        }
    end

    showContext({
        id = ('forge_core_boss_employees_%s_%s'):format(groupType, group.name),
        title = t('menu.business.employees'),
        menu = ('forge_core_boss_panel_%s_%s'):format(groupType, group.name),
        options = options,
    })
end

function Menu.openBossEmployeeActions(groupType, group, employee)
    showContext({
        id = ('forge_core_boss_employee_%s_%s_%s'):format(groupType, group.name, employee.citizenid),
        title = employee.name or employee.citizenid,
        menu = ('forge_core_boss_employees_%s_%s'):format(groupType, group.name),
        options = {
            {
                title = t('menu.business.change_grade'),
                icon = 'layers',
                onSelect = function()
                    local result = inputDialog(t('menu.business.change_grade'), {
                        { type = 'number', label = t('inputs.grade_level'), min = 0, default = tonumber(employee.grade) or 0, required = true },
                    })
                    if not result then return Menu.openBossEmployees(groupType, group) end
                    local ok, response = awaitServer(PR.Job.Callbacks.setEmployeeGrade, groupType, group.name, employee.citizenid, result[1])
                    notify({ description = ok and t('notify.business.grade_changed') or t('notify.business.grade_failed', { error = tostring(response or 'unknown') }), type = ok and 'success' or 'error' })
                end,
            },
            {
                title = t('menu.business.fire_employee'),
                icon = 'person-dash-fill',
                iconColor = 'red',
                onSelect = function()
                    local ok, response = awaitServer(PR.Job.Callbacks.fireEmployee, groupType, group.name, employee.citizenid)
                    notify({ description = ok and t('notify.business.fired') or t('notify.business.fire_failed', { error = tostring(response or 'unknown') }), type = ok and 'success' or 'error' })
                end,
            },
        },
    })
end
local stationServiceTypes = {
    shops = { icon = 'shop', title = 'menu.business.shops', create = 'menu.business.create_shop' },
    registers = { icon = 'safe2-fill', title = 'menu.business.registers', create = 'menu.business.create_register' },
    alarms = { icon = 'bell', title = 'menu.business.alarms', create = 'menu.business.create_alarm' },
    bossMenus = { icon = 'award-fill', title = 'menu.business.boss_menus', create = 'menu.business.create_boss' },
    applications = { icon = 'file-earmark-text-fill', title = 'menu.business.applications', create = 'menu.business.create_application' },
}

local function upsertStationPoint(group, stationId, key, point)
    local updated = clone(group)
    updated.stashes = type(updated.stashes) == 'table' and updated.stashes or {}

    for stationIndex = 1, #updated.stashes do
        local station = updated.stashes[stationIndex]
        if tostring(station.id) == tostring(stationId) then
            station[key] = type(station[key]) == 'table' and station[key] or {}

            local replaced = false
            for index = 1, #station[key] do
                if tostring(station[key][index].id) == tostring(point.id) then
                    station[key][index] = point
                    replaced = true
                    break
                end
            end

            if not replaced then
                station[key][#station[key] + 1] = point
            end

            break
        end
    end

    return updated
end

local function removeStationPoint(group, stationId, key, pointId)
    local updated = clone(group)

    for stationIndex = 1, #(updated.stashes or {}) do
        local station = updated.stashes[stationIndex]
        if tostring(station.id) == tostring(stationId) then
            local list = station[key] or {}
            station[key] = {}

            for index = 1, #list do
                if tostring(list[index].id) ~= tostring(pointId) then
                    station[key][#station[key] + 1] = list[index]
                end
            end

            break
        end
    end

    return updated
end

local function stationSaveAndBack(groupType, updated, station, key)
    if not saveGroup(updated) then return end

    SetTimeout(500, function()
        local refreshedStation = station
        for index = 1, #(updated.stashes or {}) do
            if tostring(updated.stashes[index].id) == tostring(station.id) then
                refreshedStation = updated.stashes[index]
                break
            end
        end

        Menu.openStationBusinessList(groupType, updated, refreshedStation, key)
    end)
end

function Menu.openStationBusinessList(groupType, group, station, key)
    local meta = stationServiceTypes[key]
    local options = {
        {
            title = t(meta.create),
            icon = 'plus',
            onSelect = function()
                Menu.openStationBusinessPointEditor(groupType, group, station, key)
            end,
        },
    }

    for _, point in ipairs(station[key] or {}) do
        options[#options + 1] = {
            title = point.label or point.title or point.id,
            description = t('menu.business.point_description', {
                status = point.enabled ~= false and t('common.active') or t('common.inactive'),
                coords = coordsText(point.coords),
            }),
            icon = point.enabled ~= false and meta.icon or 'slash-circle',
            iconColor = point.enabled ~= false and '#22c55e' or '#ffffff',
            onSelect = function()
                Menu.openStationBusinessPointDetails(groupType, group, station, key, point)
            end,
        }
    end

    showContext({
        id = ('forge_core_station_business_list_%s_%s_%s_%s'):format(groupType, group.name, station.id, key),
        title = t(meta.title),
        menu = ('forge_core_group_point_details_%s_%s_%s'):format(groupType, group.name, station.id),
        options = options,
    })
end

function Menu.openStationBusinessPointDetails(groupType, group, station, key, point)
    local options = {
        {
            title = t('menu.actions.edit'),
            description = coordsText(point.coords),
            icon = 'pen',
            onSelect = function()
                Menu.openStationBusinessPointEditor(groupType, group, station, key, point)
            end,
        },
        {
            title = point.enabled == false and t('menu.business.activate') or t('menu.business.deactivate'),
            icon = point.enabled == false and 'toggle-on' or 'toggle-off',
            onSelect = function()
                local updatedPoint = clone(point)
                updatedPoint.enabled = point.enabled == false
                stationSaveAndBack(groupType, upsertStationPoint(group, station.id, key, updatedPoint), station, key)
            end,
        },
        {
            title = t('menu.business.capture_point'),
            description = coordsText(point.coords),
            icon = 'crosshair',
            onSelect = function()
                local coords = captureRaycastPoint(point.label or point.title or point.id)
                if not coords then return Menu.openStationBusinessPointDetails(groupType, group, station, key, point) end
                local updatedPoint = clone(point)
                updatedPoint.coords = coords
                stationSaveAndBack(groupType, upsertStationPoint(group, station.id, key, updatedPoint), station, key)
            end,
        },
    }

    if key == 'shops' then
        options[#options + 1] = {
            title = t('menu.business.items'),
            description = t('menu.business.category_count', { count = tostring(#(point.items or {})) }),
            icon = 'boxes',
            onSelect = function()
                Menu.openStationShopItems(groupType, group, station, point)
            end,
        }
    elseif key == 'applications' then
        options[#options + 1] = {
            title = t('menu.business.questions'),
            description = t('menu.business.category_count', { count = tostring(#(point.questions or {})) }),
            icon = 'question-circle-fill',
            onSelect = function()
                Menu.openStationApplicationQuestions(groupType, group, station, point)
            end,
        }
        options[#options + 1] = {
            title = t('menu.business.candidates'),
            icon = 'people-fill',
            onSelect = function()
                Menu.openStationCandidates(groupType, group, station, point)
            end,
        }
    end

    options[#options + 1] = {
        title = t('menu.actions.remove'),
        icon = 'trash',
        iconColor = 'red',
        onSelect = function()
            local confirmed = alertDialog({
                header = t('dialogs.remove_business_point_header'),
                content = t('dialogs.remove_business_point_content', { point = point.label or point.title or point.id }),
                centered = true,
                cancel = true,
            })

            if confirmed == 'confirm' then
                stationSaveAndBack(groupType, removeStationPoint(group, station.id, key, point.id), station, key)
            else
                Menu.openStationBusinessPointDetails(groupType, group, station, key, point)
            end
        end,
    }

    showContext({
        id = ('forge_core_station_business_point_%s_%s_%s_%s_%s'):format(groupType, group.name, station.id, key, point.id),
        title = point.label or point.title or point.id,
        menu = ('forge_core_station_business_list_%s_%s_%s_%s'):format(groupType, group.name, station.id, key),
        options = options,
    })
end

function Menu.openStationBusinessPointEditor(groupType, group, station, key, point)
    point = point or {}

    local rows

    if key == 'shops' then
        rows = {
            { type = 'input', label = t('inputs.business_label'), required = true, default = point.label or point.title or '', min = 1, max = 64 },
            { type = 'select', label = t('inputs.business_enabled'), options = boolOptions(), default = boolDefault(point.enabled ~= false), required = true },
            { type = 'input', label = t('inputs.business_target_label'), default = point.targetLabel or '' },
            { type = 'select', label = t('inputs.business_public'), options = boolOptions(), default = boolDefault(point.public == true), required = true },
            { type = 'number', label = t('inputs.business_buy_grade'), default = tonumber(point.buyGrade or point.minGrade) or 0, min = 0 },
            { type = 'number', label = t('inputs.business_supply_grade'), default = tonumber(point.supplyGrade or point.minGrade) or 0, min = 0, required = true },
        }
    else
        rows = {
            { type = 'input', label = t('inputs.business_label'), required = true, default = point.label or point.title or '', min = 1, max = 64 },
            { type = 'select', label = t('inputs.business_enabled'), options = boolOptions(), default = boolDefault(point.enabled ~= false), required = true },
            { type = 'number', label = t('inputs.business_min_grade'), default = tonumber(point.minGrade) or 0, min = 0, required = true },
            { type = 'input', label = t('inputs.business_target_label'), default = point.targetLabel or '' },
        }
    end

    if key == 'registers' then
        rows[#rows + 1] = { type = 'number', label = t('inputs.business_register_balance'), default = tonumber(point.balance) or 0, min = 0, required = true }
        rows[#rows + 1] = { type = 'select', label = t('inputs.business_access_mode'), options = {
            { value = 'grade', label = t('menu.business.access_grade') },
            { value = 'password', label = t('menu.business.access_password') },
        }, default = point.accessMode == 'password' and 'password' or 'grade', required = true }
        rows[#rows + 1] = { type = 'input', label = t('inputs.business_password'), password = true, default = point.password or '' }
        rows[#rows + 1] = { type = 'select', label = t('inputs.business_robbery_enabled'), options = boolOptions(), default = boolDefault(point.robberyEnabled == true), required = true }
        rows[#rows + 1] = { type = 'select', label = t('inputs.business_robbery_difficulty'), options = {
            { value = 'easy', label = t('menu.business.difficulty_easy') },
            { value = 'medium', label = t('menu.business.difficulty_medium') },
            { value = 'hard', label = t('menu.business.difficulty_hard') },
        }, default = point.robbery and point.robbery.difficulty or 'medium', required = true }
        rows[#rows + 1] = { type = 'number', label = t('inputs.business_robbery_amount'), default = tonumber(point.robberyAmount) or 0, min = 0 }
        rows[#rows + 1] = { type = 'number', label = t('inputs.business_robbery_alert_chance'), default = tonumber(point.robberyAlertChance) or 35, min = 0, max = 100 }
    elseif key == 'alarms' then
        rows[#rows + 1] = { type = 'input', label = t('inputs.business_alarm_message'), default = point.message or '' }
    elseif key == 'applications' then
        rows[#rows + 1] = { type = 'number', label = t('inputs.business_min_score'), default = tonumber(point.minScore) or 70, min = 1, max = 100, required = true }
        rows[#rows + 1] = { type = 'select', label = t('inputs.business_public'), options = boolOptions(), default = boolDefault(point.public ~= false), required = true }
    end

    local result = inputDialog(point.id and t('menu.business.edit_point') or t('menu.business.create_point'), rows)
    if not result then return Menu.openStationBusinessList(groupType, group, station, key) end

    local updatedPoint = clone(point)
    updatedPoint.id = point.id or normalizeId(result[1])
    updatedPoint.label = result[1]
    updatedPoint.enabled = boolValue(result[2])

    local index
    if key == 'shops' then
        updatedPoint.targetLabel = result[3] or ''
        updatedPoint.public = boolValue(result[4])
        updatedPoint.buyGrade = tonumber(result[5]) or 0
        updatedPoint.supplyGrade = tonumber(result[6]) or 0
        updatedPoint.minGrade = updatedPoint.public and 0 or updatedPoint.buyGrade
        updatedPoint.items = type(updatedPoint.items) == 'table' and updatedPoint.items or {}
        updatedPoint.stock = type(updatedPoint.stock) == 'table' and updatedPoint.stock or {}
        updatedPoint.type = 'shop'
        index = 7
    elseif key == 'registers' then
        updatedPoint.minGrade = tonumber(result[3]) or 0
        updatedPoint.targetLabel = result[4] or ''
        index = 5
        updatedPoint.balance = tonumber(result[index]) or 0
        updatedPoint.accessMode = result[index + 1] == 'password' and 'password' or 'grade'
        updatedPoint.password = result[index + 2] or ''
        updatedPoint.robberyEnabled = boolValue(result[index + 3])
        updatedPoint.robbery = { type = 'lockpick', difficulty = result[index + 4] or 'medium' }
        updatedPoint.robberyAmount = tonumber(result[index + 5]) or 0
        updatedPoint.robberyAlertChance = tonumber(result[index + 6]) or 0
    elseif key == 'alarms' then
        updatedPoint.minGrade = tonumber(result[3]) or 0
        updatedPoint.targetLabel = result[4] or ''
        index = 5
        updatedPoint.message = result[index] or ''
    elseif key == 'applications' then
        updatedPoint.minGrade = tonumber(result[3]) or 0
        updatedPoint.targetLabel = result[4] or ''
        index = 5
        updatedPoint.minScore = tonumber(result[index]) or 70
        updatedPoint.public = boolValue(result[index + 1])
        updatedPoint.questions = type(updatedPoint.questions) == 'table' and updatedPoint.questions or {}
        updatedPoint.submissions = type(updatedPoint.submissions) == 'table' and updatedPoint.submissions or {}
    elseif key == 'bossMenus' then
        updatedPoint.minGrade = tonumber(result[3]) or 0
        updatedPoint.targetLabel = result[4] or ''
        updatedPoint.public = false
    end

    if not updatedPoint.coords then
        updatedPoint.coords = captureRaycastPoint(updatedPoint.label)
        if not updatedPoint.coords then return Menu.openStationBusinessList(groupType, group, station, key) end
    end

    stationSaveAndBack(groupType, upsertStationPoint(group, station.id, key, updatedPoint), station, key)
end

function Menu.openStationShopItems(groupType, group, station, shop)
    local options = {
        {
            title = t('menu.business.create_item'),
            icon = 'plus',
            onSelect = function()
                Menu.openStationShopItemEditor(groupType, group, station, shop)
            end,
        },
    }

    for index, item in ipairs(shop.items or {}) do
        local itemName = item.name or item.item or item.itemName
        local stock = type(shop.stock) == 'table' and tonumber(shop.stock[itemName]) or 0

        options[#options + 1] = {
            title = item.label or itemName,
            description = t('menu.business.shop_item_description', {
                price = tostring(item.price or 0),
                stock = tostring(stock or 0),
            }),
            icon = 'box',
            onSelect = function()
                Menu.openStationShopItemEditor(groupType, group, station, shop, item, index)
            end,
        }
    end

    showContext({
        id = ('forge_core_station_shop_items_%s_%s_%s_%s'):format(groupType, group.name, station.id, shop.id),
        title = t('menu.business.items'),
        menu = ('forge_core_station_business_point_%s_%s_%s_shops_%s'):format(groupType, group.name, station.id, shop.id),
        options = options,
    })
end

function Menu.openStationShopItemEditor(groupType, group, station, shop, item, itemIndex)
    item = item or {}

    local result = inputDialog(itemIndex and t('menu.business.edit_item') or t('menu.business.create_item'), {
        { type = 'input', label = t('inputs.business_item_name'), required = true, default = item.name or item.item or item.itemName or '' },
        { type = 'input', label = t('inputs.business_item_label'), default = item.label or '' },
        { type = 'number', label = t('inputs.business_price'), default = tonumber(item.price) or 0, min = 0, required = true },
    })

    if not result then return Menu.openStationShopItems(groupType, group, station, shop) end

    local updatedItem = {
        name = result[1],
        label = result[2] or '',
        price = tonumber(result[3]) or 0,
        buyGrade = tonumber(shop.buyGrade) or 0,
    }

    local updatedShop = clone(shop)
    updatedShop.items = type(updatedShop.items) == 'table' and updatedShop.items or {}
    if itemIndex then updatedShop.items[itemIndex] = updatedItem else updatedShop.items[#updatedShop.items + 1] = updatedItem end

    stationSaveAndBack(groupType, upsertStationPoint(group, station.id, 'shops', updatedShop), station, 'shops')
end

function Menu.openStationApplicationQuestions(groupType, group, station, application)
    local options = {
        {
            title = t('menu.business.create_question'),
            icon = 'plus',
            onSelect = function()
                Menu.openStationQuestionEditor(groupType, group, station, application)
            end,
        },
    }

    for index, question in ipairs(application.questions or {}) do
        options[#options + 1] = {
            title = question.label or question.question,
            description = t('menu.whitelist.question_summary', { index = tostring(index), options = tostring(#(question.options or {})) }),
            icon = 'question-circle-fill',
            onSelect = function()
                Menu.openStationQuestionEditor(groupType, group, station, application, question, index)
            end,
        }
    end

    showContext({
        id = ('forge_core_station_questions_%s_%s_%s_%s'):format(groupType, group.name, station.id, application.id),
        title = t('menu.business.questions'),
        menu = ('forge_core_station_business_point_%s_%s_%s_applications_%s'):format(groupType, group.name, station.id, application.id),
        options = options,
    })
end

function Menu.openStationQuestionEditor(groupType, group, station, application, question, questionIndex)
    question = question or {}
    local options = question.options or {}

    local result = inputDialog(questionIndex and t('menu.business.edit_question') or t('menu.business.create_question'), {
        { type = 'input', label = t('inputs.whitelist_question'), required = true, default = question.question or question.label or '' },
        { type = 'input', label = t('inputs.whitelist_option') .. ' 1', required = true, default = options[1] and (options[1].label or options[1].text) or '' },
        { type = 'input', label = t('inputs.whitelist_option') .. ' 2', required = true, default = options[2] and (options[2].label or options[2].text) or '' },
        { type = 'input', label = t('inputs.whitelist_option') .. ' 3', default = options[3] and (options[3].label or options[3].text) or '' },
        { type = 'input', label = t('inputs.whitelist_option') .. ' 4', default = options[4] and (options[4].label or options[4].text) or '' },
        { type = 'number', label = t('inputs.whitelist_option_correct'), default = tonumber(question.correct) or 1, min = 1, max = 4, required = true },
    })

    if not result then return Menu.openStationApplicationQuestions(groupType, group, station, application) end

    local updatedQuestion = { question = result[1], correct = tonumber(result[6]) or 1, options = {} }
    for i = 2, 5 do
        if (pr_lib.utils.trim(result[i]) or '') ~= '' then updatedQuestion.options[#updatedQuestion.options + 1] = { label = result[i] } end
    end

    local updatedApplication = clone(application)
    updatedApplication.questions = type(updatedApplication.questions) == 'table' and updatedApplication.questions or {}
    if questionIndex then updatedApplication.questions[questionIndex] = updatedQuestion else updatedApplication.questions[#updatedApplication.questions + 1] = updatedQuestion end

    stationSaveAndBack(groupType, upsertStationPoint(group, station.id, 'applications', updatedApplication), station, 'applications')
end

function Menu.openStationCandidates(groupType, group, station, application)
    local ok, submissions = awaitServer(PR.Job.Callbacks.getApplications, groupType, group.name, station.id, application.id)
    if not ok then
        notifyFailure('notify.business.candidates_failed', submissions)
        return
    end

    local options = {}
    for _, candidate in ipairs(submissions or {}) do
        options[#options + 1] = {
            title = candidate.name or candidate.citizenid,
            description = t('menu.business.candidate_description', {
                score = tostring(candidate.score or 0),
                status = tostring(candidate.status or 'pending'),
                phone = tostring(candidate.phone or t('common.none')),
            }),
            icon = candidate.passed and 'person-check-fill' or 'person-x-fill',
            iconColor = candidate.passed and '#22c55e' or '#ef4444',
            onSelect = function()
                Menu.openStationCandidateActions(groupType, group, station, application, candidate)
            end,
        }
    end

    if #options == 0 then options[#options + 1] = { title = t('menu.business.no_candidates'), disabled = true } end

    showContext({
        id = ('forge_core_station_candidates_%s_%s_%s_%s'):format(groupType, group.name, station.id, application.id),
        title = t('menu.business.candidates'),
        menu = ('forge_core_station_business_point_%s_%s_%s_applications_%s'):format(groupType, group.name, station.id, application.id),
        options = options,
    })
end

function Menu.openStationCandidateActions(groupType, group, station, application, candidate)
    showContext({
        id = ('forge_core_station_candidate_%s_%s_%s'):format(groupType, group.name, candidate.id),
        title = candidate.name or candidate.citizenid,
        menu = ('forge_core_station_candidates_%s_%s_%s_%s'):format(groupType, group.name, station.id, application.id),
        options = {
            {
                title = t('menu.business.accept_candidate'),
                icon = 'person-plus-fill',
                onSelect = function()
                    local ok, response = awaitServer(PR.Job.Callbacks.reviewApplication, groupType, group.name, station.id, application.id, candidate.id, 'accepted')
                    notify({ description = ok and t('notify.business.hired') or t('notify.business.hire_failed', { error = tostring(response or 'unknown') }), type = ok and 'success' or 'error' })
                end,
            },
            {
                title = t('menu.business.reject_candidate'),
                icon = 'person-dash-fill',
                onSelect = function()
                    local ok, response = awaitServer(PR.Job.Callbacks.reviewApplication, groupType, group.name, station.id, application.id, candidate.id, 'rejected')
                    notify({ description = ok and t('notify.business.rejected') or t('notify.business.reject_failed', { error = tostring(response or 'unknown') }), type = ok and 'success' or 'error' })
                end,
            },
        },
    })
end

function Menu.openBossApplications(groupType, group)
    local ok, applications = awaitServer(PR.Job.Callbacks.getApplications, groupType, group.name)
    if not ok then
        notifyFailure('notify.business.candidates_failed', applications)
        return
    end

    local options = {}
    for _, application in ipairs(applications or {}) do
        options[#options + 1] = {
            title = application.label or application.title or application.id,
            description = t('menu.business.application_station_description', {
                station = tostring(application.stationTitle or application.stationId or t('common.none')),
                count = tostring(#(application.submissions or {})),
            }),
            icon = 'file-earmark-text-fill',
            onSelect = function()
                Menu.openStationCandidates(groupType, group, { id = application.stationId, title = application.stationTitle }, application)
            end,
        }
    end

    if #options == 0 then options[#options + 1] = { title = t('menu.business.no_applications'), disabled = true } end

    showContext({
        id = ('forge_core_boss_applications_%s_%s'):format(groupType, group.name),
        title = t('menu.business.candidates'),
        menu = ('forge_core_boss_panel_%s_%s'):format(groupType, group.name),
        options = options,
    })
end
