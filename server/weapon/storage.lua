ForgeCore = ForgeCore or {}

local Storage = {}
function Storage.load()
    return pr_lib.loadJsonRecovery(PR.Weapons.Storage.file) or {}
end

function Storage.save(data)
    return pr_lib.saveJsonRecovery(PR.Weapons.Storage.file, data or {})
end

ForgeCore.WeaponStorage = Storage
