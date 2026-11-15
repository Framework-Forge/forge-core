-- Persistence remains owned by the PR library.
return function(ports)
    local PR,library={Skills=assert(ports.config)},assert(ports.library)
local Storage = {}
function Storage.load()
    return library.loadJsonRecovery(PR.Skills.Storage.file) or {}
end

function Storage.save(data)
    return library.saveJsonRecovery(PR.Skills.Storage.file, data or {})
end

return Storage
end

