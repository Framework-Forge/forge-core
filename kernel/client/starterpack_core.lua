-- Client scene and menus on canonical World35/Menu34/ForgeSession31. Descriptors only until binding.
local createRuntime=require 'kernel.client.starterpack'
local createMenu=require 'kernel.client.menu.starterpack'
return function(state,ports)
    local work,settings,world=assert(state.WorkMenus),assert(state.ServerSettingsMenus),assert(state.WorldClientCore)
    local client,config=assert(ports.client),assert(ports.config)
    assert(work.State==state and settings.State==state and world.State==state,'canonical state required')
    assert(work.Client==client and settings.Client==client and world.Client==client,'canonical client required')
    assert(work.Menu==settings.Menu and work.Menu==world.Menu and work.Shared==settings.Shared and work.Shared==world.Shared,'canonical Menu/Shared required')
    assert(client.WorldState==world.WorldState and config.Starterpack and config.Password==settings.Config.Password,'canonical world/config required')
    assert(state.ProducerCore and type(state.PlayerData)=='table','canonical PlayerData required')
    local session=assert(client.ForgeSession,'canonical ForgeSession31 required')
    assert(state.StarterpackClientCore==nil and client.Starterpack==nil,'starterpack client already attached')
    for _,name in ipairs({'openStarterpackMenu','openStarterpackSettings','openStarterpackItems','openStarterpackItem','openStarterpackItemEditor',
        'openStarterpackActions','openStarterpackPrologue','placeStarterpackVehicle','placeStarterpackLamar','openStarterpackPrologueSettings',
        'openStarterpackStopEditor','openStarterpackStop','openStarterpackStopRewards','openStarterpackReward','openStarterpackRewardEditor',
        'openStarterpackStopDialogs','openStarterpackDialog','openStarterpackDialogEditor'})do assert(work.Menu[name]==nil,'starterpack menu already attached')end
    local bindings={config=config,library=ports.library,native=ports.native,translate=ports.translate,print=ports.print,json=ports.json,
        world=world.WorldState,session=session,menu=work.Menu,shared=work.Shared}
    local runtime=createRuntime(bindings);local menu=createMenu(bindings)
    local api={State=state,Client=client,Config=config,World=world,WorldState=world.WorldState,Session=session,Starterpack=runtime.Starterpack,
        Menu=work.Menu,Shared=work.Shared,Runtime=runtime,StarterpackMenu=menu,
        Initializers=runtime.Initializers,Subscriptions=runtime.Subscriptions,Events=runtime.Events}
    client.Starterpack,state.StarterpackClientCore=runtime.Starterpack,api
    return api
end
