PR = PR or {}

PR.Vip = {
    enabled = true,
    metadataKey = 'vip',
    storageFile = 'data/vip.json',
    expirationCheckInterval = 15000,
    inventoryRetryAttempts = 40,
    inventoryRetryDelay = 250,
    tiers = {
        bronze = { label = 'Bronze', color = '#cd7f32', principal = 'vip.bronze', slots = 10, weight = 5000, xpMultiplier = 1.10, salary = { enabled = true, account = 'bank', amount = 500 } },
        gold = { label = 'Gold', color = '#f5c542', principal = 'vip.gold', slots = 20, weight = 10000, xpMultiplier = 1.25, salary = { enabled = true, account = 'bank', amount = 1000 } },
        diamond = { label = 'Diamond', color = '#4ed7ff', principal = 'vip.diamond', slots = 35, weight = 15000, xpMultiplier = 1.50, salary = { enabled = true, account = 'bank', amount = 2000 } },
    },
    Callbacks = {
        get = 'forge-core:server:vip:get', getTiers = 'forge-core:server:vip:getTiers', saveTier = 'forge-core:server:vip:saveTier', deleteTier = 'forge-core:server:vip:deleteTier', grant = 'forge-core:server:vip:grant', revoke = 'forge-core:server:vip:revoke',
    },
}