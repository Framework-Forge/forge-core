-- Canonical local player/status/permission/prison/session attachment, never activation.
local createConfig=require 'kernel.config.forge_automedic'
local createService=require 'kernel.server.automedic.service'
local createCallbacks=require 'kernel.server.automedic.callbacks'
local createSession=require 'kernel.server.forge_session'
return function(base,ports)
    local pc,catalog,groups=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.Groups)
    local transport,deps=assert(catalog.Transport),assert(catalog.Dependencies)
    assert(pc.Groups==groups and catalog.Groups==groups and base.Callbacks==transport.Security,'canonical state/Security required')
    assert(base.AutoMedicCore==nil and deps.AutoMedicService==nil and base.ForgeSession==nil,'AutoMedic/session already attached')
    assert(base.MultiJobCore and deps.PrisonService==base.MultiJobCore.PrisonService,'canonical prison policy required')
    local lookup,players,status=assert(pc.Lookup),assert(pc.Players),assert(pc.State.Status)
    local library,native=assert(ports.library),assert(ports.native)
    assert(type(ports.inventoryIntegration)=='table'and type(ports.inventoryIntegration.isReady)=='function'
        and type(ports.inventoryIntegration.clearInventoryRaw)=='function','safe explicit PR inventory contract required')
    local session=createSession({kernel={GetPlayer=assert(lookup.GetPlayer)},cache=assert(library.cache),native=native})
    local config=ports.config or createConfig()
    -- Exact installed PR money facade signatures; this source uses only cash/bank and explicit reasons.
    local money={getPlayerMoney=assert(players.GetMoney),removePlayerMoney=assert(players.RemoveMoney),addPlayerMoney=assert(players.AddMoney)}
    local services={JobService=assert(catalog.Service),PrisonService=deps.PrisonService,Session=session.Session}
    local boundary=createService({config=config,adminAce=ports.adminAce,library=library,services=services,money=money,
        inventoryIntegration=ports.inventoryIntegration,native=native,kernel={GetPlayer=lookup.GetPlayer,
            GetStatus=assert(status.Get),SetStatus=assert(status.Set),SetMetadata=assert(players.SetMetadata)}})
    local api={Base=base,PlayerCore=pc,Groups=groups,Config=config,Service=boundary.Service,Boundary=boundary,
        Session=session,Security=transport.Security,Callbacks=createCallbacks({config=config,service=boundary.Service})}
    deps.AutoMedicService,base.AutoMedicCore,base.ForgeSession=api.Service,api,session
    return api
end

