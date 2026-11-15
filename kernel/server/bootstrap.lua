-- Installed Forge server/main startup order and player ingress, descriptors only.
return function(ports)
    local services,library,native=assert(ports.services),assert(ports.library),assert(ports.native)
    local wait,setTimeout=assert(native.wait),assert(native.setTimeout)
    local api={Services={},Events={}}
    for _,name in ipairs({'CharacterSlotService','JobService','JobPayments','SkillService','WeaponService','StaffService',
        'AfkService','PasswordService','WhitelistService','DensityService','MultiJobService','VinewoodService','ObjectsService',
        'NpcsService','SpotlightsService','BillboardsService','StoresService','FarmsService','StarterpackService','DatabaseBackupService','AutoMedicService'})do
        local service=services[name]
        if service then api.Services[#api.Services+1]={name=name,handler=assert(service.start)}end
    end
    local job,staff,starter=services.JobService,services.StaffService,services.StarterpackService
    local send=job and job.sendTo;local apply=staff and staff.applyPlayer;local loaded=starter and starter.handlePlayerLoaded
    local debugEnabled=ports.debugEnabled
    function api.Begin()
        wait(0)
        if library and library.debug and library.debug.setEnabled then library.debug.setEnabled(debugEnabled==true)end
    end
    api.Events[1]={name='QBCore:Server:OnPlayerLoaded',network=true,sourceFirst=true,handler=function(source)
        if job then send(source)end
        if staff then apply(source)end
        if starter then loaded(source)end
    end}
    api.Events[2]={name='playerJoining',network=false,sourceFirst=true,handler=function(source)
        local src=source
        setTimeout(2500,function()
            if job then send(src)end
            if staff then apply(src)end
            if starter then loaded(src)end
        end)
    end}
    return api
end
