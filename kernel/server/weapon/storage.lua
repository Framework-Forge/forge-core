-- PR recovery storage boundary; never loads on construction.
return function(ports)
    local PR, library={Weapons=assert(ports.config)},assert(ports.library)
local Storage = {}
function Storage.load()
    return library.loadJsonRecovery(PR.Weapons.Storage.file) or {}
end

function Storage.save(data)
    return library.saveJsonRecovery(PR.Weapons.Storage.file, data or {})
end

    return Storage
end
