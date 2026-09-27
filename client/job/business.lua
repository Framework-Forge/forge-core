ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Business = {
    zones = {},
    lastPayload = nil,
    refreshPending = false,
}

local trim = pr_lib.utils.trim

local function boolValue(value)
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value or ''):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function normalizeId(value)
    value = (trim(value) or ''):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    value = value:gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return value
end

local function coordsVector(coords)
    if type(coords) ~= 'table' then return nil end

    local ok, vector = pcall(pr_lib.math.toVector, coords)
    if ok and type(vector) == 'vector3' then return vector end
end

local function getPlayerData()
    if pr_lib.framework and pr_lib.framework.GetPlayerData then
        local data = pr_lib.framework.GetPlayerData()
        if type(data) == 'table' then return data end
    end

    return {}
end

local function playerGroup(data, groupType)
    return groupType == 'gang' and data.gang or data.job
end

local function gradeLevel(group)
    local grade = group and group.grade
    if type(grade) == 'table' then return tonumber(grade.level or grade.grade or grade.value) or 0 end
    return tonumber(grade) or 0
end

local function accessSignature()
    local data = getPlayerData()
    local job, gang = data.job or {}, data.gang or {}
    return table.concat({ tostring(job.name or ''):lower(), tostring(gradeLevel(job)),
        tostring(gang.name or ''):lower(), tostring(gradeLevel(gang)) }, '|')
end

local function canUseGroup(groupType, groupName, minGrade)
    local data = getPlayerData()
    local group = playerGroup(data, groupType)
    local activeName = group and tostring(group.name or ''):lower() or ''
    local requiredName = tostring(groupName or ''):lower()

    return activeName == requiredName and gradeLevel(group) >= (tonumber(minGrade) or 0)
end

local function notify(data)
    if pr_lib.Notify then
        pr_lib.Notify({
            title = data.title or t('core.title'),
            description = data.description,
            type = data.type,
            position = PR.NotifyPos,
        })
    end
end

local function awaitServer(callbackName, ...)
    if not pr_lib.callback or not pr_lib.callback.await then return false, 'callback_unavailable' end
    return pr_lib.callback.await(callbackName, 10000, ...)
end

local function showContext(context)
    if not pr_lib.menus or not pr_lib.menus.RegisterContext or not pr_lib.menus.ShowContext then return false end
    pr_lib.menus.RegisterContext(context)
    pr_lib.menus.ShowContext(context.id)
    return true
end

local function inputDialog(title, rows, options)
    if not pr_lib.menus or not pr_lib.menus.InputDialog then return nil end
    return pr_lib.menus.InputDialog(title, rows, options)
end

local function clearZones()
    if pr_lib.target and pr_lib.target.removeZone then
        for i = 1, #Business.zones do
            pr_lib.target.removeZone(Business.zones[i])
        end
    end

    Business.zones = {}
end

