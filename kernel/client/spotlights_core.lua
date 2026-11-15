-- One Spotlights state, using world35 and the settings34 Menu/Shared controller.
local createRuntime=require 'kernel.client.spotlights'
local createMenu=require 'kernel.client.menu.spotlights'
return function(state,ports)
    local work,settings,world=assert(state.WorkMenus),assert(state.ServerSettingsMenus),assert(state.WorldClientCore)
    local client,config=assert(ports.client),assert(ports.config)
    assert(work.State==state and settings.State==state and world.State==state,'canonical state required')
    assert(work.Client==client and settings.Client==client and world.Client==client,'canonical client required')
    assert(work.Menu==settings.Menu and work.Menu==world.Menu and work.Shared==settings.Shared and work.Shared==world.Shared,'canonical Menu/Shared required')
    assert(client.WorldState==world.WorldState and config.Spotlights and config.Password==settings.Config.Password,'canonical world/config required')
    assert(state.SpotlightsClientCore==nil and client.Spotlights==nil,'spotlights client already attached')
    for _,name in ipairs({'openSpotlightsMenu','openSpotlightsGroup','openSpotlightActions'})do assert(work.Menu[name]==nil,'spotlights menu already attached')end
    local bindings={config=config,library=ports.library,native=ports.native,translate=ports.translate,
        world=world.WorldState,menu=work.Menu,shared=work.Shared}
    local runtime=createRuntime(bindings)
    bindings.spotlights=runtime.Spotlights
    local menu=createMenu(bindings)
    local api={State=state,Client=client,Config=config,World=world,WorldState=world.WorldState,Spotlights=runtime.Spotlights,
        Menu=work.Menu,Shared=work.Shared,Runtime=runtime,SpotlightsMenu=menu,
        Threads=runtime.Threads,Subscriptions=runtime.Subscriptions}
    client.Spotlights,state.SpotlightsClientCore=runtime.Spotlights,api
    return api
end
