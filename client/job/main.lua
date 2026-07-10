ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

pr_lib.callback.register(PR.Job.Callbacks.openMenu, function()
    if ForgeCore.Client.Menu then
        ForgeCore.Client.Menu.openMain()
        return true
    end

    return false
end)
