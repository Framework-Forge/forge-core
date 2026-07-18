ForgeCore = ForgeCore or {}

local Business = {
    shops = {},
    openHookId = nil,
    purchaseHookId = nil,
}
local trim = pr_lib.utils.trim

local function logBusiness(level, message)
    level = level or 'info'
    message = tostring(message or '')

    local debugApi = pr_lib and pr_lib.debug
    local fn = debugApi and debugApi[level]

    if type(fn) == 'function' then
        fn(('[forge-core:business] %s'):format(message))
        if level ~= 'warn' and level ~= 'error' then return end
    end

    if PR.Debug == true or level == 'warn' or level == 'error' then
        print(('[forge-core:business][%s] %s'):format(level, message))
    end
end

local function boolValue(value)
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value or ''):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function normalizeId(value)
    value = (trim(value) or ''):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    value = value:gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return value
end

local function clone(value)
    return pr_lib.table.clone(value)
end

local function getGroup(groupType, groupName)
    groupType = groupType == 'gang' and 'gang' or 'job'
    return ForgeCore.JobRegistry.get(groupType, groupName)
end

local function gradeLevel(groupData)
    local grade = groupData and groupData.grade
    if type(grade) == 'table' then return tonumber(grade.level or grade.grade or grade.value) or 0 end
    return tonumber(grade) or 0
end

local function playerGroup(playerData, groupType)
    if not playerData then return nil end
    return groupType == 'gang' and playerData.gang or playerData.job
end

local function getGradeData(group, level)
    local grades = group and group.grades or {}
    return grades[tonumber(level) or 0] or grades[tostring(tonumber(level) or 0)]
end

local function hasActiveGroup(source, groupType, groupName, minGrade)
    local playerData = pr_lib.framework.GetPlayerData(source)
    if not playerData then return false, 'invalid_player' end

    local activeGroup = playerGroup(playerData, groupType)
    if not activeGroup or tostring(activeGroup.name or ''):lower() ~= tostring(groupName or ''):lower() then
        return false, 'wrong_group'
    end

    if gradeLevel(activeGroup) < (tonumber(minGrade) or 0) then
        return false, 'low_grade'
    end

    return true, playerData, gradeLevel(activeGroup)
end

local function canManageGroup(source, groupType, group)
    if ForgeCore.JobService.canManage(source) then return true end

    local ok, _, level = hasActiveGroup(source, groupType, group and group.name, 0)
    if not ok then return false end

    local grade = getGradeData(group, level)
    return type(grade) == 'table' and (grade.isboss == true or grade.isrecruiter == true)
end

local function canBossGroup(source, groupType, group)
    if ForgeCore.JobService.canManage(source) then return true end

    local ok, _, level = hasActiveGroup(source, groupType, group and group.name, 0)
    if not ok then return false end

    local grade = getGradeData(group, level)
    return type(grade) == 'table' and grade.isboss == true
end

local function coordsVector(coords)
    if type(coords) ~= 'table' then return nil end

    local ok, vector = pcall(pr_lib.math.toVector, coords)
    if ok and type(vector) == 'vector3' then return vector end
end

local function getStation(group, stationId)
    local stations = type(group and group.stashes) == 'table' and group.stashes or {}
    local id = normalizeId(stationId)

    for index = 1, #stations do
        if normalizeId(stations[index] and stations[index].id) == id then
            return stations[index], index
        end
    end
end

local function getPointFromList(list, pointId, onlyShop)
    local id = normalizeId(pointId)
    for index = 1, #(list or {}) do
        local point = list[index]
        if normalizeId(point and point.id) == id and (not onlyShop or point.type == 'shop' or point.kind == 'shop') then
            return point, index
        end
    end
end

local function getScopedPoint(group, stationId, key, pointId, onlyShop)
    local station, stationIndex = getStation(group, stationId)
    if not station then return nil end

    local point, pointIndex = getPointFromList(station[key], pointId, onlyShop)
    if point then return station, stationIndex, point, pointIndex end
end

