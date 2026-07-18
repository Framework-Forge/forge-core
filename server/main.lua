ForgeCore = ForgeCore or {}

CreateThread(function()
    Wait(0)

    if pr_lib and pr_lib.debug and pr_lib.debug.setEnabled then
        pr_lib.debug.setEnabled(PR.Debug == true)
    end

    if ForgeCore.JobService then
        ForgeCore.JobService.start()
    end

    if ForgeCore.JobPayments then
        ForgeCore.JobPayments.start()
    end

    if ForgeCore.SkillService then
        ForgeCore.SkillService.start()
    end

    if ForgeCore.WeaponService then
        ForgeCore.WeaponService.start()
    end

    if ForgeCore.StaffService then
        ForgeCore.StaffService.start()
    end

    if ForgeCore.AfkService then
        ForgeCore.AfkService.start()
    end

    if ForgeCore.PasswordService then
        ForgeCore.PasswordService.start()
    end

    if ForgeCore.WhitelistService then
        ForgeCore.WhitelistService.start()
    end

    if ForgeCore.DensityService then
        ForgeCore.DensityService.start()
    end

    if ForgeCore.MultiJobService then
        ForgeCore.MultiJobService.start()
    end

    if ForgeCore.VinewoodService then
        ForgeCore.VinewoodService.start()
    end

    if ForgeCore.ObjectsService then
        ForgeCore.ObjectsService.start()
    end

    if ForgeCore.NpcsService then
        ForgeCore.NpcsService.start()
    end

    if ForgeCore.SpotlightsService then
        ForgeCore.SpotlightsService.start()
    end

    if ForgeCore.BillboardsService then
        ForgeCore.BillboardsService.start()
    end

    if ForgeCore.StoresService then
        ForgeCore.StoresService.start()
    end

    if ForgeCore.FarmsService then
        ForgeCore.FarmsService.start()
    end

    if ForgeCore.StarterpackService then
        ForgeCore.StarterpackService.start()
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    if ForgeCore.JobService then
        ForgeCore.JobService.sendTo(source)
    end

    if ForgeCore.StaffService then
        ForgeCore.StaffService.applyPlayer(source)
    end

    if ForgeCore.StarterpackService then
        ForgeCore.StarterpackService.handlePlayerLoaded(source)
    end
end)

AddEventHandler('playerJoining', function()
    local src = source

    SetTimeout(2500, function()
        if ForgeCore.JobService then
            ForgeCore.JobService.sendTo(src)
        end

        if ForgeCore.StaffService then
            ForgeCore.StaffService.applyPlayer(src)
        end

        if ForgeCore.StarterpackService then
            ForgeCore.StarterpackService.handlePlayerLoaded(src)
        end
    end)
end)
