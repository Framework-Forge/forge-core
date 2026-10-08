ForgeCore = ForgeCore or {}
ForgeCore.ServerMenu = ForgeCore.ServerMenu or {}

-- Optional resources use the same server-side authorization as this admin panel.
exports('CanManageServerSettings', function(source)
    return type(source)=='number' and source>0 and ForgeCore.JobService
        and ForgeCore.JobService.canManage(source)==true or false
end)

function ForgeCore.ServerMenu.open(source)
    if not ForgeCore.JobService or not ForgeCore.JobService.canManage(source) then return false end
    if source == 0 then return false end

    ForgeCore.JobService.sendTo(source)
    local opened = pr_lib.callback.await(source, PR.Job.Callbacks.openMenu, 5000)

    return opened == true
end

function ForgeCore.ServerMenu.openMeiCreator(source)
    if not source or source <= 0 then return false end

    local opened = pr_lib.callback.await(source, PR.Job.Callbacks.openMei, 5000)
    return opened == true
end

exports('OpenMeiCreator', function(source)
    return ForgeCore.ServerMenu.openMeiCreator(source)
end)

exports('OpenMEICreator', function(source)
    return ForgeCore.ServerMenu.openMeiCreator(source)
end)
