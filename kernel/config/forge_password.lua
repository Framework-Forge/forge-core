-- Whole installed config, private local table; no JSON reads.
return function()
    local PR={}
    PR.Password={}
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

    return PR.Password
end
