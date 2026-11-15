-- Same canonical PlayerData/world/Menu controller; no automatic event/thread/target installation.
local createRuntime=require 'kernel.client.farms'
local createMenu=require 'kernel.client.menu.farms'
return function(state,ports)
    local work,settings,world=assert(state.WorkMenus),assert(state.ServerSettingsMenus),assert(state.WorldClientCore)
    local client,config=assert(ports.client),assert(ports.config)
    assert(work.State==state and settings.State==state and world.State==state,'canonical state required')
    assert(work.Client==client and settings.Client==client and world.Client==client,'canonical client required')
    assert(work.Menu==settings.Menu and work.Menu==world.Menu and work.Shared==settings.Shared and work.Shared==world.Shared,'canonical Menu/Shared required')
    assert(client.WorldState==world.WorldState and config.Farms and config.Password==settings.Config.Password,'canonical world/config required')
    assert(type(state.PlayerData)=='table' and state.ProducerCore,'canonical PlayerData required')
    assert(state.FarmsClientCore==nil and client.Farms==nil,'farms client already attached')
    for _,name in ipairs({'openFarmsMenu','openFarmSettings','openFarmCreate','openFarmAdmin','openFarmEdit','openFarmAccessMenu',
        'openFarmGroupList','openFarmGroupGrade','openFarmEntranceMenu','openFarmTargetEdit','markFarmStart','markFarmStartWithDevLaser',
        'deleteFarm','openFarmItems','openFarmItemCreateSelect','openFarmItemCreateDetails','openFarmItemMenu','openFarmItemEdit',
        'openFarmItemRequired','openFarmItemLimits','openFarmItemAnimation','openFarmItemPoints','openFarmPointCaptureMenu',
        'openFarmPointMenu','openFarmPointReplaceMenu','openFarmItemExtras','openFarmExtraEdit','deleteFarmItem'})do
        assert(work.Menu[name]==nil,'farm menu already attached')
    end
    local player={GetPlayerData=function()return state.PlayerData end}
    local bindings={config=config,library=ports.library,native=ports.native,translate=ports.translate,math=ports.math,
        world=world.WorldState,menu=work.Menu,shared=work.Shared,player=player}
    local runtime=createRuntime(bindings);bindings.farms=runtime.Farms
    local menu=createMenu(bindings)
    local api={State=state,Client=client,Config=config,World=world,WorldState=world.WorldState,Farms=runtime.Farms,
        Menu=work.Menu,Shared=work.Shared,Runtime=runtime,FarmsMenu=menu,Player=player,
        Threads=runtime.Threads,Subscriptions=runtime.Subscriptions,Events=runtime.Events}
    client.Farms,state.FarmsClientCore=runtime.Farms,api
    return api
end
