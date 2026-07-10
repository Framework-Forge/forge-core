PR = PR or {}
PR.Afk = PR.Afk or {}

PR.Afk.Storage = {
    file = 'data/afk.json',
}

PR.Afk.Callbacks = {
    getSettings = 'forge-core:server:afk:getSettings',
    saveSettings = 'forge-core:server:afk:saveSettings',
}

PR.Afk.Defaults = {
    enabled = true,
    minutes = 15,
}
