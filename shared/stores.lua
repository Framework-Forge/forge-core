PR = PR or {}
PR.Stores = PR.Stores or {}

PR.Stores.Storage = {
    file = 'data/stores.json',
    oxBackupFile = 'data/shops.lua.forge-backup',
    oxFile = 'data/shops.lua',
}

PR.Stores.Defaults = {
    enabled = true,
    salesEnabled = true,
    dailyStockEnabled = true,
    defaultDailyStock = 50,
    targetDistance = 2.0,
    targetSize = vec3(0.8, 0.8, 1.4),
    paymentAccounts = { 'cash', 'bank' },
}

PR.Stores.Callbacks = {
    getAll = 'forge-core:server:stores:getAll',
    getStore = 'forge-core:server:stores:getStore',
    saveSettings = 'forge-core:server:stores:settings:save',
    createStore = 'forge-core:server:stores:create',
    updateStore = 'forge-core:server:stores:update',
    updateOwnerStore = 'forge-core:server:stores:owner:update',
    deleteStore = 'forge-core:server:stores:delete',
    setItem = 'forge-core:server:stores:item:set',
    removeItem = 'forge-core:server:stores:item:remove',
    openShop = 'forge-core:server:stores:shop:open',
    buyItem = 'forge-core:server:stores:item:buy',
    buyStore = 'forge-core:server:stores:buy',
    transferStore = 'forge-core:server:stores:transfer',
    addManager = 'forge-core:server:stores:manager:add',
    removeManager = 'forge-core:server:stores:manager:remove',
    withdraw = 'forge-core:server:stores:withdraw',
    getPlayerItems = 'forge-core:server:stores:playerItems',
    addStockFromPlayer = 'forge-core:server:stores:stock:addFromPlayer',
}
