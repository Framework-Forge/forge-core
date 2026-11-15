-- Canonical attachment only. Does not apply grants, start the service or register anything.
local createConfig=require 'kernel.config.forge_staff'
local createService=require 'kernel.server.staff.service'
local createCallbacks=require 'kernel.server.staff.callbacks'
local createCommands=require 'kernel.server.staff.commands'
return function(base,ports)
    local pc,catalog,groups=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.Groups)
    local transport,deps=assert(catalog.Transport),assert(catalog.Dependencies)
    assert(pc.Groups==groups and catalog.Groups==groups,'canonical Groups required')
    assert(base.Callbacks==transport.Security,'canonical Security required')
    assert(base.StaffCore==nil and deps.StaffService==nil,'staff already attached')
    local lookup,players=assert(pc.Lookup),assert(pc.Players)
    -- Do not use library.ace here: its implicit identity lookup can re-enter the PR framework adapter.
    assert(type(ports.aceIntegration)=='table'and type(ports.aceIntegration.isPlayerAceAllowed)=='function'
        and type(ports.aceIntegration.getPermissionCatalog)=='function','explicit safe PR ACE integration contract required')
    local config=ports.config or createConfig(ports.adminAce)
    local service=createService({config=config,adminAce=ports.adminAce,notifyPosition=ports.notifyPosition,
        services={JobService=assert(catalog.Service)},library=ports.library,ace=ports.aceIntegration,
        translate=ports.translate,native=ports.native,kernel={GetPlayer=lookup.GetPlayer,
            GetPlayerByCitizenId=lookup.GetPlayerByCitizenId,GetOfflinePlayer=players.GetOfflinePlayer,SaveOffline=players.SaveOffline}})
    local api={Base=base,PlayerCore=pc,Groups=groups,Config=config,Service=service,Security=transport.Security,
        Callbacks=createCallbacks({config=config,service=service}),
        Commands=createCommands({config=config,service=service,library=ports.library,translate=ports.translate,
            notifyPosition=ports.notifyPosition,native=ports.native}).Commands}
    deps.StaffService,base.StaffCore=service,api
    return api
end

