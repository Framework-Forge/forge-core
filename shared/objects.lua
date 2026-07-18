PR = PR or {}
PR.Objects = PR.Objects or {}

PR.Objects.Storage = {
    file = 'data/objects.json',
}

PR.Objects.Command = 'objectspawner'
PR.Objects.DeleteCommand = 'objectdelete'

PR.Objects.Defaults = {
    enabled = true,
    spawnDistance = 300.0,
    imageServer = '',
}

PR.Objects.Callbacks = {
    getAll = 'forge-core:server:objects:getAll',
    createScene = 'forge-core:server:objects:createScene',
    renameScene = 'forge-core:server:objects:renameScene',
    deleteScene = 'forge-core:server:objects:deleteScene',
    createObject = 'forge-core:server:objects:createObject',
    updateObject = 'forge-core:server:objects:updateObject',
    deleteObject = 'forge-core:server:objects:deleteObject',
}