local function addZone(data)
    if not pr_lib.target or not pr_lib.target.addBoxZone then return end

    local zoneId = pr_lib.target.addBoxZone({
        coords = data.coords,
        size = PR.Job.Points.targetSize or vec3(1.0, 1.0, 1.8),
        rotation = tonumber(data.rotation) or 0.0,
        debug = PR.Debug == true,
        options = data.options,
    })

    if zoneId then Business.zones[#Business.zones + 1] = zoneId end
end

local function shopId(groupType, groupName, stationId, point)
    local pointId = type(point) == 'table' and point.id or point
    local accessMode = type(point) == 'table' and boolValue(point.public) and 'public' or 'group'
    return ('forge_core_%s_%s_%s_%s_%s'):format(groupType == 'gang' and 'gang' or 'job', normalizeId(groupName), normalizeId(stationId), normalizeId(pointId), accessMode)
end

local function openShopSupply(groupType, group, station, shop)
    local ok, items = awaitServer(PR.Job.Callbacks.getSupplyItems, groupType, group.name, station.id, shop.id)
    if not ok then
        notify({ description = t('notify.business.shop_supply_failed', { error = tostring(items or 'unknown') }), type = 'error' })
        return
    end

    local options = {}
    for _, item in ipairs(items or {}) do
        options[#options + 1] = {
            value = item.name,
            label = ('%s (%s)'):format(item.label or item.name, tostring(item.count or 0)),
        }
    end

    if #options == 0 then
        notify({ description = t('menu.business.no_supply_items'), type = 'error' })
        return
    end

    local rows = {
        {
            type = 'select',
            label = t('inputs.business_item_name'),
            options = options,
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.business_amount'),
            min = 1,
            default = 1,
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.business_price'),
            min = 0,
            default = 0,
            required = true,
        },
    }

    local result = inputDialog(t('menu.business.supply_shop'), rows)
    if not result then return end

    local success, response = awaitServer(PR.Job.Callbacks.supplyShop, groupType, group.name, station.id, shop.id, result[1], result[2], result[3])
    notify({
        description = success and t('notify.business.shop_supplied') or t('notify.business.shop_supply_failed', { error = tostring(response or 'unknown') }),
        type = success and 'success' or 'error',
    })
end

local function lockpickDifficulty(config)
    local difficulty = tostring(config and config.difficulty or 'medium'):lower()
    if difficulty == 'easy' then return 2, 40, 3, 45, 400 end
    if difficulty == 'hard' then return 5, 18, 1, 25, 700 end
    return 3, 30, 2, 40, 500
end

local function runLockpick(config)
    if GetResourceState('glitch-minigames') ~= 'started' then return false end

    local rounds, sweetSpot, failures, shake, lockTime = lockpickDifficulty(config)
    return exports['glitch-minigames']:StartLockpickGame(rounds, sweetSpot, failures, shake, lockTime) == true
end

local function openRegister(groupType, group, station, register)
    local ok, balance = awaitServer(PR.Job.Callbacks.getRegisterBalance, groupType, group.name, station.id, register.id)
    balance = ok and tonumber(balance) or 0
    local passwordAccess = register.accessMode == 'password'
    local employeeAccess = passwordAccess or canUseGroup(groupType, group.name, tonumber(register.minGrade) or 0)

    local options = {
        {
            title = t('menu.business.register_balance'),
            description = t('menu.business.money_value', { amount = tostring(balance) }),
            icon = 'wallet',
            disabled = true,
        },
    }

    if employeeAccess then
        options[#options + 1] = {
            title = t('menu.business.deposit'),
            icon = 'download',
            onSelect = function()
                local result = inputDialog(t('menu.business.deposit'), {
                    { type = 'number', label = t('inputs.business_amount'), min = 1, required = true },
                    { type = 'input', label = t('inputs.business_password'), password = true, default = '' },
                })
                if not result then return openRegister(groupType, group, station, register) end
                local success, response = awaitServer(PR.Job.Callbacks.registerAction, groupType, group.name, station.id, register.id, 'deposit', result[1], result[2])
                notify({ description = success and t('notify.business.register_saved') or t('notify.business.register_failed', { error = tostring(response or 'unknown') }), type = success and 'success' or 'error' })
                if success then openRegister(groupType, group, station, register) end
            end,
        }
        options[#options + 1] = {
            title = t('menu.business.withdraw'),
            icon = 'upload',
            onSelect = function()
                local result = inputDialog(t('menu.business.withdraw'), {
                    { type = 'number', label = t('inputs.business_amount'), min = 1, required = true },
                    { type = 'input', label = t('inputs.business_password'), password = true, default = '' },
                })
                if not result then return openRegister(groupType, group, station, register) end
                local success, response = awaitServer(PR.Job.Callbacks.registerAction, groupType, group.name, station.id, register.id, 'withdraw', result[1], result[2])
                notify({ description = success and t('notify.business.register_saved') or t('notify.business.register_failed', { error = tostring(response or 'unknown') }), type = success and 'success' or 'error' })
                if success then openRegister(groupType, group, station, register) end
            end,
        }
    end

    if register.robberyEnabled == true then
        options[#options + 1] = {
            title = t('menu.business.rob_register'),
            icon = 'unlock-fill',
            iconColor = '#ef4444',
            onSelect = function()
                if not runLockpick(register.robbery) then
                    notify({ description = t('notify.business.robbery_failed'), type = 'error' })
                    return
                end

                if pr_lib.progress and pr_lib.progress.doProgressbar then
                    local progressed = pr_lib.progress.doProgressbar(7000, t('menu.business.robbery_progress'), { 'anim@heists@ornate_bank@grab_cash', 'grab' })
                    if not progressed then return end
                end

                local success, response = awaitServer(PR.Job.Callbacks.robRegister, groupType, group.name, station.id, register.id, register.robberyAmount)
                notify({ description = success and t('notify.business.robbery_success', { amount = tostring(response or 0) }) or t('notify.business.robbery_server_failed', { error = tostring(response or 'unknown') }), type = success and 'success' or 'error' })
            end,
        }
    end

    showContext({
        id = ('forge_core_business_register_%s_%s_%s_%s'):format(groupType, group.name, station.id, register.id),
        title = register.label or register.title or t('menu.business.register'),
        options = options,
    })
end

local function openApplication(groupType, group, station, application)
    local rows = {}
    for index, question in ipairs(application.questions or {}) do
        local options = {}
        for optionIndex, option in ipairs(question.options or {}) do
            options[#options + 1] = { value = tostring(optionIndex), label = option.label or option.text or tostring(option) }
        end

        rows[#rows + 1] = {
            type = 'select',
            label = question.label or question.question or t('menu.business.question_number', { index = tostring(index) }),
            options = options,
            required = true,
        }
    end

    if #rows == 0 then
        notify({ description = t('notify.business.no_questions'), type = 'error' })
        return
    end

    local result = inputDialog(application.label or application.title or t('menu.business.application'), rows)
    if not result then return end

    local ok, response = awaitServer(PR.Job.Callbacks.submitApplication, groupType, group.name, station.id, application.id, result)
    notify({
        description = ok and t('notify.business.application_sent', { score = tostring(response.score or 0) }) or t('notify.business.application_failed', { error = tostring(response or 'unknown') }),
        type = ok and (response.passed and 'success' or 'inform') or 'error',
    })
end

local function openBoss(groupType, group)
    if ForgeCore.Client.Menu and ForgeCore.Client.Menu.openBossPanel then
        ForgeCore.Client.Menu.openBossPanel(groupType, group)
        return
    end

    notify({ description = t('notify.business.boss_unavailable'), type = 'error' })
end

local function addPointZone(groupType, group, station, key, point, icon, labelKey, handler, publicAllowed, gradeField)
    local coords = coordsVector(point and point.coords)
    local isPublic = publicAllowed and point and boolValue(point.public)
    local minGrade = tonumber(point and (point[gradeField or 'minGrade'] or point.minGrade)) or 0

    if type(point) ~= 'table' or point.enabled == false or not coords then return end
    if not isPublic and not canUseGroup(groupType, group.name, minGrade) then return end

    addZone({
        coords = coords,
        rotation = point.rotation,
        options = {
            {
                name = ('forge_core_business_%s_%s_%s_%s_%s'):format(key, groupType, group.name, normalizeId(station.id), normalizeId(point.id)),
                icon = icon,
                label = point.targetLabel or point.label or point.title or t(labelKey, { title = group.label or group.name }),
                distance = PR.Job.Points.targetDistance or 2.0,
                canInteract = function()
                    return isPublic or canUseGroup(groupType, group.name, minGrade)
                end,
                onSelect = function()
                    handler(groupType, group, station, point)
                end,
            },
        },
    })
end

local function buildStation(groupType, group, station)
    for _, shop in ipairs(station.shops or {}) do
        local coords = coordsVector(shop.coords)
        if type(shop) == 'table' and shop.enabled ~= false and coords then
            local isPublic = boolValue(shop.public)
            local buyGrade = tonumber(shop.buyGrade or shop.minGrade) or 0
            if isPublic or canUseGroup(groupType, group.name, buyGrade) then
                local options = {
                    {
                        name = ('forge_core_shop_open_%s_%s_%s_%s'):format(groupType, group.name, normalizeId(station.id), normalizeId(shop.id)),
                        icon = 'shop',
                        label = shop.targetLabel or shop.label or t('menu.business.shop_target', { title = group.label or group.name }),
                        distance = PR.Job.Points.targetDistance or 2.0,
                        canInteract = function()
                            return isPublic or canUseGroup(groupType, group.name, buyGrade)
                        end,
                        onSelect = function()
                            if not shop.items or #shop.items == 0 then
                                notify({ description = t('menu.business.no_shop_stock'), type = 'error' })
                                return
                            end

                            local ok, response = awaitServer(PR.Job.Callbacks.openShop, groupType, group.name, station.id, shop.id)
                            if not ok then
                                notify({ description = t('notify.business.shop_open_failed', { error = tostring(response or 'unknown') }), type = 'error' })
                                return
                            end

                            pr_lib.inventory.openInventory('shop', { type = response or shopId(groupType, group.name, station.id, shop) })
                        end,
                    },
                }

                if canUseGroup(groupType, group.name, tonumber(shop.supplyGrade or shop.minGrade) or 0) then
                    options[#options + 1] = {
                        name = ('forge_core_shop_supply_%s_%s_%s_%s'):format(groupType, group.name, normalizeId(station.id), normalizeId(shop.id)),
                        icon = 'boxes',
                        label = t('menu.business.supply_shop'),
                        distance = PR.Job.Points.targetDistance or 2.0,
                        onSelect = function()
                            openShopSupply(groupType, group, station, shop)
                        end,
                    }
                end

                addZone({ coords = coords, rotation = shop.rotation, options = options })
            end
        end
    end

    for _, register in ipairs(station.registers or {}) do
        local coords = coordsVector(register and register.coords)
        if type(register) == 'table' and register.enabled ~= false and coords and (register.accessMode == 'password' or register.robberyEnabled == true or canUseGroup(groupType, group.name, register.minGrade)) then
            addZone({
                coords = coords,
                rotation = register.rotation,
                options = {
                    {
                        name = ('forge_core_business_registers_%s_%s_%s_%s'):format(groupType, group.name, normalizeId(station.id), normalizeId(register.id)),
                        icon = 'safe2-fill',
                        label = register.targetLabel or register.label or register.title or t('menu.business.register_target', { title = group.label or group.name }),
                        distance = PR.Job.Points.targetDistance or 2.0,
                        canInteract = function()
                            return register.accessMode == 'password' or register.robberyEnabled == true or canUseGroup(groupType, group.name, register.minGrade)
                        end,
                        onSelect = function()
                            openRegister(groupType, group, station, register)
                        end,
                    },
                },
            })
        end
    end
    for _, alarm in ipairs(station.alarms or {}) do
        addPointZone(groupType, group, station, 'alarms', alarm, 'fa-solid fa-bell', 'menu.business.alarm_target', function(activeGroupType, activeGroup, activeStation, point)
            local ok, response = awaitServer(PR.Job.Callbacks.sendAlarm, activeGroupType, activeGroup.name, activeStation.id, point.id)
            notify({ description = ok and t('notify.business.alarm_sent') or t('notify.business.alarm_failed', { error = tostring(response or 'unknown') }), type = ok and 'success' or 'error' })
        end, false)
    end
    for _, bossMenu in ipairs(station.bossMenus or {}) do
        addPointZone(groupType, group, station, 'bossMenus', bossMenu, 'fa-solid fa-crown', 'menu.business.boss_target', openBoss, false)
    end
    for _, application in ipairs(station.applications or {}) do
        addPointZone(groupType, group, station, 'applications', application, 'fa-solid fa-file-signature', 'menu.business.application_target', openApplication, true)
    end
end

local function buildForGroup(groupType, group)
    for _, station in ipairs(group.stashes or {}) do
        buildStation(groupType, group, station)
    end
end

function Business.refresh(payload)
    clearZones()

    if type(payload) ~= 'table' then return end
    Business.lastPayload = payload
    Business.accessSignature = accessSignature()

    for _, group in ipairs(payload.jobs or {}) do buildForGroup('job', group) end
    for _, group in ipairs(payload.gangs or {}) do buildForGroup('gang', group) end
end

function Business.refreshCurrent(accessOnly)
    if accessOnly and Business.accessSignature == accessSignature() then return end
    if Business.refreshPending then return end

    Business.refreshPending = true
    SetTimeout(250, function()
        Business.refreshPending = false
        if type(Business.lastPayload) == 'table' then Business.refresh(Business.lastPayload) end
    end)
end

RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    Business.refreshCurrent(true)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    Business.refreshCurrent()
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function()
    Business.refreshCurrent()
end)

RegisterNetEvent('esx:setJob', function()
    Business.refreshCurrent()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then clearZones() end
end)

ForgeCore.Client.JobBusiness = Business
