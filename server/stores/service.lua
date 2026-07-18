ForgeCore = ForgeCore or {}

local Service = {
    state = {},
    locks = {},
    shops = {},
    purchaseHookId = nil,
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
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('stores.title'),
        description = data.description,
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

local function removeItem(source, name, count)
    if pr_lib and pr_lib.inventory and pr_lib.inventory.RemoveItem then
        return pr_lib.inventory.RemoveItem(source, name, count)
    end

    if GetResourceState('ox_inventory'):find('start') ~= nil then
        return exports.ox_inventory:RemoveItem(source, name, count)
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
            if removed ~= false then return true, account end
        end
    end

    return false, 'not_enough_money'
end

local function refundPlayer(source, account, amount, reason)
    amount = math.floor(numberValue(amount))
    if amount <= 0 or account == 'free' then return end

    account = tostring(account or '')
    if account:sub(1, 5) == 'item:' then
        addItem(source, account:sub(6), amount)
        return
    end

    local framework = pr_lib and pr_lib.framework
    if framework and framework.addPlayerMoney then
        framework.addPlayerMoney(source, account, amount, reason)
    end
end

local function normalizeItem(item)
    item = type(item) == 'table' and item or {}
    local name = trim(item.name)

    return {
        name = name,
        label = trim(item.label) ~= '' and trim(item.label) or itemLabel(name),
        price = math.max(0, math.floor(numberValue(item.price))),
        dailyStock = math.max(0, math.floor(numberValue(item.dailyStock or item.daily or item.count, PR.Stores.Defaults.defaultDailyStock))),
        metadata = type(item.metadata) == 'table' and item.metadata or nil,
        currency = trim(item.currency) ~= '' and trim(item.currency) or 'money',
        grade = item.grade,
        enabled = boolValue(item.enabled, true),
    }
end

local function normalizeStore(store)
    store = type(store) == 'table' and store or {}
    local id = normalizeId(store.id ~= nil and store.id or store.label)

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
        coords = normalizeVector(store.coords or store.shopcoords),
        rotation = numberValue(store.rotation or store.heading),
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
            normalized.stock[item.name] = math.max(0, math.floor(numberValue(normalized.stock[item.name], item.dailyStock)))
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

local function buildShopInventory(store)
    local inventory = {}
    for _, item in ipairs(store.items or {}) do
        local stock = math.max(0, math.floor(numberValue(store.stock and store.stock[item.name])))
        if item.enabled ~= false and stock > 0 and not isBlacklisted(item.name) and itemExists(item.name) then
            inventory[#inventory + 1] = {
                name = item.name,
                price = math.max(0, math.floor(numberValue(item.price))),
                count = stock,
                metadata = item.metadata,
                currency = item.currency ~= 'money' and item.currency or nil,
                grade = item.grade,
            }
        else
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

local function handleShopPurchase(success, payload)
    if success ~= true or type(payload) ~= 'table' then return end

    local storeId = Service.shops[tostring(payload.shopType or '')]
    if not storeId then return end

    local store = storeById(storeId)
    if not store then return end

    local name = trim(payload.itemName or itemName(payload.fromSlot))
    local count = math.max(0, math.floor(numberValue(payload.count)))
    local total = math.max(0, math.floor(numberValue(payload.totalPrice, numberValue(payload.price) * count)))
    if name == '' or count <= 0 then return end

    store.stock = type(store.stock) == 'table' and store.stock or {}
    local previousStock = math.max(0, math.floor(numberValue(store.stock[name])))
    store.stock[name] = math.max(previousStock - count, 0)

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
    local saved = Service.save()
    registerShop(store)
    logStore(saved and 'info' or 'error', ('ox purchase store=%s item=%s count=%s stock=%s->%s total=%s'):format(
        tostring(store.id),
        name,
        tostring(count),
        tostring(previousStock),
        tostring(store.stock[name]),
        tostring(total)
    ))
end

local function registerPurchaseHook()
    if Service.purchaseHookId or not pr_lib.inventory or not pr_lib.inventory.RegisterHook then return end

    Service.purchaseHookId = pr_lib.inventory.RegisterHook('buyItem', function()
        return nil
    end)

    if Service.purchaseHookId then
        AddEventHandler(Service.purchaseHookId, handleShopPurchase)
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
    local loaded = pr_lib.loadJson(PR.Stores.Storage.file, true)
    if type(loaded) == 'table' then return loaded end
    return nil
end

local function writeState(state)
    local saved = pr_lib.saveJson(PR.Stores.Storage.file, state, { indent = true })
    return saved == true or type(saved) == 'table'
end

function storeById(storeId)
    storeId = normalizeId(storeId)
    for index, store in ipairs(Service.state.stores or {}) do
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

local function restockDaily()
    local settings = Service.state.settings
    if settings.dailyStockEnabled ~= true then return false end

    local today = todayKey()
    if settings.lastRestock == today then return false end

    for _, store in ipairs(Service.state.stores or {}) do
        if store.owner == '' then
            for _, item in ipairs(store.items or {}) do
                store.stock[item.name] = math.max(0, math.floor(numberValue(item.dailyStock, settings.defaultDailyStock)))
            end
        end
    end

    settings.lastRestock = today
    return true
end

local function publish()
    GlobalState.forgeStores = {
        settings = Service.state.settings,
        stores = Service.state.stores or {},
        revision = Service.state.revision or GetGameTimer(),
    }
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
        if store.enabled ~= false then
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
    if restockDaily() then writeState(Service.state) end
    registerAllShops()
    publish()
    return Service.getAll()
end

function Service.save()
    Service.state.revision = GetGameTimer()
    if not writeState(Service.state) then return false, 'save_failed' end
    registerAllShops()
    publish()
    return true, Service.getAll()
end

function Service.start()
    Service.load()
    logStore('info', ForgeCore.t('debug.stores.started'))
end

function Service.saveSettings(source, settings)
    if not canManage(source) then return false, 'no_permission' end

    settings = normalizeSettings(settings)
    Service.state.settings.enabled = settings.enabled
    Service.state.settings.salesEnabled = settings.salesEnabled
    Service.state.settings.dailyStockEnabled = settings.dailyStockEnabled
    Service.state.settings.defaultDailyStock = settings.defaultDailyStock
    Service.state.settings.blacklist = settings.blacklist

    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.stores.settings_saved'), type = 'success' }) end
    return ok, payload
end

function Service.createStore(source, data)
    if not canManage(source) then return false, 'no_permission' end

    data = type(data) == 'table' and data or {}
    local label = trim(data.label)
    if label == '' then return false, 'invalid_label' end

    data.id = normalizeId(data.id ~= nil and data.id or label)
    if data.id == '' then return false, 'invalid_id' end
    if storeById(data.id) then return false, 'duplicate_store' end

    local store = normalizeStore(data)
    Service.state.stores[#Service.state.stores + 1] = store

    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.stores.store_saved'), type = 'success' }) end
    return ok, payload
end

function Service.updateStore(source, storeId, changes)
    if not canManage(source) then return false, 'no_permission' end

    local store = storeById(storeId)
    if not store then return false, 'store_not_found' end

    changes = type(changes) == 'table' and changes or {}
    if changes.label ~= nil then store.label = trim(changes.label) end
    if changes.enabled ~= nil then store.enabled = boolValue(changes.enabled, store.enabled) end
    if changes.purchasePrice ~= nil or changes.price ~= nil then store.purchasePrice = math.max(0, math.floor(numberValue(changes.purchasePrice or changes.price))) end
    if changes.saleListed ~= nil then store.saleListed = boolValue(changes.saleListed, store.saleListed) end
    if changes.targetLabel ~= nil then store.targetLabel = trim(changes.targetLabel) end
    if changes.coords ~= nil then store.coords = normalizeVector(changes.coords) end
    if changes.rotation ~= nil or changes.heading ~= nil then store.rotation = numberValue(changes.rotation or changes.heading) end
    if changes.blip ~= nil then store.blip = type(changes.blip) == 'table' and changes.blip or nil end

    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.stores.store_saved'), type = 'success' }) end
    return ok, payload
end

function Service.updateOwnerStore(source, storeId, changes)
    local store = storeById(storeId)
    if not store then return false, 'store_not_found' end
    if store.owner ~= citizenId(source) then return false, 'no_permission' end

    changes = type(changes) == 'table' and changes or {}
    if changes.salesPaused ~= nil then store.salesPaused = boolValue(changes.salesPaused, store.salesPaused) end
    if changes.saleListed ~= nil then store.saleListed = boolValue(changes.saleListed, store.saleListed) end
    if changes.purchasePrice ~= nil or changes.price ~= nil then store.purchasePrice = math.max(0, math.floor(numberValue(changes.purchasePrice or changes.price))) end

    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.stores.store_saved'), type = 'success' }) end
    return ok, payload
end

function Service.deleteStore(source, storeId)
    if not canManage(source) then return false, 'no_permission' end

    local _, index = storeById(storeId)
    if not index then return false, 'store_not_found' end

    table.remove(Service.state.stores, index)
    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.stores.store_deleted'), type = 'success' }) end
    return ok, payload
end

function Service.setItem(source, storeId, itemData)
    local store = storeById(storeId)
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
    store.stock[item.name] = math.max(0, math.floor(numberValue(itemData and itemData.stock, store.stock[item.name] or item.dailyStock)))

    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.stores.item_saved'), type = 'success' }) end
    return ok, payload
end

function Service.removeItem(source, storeId, itemName)
    local store = storeById(storeId)
    if not store then return false, 'store_not_found' end
    if not canManage(source) and not hasStoreAccess(source, store) then return false, 'no_permission' end

    itemName = trim(itemName)
    for index, item in ipairs(store.items or {}) do
        if item.name == itemName then
            table.remove(store.items, index)
            store.stock[itemName] = nil
            local ok, payload = Service.save()
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
    local store = storeById(storeId)
    if not store or store.enabled == false then return false, 'store_not_found' end
    if Service.state.settings.enabled ~= true then return false, 'stores_disabled' end
    if not hasGroupAccess(source, store) then return false, 'no_permission' end

    itemName = trim(itemName)
    count = math.max(1, math.floor(numberValue(count, 1)))
    local item = storeItem(store, itemName)
    if not item or item.enabled == false then return false, 'item_not_found' end
    if isBlacklisted(itemName) then return false, 'blacklisted_item' end

    local lockKey = ('%s:%s'):format(store.id, itemName)
    if Service.locks[lockKey] then return false, 'busy' end
    Service.locks[lockKey] = true

    local stock = math.max(0, math.floor(numberValue(store.stock[itemName])))
    if stock < count then
        Service.locks[lockKey] = nil
        return false, 'no_stock'
    end

    if not canCarry(source, itemName, count, item.metadata) then
        Service.locks[lockKey] = nil
        return false, 'cannot_carry'
    end

    local total = math.max(0, math.floor(numberValue(item.price) * count))
    local charged, account = chargePlayer(source, total, 'forge-core:store-purchase', item.currency)
    if not charged then
        Service.locks[lockKey] = nil
        return false, account
    end

    if not addItem(source, itemName, count, item.metadata) then
        refundPlayer(source, account, total, 'forge-core:store-refund')
        Service.locks[lockKey] = nil
        return false, 'add_item_failed'
    end

    store.stock[itemName] = stock - count
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

    local ok, err = Service.save()
    Service.locks[lockKey] = nil

    if not ok then return false, err end
    return true, {
        item = itemName,
        label = item.label or itemLabel(itemName),
        count = count,
        total = total,
        stock = store.stock[itemName],
    }
end

function Service.buyStore(source, storeId, account)
    local store = storeById(storeId)
    if not store or store.enabled == false then return false, 'store_not_found' end
    if Service.state.settings.salesEnabled ~= true then return false, 'sales_disabled' end
    if store.owner ~= '' and store.saleListed ~= true then return false, 'already_owned' end

    local cid = citizenId(source)
    if cid == '' then return false, 'invalid_player' end
    if store.owner == cid then return false, 'already_owned' end

    account = trim(account)
    if account ~= 'cash' and account ~= 'bank' and account ~= 'money' then account = 'cash' end
    if account == 'money' then account = 'cash' end

    local charged, paidAccount = chargePlayer(source, store.purchasePrice, 'forge-core:store-buy', account)
    if not charged then return false, paidAccount end

    store.owner = cid
    store.ownerName = playerName(source)
    store.ownerPhone = playerContact(source)
    store.saleListed = false
    store.managers = {}

    local ok, payload = Service.save()
    if not ok then
        refundPlayer(source, paidAccount, store.purchasePrice, 'forge-core:store-buy-refund')
        return false, payload
    end

    notify(source, { description = ForgeCore.t('notify.stores.store_bought'), type = 'success' })
    return true, payload
end

function Service.transferStore(source, storeId, targetSource)
    local store = storeById(storeId)
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

    local ok, payload = Service.save()
    return ok, payload
end

function Service.addManager(source, storeId, targetSource)
    local store = storeById(storeId)
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

    local ok, payload = Service.save()
    return ok, payload
end

function Service.removeManager(source, storeId, citizenid)
    local store = storeById(storeId)
    if not store then return false, 'store_not_found' end
    if store.owner ~= citizenId(source) then return false, 'no_permission' end

    citizenid = trim(citizenid)
    store.managers = type(store.managers) == 'table' and store.managers or {}
    for index, manager in ipairs(store.managers) do
        local managerId = type(manager) == 'table' and manager.citizenid or manager
        if managerId == citizenid then
            table.remove(store.managers, index)
            local ok, payload = Service.save()
            return ok, payload
        end
    end

    return false, 'manager_not_found'
end

function Service.withdraw(source, storeId)
    local store = storeById(storeId)
    if not store then return false, 'store_not_found' end
    if store.owner ~= citizenId(source) then return false, 'no_permission' end

    local amount = math.max(0, math.floor(numberValue(store.balance)))
    if amount <= 0 then return false, 'no_balance' end

    store.balance = 0
    local ok, payload = Service.save()
    if not ok then return false, payload end

    if pr_lib and pr_lib.framework and pr_lib.framework.addPlayerMoney then
        pr_lib.framework.addPlayerMoney(source, 'cash', amount, 'forge-core:store-withdraw')
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
    local store = storeById(storeId)
    if not store then return false, 'store_not_found' end
    if not canManage(source) and not hasStoreAccess(source, store) then return false, 'no_permission' end

    itemName = trim(itemName)
    count = math.max(1, math.floor(numberValue(count, 1)))
    price = math.max(0, math.floor(numberValue(price, 0)))
    if itemName == '' or not itemExists(itemName) then return false, 'invalid_item' end
    if isBlacklisted(itemName) then return false, 'blacklisted_item' end
    if itemCount(source, itemName) < count then return false, 'not_enough_items' end
    if not removeItem(source, itemName, count) then return false, 'remove_item_failed' end

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

    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.stores.stock_added'), type = 'success' }) end
    return ok, payload
end

ForgeCore.StoresService = Service
