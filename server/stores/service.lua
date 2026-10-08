ForgeCore = ForgeCore or {}

local Service = {
    state = {},
    locks = {},
    incidents = {},
    shops = {},
    dailyStock = {},
    notificationHistory = {},
    purchaseHookId = nil,
    purchaseEventHandle = nil,
    initialized = false,
}

local function logStore(level, message)
    level = level or 'info'
    message = tostring(message or '')

    local debugApi = pr_lib and pr_lib.debug
    local fn = debugApi and debugApi[level]
    if type(fn) == 'function' then
        fn(('[forge-core:stores] %s'):format(message))
        if level ~= 'warn' and level ~= 'error' then return end
    end

    if PR.Debug == true or level == 'warn' or level == 'error' then
        print(('[forge-core:stores][%s] %s'):format(level, message))
    end
end

local function notify(source, data)
    if not source or source <= 0 then return end
    local notifications = pr_lib and pr_lib.notifications
    if (not notifications or not notifications.NotifyPlayer) and pr_lib then notifications = pr_lib.notify end
    if not notifications or not notifications.NotifyPlayer then return end

    local description = tostring(data.description or '')
    local key = ('%s:%s:%s'):format(source, tostring(data.type or 'info'), description)
    local now = GetGameTimer()
    local previous = Service.notificationHistory[key]
    if previous and now - previous < 1000 then return end
    Service.notificationHistory[key] = now

    notifications.NotifyPlayer(source, {
        id = data.id or ('forge_core_stores_%s'):format(tostring(data.type or 'info')),
        title = data.title or ForgeCore.t('stores.title'),
        description = description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function clone(value)
    return pr_lib and pr_lib.table and pr_lib.table.clone and pr_lib.table.clone(value) or value
end

local function trim(value)
    if pr_lib and pr_lib.utils and pr_lib.utils.trim then return pr_lib.utils.trim(value) end
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function numberValue(value, fallback)
    return tonumber(value) or fallback or 0
end

local function normalizeId(value)
    value = trim(value):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    value = value:gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return value
end

local function normalizeVector(value)
    value = type(value) == 'table' and value or {}
    return {
        x = numberValue(value.x or value[1]),
        y = numberValue(value.y or value[2]),
        z = numberValue(value.z or value[3]),
    }
end

local function todayKey()
    return os.date('%Y-%m-%d')
end

local function canManage(source)
    if source == 0 then return true end
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end

    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function playerData(source)
    if pr_lib and pr_lib.framework and pr_lib.framework.GetPlayerData then
        local data = pr_lib.framework.GetPlayerData(source)
        if type(data) == 'table' then return data end
    end

    return {}
end

local function citizenId(source)
    local data = playerData(source)
    return tostring(data.citizenid or data.citizenId or data.citizenID or '')
end

local function playerName(source)
    local data = playerData(source)
    local charinfo = type(data.charinfo) == 'table' and data.charinfo or {}
    local full = trim(('%s %s'):format(charinfo.firstname or '', charinfo.lastname or ''))
    return full ~= '' and full or GetPlayerName(source) or tostring(source)
end

local function playerContact(source)
    local data = playerData(source)
    local charinfo = type(data.charinfo) == 'table' and data.charinfo or {}
    return tostring(data.phone or data.phone_number or charinfo.phone or charinfo.phoneNumber or '')
end

local function itemLabel(name)
    name = tostring(name or '')
    if pr_lib and pr_lib.inventory then
        if pr_lib.inventory.GetItemLabel then
            local label = pr_lib.inventory.GetItemLabel(name)
            if label and label ~= '' then return label end
        end

        if pr_lib.inventory.Items then
            local item = pr_lib.inventory.Items(name)
            if type(item) == 'table' and item.label then return item.label end
        end
    end

    return name
end

local function itemExists(name)
    name = tostring(name or '')
    if name == '' then return false end
    if not pr_lib or not pr_lib.inventory or not pr_lib.inventory.Items then return true end

    local item = pr_lib.inventory.Items(name)
    return item ~= nil
end

local function addItem(source, name, count, metadata)
    if pr_lib and pr_lib.inventory and pr_lib.inventory.AddItem then
        return pr_lib.inventory.AddItem(source, name, count, metadata)
    end

    if GetResourceState('ox_inventory'):find('start') ~= nil then
        return exports.ox_inventory:AddItem(source, name, count, metadata)
    end

    return false
end

local function removeItem(source, name, count, metadata, slot)
    if pr_lib and pr_lib.inventory and pr_lib.inventory.RemoveItem then
        return pr_lib.inventory.RemoveItem(source, name, count, metadata, slot)
    end

    if GetResourceState('ox_inventory'):find('start') ~= nil then
        return exports.ox_inventory:RemoveItem(source, name, count, metadata, slot)
    end

    return false
end

local function itemCount(source, name)
    if pr_lib and pr_lib.inventory and pr_lib.inventory.GetItemCount then
        return tonumber(pr_lib.inventory.GetItemCount(source, name)) or 0
    end

    if GetResourceState('ox_inventory'):find('start') ~= nil then
        return tonumber(exports.ox_inventory:Search(source, 'count', name)) or 0
    end

    return 0
end

local function canCarry(source, name, count, metadata)
    if pr_lib and pr_lib.inventory and pr_lib.inventory.CanCarryItem then
        local ok = pr_lib.inventory.CanCarryItem(source, name, count, metadata)
        if ok ~= nil then return ok == true end
    end

    return true
end

local function isMoneyCurrency(currency)
    currency = trim(currency)
    return currency == '' or currency == 'money' or currency == 'cash' or currency == 'bank'
end

local function chargePlayer(source, amount, reason, currency)
    amount = math.floor(numberValue(amount))
    if amount <= 0 then return true, 'free' end

    currency = trim(currency)
    if not isMoneyCurrency(currency) then
        if itemCount(source, currency) < amount then return false, 'not_enough_currency' end
        if removeItem(source, currency, amount) then return true, ('item:%s'):format(currency) end
        return false, 'remove_currency_failed'
    end

    local framework = pr_lib and pr_lib.framework
    if not framework or not framework.removePlayerMoney then return false, 'money_unavailable' end

    local accounts = PR.Stores.Defaults.paymentAccounts or { 'cash', 'bank' }
    if currency == 'cash' or currency == 'bank' then
        accounts = { currency }
    end

    for _, account in ipairs(accounts) do
        if (tonumber(framework.getPlayerMoney and framework.getPlayerMoney(source, account)) or 0) >= amount then
            local removed = framework.removePlayerMoney(source, account, amount, reason)
            if removed == true then return true, account end
        end
    end

    return false, 'not_enough_money'
end

local function refundPlayer(source, account, amount, reason)
    amount = math.floor(numberValue(amount))
    if amount <= 0 or account == 'free' then return true end

    account = tostring(account or '')
    if account:sub(1, 5) == 'item:' then
        return addItem(source, account:sub(6), amount) == true
    end

    local framework = pr_lib and pr_lib.framework
    if framework and framework.addPlayerMoney then
        return framework.addPlayerMoney(source, account, amount, reason) == true
    end
    return false
end

local function normalizeItem(item)
    item = type(item) == 'table' and item or {}
    local name = trim(item.name)

    return {
        name = name,
        label = trim(item.label) ~= '' and trim(item.label) or itemLabel(name),
        price = math.max(0, math.floor(numberValue(item.price))),
        dailyStock = math.max(0, math.floor(numberValue(item.dailyStock or item.daily, PR.Stores.Defaults.defaultDailyStock))),
        metadata = type(item.metadata) == 'table' and item.metadata or nil,
        currency = trim(item.currency) ~= '' and trim(item.currency) or 'money',
        grade = item.grade,
        enabled = boolValue(item.enabled, true),
    }
end

local function normalizeStorePoints(store)
    local points = {}
    local source = type(store.points) == 'table' and store.points or {}

    for _, point in ipairs(source) do
        local coords = normalizeVector(type(point) == 'table' and (point.coords or point) or nil)
        if coords then
            points[#points + 1] = {
                coords = coords,
                rotation = numberValue(type(point) == 'table' and (point.rotation or point.heading) or nil),
            }
        end
    end

    if #points == 0 then
        local coords = normalizeVector(store.coords or store.shopcoords)
        if coords then
            points[1] = {
                coords = coords,
                rotation = numberValue(store.rotation or store.heading),
            }
        end
    end

    return points
end

local function normalizeStore(store)
    store = type(store) == 'table' and store or {}
    local id = normalizeId(store.id ~= nil and store.id or store.label)
    local points = normalizeStorePoints(store)
    local primaryPoint = points[1]

    local normalized = {
        id = id,
        label = trim(store.label) ~= '' and trim(store.label) or id,
        enabled = boolValue(store.enabled, true),
        salesPaused = boolValue(store.salesPaused, false),
        owner = trim(store.owner),
        ownerName = trim(store.ownerName),
        ownerPhone = trim(store.ownerPhone),
        purchasePrice = math.max(0, math.floor(numberValue(store.purchasePrice or store.price))),
        saleListed = boolValue(store.saleListed, false),
        balance = math.max(0, math.floor(numberValue(store.balance))),
        coords = primaryPoint and primaryPoint.coords or nil,
        rotation = primaryPoint and primaryPoint.rotation or 0.0,
        points = points,
        targetLabel = trim(store.targetLabel),
        blip = type(store.blip) == 'table' and store.blip or nil,
        groups = type(store.groups) == 'table' and store.groups or nil,
        managers = type(store.managers) == 'table' and store.managers or {},
        items = {},
        stock = type(store.stock) == 'table' and store.stock or {},
        currencyBalances = type(store.currencyBalances) == 'table' and store.currencyBalances or {},
        sales = type(store.sales) == 'table' and store.sales or {},
    }

    local seenItems = {}
    for _, item in ipairs(type(store.items) == 'table' and store.items or type(store.inventory) == 'table' and store.inventory or {}) do
        item = normalizeItem(item)
        if item.name ~= '' and not seenItems[item.name] then
            seenItems[item.name] = true
            normalized.items[#normalized.items + 1] = item
            if normalized.owner == '' then
                normalized.stock[item.name] = nil
            else
                normalized.stock[item.name] = math.max(0, math.floor(numberValue(normalized.stock[item.name])))
            end
        end
    end

    table.sort(normalized.items, function(left, right) return tostring(left.label) < tostring(right.label) end)
    return normalized
end

local storeById
local isBlacklisted

local function hasStoreAccess(source, store)
    local cid = citizenId(source)
    if cid == '' then return false end
    if store.owner == cid then return true end

    for _, manager in ipairs(type(store.managers) == 'table' and store.managers or {}) do
        if type(manager) == 'table' and manager.citizenid == cid then return true end
        if type(manager) == 'string' and manager == cid then return true end
    end

    return false
end

local function shopId(storeId)
    return ('forge_core_store_%s'):format(normalizeId(storeId))
end

local function itemName(item)
    if type(item) == 'table' then return trim(item.name) end
    return trim(item)
end

local function usesOwnerStock(store)
    return trim(store and store.owner) ~= ''
end

local function availableStock(store, item, daily)
    daily = daily or Service.dailyStock
    if usesOwnerStock(store) then
        return math.max(0, math.floor(numberValue(store.stock and store.stock[item.name])))
    end

    daily[store.id] = daily[store.id] or {}
    local remaining = daily[store.id][item.name]
    if remaining == nil then
        remaining = math.max(0, math.floor(numberValue(item.dailyStock)))
        daily[store.id][item.name] = remaining
    end
    return remaining
end

local function setAvailableStock(store, item, amount, daily)
    daily = daily or Service.dailyStock
    amount = math.max(0, math.floor(numberValue(amount)))
    if usesOwnerStock(store) then
        store.stock = type(store.stock) == 'table' and store.stock or {}
        store.stock[item.name] = amount
        return
    end

    daily[store.id] = daily[store.id] or {}
    daily[store.id][item.name] = amount
end

local function initializeDailyStock()
    Service.dailyStock = {}
    for _, store in ipairs((state or Service.state).stores or {}) do
        if not usesOwnerStock(store) then
            Service.dailyStock[store.id] = {}
            for _, item in ipairs(store.items or {}) do
                Service.dailyStock[store.id][item.name] = math.max(0, math.floor(numberValue(item.dailyStock)))
            end
        end
    end
end

local function buildShopInventory(store)
    local inventory = {}
    for _, item in ipairs(store.items or {}) do
        local stock = availableStock(store, item)
        if item.enabled ~= false and stock > 0 and not isBlacklisted(item.name) and itemExists(item.name) then
            inventory[#inventory + 1] = {
                name = item.name,
                price = math.max(0, math.floor(numberValue(item.price))),
                count = stock,
                metadata = item.metadata,
                currency = item.currency ~= 'money' and item.currency or nil,
                grade = item.grade,
            }
        elseif item.enabled ~= false and not itemExists(item.name) then
            logStore('warn', ('shop item ignored store=%s item=%s stock=%s enabled=%s exists=%s'):format(
                tostring(store.id),
                tostring(item.name),
                tostring(stock),
                tostring(item.enabled ~= false),
                tostring(itemExists(item.name))
            ))
        end
    end

    return inventory
end

local function registerShop(store)
    if not pr_lib.inventory or not pr_lib.inventory.RegisterShop then return false, 'inventory_unavailable' end

    local id = shopId(store.id)
    Service.shops[id] = store.id
    pr_lib.inventory.RegisterShop(id, {
        name = store.label or id,
        groups = store.groups,
        inventory = buildShopInventory(store),
    })

    return true, id
end

-- Copy just the edited store and its temporary stock, not every store/player.
local function storeDraft(storeId)
    storeId = normalizeId(storeId)
    local _, index = storeById(storeId)
    local draft = pr_lib.jsonDraft(Service.state, { stores = index and { [index] = true } or 'shallow' })
    local daily = pr_lib.jsonDraft(Service.dailyStock, { [tostring(storeId)] = true })
    return draft, daily
end

local function incident(storeId, source, operation, details)
    local key = tostring(storeId)
    Service.incidents[key] = { at = os.time(), citizenid = citizenId(source), operation = operation, details = details }
    if pr_lib.inventory.RemoveShop then pr_lib.inventory.RemoveShop(shopId(storeId)) end
    pr_lib.recordJsonIncident(PR.Stores.Storage.file, key, Service.incidents[key])
    return false, 'reconciliation_required'
end

local function compensate(storeId, source, operation, actions, details)
    local failures = {}
    for index = #actions, 1, -1 do
        local ok, result = pcall(actions[index])
        if not ok or result ~= true then failures[#failures + 1] = index end
    end
    if #failures > 0 then return incident(storeId, source, operation, { failedSteps = failures, transaction = details }) end
    return true
end

local function applyShopPurchase(success, payload)
    if success ~= true or type(payload) ~= 'table' then return end

    local storeId = Service.shops[tostring(payload.shopType or '')]
    if not storeId then return end

    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store then return end

    local name = trim(payload.itemName or itemName(payload.fromSlot))
    local count = math.max(0, math.floor(numberValue(payload.count)))
    local total = math.max(0, math.floor(numberValue(payload.totalPrice, numberValue(payload.price) * count)))
    if name == '' or count <= 0 then return end

    local purchasedItem
    for _, candidate in ipairs(store.items or {}) do
        if candidate.name == name then purchasedItem = candidate break end
    end
    local previousStock = purchasedItem and availableStock(store, purchasedItem, daily) or 0
    if purchasedItem then setAvailableStock(store, purchasedItem, previousStock - count, daily) end

    if isMoneyCurrency(payload.currency or 'money') then
        store.balance = math.max(0, math.floor(numberValue(store.balance) + total))
    else
        local currency = trim(payload.currency)
        store.currencyBalances = type(store.currencyBalances) == 'table' and store.currencyBalances or {}
        store.currencyBalances[currency] = math.max(0, math.floor(numberValue(store.currencyBalances[currency]) + total))
    end

    store.sales[#store.sales + 1] = {
        item = name,
        count = count,
        total = total,
        currency = payload.currency or 'money',
        buyer = citizenId(payload.source),
        at = os.time(),
    }

    while #store.sales > 50 do table.remove(store.sales, 1) end
    local saved = Service.save(draft, storeId, daily, true, true)
    if not saved then incident(storeId, payload.source, 'inventory-post-purchase', { item = name, count = count, total = total }) end
    logStore(saved and 'info' or 'error', ('ox purchase store=%s item=%s count=%s stock=%s->%s total=%s'):format(
        tostring(store.id),
        name,
        tostring(count),
        tostring(previousStock),
        tostring(purchasedItem and availableStock(store, purchasedItem) or 0),
        tostring(total)
    ))
end

local function handleShopPurchase(success, payload)
    local ok, err = pr_lib.withJsonLock(PR.Stores.Storage.file, applyShopPurchase, success, payload)
    if ok == false and err == 'busy' and type(payload) == 'table' then
        incident(Service.shops[tostring(payload.shopType or '')] or 'unknown', payload.source, 'inventory-post-purchase-busy', payload)
    end
end

local function registerPurchaseHook()
    if Service.purchaseHookId or not pr_lib.inventory or not pr_lib.inventory.RegisterHook then return end

    Service.purchaseHookId = pr_lib.inventory.RegisterHook('buyItem', function(payload)
        local storeId = type(payload) == 'table' and Service.shops[tostring(payload.shopType or '')]
        if storeId and Service.incidents[tostring(storeId)] then return false end
        return nil
    end)

    if Service.purchaseHookId then
        Service.purchaseEventHandle = AddEventHandler(Service.purchaseHookId, handleShopPurchase)
    end
end

local function normalizeSettings(settings)
    settings = type(settings) == 'table' and settings or {}

    local blacklist = {}
    for key, value in pairs(type(settings.blacklist) == 'table' and settings.blacklist or {}) do
        if type(key) == 'number' then
            local item = trim(value)
            if item ~= '' then blacklist[item] = true end
        elseif value == true then
            local item = trim(key)
            if item ~= '' then blacklist[item] = true end
        end
    end

    return {
        enabled = boolValue(settings.enabled, PR.Stores.Defaults.enabled),
        salesEnabled = boolValue(settings.salesEnabled, PR.Stores.Defaults.salesEnabled),
        dailyStockEnabled = boolValue(settings.dailyStockEnabled, PR.Stores.Defaults.dailyStockEnabled),
        defaultDailyStock = math.max(0, math.floor(numberValue(settings.defaultDailyStock, PR.Stores.Defaults.defaultDailyStock))),
        lastRestock = trim(settings.lastRestock),
        stockModelVersion = math.max(1, math.floor(numberValue(settings.stockModelVersion, 1))),
        blacklist = blacklist,
    }
end

local function normalizeState(state)
    state = type(state) == 'table' and state or {}
    local normalized = {
        settings = normalizeSettings(state.settings),
        stores = {},
        revision = GetGameTimer(),
    }

    local seenStores = {}
    for _, store in ipairs(type(state.stores) == 'table' and state.stores or {}) do
        store = normalizeStore(store)
        if store.id ~= '' and not seenStores[store.id] then
            seenStores[store.id] = true
            normalized.stores[#normalized.stores + 1] = store
        end
    end

    table.sort(normalized.stores, function(left, right) return tostring(left.label) < tostring(right.label) end)
    return normalized
end

local function readState()
    local loaded = pr_lib.loadJsonRecovery(PR.Stores.Storage.file, true)
    if type(loaded) == 'table' then return loaded end
    return nil
end

local function writeState(state, frequent)
    local saved, reason = pr_lib.saveJsonRecovery(PR.Stores.Storage.file, state, { backup = frequent and 'on_failure' or 'always' })
    return saved == true, reason
end

function storeById(storeId, state)
    storeId = normalizeId(storeId)
    for index, store in ipairs((state or Service.state).stores or {}) do
        if store.id == storeId then return store, index end
    end
end

function isBlacklisted(item)
    return Service.state.settings.blacklist[tostring(item or '')] == true
end

local function importOxStores()
    local raw = LoadResourceFile('ox_inventory', PR.Stores.Storage.oxBackupFile)
        or LoadResourceFile('ox_inventory', PR.Stores.Storage.oxFile)

    if not raw or raw == '' then return {} end

    raw = raw:gsub('`([^`]+)`', "'%1'")

    local env = {
        vec3 = function(x, y, z) return { x = x, y = y, z = z } end,
        vector3 = function(x, y, z) return { x = x, y = y, z = z } end,
        shared = { police = { police = 0 } },
    }

    local loader, err = load(raw, '@ox_inventory/data/shops.lua', 't', env)
    if not loader then
        logStore('warn', ('ox shops import parse failed: %s'):format(tostring(err)))
        return {}
    end

    local ok, shops = pcall(loader)
    if not ok or type(shops) ~= 'table' then
        logStore('warn', ('ox shops import failed: %s'):format(tostring(shops)))
        return {}
    end

    local imported = {}
    for shopType, shop in pairs(shops) do
        if type(shop) == 'table' and type(shop.inventory) == 'table' then
            local points = type(shop.targets) == 'table' and #shop.targets > 0 and shop.targets
                or type(shop.locations) == 'table' and shop.locations
                or {}

            for index, point in ipairs(points) do
                local coords = point.loc or point.coords or point
                local label = ('%s %s'):format(shop.name or shopType, tostring(index))
                local id = normalizeId(('%s_%s'):format(shopType, index))
                imported[#imported + 1] = normalizeStore({
                    id = id,
                    label = label,
                    enabled = true,
                    purchasePrice = 0,
                    coords = coords,
                    rotation = point.heading or 0.0,
                    targetLabel = shop.label,
                    blip = shop.blip and {
                        enabled = true,
                        sprite = shop.blip.id,
                        color = shop.blip.colour,
                        scale = shop.blip.scale,
                    } or nil,
                    groups = shop.groups or shop.jobs,
                    items = shop.inventory,
                })
            end
        end
    end

    logStore('info', ('imported ox shops stores=%s'):format(#imported))
    return imported
end

local function restockDaily(state)
    local settings = state.settings
    if settings.dailyStockEnabled ~= true then return false end

    local today = todayKey()
    if settings.lastRestock == today then return false end


    settings.lastRestock = today
    return true
end

local function migrateStockModel(state)
    local settings = state.settings
    local currentVersion = math.max(1, math.floor(numberValue(settings.stockModelVersion, 1)))
    local targetVersion = math.max(4, math.floor(numberValue(PR.Stores.Defaults.stockModelVersion, 4)))
    if currentVersion >= targetVersion then return false end

    for _, store in ipairs(state.stores or {}) do
        if not usesOwnerStock(store) then store.stock = {} end
    end

    settings.stockModelVersion = targetVersion
    return true
end

local function publish()
    ForgeCore.State.publish('stores',{
        settings = Service.state.settings,
        stores = Service.state.stores or {},
        revision = Service.state.revision or GetGameTimer(),
    })
end

function Service.getAll()
    return {
        settings = clone(Service.state.settings),
        stores = clone(Service.state.stores or {}),
        revision = Service.state.revision,
    }
end

local function registerAllShops()
    registerPurchaseHook()
    Service.shops = {}
    for _, store in ipairs(Service.state.stores or {}) do
        if store.enabled ~= false and not Service.incidents[tostring(store.id)] then
            registerShop(store)
        end
    end
end

function Service.load()
    local state = readState()
    if not state then
        state = {
            settings = clone(PR.Stores.Defaults),
            stores = importOxStores(),
        }
    end

    Service.state = normalizeState(state)
    initializeDailyStock()
    Service.incidents = pr_lib.loadJsonRecovery(PR.Stores.Storage.file .. '.incidents.json') or {}
    local draft = pr_lib.jsonDraft(Service.state)
    local migrated = migrateStockModel(draft)
    local restocked = restockDaily(draft)
    if migrated or restocked then
        local saved, reason = writeState(draft)
        if not saved then error(('stores initialization %s [%s]'):format(tostring(reason), PR.Stores.Storage.file)) end
        Service.state = draft
    end
    registerAllShops()
    publish()
    Service.initialized = true
    print(('[forge-core:stores] JSON carregado: %s lojas; habilitado=%s'):format(
        #Service.state.stores, tostring(Service.state.settings.enabled)))
    return Service.getAll()
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= 'ox_inventory' then return end
    if Service.purchaseEventHandle then RemoveEventHandler(Service.purchaseEventHandle) end
    Service.purchaseEventHandle, Service.purchaseHookId = nil, nil
    Service.shops = {}
end)
AddEventHandler('onResourceStart', function(resource)
    if resource ~= 'ox_inventory' or not Service.initialized then return end
    SetTimeout(0, function()
        if GetResourceState('ox_inventory') == 'started' then registerAllShops() end
    end)
end)
local inventoryRefreshScheduled = false
AddEventHandler('forge-core:server:inventory:reloaded', function()
    if not Service.initialized or inventoryRefreshScheduled then return end
    inventoryRefreshScheduled = true
    SetTimeout(0, function()
        inventoryRefreshScheduled = false
        if GetResourceState('ox_inventory') == 'started' then registerAllShops() end
    end)
end)

function Service.save(draft, changedStoreId, daily, noPayload, frequent)
    draft = draft or pr_lib.jsonDraft(Service.state, {})
    draft.revision = GetGameTimer()
    if not writeState(draft, frequent) then return false, 'save_failed' end
    Service.state = draft
    if daily then Service.dailyStock = daily end
    if changedStoreId then
        local store = storeById(changedStoreId)
        if store and store.enabled ~= false then registerShop(store)
        elseif pr_lib.inventory.RemoveShop then pr_lib.inventory.RemoveShop(shopId(changedStoreId)) end
    else registerAllShops() end
    publish()
    if noPayload then return true end
    return true, Service.getAll()
end

function Service.start()
    Service.load()
    logStore('info', ForgeCore.t('debug.stores.started'))
end

function Service.saveSettings(source, settings)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state, { settings = true })

    settings = normalizeSettings(settings)
    draft.settings.enabled = settings.enabled
    draft.settings.salesEnabled = settings.salesEnabled
    draft.settings.dailyStockEnabled = settings.dailyStockEnabled
    draft.settings.defaultDailyStock = settings.defaultDailyStock
    draft.settings.blacklist = settings.blacklist

    local ok, payload = Service.save(draft)
    if ok then notify(source, { description = ForgeCore.t('notify.stores.settings_saved'), type = 'success' }) end
    return ok, payload
end

function Service.createStore(source, data)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state, { stores = 'shallow' })

    data = type(data) == 'table' and data or {}
    local label = trim(data.label)
    if label == '' then return false, 'invalid_label' end

    data.id = normalizeId(data.id ~= nil and data.id or label)
    if data.id == '' then return false, 'invalid_id' end
    if storeById(data.id) then return false, 'duplicate_store' end

    local store = normalizeStore(data)
    draft.stores[#draft.stores + 1] = store

    local ok, payload = Service.save(draft)
    if ok then notify(source, { description = ForgeCore.t('notify.stores.store_saved'), type = 'success' }) end
    return ok, payload
end

function Service.updateStore(source, storeId, changes)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    if not canManage(source) then return false, 'no_permission' end

    local store = storeById(storeId, draft)
    if not store then return false, 'store_not_found' end

    changes = type(changes) == 'table' and changes or {}
    if changes.label ~= nil then store.label = trim(changes.label) end
    if changes.enabled ~= nil then store.enabled = boolValue(changes.enabled, store.enabled) end
    if changes.purchasePrice ~= nil or changes.price ~= nil then store.purchasePrice = math.max(0, math.floor(numberValue(changes.purchasePrice or changes.price))) end
    if changes.saleListed ~= nil then store.saleListed = boolValue(changes.saleListed, store.saleListed) end
    if changes.targetLabel ~= nil then store.targetLabel = trim(changes.targetLabel) end
    if changes.points ~= nil then
        local candidate = normalizeStorePoints({ points = changes.points })
        if #candidate == 0 then return false, 'invalid_store_points' end

        local origin = candidate[1].coords
        local radius = math.max(0.0, numberValue(PR.Stores.Defaults.additionalPointRadius, 50.0))
        for index = 2, #candidate do
            local coords = candidate[index].coords
            local dx, dy, dz = coords.x - origin.x, coords.y - origin.y, coords.z - origin.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) > radius then
                return false, 'store_point_out_of_range'
            end
        end

        store.points = candidate
        store.coords = candidate[1].coords
        store.rotation = candidate[1].rotation
    elseif changes.coords ~= nil then
        store.coords = normalizeVector(changes.coords)
        store.rotation = numberValue(changes.rotation or changes.heading or store.rotation)
        store.points = { { coords = store.coords, rotation = store.rotation } }
    elseif changes.rotation ~= nil or changes.heading ~= nil then
        store.rotation = numberValue(changes.rotation or changes.heading)
        if type(store.points) == 'table' and store.points[1] then store.points[1].rotation = store.rotation end
    end
    if changes.blip ~= nil then store.blip = type(changes.blip) == 'table' and changes.blip or nil end

    local ok, payload = Service.save(draft, storeId, daily)
    if ok then notify(source, { description = ForgeCore.t('notify.stores.store_saved'), type = 'success' }) end
    return ok, payload
end

function Service.updateOwnerStore(source, storeId, changes)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store then return false, 'store_not_found' end
    if store.owner ~= citizenId(source) then return false, 'no_permission' end

    changes = type(changes) == 'table' and changes or {}
    if changes.label ~= nil then
        local label = trim(changes.label)
        if label == '' then return false, 'invalid_label' end
        store.label = label
    end
    if changes.targetLabel ~= nil then store.targetLabel = trim(changes.targetLabel) end
    if changes.salesPaused ~= nil then store.salesPaused = boolValue(changes.salesPaused, store.salesPaused) end
    if changes.saleListed ~= nil then store.saleListed = boolValue(changes.saleListed, store.saleListed) end
    if changes.purchasePrice ~= nil or changes.price ~= nil then store.purchasePrice = math.max(0, math.floor(numberValue(changes.purchasePrice or changes.price))) end
    if changes.points ~= nil then
        local candidate = normalizeStorePoints({ points = changes.points })
        if #candidate == 0 then return false, 'invalid_store_points' end

        local origin = candidate[1].coords
        local radius = math.max(0.0, numberValue(PR.Stores.Defaults.additionalPointRadius, 50.0))
        for index = 2, #candidate do
            local coords = candidate[index].coords
            local dx, dy, dz = coords.x - origin.x, coords.y - origin.y, coords.z - origin.z
            if math.sqrt(dx * dx + dy * dy + dz * dz) > radius then
                return false, 'store_point_out_of_range'
            end
        end

        store.points = candidate
        store.coords = candidate[1].coords
        store.rotation = candidate[1].rotation
    end

    local ok, payload = Service.save(draft, storeId, daily)
    if ok then notify(source, { description = ForgeCore.t('notify.stores.store_saved'), type = 'success' }) end
    return ok, payload
end

function Service.deleteStore(source, storeId)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state, { stores = 'shallow' })

    local _, index = storeById(storeId, draft)
    if not index then return false, 'store_not_found' end

    table.remove(draft.stores, index)
    local ok, payload = Service.save(draft)
    if ok then notify(source, { description = ForgeCore.t('notify.stores.store_deleted'), type = 'success' }) end
    return ok, payload
end

function Service.getItems(source)
    local rawItems
    if pr_lib and pr_lib.inventory and pr_lib.inventory.Items then
        local ok, result = pcall(pr_lib.inventory.Items)
        if ok then rawItems = result end
    end

    if type(rawItems) ~= 'table' and GetResourceState('ox_inventory'):find('start') then
        local ok, result = pcall(function() return exports.ox_inventory:Items() end)
        if ok then rawItems = result end
    end

    local items = {}
    for name, data in pairs(type(rawItems) == 'table' and rawItems or {}) do
        local itemName = type(name) == 'string' and name or type(data) == 'table' and data.name
        if itemName and itemName ~= '' and not isBlacklisted(itemName) then
            items[#items + 1] = {
                name = itemName,
                label = type(data) == 'table' and (data.label or data.name) or itemName,
            }
        end
    end

    table.sort(items, function(left, right)
        return tostring(left.label or left.name):lower() < tostring(right.label or right.name):lower()
    end)
    return true, items
end

function Service.setItem(source, storeId, itemData)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store then return false, 'store_not_found' end
    if not canManage(source) and not hasStoreAccess(source, store) then return false, 'no_permission' end

    local item = normalizeItem(itemData)
    if item.name == '' or not itemExists(item.name) then return false, 'invalid_item' end
    if isBlacklisted(item.name) then return false, 'blacklisted_item' end

    local replaced = false
    for index, existing in ipairs(store.items or {}) do
        if existing.name == item.name then
            store.items[index] = item
            replaced = true
            break
        end
    end

    if not replaced then store.items[#store.items + 1] = item end
    if trim(store.owner) == '' then
        store.stock[item.name] = nil
        daily[store.id] = daily[store.id] or {}
        daily[store.id][item.name] = math.max(0, math.floor(numberValue(item.dailyStock)))
    elseif store.stock[item.name] == nil then
        store.stock[item.name] = 0
    end

    local ok, payload = Service.save(draft, storeId, daily)
    if ok then notify(source, { description = ForgeCore.t('notify.stores.item_saved'), type = 'success' }) end
    return ok, payload
end

function Service.removeItem(source, storeId, itemName)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store then return false, 'store_not_found' end
    if not canManage(source) and not hasStoreAccess(source, store) then return false, 'no_permission' end

    itemName = trim(itemName)
    for index, item in ipairs(store.items or {}) do
        if item.name == itemName then
            table.remove(store.items, index)
            store.stock[itemName] = nil
            if daily[store.id] then daily[store.id][itemName] = nil end
            local ok, payload = Service.save(draft, storeId, daily)
            if ok then notify(source, { description = ForgeCore.t('notify.stores.item_removed'), type = 'success' }) end
            return ok, payload
        end
    end

    return false, 'item_not_found'
end

function Service.getStore(source, storeId)
    local store = storeById(storeId)
    if not store then return false, 'store_not_found' end

    local cid = citizenId(source)
    return true, {
        store = clone(store),
        isOwner = cid ~= '' and store.owner == cid,
        hasAccess = hasStoreAccess(source, store),
        canManage = canManage(source),
    }
end

function Service.openShop(source, storeId)
    local store = storeById(storeId)
    if not store or store.enabled == false then return false, 'store_not_found' end
    if Service.state.settings.enabled ~= true then return false, 'stores_disabled' end
    if store.salesPaused == true then return false, 'sales_paused' end

    local ok, idOrError = registerShop(store)
    if not ok then return false, idOrError end
    return true, idOrError
end

local function storeItem(store, itemName)
    for _, item in ipairs(store.items or {}) do
        if item.name == itemName then return item end
    end
end

local function hasGroupAccess(source, store)
    if type(store.groups) ~= 'table' then return true end
    if pr_lib and pr_lib.framework and pr_lib.framework.PlayerHasJob then
        for group, grade in pairs(store.groups) do
            if pr_lib.framework.PlayerHasJob(source, group, grade) then return true end
        end
    end

    return false
end

function Service.buyItem(source, storeId, itemName, count)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store or store.enabled == false then return false, 'store_not_found' end
    if draft.settings.enabled ~= true then return false, 'stores_disabled' end
    if not hasGroupAccess(source, store) then return false, 'no_permission' end

    itemName = trim(itemName)
    count = math.max(1, math.floor(numberValue(count, 1)))
    local item = storeItem(store, itemName)
    if not item or item.enabled == false then return false, 'item_not_found' end
    if isBlacklisted(itemName) then return false, 'blacklisted_item' end

    local lockKey = ('%s:%s'):format(store.id, itemName)
    if Service.locks[lockKey] then return false, 'busy' end
    Service.locks[lockKey] = true

    local stock = availableStock(store, item, daily)
    if stock < count then
        Service.locks[lockKey] = nil
        return false, 'no_stock'
    end

    if not canCarry(source, itemName, count, item.metadata) then
        Service.locks[lockKey] = nil
        return false, 'cannot_carry'
    end

    local total = math.max(0, math.floor(numberValue(item.price) * count))
    local called, charged, account = pcall(chargePlayer, source, total, 'forge-core:store-purchase', item.currency)
    if not called then
        Service.locks[lockKey] = nil
        return incident(storeId, source, 'charge-unknown', { amount = total, currency = item.currency, item = itemName, count = count })
    end
    if not charged then
        Service.locks[lockKey] = nil
        return false, account
    end

    local addedCall, added = pcall(addItem, source, itemName, count, item.metadata)
    if not addedCall then
        Service.locks[lockKey] = nil
        return incident(storeId, source, 'delivery-unknown', { amount = total, account = account, item = itemName, count = count, metadata = item.metadata })
    end
    if added ~= true then
        local restored = compensate(storeId, source, 'purchase', {
            function() return refundPlayer(source, account, total, 'forge-core:store-refund') end,
        }, { amount = total, account = account, item = itemName, count = count, metadata = item.metadata })
        if not restored then Service.locks[lockKey] = nil; return false, 'reconciliation_required' end
        Service.locks[lockKey] = nil
        return false, 'add_item_failed'
    end

    setAvailableStock(store, item, stock - count, daily)
    if isMoneyCurrency(item.currency) then
        store.balance = math.max(0, math.floor(numberValue(store.balance) + total))
    else
        store.currencyBalances = type(store.currencyBalances) == 'table' and store.currencyBalances or {}
        store.currencyBalances[item.currency] = math.max(0, math.floor(numberValue(store.currencyBalances[item.currency]) + total))
    end

    store.sales[#store.sales + 1] = {
        item = itemName,
        count = count,
        total = total,
        currency = item.currency,
        buyer = citizenId(source),
        at = os.time(),
    }

    while #store.sales > 50 do table.remove(store.sales, 1) end

    local ok, err = Service.save(draft, storeId, daily, true, true)
    Service.locks[lockKey] = nil

    if not ok then
        local restored = compensate(storeId, source, 'purchase', {
            function() return refundPlayer(source, account, total, 'forge-core:store-refund') end,
            function() return removeItem(source, itemName, count, item.metadata) == true end,
        }, { amount = total, account = account, item = itemName, count = count, metadata = item.metadata })
        return false, restored and err or 'reconciliation_required'
    end
    return true, {
        item = itemName,
        label = item.label or itemLabel(itemName),
        count = count,
        total = total,
        stock = availableStock(store, item, daily),
    }
end

function Service.buyStore(source, storeId, account)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store or store.enabled == false then return false, 'store_not_found' end
    if draft.settings.salesEnabled ~= true then return false, 'sales_disabled' end
    if store.owner ~= '' and store.saleListed ~= true then return false, 'already_owned' end

    local cid = citizenId(source)
    if cid == '' then return false, 'invalid_player' end
    if store.owner == cid then return false, 'already_owned' end

    account = trim(account)
    if account ~= 'cash' and account ~= 'bank' and account ~= 'money' then account = 'cash' end
    if account == 'money' then account = 'cash' end

    local called, charged, paidAccount = pcall(chargePlayer, source, store.purchasePrice, 'forge-core:store-buy', account)
    if not called then return incident(storeId, source, 'ownership-charge-unknown', { amount = store.purchasePrice, account = account }) end
    if not charged then return false, paidAccount end

    store.owner = cid
    store.ownerName = playerName(source)
    store.ownerPhone = playerContact(source)
    store.salesPaused = false
    store.saleListed = false
    store.managers = {}
    daily[store.id] = nil
    store.stock = type(store.stock) == 'table' and store.stock or {}
    for _, item in ipairs(store.items or {}) do
        store.stock[item.name] = 0
    end

    local ok, payload = Service.save(draft, storeId, daily, false, true)
    if not ok then
        local restored = compensate(storeId, source, 'ownership', {
            function() return refundPlayer(source, paidAccount, store.purchasePrice, 'forge-core:store-buy-refund') end,
        }, { amount = store.purchasePrice, account = paidAccount })
        if not restored then return false, 'reconciliation_required' end
        return false, payload
    end

    notify(source, { description = ForgeCore.t('notify.stores.store_bought'), type = 'success' })
    return true, payload
end

function Service.transferStore(source, storeId, targetSource)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store then return false, 'store_not_found' end
    if store.owner ~= citizenId(source) then return false, 'no_permission' end

    targetSource = tonumber(targetSource)
    if not targetSource or targetSource <= 0 then return false, 'invalid_player' end

    local cid = citizenId(targetSource)
    if cid == '' then return false, 'invalid_player' end

    store.owner = cid
    store.ownerName = playerName(targetSource)
    store.ownerPhone = playerContact(targetSource)
    store.saleListed = false
    store.managers = {}

    local ok, payload = Service.save(draft, storeId, daily)
    return ok, payload
end

function Service.addManager(source, storeId, targetSource)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store then return false, 'store_not_found' end
    if store.owner ~= citizenId(source) then return false, 'no_permission' end

    targetSource = tonumber(targetSource)
    if not targetSource or targetSource <= 0 then return false, 'invalid_player' end

    local cid = citizenId(targetSource)
    if cid == '' or cid == store.owner then return false, 'invalid_player' end

    store.managers = type(store.managers) == 'table' and store.managers or {}
    for _, manager in ipairs(store.managers) do
        if type(manager) == 'table' and manager.citizenid == cid then return false, 'already_manager' end
        if type(manager) == 'string' and manager == cid then return false, 'already_manager' end
    end

    store.managers[#store.managers + 1] = {
        citizenid = cid,
        name = playerName(targetSource),
        phone = playerContact(targetSource),
    }

    local ok, payload = Service.save(draft, storeId, daily)
    return ok, payload
end

function Service.removeManager(source, storeId, citizenid)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store then return false, 'store_not_found' end
    if store.owner ~= citizenId(source) then return false, 'no_permission' end

    citizenid = trim(citizenid)
    store.managers = type(store.managers) == 'table' and store.managers or {}
    for index, manager in ipairs(store.managers) do
        local managerId = type(manager) == 'table' and manager.citizenid or manager
        if managerId == citizenid then
            table.remove(store.managers, index)
            local ok, payload = Service.save(draft, storeId, daily)
            return ok, payload
        end
    end

    return false, 'manager_not_found'
end

function Service.withdraw(source, storeId)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store then return false, 'store_not_found' end
    if store.owner ~= citizenId(source) then return false, 'no_permission' end

    local amount = math.max(0, math.floor(numberValue(store.balance)))
    if amount <= 0 then return false, 'no_balance' end

    local framework = pr_lib and pr_lib.framework
    if not framework or not framework.addPlayerMoney or not framework.removePlayerMoney then return false, 'money_unavailable' end
    local called, credited = pcall(framework.addPlayerMoney, source, 'cash', amount, 'forge-core:store-withdraw')
    if not called then return incident(storeId, source, 'withdraw-credit-unknown', { amount = amount, account = 'cash' }) end
    if credited ~= true then return false, 'credit_failed' end
    store.balance = 0
    local ok, payload = Service.save(draft, storeId, daily, false, true)
    if not ok then
        local restored = compensate(storeId, source, 'withdraw', {
            function() return framework.removePlayerMoney(source, 'cash', amount, 'forge-core:store-withdraw-rollback') == true end,
        }, { amount = amount, account = 'cash' })
        return false, restored and payload or 'reconciliation_required'
    end

    return true, amount
end

function Service.getPlayerItems(source)
    local items = {}
    local seen = {}
    local inventory = pr_lib and pr_lib.inventory
    local list = inventory and inventory.GetPlayerInventory and inventory.GetPlayerInventory(source) or {}

    for _, item in pairs(type(list) == 'table' and list or {}) do
        local name = item and item.name
        local count = tonumber(item and (item.count or item.amount)) or 0
        if name and count > 0 and not seen[name] then
            seen[name] = true
            items[#items + 1] = {
                name = name,
                label = itemLabel(name),
                count = count,
            }
        end
    end

    table.sort(items, function(left, right) return tostring(left.label) < tostring(right.label) end)
    return true, items
end

function Service.addStockFromPlayer(source, storeId, itemName, count, price)
    storeId = normalizeId(storeId)
    if Service.incidents[tostring(storeId)] then return false, 'reconciliation_required' end
    local draft, daily = storeDraft(storeId)
    local store = storeById(storeId, draft)
    if not store then return false, 'store_not_found' end
    if not canManage(source) and not hasStoreAccess(source, store) then return false, 'no_permission' end

    itemName = trim(itemName)
    count = math.max(1, math.floor(numberValue(count, 1)))
    price = math.max(0, math.floor(numberValue(price, 0)))
    if itemName == '' or not itemExists(itemName) then return false, 'invalid_item' end
    if isBlacklisted(itemName) then return false, 'blacklisted_item' end
    if itemCount(source, itemName) < count then return false, 'not_enough_items' end
    -- Preserve slot metadata when restoring a rejected stock deposit.
    local removed, remaining = {}, count
    local inventory = pr_lib.inventory
    for _, slot in pairs(inventory.GetPlayerInventory(source) or {}) do
        if slot.name == itemName and remaining > 0 then
            local amount = math.min(remaining, tonumber(slot.count or slot.amount) or 0)
            if amount > 0 then
                local called, removedItem = pcall(removeItem, source, itemName, amount, slot.metadata or slot.info, slot.slot)
                if not called then
                    return incident(storeId, source, 'stock-removal-unknown', { item = itemName, count = amount,
                        metadata = slot.metadata or slot.info, slot = slot.slot, previousRemoved = removed })
                end
                if removedItem ~= true then break end
                removed[#removed + 1] = { count = amount, metadata = slot.metadata or slot.info }
                remaining = remaining - amount
            end
        end
    end
    local function restoreItems()
        local actions = {}
        for _, slot in ipairs(removed) do
            actions[#actions + 1] = function() return addItem(source, itemName, slot.count, slot.metadata) == true end
        end
        return compensate(storeId, source, 'stock-deposit', actions, { item = itemName, removed = removed })
    end
    if remaining > 0 then
        local restored = restoreItems()
        return false, restored and 'remove_item_failed' or 'reconciliation_required'
    end

    local item = storeItem(store, itemName)
    if item then
        item.price = price
        item.label = item.label ~= '' and item.label or itemLabel(itemName)
    else
        store.items[#store.items + 1] = normalizeItem({
            name = itemName,
            label = itemLabel(itemName),
            price = price,
            dailyStock = 0,
        })
    end

    store.stock[itemName] = math.max(0, math.floor(numberValue(store.stock[itemName]) + count))

    local ok, payload = Service.save(draft, storeId, daily)
    if not ok and not restoreItems() then return false, 'reconciliation_required' end
    if ok then notify(source, { description = ForgeCore.t('notify.stores.stock_added'), type = 'success' }) end
    return ok, payload
end

pr_lib.wrapJsonMutations(PR.Stores.Storage.file, Service, {
    'saveSettings', 'createStore', 'updateStore', 'updateOwnerStore', 'deleteStore', 'setItem', 'removeItem', 'buyItem', 'buyStore', 'transferStore', 'addManager', 'removeManager', 'withdraw', 'addStockFromPlayer',
})

ForgeCore.StoresService = Service
