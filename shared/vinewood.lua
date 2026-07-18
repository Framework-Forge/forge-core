PR = PR or {}
PR.Vinewood = PR.Vinewood or {}

PR.Vinewood.Storage = {
    file = 'data/vinewood.json',
}

PR.Vinewood.Callbacks = {
    getSettings = 'forge-core:server:vinewood:getSettings',
    saveSettings = 'forge-core:server:vinewood:saveSettings',
}

PR.Vinewood.Defaults = {
    enabled = true,
    text = 'FORGE',
    color = '#FFFFFF',
}

PR.Vinewood.Command = 'vinewood'

PR.Vinewood.Texture = {
    dictionary = 'mainTexture',
    name = 'techdevontop',
    runtimeTxd = 'txd_forge_vinewood_sign',
    runtimeTxn = 'txn_forge_vinewood_sign',
}

PR.Vinewood.Coords = {
    { coords = vector3(668.4682, 1211.0850, 326.0588), heading = 343.5 },
    { coords = vector3(681.3944, 1204.1750, 326.2883), heading = 344.99996948242 },
    { coords = vector3(696.2234, 1199.1080, 326.3676), heading = 344.99996948242 },
    { coords = vector3(711.2237, 1196.9670, 326.2217), heading = 344.99996948242 },
    { coords = vector3(728.8736, 1194.6030, 326.5620), heading = 344.99996948242 },
    { coords = vector3(745.7531, 1187.6000, 327.8065), heading = 344.99996948242 },
    { coords = vector3(763.6939, 1184.8940, 329.1479), heading = 344.99996948242 },
    { coords = vector3(776.6939, 1174.8940, 326.1479), heading = 344.99996948242 },
}
