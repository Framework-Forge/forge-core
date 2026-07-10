PR = PR or {}
PR.Weapons = PR.Weapons or {}

PR.Weapons.Storage = {
    file = 'data/weapons.json',
}

PR.Weapons.Callbacks = {
    getAll = 'forge-core:server:weapons:getAll',
    save = 'forge-core:server:weapons:save',
    delete = 'forge-core:server:weapons:delete',
    setActive = 'forge-core:server:weapons:setActive',
}

PR.Weapons.Categories = {
    { value = 'Melee', label = 'Corpo a corpo' },
    { value = 'Pistol', label = 'Pistola' },
    { value = 'Submachine Gun', label = 'Submetralhadora' },
    { value = 'Shotgun', label = 'Shotgun' },
    { value = 'Assault Rifle', label = 'Rifle' },
    { value = 'Light Machine Gun', label = 'Metralhadora' },
    { value = 'Sniper Rifle', label = 'Sniper' },
    { value = 'Heavy Weapons', label = 'Pesada' },
    { value = 'Throwable', label = 'Arremessavel' },
    { value = 'Miscellaneous', label = 'Diversos' },
    { value = 'Animals', label = 'Animais' },
}

PR.Weapons.AmmoTypes = {
    { value = 'none', label = 'Sem municao' },
    { value = 'AMMO_PISTOL', label = 'AMMO_PISTOL' },
    { value = 'AMMO_SMG', label = 'AMMO_SMG' },
    { value = 'AMMO_RIFLE', label = 'AMMO_RIFLE' },
    { value = 'AMMO_SHOTGUN', label = 'AMMO_SHOTGUN' },
    { value = 'AMMO_MG', label = 'AMMO_MG' },
    { value = 'AMMO_SNIPER', label = 'AMMO_SNIPER' },
    { value = 'AMMO_RPG', label = 'AMMO_RPG' },
    { value = 'AMMO_GRENADELAUNCHER', label = 'AMMO_GRENADELAUNCHER' },
    { value = 'AMMO_MINIGUN', label = 'AMMO_MINIGUN' },
    { value = 'AMMO_STINGER', label = 'AMMO_STINGER' },
    { value = 'AMMO_FLARE', label = 'AMMO_FLARE' },
    { value = 'AMMO_STUNGUN', label = 'AMMO_STUNGUN' },
}

PR.Weapons.Defaults = {
    name = '',
    label = '',
    weapontype = 'Pistol',
    ammotype = 'AMMO_PISTOL',
    damagereason = 'Died',
    active = true,
}
