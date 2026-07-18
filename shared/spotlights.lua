PR = PR or {}
PR.Spotlights = PR.Spotlights or {}

PR.Spotlights.Storage = {
    file = 'data/spotlights.json',
}

PR.Spotlights.Defaults = {
    enabled = true,
    drawDistance = 450.0,
}

PR.Spotlights.Callbacks = {
    getAll = 'forge-core:server:spotlights:getAll',
    createGroup = 'forge-core:server:spotlights:createGroup',
    renameGroup = 'forge-core:server:spotlights:renameGroup',
    deleteGroup = 'forge-core:server:spotlights:deleteGroup',
    createLight = 'forge-core:server:spotlights:createLight',
    updateLight = 'forge-core:server:spotlights:updateLight',
    deleteLight = 'forge-core:server:spotlights:deleteLight',
}