local function shopId(groupType, groupName, stationId, point, forcedAccessMode)
    local pointId = type(point) == 'table' and point.id or point
    local accessMode = forcedAccessMode or (type(point) == 'table' and boolValue(point.public) and 'public' or 'group')
    return ('forge_core_%s_%s_%s_%s_%s'):format(groupType == 'gang' and 'gang' or 'job', normalizeId(groupName), normalizeId(stationId), normalizeId(pointId), accessMode)
end

local function itemName(item)
    return trim(item and (item.name or item.item or item.itemName)) or ''
end

local function itemLabel(name)
    if pr_lib.inventory and pr_lib.inventory.GetItemLabel then
        local label = pr_lib.inventory.GetItemLabel(name)
        if (trim(label) or '') ~= '' then return label end
    end

    if pr_lib.inventory and pr_lib.inventory.Items then
        local item = pr_lib.inventory.Items(name)
        if type(item) == 'table' and (trim(item.label) or '') ~= '' then return item.label end
    end

    return name
end

local function shopStockCount(shop, item)
    local stock = type(shop.stock) == 'table' and shop.stock or {}
    return tonumber(stock[itemName(item)]) or tonumber(item.stock or item.stockAmount) or 0
end

local function buildShopInventory(shop)
    local inventory = {}

    for slot, item in ipairs(shop.items or {}) do
        local name = itemName(item)
        if name ~= '' then
            inventory[#inventory + 1] = {
                name = name,
                price = tonumber(item.price) or 0,
                count = shopStockCount(shop, item),
                license = (trim(item.license) or '') ~= '' and trim(item.license) or nil,
                metadata = type(item.metadata) == 'table' and item.metadata or nil,
                slot = slot,
            }
        end
    end

    return inventory
end

local function ensureRenewedSocietyAccount(accountName, accountLabel)
    if GetResourceState('Renewed-Banking') ~= 'started' then return false end

    local ok, account = pcall(function()
        return exports['Renewed-Banking']:GetJobAccount(accountName)
    end)

    if ok and account then return true end

    ok, account = pcall(function()
        return exports['Renewed-Banking']:CreateJobAccount({
            name = accountName,
            label = accountLabel or accountName,
        }, 0)
    end)

    if ok and account then
        logBusiness('info', ('Renewed-Banking society account created account=%s'):format(accountName))
        return true
    end

    logBusiness('warn', ('Renewed-Banking society account create failed account=%s result=%s'):format(accountName, tostring(account)))
    return false
end

