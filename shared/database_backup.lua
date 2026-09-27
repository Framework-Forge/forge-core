PR = PR or {}

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
