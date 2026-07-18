PR = PR or {}
PR.Inventory = PR.Inventory or {}

PR.Inventory.Storage = {
    items = 'data/items.json',
    weaponInventory = 'data/weapon_inventory.json',
}

PR.Inventory.Callbacks = {
    getAll = 'forge-core:server:inventory:getAll',
    saveItem = 'forge-core:server:inventory:saveItem',
    deleteItem = 'forge-core:server:inventory:deleteItem',
    setItemActive = 'forge-core:server:inventory:setItemActive',
    saveAmmo = 'forge-core:server:inventory:saveAmmo',
    deleteAmmo = 'forge-core:server:inventory:deleteAmmo',
    setAmmoActive = 'forge-core:server:inventory:setAmmoActive',
    saveComponent = 'forge-core:server:inventory:saveComponent',
    deleteComponent = 'forge-core:server:inventory:deleteComponent',
    setComponentActive = 'forge-core:server:inventory:setComponentActive',
    parseDefinition = 'forge-core:server:inventory:parseDefinition',
}

PR.Inventory.ItemDefaults = {
    name = '',
    label = '',
    weight = 0,
    stack = true,
    close = true,
    active = true,
}

PR.Inventory.AmmoDefaults = {
    name = '',
    label = '',
    weight = 0,
    active = true,
}

PR.Inventory.ComponentDefaults = {
    name = '',
    label = '',
    weight = 0,
    type = 'component',
    active = true,
}

PR.Inventory.AccessModes = {
    { value = 'free', label = 'Livre' },
    { value = 'job', label = 'Emprego' },
    { value = 'gang', label = 'Gangue' },
    { value = 'admin', label = 'Admin' },
}

PR.Inventory.DefaultAccess = {
    mode = 'free',
    name = '',
    grade = 0,
}