local function addSocietyRevenue(accountName, amount, accountLabel)
    accountName = normalizeId(accountName)
    amount = math.floor(tonumber(amount) or 0)
    local reason = 'forge-core:shop-sale'
    if accountName == '' or amount <= 0 then
        logBusiness('warn', ('shop sale revenue ignored account=%s amount=%s'):format(accountName, tostring(amount)))
        return false
    end

    if GetResourceState('Renewed-Banking') == 'started' then
        ensureRenewedSocietyAccount(accountName, accountLabel)

        local ok, result = pcall(function()
            return exports['Renewed-Banking']:addAccountMoney(accountName, amount)
        end)

        if ok and result ~= false then
            pcall(function()
                exports['Renewed-Banking']:handleTransaction(accountName, ForgeCore.t('banking.shop_sale_title'), amount, reason, 'Forge Core', accountLabel or accountName, 'deposit')
            end)

            logBusiness('info', ('shop sale credited via Renewed-Banking account=%s amount=%s'):format(accountName, tostring(amount)))
            return true
        end

        logBusiness('warn', ('Renewed-Banking addAccountMoney failed account=%s amount=%s result=%s'):format(accountName, tostring(amount), tostring(result)))
    end

    if pr_lib.banking and pr_lib.banking.AddJobAccountBalance then
        local ok, result = pcall(pr_lib.banking.AddJobAccountBalance, accountName, amount, reason)
        if ok and result ~= false then
            logBusiness('info', ('shop sale credited via pr_lib.banking account=%s amount=%s'):format(accountName, tostring(amount)))
            return true
        end

        logBusiness('warn', ('pr_lib.banking society credit failed account=%s amount=%s result=%s'):format(accountName, tostring(amount), tostring(result)))
    end

    if pr_lib.framework and pr_lib.framework.AddJobAccountBalance then
        local ok, result = pcall(pr_lib.framework.AddJobAccountBalance, accountName, amount, reason)
        if ok and result ~= false then
            logBusiness('info', ('shop sale credited via pr_lib.framework account=%s amount=%s'):format(accountName, tostring(amount)))
            return true
        end

        logBusiness('warn', ('pr_lib.framework society credit failed account=%s amount=%s result=%s'):format(accountName, tostring(amount), tostring(result)))
    end

    if pr_lib.framework and pr_lib.framework.addSocietyBalance then
        local ok, result = pcall(pr_lib.framework.addSocietyBalance, accountName, amount, reason)
        if ok and result ~= false then
            logBusiness('info', ('shop sale credited via pr_lib.framework.addSocietyBalance account=%s amount=%s'):format(accountName, tostring(amount)))
            return true
        end

        logBusiness('warn', ('pr_lib.framework.addSocietyBalance failed account=%s amount=%s result=%s'):format(accountName, tostring(amount), tostring(result)))
    end

    if GetResourceState('ps-banking') == 'started' then
        local ok, result = pcall(function()
            return exports['ps-banking']:AddMoney(accountName, amount, reason)
        end)

        if ok and result ~= false then
            logBusiness('info', ('shop sale credited via ps-banking account=%s amount=%s'):format(accountName, tostring(amount)))
            return true
        end

        logBusiness('warn', ('ps-banking AddMoney failed account=%s amount=%s result=%s'):format(accountName, tostring(amount), tostring(result)))
    end

    logBusiness('error', ('unable to credit shop sale account=%s amount=%s'):format(accountName, tostring(amount)))
    return false
end

local function handleShopPurchase(success, payload)
    if success ~= true or type(payload) ~= 'table' then return end

    local shopType = tostring(payload.shopType or '')
    local shopInfo = Business.shops[shopType]
    if not shopInfo then
        if shopType:sub(1, 17) == 'forge_core_store_' then return end
        logBusiness('warn', ('buyItem ignored unknown shopType=%s item=%s count=%s'):format(shopType, tostring(payload.itemName), tostring(payload.count)))
        return
    end

    local group = getGroup(shopInfo.groupType, shopInfo.groupName)
    if not group then
        logBusiness('warn', ('buyItem group not found shopType=%s group=%s'):format(shopType, tostring(shopInfo.groupName)))
        return
    end

    local _, stationIndex, shop, shopIndex = getScopedPoint(group, shopInfo.stationId, 'shops', shopInfo.pointId, true)
    if not shop then
        logBusiness('warn', ('buyItem shop point not found shopType=%s station=%s point=%s'):format(shopType, tostring(shopInfo.stationId), tostring(shopInfo.pointId)))
        return
    end

    local name = trim(payload.itemName or itemName(payload.fromSlot)) or ''
    local count = math.floor(tonumber(payload.count) or 0)
    local totalPrice = math.floor(tonumber(payload.totalPrice) or ((tonumber(payload.price) or 0) * count))
    if name == '' or count <= 0 then
        logBusiness('warn', ('buyItem invalid payload shopType=%s item=%s count=%s'):format(shopType, name, tostring(count)))
        return
    end

    local updated = clone(group)
    local targetShop = updated.stashes[stationIndex].shops[shopIndex]
    targetShop.stock = type(targetShop.stock) == 'table' and targetShop.stock or {}
    local previousStock = tonumber(targetShop.stock[name]) or 0
    targetShop.stock[name] = math.max((tonumber(targetShop.stock[name]) or 0) - count, 0)

    local saved = ForgeCore.JobService.upsert(0, updated, shopInfo.groupType)
    local credited = addSocietyRevenue(shopInfo.groupName, totalPrice, shopInfo.groupLabel)
    logBusiness(saved == true and 'info' or 'error', ('shop purchase shop=%s group=%s item=%s count=%s stock=%s->%s total=%s saved=%s credited=%s'):format(
        shopType,
        tostring(shopInfo.groupName),
        name,
        tostring(count),
        tostring(previousStock),
        tostring(targetShop.stock[name]),
        tostring(totalPrice),
        tostring(saved),
        tostring(credited)
    ))
