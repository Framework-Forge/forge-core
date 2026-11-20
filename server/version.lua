local REPO_OWNER = "Framework-Forge"
local REPO_NAME = "forge-core"
local VERSION_CHECK = true

if IsDuplicityVersion() then
    CreateThread(function()
        Wait(5000)
        if VERSION_CHECK then
            if GetResourceState('pr_bridge') ~= 'started' then return end
            local library = exports.pr_bridge:getLib()
            if library and library.versionCheck then
                library.versionCheck(("%s/%s"):format(REPO_OWNER, REPO_NAME))
            end
        end
    end)
end
