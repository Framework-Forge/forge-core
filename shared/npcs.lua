PR = PR or {}
PR.Npcs = PR.Npcs or {}

PR.Npcs.Storage = {
    file = 'data/npcs.json',
}

PR.Npcs.Command = 'npcspawner'
PR.Npcs.DeleteCommand = 'npcdelete'

PR.Npcs.Defaults = {
    enabled = true,
    spawnDistance = 120.0,
    interactionDistance = 2.0,
    drawTextKey = 38,
}

PR.Npcs.Callbacks = {
    getAll = 'forge-core:server:npcs:getAll',
    createGroup = 'forge-core:server:npcs:createGroup',
    renameGroup = 'forge-core:server:npcs:renameGroup',
    deleteGroup = 'forge-core:server:npcs:deleteGroup',
    createNpc = 'forge-core:server:npcs:createNpc',
    updateNpc = 'forge-core:server:npcs:updateNpc',
    deleteNpc = 'forge-core:server:npcs:deleteNpc',
}