end

local function validateShopOpen(payload)
    if type(payload) ~= 'table' then return end

    local shopType = tostring(payload.shopType or '')
    local shopInfo = Business.shops[shopType]
    if not shopInfo then return end
    if shopInfo.public == true then return end

    local ok, err = hasActiveGroup(payload.source, shopInfo.groupType, shopInfo.groupName, shopInfo.buyGrade)
    if not ok then
        logBusiness('warn', ('ox openShop blocked source=%s shop=%s group=%s reason=%s'):format(
            tostring(payload.source),
            shopType,
            tostring(shopInfo.groupName),
            tostring(err)
        ))
        return false
    end
end

local function registerOpenShopHook()
    if Business.openHookId or not pr_lib.inventory or not pr_lib.inventory.RegisterHook then return end

    Business.openHookId = pr_lib.inventory.RegisterHook('openShop', validateShopOpen)
    if Business.openHookId then
        logBusiness('info', ('registered ox_inventory openShop hook=%s'):format(tostring(Business.openHookId)))
    else
        logBusiness('warn', 'unable to register ox_inventory openShop hook')
    end
end

local function registerPurchaseHook()
    if Business.purchaseHookId or not pr_lib.inventory or not pr_lib.inventory.RegisterHook then return end

    Business.purchaseHookId = pr_lib.inventory.RegisterHook('buyItem', function()
        return nil
    end)

    if Business.purchaseHookId then
        AddEventHandler(Business.purchaseHookId, handleShopPurchase)
        logBusiness('info', ('registered ox_inventory buyItem hook=%s'):format(tostring(Business.purchaseHookId)))
    else
        logBusiness('warn', 'unable to register ox_inventory buyItem hook')
    end
end

