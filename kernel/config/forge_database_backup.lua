-- Whole installed config, private local table; no JSON reads.
return function()
    local PR={}

PR.DatabaseBackup = {
    Storage = {
        directory = 'backups/database',
        historyFile = 'backups/database/history.json',
        maxHistory = 50,
    },
    Callbacks = {
        getHistory = 'forge-core:server:databaseBackup:history',
        create = 'forge-core:server:databaseBackup:create',
    },
}

    return PR.DatabaseBackup
end
