-- One callback descriptor; no automatic PR registration or central menu import.
return function(ports)
    local client,PR=assert(ports.client),{Job=assert(ports.config)}
    local callbacks={}
    local function callback(name,handler)callbacks[name]=handler end
callback(PR.Job.Callbacks.openMenu, function()
    if client.Menu then
        client.Menu.openMain()
        return true
    end

    return false
end)

    return {Callbacks=callbacks}
end
