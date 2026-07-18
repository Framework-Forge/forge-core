ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local alertDialog = Shared.alertDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local boolValue = Shared.boolValue
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions

local function notify(data)
    Shared.notify({
        title = data.title or t('stores.title'),
        description = data.description,
        type = data.type,
    })
end

local function fetchPayload()
    local ok, payload = awaitServer(PR.Stores.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.stores.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.settings = type(payload.settings) == 'table' and payload.settings or {}
    payload.stores = type(payload.stores) == 'table' and payload.stores or {}
    return payload
end

local function fetchStore(storeId)
    local ok, payload = awaitServer(PR.Stores.Callbacks.getStore, storeId)
    if not ok then
        notifyFailure('notify.stores.load_failed', payload)
        return nil
    end

    return type(payload) == 'table' and payload or nil
end

local function playerCoords()
    local coords = GetEntityCoords(PlayerPedId())
    return {
        x = tonumber(('%0.3f'):format(coords.x)),
        y = tonumber(('%0.3f'):format(coords.y)),
        z = tonumber(('%0.3f'):format(coords.z)),
    }
end

local function heading()
    return tonumber(('%0.2f'):format(GetEntityHeading(PlayerPedId())))
end

local function teleportToStore(store)
    local coords = type(store.coords) == 'table' and store.coords or {}
    local ped = PlayerPedId()
    SetEntityCoords(ped, tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0, false, false, false, false)
    SetEntityHeading(ped, tonumber(store.rotation) or GetEntityHeading(ped))
end

local function stockOf(store, itemName)
    return tonumber(type(store.stock) == 'table' and store.stock[itemName]) or 0
end

local function storeDescription(store)
    return t('menu.stores.store_description', {
        status = store.enabled == false and t('common.inactive') or t('common.active'),
        owner = store.ownerName ~= '' and store.ownerName or t('menu.stores.no_owner'),
        items = tostring(#(store.items or {})),
    })
end

local function blacklistToText(blacklist)
    local items = {}
    for item, enabled in pairs(type(blacklist) == 'table' and blacklist or {}) do
        if enabled == true then items[#items + 1] = item end
    end

    table.sort(items)
    return table.concat(items, ', ')
end

function Menu.openStoresAdminMenu()
    local payload = fetchPayload()
    if not payload then return end

    local settings = payload.settings
    local options = {
        {
            title = t('menu.stores.settings'),
            description = t('menu.stores.settings_description', {
                status = settings.enabled == false and t('common.inactive') or t('common.active'),
                sales = settings.salesEnabled == false and t('common.inactive') or t('common.active'),
            }),
            icon = 'sliders',
            onSelect = function()
                Menu.openStoresSettings(settings)
            end,
        },
        {
            title = t('menu.stores.blacklist'),
            description = blacklistToText(settings.blacklist) ~= '' and blacklistToText(settings.blacklist) or t('common.none'),
            icon = 'ban',
            onSelect = function()
                Menu.openStoresBlacklist(settings)
            end,
        },
        {
            title = t('menu.stores.create_store'),
            description = t('menu.stores.create_store_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openStoreCreate()
            end,
        },
    }

    for _, store in ipairs(payload.stores) do
        options[#options + 1] = {
            title = store.label,
            description = storeDescription(store),
            icon = store.owner ~= '' and 'store' or 'store-slash',
            onSelect = function()
                Menu.openStoreAdmin(store.id)
            end,
        }
    end

    showContext({
        id = 'forge_core_stores_admin',
        title = t('menu.stores.title'),
        menu = 'forge_core_server_settings',
        options = options,
    })
end

function Menu.openStoresSettings(settings)
    settings = type(settings) == 'table' and settings or {}
    local result = inputDialog(t('menu.stores.settings'), {
        {
            type = 'select',
            label = t('inputs.stores_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled ~= false),
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.stores_sales_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.salesEnabled ~= false),
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.stores_daily_stock_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.dailyStockEnabled ~= false),
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.stores_default_daily_stock'),
            default = tonumber(settings.defaultDailyStock) or PR.Stores.Defaults.defaultDailyStock,
            min = 0,
            required = true,
        },
    })

    if not result then return Menu.openStoresAdminMenu() end

    local ok, response = awaitServer(PR.Stores.Callbacks.saveSettings, {
        enabled = boolValue(result[1]),
        salesEnabled = boolValue(result[2]),
        dailyStockEnabled = boolValue(result[3]),
        defaultDailyStock = tonumber(result[4]) or PR.Stores.Defaults.defaultDailyStock,
        blacklist = settings.blacklist or {},
    })

    if not ok then notifyFailure('notify.stores.save_failed', response) end
    SetTimeout(400, Menu.openStoresAdminMenu)
end

function Menu.openStoresBlacklist(settings)
    settings = type(settings) == 'table' and settings or {}
    local result = inputDialog(t('menu.stores.blacklist'), {
        {
            type = 'textarea',
            label = t('inputs.stores_blacklist'),
            default = blacklistToText(settings.blacklist),
        },
    })

    if not result then return Menu.openStoresAdminMenu() end

    local blacklist = {}
    for item in tostring(result[1] or ''):gmatch('[^,%s]+') do
        blacklist[item] = true
    end

    local ok, response = awaitServer(PR.Stores.Callbacks.saveSettings, {
        enabled = settings.enabled ~= false,
        salesEnabled = settings.salesEnabled ~= false,
        dailyStockEnabled = settings.dailyStockEnabled ~= false,
        defaultDailyStock = tonumber(settings.defaultDailyStock) or PR.Stores.Defaults.defaultDailyStock,
        blacklist = blacklist,
    })

    if not ok then notifyFailure('notify.stores.save_failed', response) end
    SetTimeout(400, Menu.openStoresAdminMenu)
end

function Menu.openStoreCreate()
    local result = inputDialog(t('menu.stores.create_store'), {
        { type = 'input', label = t('inputs.store_label'), required = true },
        { type = 'number', label = t('inputs.store_purchase_price'), min = 0, default = 0, required = true },
        { type = 'select', label = t('inputs.store_enabled'), options = boolOptions(), default = 'true', required = true },
        { type = 'input', label = t('inputs.store_target_label'), default = '' },
    })

    if not result then return Menu.openStoresAdminMenu() end

    local ok, response = awaitServer(PR.Stores.Callbacks.createStore, {
        label = tostring(result[1] or ''),
        purchasePrice = tonumber(result[2]) or 0,
        enabled = boolValue(result[3]),
        targetLabel = tostring(result[4] or ''),
        coords = playerCoords(),
        rotation = heading(),
        blip = { enabled = true, sprite = 59, color = 69, scale = 0.8 },
    })

    if not ok then notifyFailure('notify.stores.save_failed', response) end
    SetTimeout(400, Menu.openStoresAdminMenu)
end

function Menu.openStoreAdmin(storeId)
    local payload = fetchStore(storeId)
    if not payload then return end

    local store = payload.store
    showContext({
        id = ('forge_core_store_admin_%s'):format(store.id),
        title = store.label,
        menu = 'forge_core_stores_admin',
        options = {
            {
                title = t('menu.stores.edit_store'),
                description = storeDescription(store),
                icon = 'pen-to-square',
                onSelect = function()
                    Menu.openStoreEdit(store)
                end,
            },
            {
                title = t('menu.stores.set_coords'),
                description = t('menu.stores.set_coords_description'),
                icon = 'location-crosshairs',
                onSelect = function()
                    local ok, response = awaitServer(PR.Stores.Callbacks.updateStore, store.id, {
                        coords = playerCoords(),
                        rotation = heading(),
                    })
                    if not ok then notifyFailure('notify.stores.save_failed', response) end
                    SetTimeout(400, function() Menu.openStoreAdmin(store.id) end)
                end,
            },
            {
                title = t('menu.stores.teleport_store'),
                icon = 'location-dot',
                onSelect = function()
                    teleportToStore(store)
                    Menu.openStoreAdmin(store.id)
                end,
            },
            {
                title = t('menu.stores.products'),
                description = t('menu.stores.products_description', { count = tostring(#(store.items or {})) }),
                icon = 'boxes-stacked',
                onSelect = function()
                    Menu.openStoreProducts(store.id)
                end,
            },
            {
                title = t('menu.stores.open_storefront'),
                icon = 'cart-shopping',
                onSelect = function()
                    Menu.openStorefront(store.id)
                end,
            },
            {
                title = t('menu.stores.delete_store'),
                icon = 'trash',
                iconColor = '#ef4444',
                onSelect = function()
                    local confirmed = not alertDialog or alertDialog({
                        header = t('menu.stores.delete_store'),
                        content = t('dialogs.remove_store_content', { store = store.label }),
                        centered = true,
                        cancel = true,
                    }) == 'confirm'
                    if not confirmed then return Menu.openStoreAdmin(store.id) end

                    local ok, response = awaitServer(PR.Stores.Callbacks.deleteStore, store.id)
                    if not ok then notifyFailure('notify.stores.delete_failed', response) end
                    SetTimeout(400, Menu.openStoresAdminMenu)
                end,
            },
        },
    })
end

function Menu.openStoreEdit(store)
    local result = inputDialog(t('menu.stores.edit_store'), {
        { type = 'input', label = t('inputs.store_label'), default = store.label, required = true },
        { type = 'number', label = t('inputs.store_purchase_price'), min = 0, default = tonumber(store.purchasePrice) or 0, required = true },
        { type = 'select', label = t('inputs.store_enabled'), options = boolOptions(), default = boolDefault(store.enabled ~= false), required = true },
        { type = 'select', label = t('inputs.store_sale_listed'), options = boolOptions(), default = boolDefault(store.saleListed == true), required = true },
        { type = 'input', label = t('inputs.store_target_label'), default = store.targetLabel or '' },
    })

    if not result then return Menu.openStoreAdmin(store.id) end

    local ok, response = awaitServer(PR.Stores.Callbacks.updateStore, store.id, {
        label = tostring(result[1] or ''),
        purchasePrice = tonumber(result[2]) or 0,
        enabled = boolValue(result[3]),
        saleListed = boolValue(result[4]),
        targetLabel = tostring(result[5] or ''),
    })

    if not ok then notifyFailure('notify.stores.save_failed', response) end
    SetTimeout(400, function() Menu.openStoreAdmin(store.id) end)
end

function Menu.openStoreProducts(storeId)
    local payload = fetchStore(storeId)
    if not payload then return end

    local store = payload.store
    local options = {
        {
            title = t('menu.stores.add_product'),
            description = t('menu.stores.add_product_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openStoreProductEditor(store.id)
            end,
        },
    }

    for _, item in ipairs(store.items or {}) do
        local editableItem = Shared.clone(item)
        editableItem.currentStock = stockOf(store, item.name)

        options[#options + 1] = {
            title = item.label or item.name,
            description = t('menu.stores.product_description', {
                item = item.name,
                price = tostring(item.price or 0),
                stock = tostring(stockOf(store, item.name)),
                daily = tostring(item.dailyStock or 0),
            }),
            icon = 'box',
            onSelect = function()
                Menu.openStoreProductActions(store.id, editableItem)
            end,
        }
    end

    showContext({
        id = ('forge_core_store_products_%s'):format(store.id),
        title = t('menu.stores.products'),
        menu = ('forge_core_store_admin_%s'):format(store.id),
        options = options,
    })
end

function Menu.openStoreProductActions(storeId, item)
    item = type(item) == 'table' and item or {}

    showContext({
        id = ('forge_core_store_product_actions_%s_%s'):format(storeId, item.name or 'item'),
        title = item.label or item.name or t('menu.stores.products'),
        menu = ('forge_core_store_products_%s'):format(storeId),
        options = {
            {
                title = t('menu.stores.edit_product'),
                icon = 'pen-to-square',
                onSelect = function()
                    Menu.openStoreProductEditor(storeId, item)
                end,
            },
            {
                title = t('menu.stores.remove_product'),
                icon = 'trash',
                iconColor = '#ef4444',
                onSelect = function()
                    local ok, response = awaitServer(PR.Stores.Callbacks.removeItem, storeId, item.name)
                    if not ok then notifyFailure('notify.stores.item_remove_failed', response) end
                    SetTimeout(400, function() Menu.openStoreProducts(storeId) end)
                end,
            },
        },
    })
end

function Menu.openStoreProductEditor(storeId, item)
    item = type(item) == 'table' and item or {}
    local result = inputDialog(t('menu.stores.product_editor'), {
        { type = 'input', label = t('inputs.store_item_name'), default = item.name or '', required = true },
        { type = 'input', label = t('inputs.store_item_label'), default = item.label or '' },
        { type = 'number', label = t('inputs.store_item_price'), min = 0, default = tonumber(item.price) or 0, required = true },
        { type = 'number', label = t('inputs.store_item_stock'), min = 0, default = tonumber(item.stock or item.currentStock) or 0, required = true },
        { type = 'number', label = t('inputs.store_item_daily_stock'), min = 0, default = tonumber(item.dailyStock) or 0, required = true },
        { type = 'select', label = t('inputs.store_item_enabled'), options = boolOptions(), default = boolDefault(item.enabled ~= false), required = true },
    })

    if not result then return Menu.openStoreProducts(storeId) end

    local ok, response = awaitServer(PR.Stores.Callbacks.setItem, storeId, {
        name = tostring(result[1] or ''),
        label = tostring(result[2] or ''),
        price = tonumber(result[3]) or 0,
        stock = tonumber(result[4]) or 0,
        dailyStock = tonumber(result[5]) or 0,
        enabled = boolValue(result[6]),
    })

    if not ok then notifyFailure('notify.stores.item_save_failed', response) end
    SetTimeout(400, function() Menu.openStoreProducts(storeId) end)
end

function Menu.openStoreInventory(storeId)
    local ok, response = awaitServer(PR.Stores.Callbacks.openShop, storeId)
    if not ok then
        notifyFailure('notify.stores.open_failed', response)
        return false
    end

    if pr_lib and pr_lib.inventory and pr_lib.inventory.openInventory then
        pr_lib.inventory.openInventory('shop', { type = response })
        return true
    end

    notifyFailure('notify.stores.open_failed', 'inventory_unavailable')
    return false
end

function Menu.openStorefront(storeId)
    local payload = fetchStore(storeId)
    if not payload then return end

    local store = payload.store
    local options = {}

    if not payload.hasAccess and store.owner ~= '' and store.saleListed ~= true then
        Menu.openStoreInventory(store.id)
        return
    end

    if payload.hasAccess then
        options[#options + 1] = {
            title = t('menu.stores.owner_manage'),
            description = t('menu.stores.owner_manage_description', { balance = tostring(store.balance or 0) }),
            icon = 'crown',
            onSelect = function()
                Menu.openStoreOwnerMenu(store.id)
            end,
        }
    end

    if store.owner == '' or store.saleListed == true then
        options[#options + 1] = {
            title = t('menu.stores.buy_store', { price = tostring(store.purchasePrice or 0) }),
            description = t('menu.stores.buy_store_description'),
            icon = 'store',
            onSelect = function()
                Menu.openStoreBuyStore(store.id)
            end,
        }
    end

    options[#options + 1] = {
        title = t('menu.stores.open_inventory_store'),
        description = t('menu.stores.open_inventory_store_description'),
        icon = 'cart-shopping',
        onSelect = function()
            Menu.openStoreInventory(store.id)
        end,
    }

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.stores.no_products'),
            icon = 'box-open',
            disabled = true,
        }
    end

    showContext({
        id = ('forge_core_storefront_%s'):format(store.id),
        title = store.label,
        options = options,
    })
end

function Menu.openStoreBuyStore(storeId)
    local payload = fetchStore(storeId)
    if not payload then return end

    local store = payload.store
    local result = inputDialog(t('menu.stores.buy_store', { price = tostring(store.purchasePrice or 0) }), {
        {
            type = 'select',
            label = t('inputs.store_payment_account'),
            options = {
                { value = 'cash', label = t('menu.stores.pay_cash') },
                { value = 'bank', label = t('menu.stores.pay_bank') },
            },
            default = 'cash',
            required = true,
        },
    })

    if not result then return Menu.openStorefront(storeId) end

    local ok, response = awaitServer(PR.Stores.Callbacks.buyStore, store.id, tostring(result[1] or 'cash'))
    notify({
        description = ok and t('notify.stores.store_bought') or t('notify.stores.buy_store_failed', { error = tostring(response or 'unknown') }),
        type = ok and 'success' or 'error',
    })
    SetTimeout(400, function() Menu.openStorefront(store.id) end)
end

function Menu.openStoreBuyItem(storeId, item)
    local result = inputDialog(item.label or item.name, {
        { type = 'number', label = t('inputs.store_buy_amount'), min = 1, default = 1, required = true },
    })

    if not result then return Menu.openStorefront(storeId) end

    local ok, response = awaitServer(PR.Stores.Callbacks.buyItem, storeId, item.name, tonumber(result[1]) or 1)
    notify({
        description = ok and t('notify.stores.item_bought', {
            count = tostring(response.count or 1),
            item = response.label or item.label or item.name,
            total = tostring(response.total or 0),
        }) or t('notify.stores.buy_failed', { error = tostring(response or 'unknown') }),
        type = ok and 'success' or 'error',
    })

    SetTimeout(400, function() Menu.openStorefront(storeId) end)
end

function Menu.openStoreOwnerMenu(storeId)
    local payload = fetchStore(storeId)
    if not payload then return end

    local store = payload.store
    local options = {
        {
            title = t('menu.stores.open_inventory_store'),
            description = t('menu.stores.open_inventory_store_description'),
            icon = 'cart-shopping',
            onSelect = function()
                Menu.openStoreInventory(store.id)
            end,
        },
        {
            title = t('menu.stores.owner_settings'),
            description = t('menu.stores.owner_settings_description', {
                status = store.salesPaused == true and t('common.inactive') or t('common.active'),
                sale = store.saleListed == true and t('common.active') or t('common.inactive'),
            }),
            icon = 'sliders',
            disabled = not payload.isOwner,
            onSelect = function()
                Menu.openStoreOwnerSettings(store)
            end,
        },
        {
            title = t('menu.stores.products'),
            description = t('menu.stores.products_description', { count = tostring(#(store.items or {})) }),
            icon = 'boxes-stacked',
            onSelect = function()
                Menu.openStoreProducts(store.id)
            end,
        },
        {
            title = t('menu.stores.owner_stock'),
            description = t('menu.stores.owner_stock_description'),
            icon = 'boxes-stacked',
            onSelect = function()
                Menu.openStoreOwnerStock(store.id)
            end,
        },
    }

    if payload.isOwner then
        options[#options + 1] = {
            title = t('menu.stores.managers'),
            description = t('menu.stores.managers_description', { count = tostring(#(store.managers or {})) }),
            icon = 'users-gear',
            onSelect = function()
                Menu.openStoreManagers(store.id)
            end,
        }

        options[#options + 1] = {
            title = t('menu.stores.transfer_store'),
            description = t('menu.stores.transfer_store_description'),
            icon = 'right-left',
            onSelect = function()
                Menu.openStoreTransfer(store.id)
            end,
        }

        options[#options + 1] = {
            title = t('menu.stores.withdraw', { amount = tostring(store.balance or 0) }),
            icon = 'money-bill-wave',
            onSelect = function()
                local ok, response = awaitServer(PR.Stores.Callbacks.withdraw, store.id)
                notify({
                    description = ok and t('notify.stores.withdrawn', { amount = tostring(response or 0) }) or t('notify.stores.withdraw_failed', { error = tostring(response or 'unknown') }),
                    type = ok and 'success' or 'error',
                })
                SetTimeout(400, function() Menu.openStoreOwnerMenu(store.id) end)
            end,
        }
    end

    showContext({
        id = ('forge_core_store_owner_%s'):format(store.id),
        title = store.label,
        menu = ('forge_core_storefront_%s'):format(store.id),
        options = options,
    })
end

function Menu.openStoreOwnerSettings(store)
    local result = inputDialog(t('menu.stores.owner_settings'), {
        { type = 'select', label = t('inputs.store_sales_enabled'), options = boolOptions(), default = boolDefault(store.salesPaused ~= true), required = true },
        { type = 'select', label = t('inputs.store_sale_listed'), options = boolOptions(), default = boolDefault(store.saleListed == true), required = true },
        { type = 'number', label = t('inputs.store_purchase_price'), min = 0, default = tonumber(store.purchasePrice) or 0, required = true },
    })

    if not result then return Menu.openStoreOwnerMenu(store.id) end

    local ok, response = awaitServer(PR.Stores.Callbacks.updateOwnerStore, store.id, {
        salesPaused = not boolValue(result[1]),
        saleListed = boolValue(result[2]),
        purchasePrice = tonumber(result[3]) or 0,
    })

    if not ok then notifyFailure('notify.stores.save_failed', response) end
    SetTimeout(400, function() Menu.openStoreOwnerMenu(store.id) end)
end

function Menu.openStoreTransfer(storeId)
    local result = inputDialog(t('menu.stores.transfer_store'), {
        { type = 'number', label = t('inputs.target_source'), min = 1, required = true },
    })

    if not result then return Menu.openStoreOwnerMenu(storeId) end

    local ok, response = awaitServer(PR.Stores.Callbacks.transferStore, storeId, tonumber(result[1]) or 0)
    notify({
        description = ok and t('notify.stores.transfer_done') or t('notify.stores.transfer_failed', { error = tostring(response or 'unknown') }),
        type = ok and 'success' or 'error',
    })
    SetTimeout(400, function() Menu.openStorefront(storeId) end)
end

function Menu.openStoreManagers(storeId)
    local payload = fetchStore(storeId)
    if not payload then return end
    local store = payload.store
    local options = {
        {
            title = t('menu.stores.add_manager'),
            icon = 'user-plus',
            onSelect = function()
                Menu.openStoreAddManager(store.id)
            end,
        },
    }

    for _, manager in ipairs(store.managers or {}) do
        local managerId = type(manager) == 'table' and manager.citizenid or tostring(manager)
        options[#options + 1] = {
            title = type(manager) == 'table' and manager.name or managerId,
            description = managerId,
            icon = 'user-gear',
            onSelect = function()
                local ok, response = awaitServer(PR.Stores.Callbacks.removeManager, store.id, managerId)
                notify({
                    description = ok and t('notify.stores.manager_removed') or t('notify.stores.manager_remove_failed', { error = tostring(response or 'unknown') }),
                    type = ok and 'success' or 'error',
                })
                SetTimeout(400, function() Menu.openStoreManagers(store.id) end)
            end,
        }
    end

    showContext({
        id = ('forge_core_store_managers_%s'):format(store.id),
        title = t('menu.stores.managers'),
        menu = ('forge_core_store_owner_%s'):format(store.id),
        options = options,
    })
end

function Menu.openStoreAddManager(storeId)
    local result = inputDialog(t('menu.stores.add_manager'), {
        { type = 'number', label = t('inputs.target_source'), min = 1, required = true },
    })

    if not result then return Menu.openStoreManagers(storeId) end

    local ok, response = awaitServer(PR.Stores.Callbacks.addManager, storeId, tonumber(result[1]) or 0)
    notify({
        description = ok and t('notify.stores.manager_added') or t('notify.stores.manager_add_failed', { error = tostring(response or 'unknown') }),
        type = ok and 'success' or 'error',
    })
    SetTimeout(400, function() Menu.openStoreManagers(storeId) end)
end

function Menu.openStoreOwnerStock(storeId)
    local ok, items = awaitServer(PR.Stores.Callbacks.getPlayerItems)
    if not ok then
        notifyFailure('notify.stores.load_failed', items)
        return Menu.openStoreOwnerMenu(storeId)
    end

    local options = {}
    for _, item in ipairs(items or {}) do
        options[#options + 1] = {
            value = item.name,
            label = ('%s (%s)'):format(item.label or item.name, tostring(item.count or 0)),
        }
    end

    if #options == 0 then
        notify({ description = t('notify.stores.no_inventory_items'), type = 'error' })
        return Menu.openStoreOwnerMenu(storeId)
    end

    local result = inputDialog(t('menu.stores.owner_stock'), {
        { type = 'select', label = t('inputs.store_item_name'), options = options, required = true, searchable = true },
        { type = 'number', label = t('inputs.store_item_stock'), min = 1, default = 1, required = true },
        { type = 'number', label = t('inputs.store_item_price'), min = 0, default = 0, required = true },
    })

    if not result then return Menu.openStoreOwnerMenu(storeId) end

    local success, response = awaitServer(PR.Stores.Callbacks.addStockFromPlayer, storeId, result[1], result[2], result[3])
    notify({
        description = success and t('notify.stores.stock_added') or t('notify.stores.stock_add_failed', { error = tostring(response or 'unknown') }),
        type = success and 'success' or 'error',
    })

    SetTimeout(400, function() Menu.openStoreOwnerMenu(storeId) end)
end
