-- Full installed private configuration; no JSON or runtime effects.
return function(seed)
    local PR={Afk=seed or {}}
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
    return PR.Afk
end