local function registerShop(group, station, shop, accessMode)
    local id = shopId(group.type, group.name, station.id, shop, accessMode)
    local inventory = buildShopInventory(shop)

    Business.shops[id] = {
        groupType = group.type,
        groupName = group.name,
        groupLabel = group.label or group.name,
        stationId = station.id,
        pointId = shop.id,
        public = accessMode == 'public',
        buyGrade = tonumber(shop.buyGrade or shop.minGrade) or 0,
    }

    logBusiness('info', ('register shop id=%s group=%s public=%s items=%s access=%s'):format(
        id,
        tostring(group.name),
        tostring(accessMode == 'public'),
        tostring(#inventory),
        'forge-controlled'
    ))

    pr_lib.inventory.RegisterShop(id, {
        name = shop.label or shop.title or station.title or group.label or id,
        inventory = inventory,
    })

    return id
end

function Business.registerAll()
    if not pr_lib.inventory or not pr_lib.inventory.RegisterShop then return false, 'inventory_unavailable' end
    registerOpenShopHook()
    registerPurchaseHook()
    Business.shops = {}

    local groups = {}
    for _, group in pairs(ForgeCore.JobRegistry.getJobs() or {}) do
        group.type = 'job'
        groups[#groups + 1] = group
    end
    for _, group in pairs(ForgeCore.JobRegistry.getGangs() or {}) do
        group.type = 'gang'
        groups[#groups + 1] = group
    end

    for i = 1, #groups do
        local group = groups[i]
        local stations = type(group.stashes) == 'table' and group.stashes or {}

        for stationIndex = 1, #stations do
            local station = stations[stationIndex]
            for _, shop in ipairs(station.shops or {}) do
                if shop.enabled ~= false then
                    if boolValue(shop.public) then
                        registerShop(group, station, shop, 'public')
                    else
                        registerShop(group, station, shop, 'group')
                    end
                end
            end
        end

    end

    return true
end

function Business.openShop(source, groupType, groupName, stationId, pointId)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end

    local _, _, shop = getScopedPoint(group, stationId, 'shops', pointId, true)
    if not shop or shop.enabled == false then return false, 'shop_not_found' end

    local isPublic = boolValue(shop.public)
    if not isPublic then
        local ok, err = hasActiveGroup(source, groupType, group.name, tonumber(shop.buyGrade or shop.minGrade) or 0)
        if not ok then
            logBusiness('warn', ('shop access denied source=%s group=%s station=%s shop=%s reason=%s'):format(tostring(source), tostring(group.name), tostring(stationId), tostring(pointId), tostring(err)))
            return false, err
        end
    end

    local accessMode = isPublic and 'public' or 'group'
    local id = registerShop(group, { id = stationId, title = stationId }, shop, accessMode)
    if not Business.shops[id] then
        logBusiness('warn', ('shop id not indexed, refreshing registrations id=%s'):format(id))
        Business.registerAll()
    end

    logBusiness('info', ('shop open allowed source=%s id=%s public=%s group=%s'):format(tostring(source), id, tostring(isPublic), tostring(group.name)))
    return true, id
end

function Business.getSupplyItems(source, groupType, groupName, stationId, pointId)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end

    local _, _, shop = getScopedPoint(group, stationId, 'shops', pointId, true)
    if not shop or shop.enabled == false then return false, 'shop_not_found' end

    local ok, err = hasActiveGroup(source, groupType, group.name, tonumber(shop.supplyGrade or shop.minGrade) or 0)
    if not ok then return false, err end

    local items = pr_lib.inventory.GetInventoryItems(source) or {}
    local mapped = {}

    for _, item in pairs(items) do
        local name = itemName(item)
        local count = tonumber(item.count or item.amount or item.quantity) or 0

        if name ~= '' and count > 0 then
            mapped[name] = mapped[name] or {
                name = name,
                label = item.label or itemLabel(name),
                count = 0,
            }
            mapped[name].count = mapped[name].count + count
        end
    end

    local list = {}
    for _, item in pairs(mapped) do
        list[#list + 1] = item
    end

    table.sort(list, function(left, right)
        return tostring(left.label or left.name) < tostring(right.label or right.name)
    end)

    return true, list
end

local function findShopItem(shop, name)
    for index, item in ipairs(shop.items or {}) do
        if itemName(item) == name then return item, index end
    end
end

function Business.supplyShop(source, groupType, groupName, stationId, pointId, selectedItem, amount, price)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end

    local _, stationIndex, shop, shopIndex = getScopedPoint(group, stationId, 'shops', pointId, true)
    if not shop or shop.enabled == false then return false, 'shop_not_found' end

    local ok, err = hasActiveGroup(source, groupType, group.name, tonumber(shop.supplyGrade or shop.minGrade) or 0)
    if not ok then return false, err end

    local name = trim(selectedItem) or ''
    amount = math.floor(tonumber(amount) or 0)
    price = math.floor(tonumber(price) or 0)
    if name == '' or amount <= 0 then return false, 'invalid_item' end
    if price < 0 then return false, 'invalid_price' end

    local available = tonumber(pr_lib.inventory.GetItemCount(source, name)) or 0
    if available < amount then return false, 'item_missing' end

    if not pr_lib.inventory.RemoveItem(source, name, amount) then return false, 'item_missing' end

    local updated = clone(group)
    local targetShop = updated.stashes[stationIndex].shops[shopIndex]
    targetShop.items = type(targetShop.items) == 'table' and targetShop.items or {}

    local targetItem = findShopItem(targetShop, name)
    if targetItem then
        targetItem.price = price
        targetItem.label = targetItem.label or itemLabel(name)
        targetItem.buyGrade = tonumber(targetItem.buyGrade or targetShop.buyGrade or targetShop.minGrade) or 0
    else
        targetShop.items[#targetShop.items + 1] = {
            name = name,
            label = itemLabel(name),
            price = price,
            buyGrade = tonumber(targetShop.buyGrade or targetShop.minGrade) or 0,
        }
    end

    targetShop.stock = type(targetShop.stock) == 'table' and targetShop.stock or {}
    targetShop.stock[name] = (tonumber(targetShop.stock[name]) or 0) + amount

    local saved = ForgeCore.JobService.upsert(0, updated, groupType)
    if saved ~= true then return false, 'save_failed' end

    return true, targetShop.stock[name]
end

function Business.getRegisterBalance(source, groupType, groupName, stationId, pointId)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end

    local _, _, register = getScopedPoint(group, stationId, 'registers', pointId)
    if not register or register.enabled == false then return false, 'register_not_found' end

    local ok, err = hasActiveGroup(source, groupType, group.name, tonumber(register.minGrade) or 0)
    if not ok then return false, err end

    return true, tonumber(register.balance) or 0
end

local function validateRegisterAccess(source, register, password)
    if (trim(register.password) or '') ~= '' and tostring(password or '') ~= tostring(register.password) then
        return false, 'wrong_password'
    end

    return true
end

function Business.registerAction(source, groupType, groupName, stationId, pointId, action, amount, password)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end

    local _, stationIndex, register, registerIndex = getScopedPoint(group, stationId, 'registers', pointId)
    if not register or register.enabled == false then return false, 'register_not_found' end

    local accessMode = register.accessMode == 'password' and 'password' or 'grade'
    local ok, err

    if accessMode == 'password' then
        ok, err = validateRegisterAccess(source, register, password)
        if not ok then return false, err end
    else
        ok, err = hasActiveGroup(source, groupType, group.name, tonumber(register.minGrade) or 0)
        if not ok then return false, err end
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, 'invalid_amount' end

    local updated = clone(group)
    local targetRegister = updated.stashes[stationIndex].registers[registerIndex]
    targetRegister.balance = tonumber(targetRegister.balance) or 0

    if action == 'deposit' then
        if not pr_lib.inventory.RemoveItem(source, 'money', amount) then return false, 'money_missing' end
        targetRegister.balance = targetRegister.balance + amount
    elseif action == 'withdraw' then
        if targetRegister.balance < amount then return false, 'register_money_missing' end
        if not pr_lib.inventory.AddItem(source, 'money', amount) then return false, 'add_failed' end
        targetRegister.balance = targetRegister.balance - amount
    else
        return false, 'invalid_action'
    end

    local saved = ForgeCore.JobService.upsert(0, updated, groupType)
    return saved == true, saved == true and targetRegister.balance or 'save_failed'
end

function Business.robRegister(source, groupType, groupName, stationId, pointId, amount)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end

    local _, stationIndex, register, registerIndex = getScopedPoint(group, stationId, 'registers', pointId)
    if not register or register.enabled == false then return false, 'register_not_found' end
    if register.robberyEnabled ~= true then return false, 'robbery_disabled' end

    local updated = clone(group)
    local targetRegister = updated.stashes[stationIndex].registers[registerIndex]
    targetRegister.balance = tonumber(targetRegister.balance) or 0
    local balance = math.floor(targetRegister.balance)
    local limit = math.floor(tonumber(register.robberyAmount) or tonumber(amount) or balance)
    if limit <= 0 then limit = balance end

    amount = math.min(balance, limit)
    if amount <= 0 then
        logBusiness('warn', ('register robbery empty source=%s group=%s station=%s register=%s balance=%s limit=%s'):format(tostring(source), tostring(group.name), tostring(stationId), tostring(pointId), tostring(balance), tostring(limit)))
        return false, 'register_money_missing'
    end

    if not pr_lib.inventory.AddItem(source, 'money', amount) then return false, 'add_failed' end
    targetRegister.balance = balance - amount

    local chance = tonumber(register.robberyAlertChance) or 0
    if chance > 0 and math.random(100) <= math.min(chance, 100) then
        local coords = GetEntityCoords(GetPlayerPed(source))
        TriggerEvent('forge-core:server:job:alarm', source, {
            groupType = groupType,
            group = group.name,
            label = group.label,
            point = register.label or register.title or pointId,
            message = ForgeCore.t('notify.business.robbery_police_alert', { register = register.label or register.title or pointId }),
            coords = { x = coords.x, y = coords.y, z = coords.z },
        })
    end

    local saved = ForgeCore.JobService.upsert(0, updated, groupType)
    logBusiness(saved == true and 'info' or 'error', ('register robbery source=%s group=%s station=%s register=%s balance=%s limit=%s stolen=%s remaining=%s saved=%s'):format(
        tostring(source),
        tostring(group.name),
        tostring(stationId),
        tostring(pointId),
        tostring(balance),
        tostring(limit),
        tostring(amount),
        tostring(targetRegister.balance),
        tostring(saved)
    ))
    return saved == true, saved == true and amount or 'save_failed'
end

function Business.sendAlarm(source, groupType, groupName, stationId, pointId)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end

    local _, _, alarm = getScopedPoint(group, stationId, 'alarms', pointId)
    if not alarm or alarm.enabled == false then return false, 'alarm_not_found' end

    local ok, err = hasActiveGroup(source, groupType, group.name, tonumber(alarm.minGrade) or 0)
    if not ok then return false, err end

    local coords = GetEntityCoords(GetPlayerPed(source))
    TriggerEvent('forge-core:server:job:alarm', source, {
        groupType = groupType,
        group = group.name,
        label = group.label,
        point = alarm.label or alarm.title or pointId,
        message = alarm.message,
        coords = { x = coords.x, y = coords.y, z = coords.z },
    })

    return true
end

local function playerIdentity(source)
    local data = pr_lib.framework.GetPlayerData(source)
    local charinfo = type(data) == 'table' and type(data.charinfo) == 'table' and data.charinfo or {}
    local name = trim(('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')) or ''
    if name == '' then name = GetPlayerName(source) or tostring(source) end

    local phone
    if pr_lib.phone and pr_lib.phone.GetPhoneNumberFromIdentifier then
        local ok, result = pcall(pr_lib.phone.GetPhoneNumberFromIdentifier, source, true)
        if ok then phone = result end
    end

    return {
        source = source,
        citizenid = data and data.citizenid,
        name = name,
        phone = phone or charinfo.phone or charinfo.phone_number or '',
    }
end

function Business.submitApplication(source, groupType, groupName, stationId, pointId, answers)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end

    local _, stationIndex, application, applicationIndex = getScopedPoint(group, stationId, 'applications', pointId)
    if not application or application.enabled == false then return false, 'application_not_found' end

    local questions = type(application.questions) == 'table' and application.questions or {}
    if #questions < 1 then return false, 'no_questions' end

    answers = type(answers) == 'table' and answers or {}
    local correct = 0

    for index, question in ipairs(questions) do
        if tostring(answers[index]) == tostring(question.correct) then correct = correct + 1 end
    end

    local score = math.floor((correct / #questions) * 100)
    local identity = playerIdentity(source)
    if not identity.citizenid then return false, 'invalid_player' end

    local updated = clone(group)
    local target = updated.stashes[stationIndex].applications[applicationIndex]
    target.submissions = type(target.submissions) == 'table' and target.submissions or {}

    for i = #target.submissions, 1, -1 do
        if target.submissions[i].citizenid == identity.citizenid and target.submissions[i].status == 'pending' then
            table.remove(target.submissions, i)
        end
    end

    target.submissions[#target.submissions + 1] = {
        id = ('%s_%s'):format(identity.citizenid, os.time()),
        citizenid = identity.citizenid,
        name = identity.name,
        phone = identity.phone,
        score = score,
        passed = score >= (tonumber(application.minScore) or 70),
        answers = answers,
        status = 'pending',
        createdAt = os.time(),
    }

    local saved = ForgeCore.JobService.upsert(0, updated, groupType)
    if saved ~= true then return false, 'save_failed' end

    return true, { score = score, passed = score >= (tonumber(application.minScore) or 70) }
end

function Business.getApplications(source, groupType, groupName, stationId, pointId)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end
    if not canManageGroup(source, groupType, group) then return false, 'no_permission' end

    if pointId then
        local _, _, application = getScopedPoint(group, stationId, 'applications', pointId)
        return true, application and (application.submissions or {}) or {}
    end

    local applications = {}
    for _, station in ipairs(group.stashes or {}) do
        for _, application in ipairs(station.applications or {}) do
            local copy = clone(application)
            copy.stationId = station.id
            copy.stationTitle = station.title
            applications[#applications + 1] = copy
        end
    end
    return true, applications
end

function Business.reviewApplication(source, groupType, groupName, stationId, pointId, submissionId, status)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end
    if not canManageGroup(source, groupType, group) then return false, 'no_permission' end

    status = status == 'accepted' and 'accepted' or status == 'rejected' and 'rejected' or nil
    if not status then return false, 'invalid_status' end

    local _, stationIndex, application, applicationIndex = getScopedPoint(group, stationId, 'applications', pointId)
    if not application then return false, 'application_not_found' end

    local updated = clone(group)
    local target = updated.stashes[stationIndex].applications[applicationIndex]
    local submissions = target.submissions or {}

    for i = 1, #submissions do
        if tostring(submissions[i].id) == tostring(submissionId) then
            submissions[i].status = status
            if status == 'accepted' then
                return Business.hirePlayer(source, groupType, groupName, submissions[i].citizenid, 0, updated)
            end

            local saved = ForgeCore.JobService.upsert(0, updated, groupType)
            return saved == true, saved == true and submissions[i] or 'save_failed'
        end
    end

    return false, 'submission_not_found'
end

local function playerNameByCitizenid(citizenid)
    if pr_lib.framework.GetPlayerNameByIdentifier then
        return pr_lib.framework.GetPlayerNameByIdentifier(citizenid)
    end

    return citizenid
end

function Business.getEmployees(source, groupType, groupName)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end
    if not canManageGroup(source, groupType, group) then return false, 'no_permission' end

    local rows
    if GetResourceState('qbx_core') == 'started' then
        local ok, result = pcall(function()
            return exports.qbx_core:GetGroupMembers(group.name, groupType == 'gang' and 'gang' or 'job')
        end)
        if ok then rows = result end
    end

    if not rows and MySQL and MySQL.query and MySQL.query.await then
        rows = MySQL.query.await('SELECT citizenid, grade FROM player_groups WHERE `group` = ? AND type = ?', {
            group.name,
            groupType == 'gang' and 'gang' or 'job',
        }) or {}
    end

    if not rows then return false, 'database_unavailable' end

    local employees = {}
    for i = 1, #rows do
        local citizenid = rows[i].citizenid
        employees[#employees + 1] = {
            citizenid = citizenid,
            grade = tonumber(rows[i].grade) or 0,
            name = playerNameByCitizenid(citizenid),
        }
    end

    return true, employees
end

function Business.hirePlayer(source, groupType, groupName, citizenid, grade, groupOverride)
    local group = groupOverride or getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end
    if source ~= 0 and not canManageGroup(source, groupType, group) then return false, 'no_permission' end

    grade = tonumber(grade) or 0
    local ok, err
    if groupType == 'gang' then
        ok, err = pr_lib.framework.AddPlayerToGang(citizenid, group.name, grade)
    else
        ok, err = pr_lib.framework.AddPlayerToJob(citizenid, group.name, grade)
    end

    if not ok then return false, err and (err.code or err.message) or 'hire_failed' end

    if groupOverride then
        local saved = ForgeCore.JobService.upsert(0, groupOverride, groupType)
        if saved ~= true then return false, 'save_failed' end
    end

    return true
end

function Business.fireEmployee(source, groupType, groupName, citizenid)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end
    if not canBossGroup(source, groupType, group) then return false, 'no_permission' end

    local ok, err
    if groupType == 'gang' then
        ok, err = pr_lib.framework.RemovePlayerFromGang(citizenid, group.name)
    else
        ok, err = pr_lib.framework.RemovePlayerFromJob(citizenid, group.name)
    end

    if not ok then return false, err and (err.code or err.message) or 'fire_failed' end
    return true
end

function Business.setEmployeeGrade(source, groupType, groupName, citizenid, grade)
    local group = getGroup(groupType, groupName)
    if not group then return false, 'group_not_found' end
    if not canBossGroup(source, groupType, group) then return false, 'no_permission' end

    return Business.hirePlayer(0, groupType, group.name, citizenid, grade)
end

ForgeCore.JobBusiness = Business
