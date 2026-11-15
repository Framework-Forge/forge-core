-- Reuse world35, Session31 and the settings controller; do not create a duplicate producer.
local createRuntime=require 'kernel.client.vinewood'
local createMenu=require 'kernel.client.menu.vinewood'
return function(state,ports)
    local work,settings,world,medical=assert(state.WorkMenus),assert(state.ServerSettingsMenus),
        assert(state.WorldClientCore),assert(state.AutoMedicClientCore)
    local client,config=assert(ports.client),assert(ports.config)
    assert(work.State==state and settings.State==state and world.State==state and medical.State==state,'canonical state required')
    assert(work.Client==client and settings.Client==client and world.Client==client and medical.Client==client,'canonical client required')
    assert(work.Menu==settings.Menu and world.Menu==work.Menu and work.Shared==settings.Shared and world.Shared==work.Shared,'canonical Menu/Shared required')
    assert(client.ForgeSession==medical.Session.Session and client.WorldState==world.WorldState,'canonical Session/world required')
    assert(config.Vinewood and config.Password==settings.Config.Password,'canonical config required')
    assert(state.VinewoodClientCore==nil and work.Menu.openVinewoodMenu==nil and work.Menu.openVinewoodEditor==nil,'Vinewood client already attached')
    local bindings={config=config,library=ports.library,native=ports.native,world=world.WorldState,
        session=client.ForgeSession,menu=work.Menu,shared=work.Shared}
    local runtime=createRuntime(bindings)
    local menu=createMenu(bindings)
    local api={State=state,Client=client,Config=config,World=world,WorldState=world.WorldState,
        Session=medical.Session,Menu=work.Menu,Shared=work.Shared,Runtime=runtime,VinewoodMenu=menu,
        Threads=runtime.Threads,Events=runtime.Events,Subscriptions=runtime.Subscriptions,Commands=menu.Commands}
    state.VinewoodClientCore=api
    return api
end
