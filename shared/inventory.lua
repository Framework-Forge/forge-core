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
    getGiveCatalog = 'forge-core:server:inventory:getGiveCatalog',
    give = 'forge-core:server:inventory:give',
}

PR.Inventory.InteractionKinds = {
    { value = 'consumable', label = 'Consumivel' },
    { value = 'interact', label = 'Interacao' },
}

PR.Inventory.ConsumableCategories = {
    { value = 'food', label = 'Comida' },
    { value = 'drink', label = 'Bebida' },
    { value = 'alcohol', label = 'Alcool' },
    { value = 'narco', label = 'Narcotico' },
}

PR.Inventory.SpecialEffects = {
    { value = '', label = 'Nenhum' },
    { value = 'adrenaline', label = 'Adrenalina (corrida)' },
    { value = 'weed', label = 'Maconha' },
    { value = 'coke', label = 'Cocaina' },
    { value = 'crack', label = 'Crack' },
    { value = 'ecstasy', label = 'Ecstasy' },
    { value = 'oxy', label = 'Oxy' },
    { value = 'meth', label = 'Metanfetamina' },
}

PR.Inventory.PersistentInteraction = {
    cancelKey = 'H',
    cancelDescription = 'Cancelar interacao persistente de item',
    reapplyInterval = 500,
}
PR.Inventory.InteractionDefaults = {
    enabled = false,
    kind = 'consumable',
    category = 'food',
    duration = 5000,
    canCancel = true,
    remove = 1,
    effect = '',
    effectDuration = 12000,
    effectStrength = 1.15,
    animation = {
        mode = 'partial',
        dict = '',
        anim = '',
        flags = 49,
        props = {},
    },
    effects = {
        health = { min = 0, max = 0 },
        armor = { min = 0, max = 0 },
        hunger = { min = 0, max = 0 },
        thirst = { min = 0, max = 0 },
        stress = { min = 0, max = 0 },
        oxygen = { min = 0, max = 0 },
    },
}

-- Legacy consumable definitions migrated into Forge Core. These definitions
-- are copied into existing Forge items on load and then persisted in items.json.
PR.Inventory.LegacyInteractions = {
    sandwich = { category = 'food', hunger = { 35, 54 }, stress = { -4, -1 } },
    tosti = { category = 'food', hunger = { 40, 50 }, stress = { -4, -1 } },
    twerks_candy = { category = 'food', hunger = { 35, 54 }, stress = { -4, -1 } },
    snikkel_candy = { category = 'food', hunger = { 40, 50 }, stress = { -4, -1 } },
    water_bottle = { category = 'drink', thirst = { 35, 54 }, stress = { -4, -1 } },
    kurkakola = { category = 'drink', thirst = { 35, 54 }, stress = { -4, -1 } },
    coffee = {
        category = 'drink', thirst = { 40, 50 }, stress = { 1, 10 },
        animation = { dict = 'amb@world_human_drinking@coffee@male@idle_a', anim = 'idle_c', flags = 49 },
        props = { { model = 'p_amb_coffeecup_01', bone = 28422 } },
    },
    whiskey = { category = 'alcohol', thirst = { 20, 30 }, stress = { -4, -1 }, alcohol = 1.0 },
    beer = { category = 'alcohol', thirst = { 30, 40 }, stress = { -4, -1 }, alcohol = 0.25 },
    vodka = { category = 'alcohol', thirst = { 20, 40 }, stress = { -4, -1 }, alcohol = 1.0 },
    joint = { category = 'narco', stress = { -18, -15 }, duration = 1500, effect = 'weed' },
    cokebaggy = { category = 'narco', duration = 6500, effect = 'coke' },
    crack_baggy = { category = 'narco', duration = 8500, effect = 'crack' },
    xtcbaggy = { category = 'narco', duration = 3000, effect = 'ecstasy' },
    oxy = { category = 'narco', duration = 2000, health = { 54, 54 }, effect = 'oxy' },
    meth = { category = 'narco', duration = 1500, effect = 'meth' },
}

PR.Inventory.ItemDefaults = {
    name = '',
    label = '',
    weight = 0,
    stack = false,
    close = true,
    active = true,
}

PR.Inventory.AmmoDefaults = {
    name = '',
    label = '',
    weight = 0,
    stack = true,
    active = true,
}

PR.Inventory.ComponentDefaults = {
    name = '',
    label = '',
    weight = 0,
    stack = false,
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
