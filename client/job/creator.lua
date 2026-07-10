ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Creator = {}

function Creator.openJob()
    if ForgeCore.Client.Menu then
        ForgeCore.Client.Menu.openGroupCreator('job')
    end
end

function Creator.openGang()
    if ForgeCore.Client.Menu then
        ForgeCore.Client.Menu.openGroupCreator('gang')
    end
end

ForgeCore.Client.JobCreator = Creator
