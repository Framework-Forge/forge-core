ForgeCore = ForgeCore or {}

local Storage = {}
function Storage.load()
    return pr_lib.loadJsonRecovery(PR.Skills.Storage.file) or {}
end

function Storage.save(data)
    return pr_lib.saveJsonRecovery(PR.Skills.Storage.file, data or {})
end

ForgeCore.SkillStorage = Storage
