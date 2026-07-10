PR = PR or {}
PR.Password = PR.Password or {}

PR.Password.Storage = {
    file = 'data/server_password.json',
}

PR.Password.Callbacks = {
    getSettings = 'forge-core:server:password:getSettings',
    saveSettings = 'forge-core:server:password:saveSettings',
}

PR.Password.Defaults = {
    enabled = false,
    password = '',
    supportLink = '',
    cardTitle = '',
    cardDescription = '',
    placeholder = '',
    submitText = '',
}
