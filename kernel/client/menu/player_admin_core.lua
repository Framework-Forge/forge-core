-- Personal/admin menu extensions reuse one controller, RPC library and session; no open/register here.
local createPersonal=require 'kernel.client.menu.player'
local createManagement=require 'kernel.client.menu.players'
local createPrison=require 'kernel.client.menu.prison'
return function(state,ports)
    local work,settings,world=assert(state.WorkMenus),assert(state.ServerSettingsMenus),assert(state.WorldClientCore)
    local client,config=assert(ports.client),assert(ports.config)
    assert(work.State==state and settings.State==state and world.State==state,'canonical state required')
    assert(work.Client==client and settings.Client==client and world.Client==client,'canonical client required')
    assert(work.Menu==settings.Menu and work.Menu==world.Menu and work.Shared==settings.Shared and work.Shared==world.Shared,'canonical menu required')
    assert(state.ProducerCore and client.ForgeSession and client.WorldState==world.WorldState,'canonical producer/session/world required')
    assert(config.Player and config.PlayerManagement and config.Staff and config.CharacterSlots,'local configuration required')
    assert(state.PlayerAdminMenus==nil,'player menus already attached')
    for _,name in ipairs({'openPlayerMenu','openPlayerGiveAdmin','openPlayersManagement','openManagedPlayer',
        'openPlayerWhitelistAdmin','openPlayerJobsAdmin','openPlayerStaffAdmin','setPlayerPrison','releasePlayerPrison'})do assert(work.Menu[name]==nil,'player menu already attached')end
    assert(work.Shared.prisonDescription==nil,'prison helper already attached')
    local bindings={config=config,menu=work.Menu,shared=work.Shared,native=assert(ports.native),library=assert(ports.library)}
    local prison=createPrison(bindings)
    local personal,management=createPersonal(bindings),createManagement(bindings)
    local api={State=state,Client=client,Config=config,Menu=work.Menu,Shared=work.Shared,Session=client.ForgeSession,
        World=world,Personal=personal,Management=management,Prison=prison}
    state.PlayerAdminMenus=api
    return api
end
