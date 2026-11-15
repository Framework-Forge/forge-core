-- One Npcs state, using world35 and the settings34 Menu/Shared controller.
local createRuntime=require 'kernel.client.npcs'
local createMenu=require 'kernel.client.menu.npcs'
return function(state,ports)
    local work,settings,world=assert(state.WorkMenus),assert(state.ServerSettingsMenus),assert(state.WorldClientCore)
    local client,config=assert(ports.client),assert(ports.config)
    assert(work.State==state and settings.State==state and world.State==state,'canonical state required')
    assert(work.Client==client and settings.Client==client and world.Client==client,'canonical client required')
    assert(work.Menu==settings.Menu and work.Menu==world.Menu and work.Shared==settings.Shared and work.Shared==world.Shared,'canonical Menu/Shared required')
    assert(client.WorldState==world.WorldState and config.Npcs and config.Password==settings.Config.Password,'canonical world/config required')
    assert(state.NpcsClientCore==nil and client.Npcs==nil,'npcs client already attached')
    for _,name in ipairs({'openNpcsMenu','openNpcsGroup','openNpcActions'})do assert(work.Menu[name]==nil,'npcs menu already attached')end
    local legacy,producer,session=assert(state.LegacyCore),assert(state.ProducerCore),assert(client.ForgeSession)
    local groups=assert(legacy.Groups)
    assert(legacy.State==state and producer.State==state and session==state.AutoMedicClientCore.Session.Session,'canonical groups/session required')
    local bindings={config=config,library=ports.library,native=ports.native,translate=ports.translate,
        world=world.WorldState,menu=work.Menu,shared=work.Shared,session=session,integration=ports.integration,
        groups=groups,isReady=function()return state.LegacyCore==legacy and legacy.State==state and legacy.Groups==groups
            and state.ProducerCore==producer and producer.State==state end}
    local runtime=createRuntime(bindings)
    bindings.npcs=runtime.Npcs
    local menu=createMenu(bindings)
    local api={State=state,Client=client,Config=config,World=world,WorldState=world.WorldState,Npcs=runtime.Npcs,
        Menu=work.Menu,Shared=work.Shared,Runtime=runtime,NpcsMenu=menu,Groups=groups,Session=session,
        Threads=runtime.Threads,Subscriptions=runtime.Subscriptions,Events=runtime.Events,Commands=menu.Commands}
    client.Npcs,state.NpcsClientCore=runtime.Npcs,api
    return api
end
