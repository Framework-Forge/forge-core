PR = PR or {}
PR.Starterpack = PR.Starterpack or {}

PR.Starterpack.Storage = {
    file = 'data/starterpack.json',
}

PR.Starterpack.Defaults = {
    settings = {
        enabled = true,
        oncePerCharacter = true,
        autoGiveOnFirstJoin = false,
    },
    items = {},
    claimed = {},
    prologue = {
        enabled = false,
        lamarModel = 'ig_lamardavis',
        vehicleModel = 'asea',
        autopilotMaxSpeed = 22.0,
        finishBehavior = 'lamar_drives_away',
        start = {
            coords = { x = 0.0, y = 0.0, z = 0.0 },
            heading = 0.0,
        },
        vehicleStart = {
            coords = { x = 0.0, y = 0.0, z = 0.0 },
            heading = 0.0,
        },
        lamarStart = {
            coords = { x = 0.0, y = 0.0, z = 0.0 },
            heading = 0.0,
        },
        stops = {},
    },
}

PR.Starterpack.Callbacks = {
    getAll = 'forge-core:server:starterpack:getAll',
    saveSettings = 'forge-core:server:starterpack:settings:save',
    savePrologue = 'forge-core:server:starterpack:prologue:save',
    setItem = 'forge-core:server:starterpack:item:set',
    removeItem = 'forge-core:server:starterpack:item:remove',
    setStop = 'forge-core:server:starterpack:stop:set',
    removeStop = 'forge-core:server:starterpack:stop:remove',
    grantReward = 'forge-core:server:starterpack:reward:grant',
    completePrologue = 'forge-core:server:starterpack:prologue:complete',
    claim = 'forge-core:server:starterpack:claim',
    giveToPlayer = 'forge-core:server:starterpack:giveToPlayer',
    resetClaim = 'forge-core:server:starterpack:resetClaim',
}

PR.Starterpack.Events = {
    startTest = 'forge-core:client:starterpack:startTest',
    refresh = 'forge-core:client:starterpack:refresh',
    editStopKeyframes = 'forge-core:client:starterpack:editStopKeyframes',
}
