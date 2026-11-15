-- One canonical PlayerData and world, using the same settings Menu/Shared controller.
local createRuntime=require 'kernel.client.stores'
local createMenu=require 'kernel.client.menu.stores'
local methods={'openStoresAdminMenu','openStoresSettings','openStoresBlacklist','openStoreCreate','openStorePoints',
    'openStoreAdmin','openStoreEdit','openStoreProducts','openStoreProductActions','openStoreProductEditor',
    'openStoreInventory','openStorefront','openStoreBuyStore','openStoreBuyItem','openStoreOwnerMenu','openStoreOwnerEdit',
    'openStoreOwnerSettings','openStoreTransfer','openStoreManagers','openStoreAddManager','openStoreOwnerStock'}
return function(state,ports)
    local work,settings,world=assert(state.WorkMenus),assert(state.ServerSettingsMenus),assert(state.WorldClientCore)
    local client,config=assert(ports.client),assert(ports.config)
    assert(work.State==state and settings.State==state and world.State==state,'canonical state required')
    assert(work.Client==client and settings.Client==client and world.Client==client,'canonical client required')
    assert(work.Menu==settings.Menu and work.Menu==world.Menu and work.Shared==settings.Shared and work.Shared==world.Shared,'canonical Menu/Shared required')
    assert(client.WorldState==world.WorldState and config.Stores and config.Password==settings.Config.Password,'canonical world/config required')
    assert(type(state.PlayerData)=='table' and state.ProducerCore,'canonical PlayerData required')
    assert(state.StoresClientCore==nil and client.Stores==nil,'stores client already attached')
    for _,name in ipairs(methods)do assert(work.Menu[name]==nil,'stores menu already attached')end
    -- PR normalizer's identifier fallback, now reading the canonical local snapshot.
    local player={GetPlayerIdentifier=function()
        local data=state.PlayerData or {}
        return data.citizenid or data.identifier or data.charId
    end}
    local bindings={config=config,library=ports.library,native=ports.native,translate=ports.translate,
        world=world.WorldState,menu=work.Menu,shared=work.Shared,player=player}
    local runtime=createRuntime(bindings)
    local menu=createMenu(bindings)
    local api={State=state,Client=client,Config=config,World=world,WorldState=world.WorldState,Stores=runtime.Stores,
        Menu=work.Menu,Shared=work.Shared,Runtime=runtime,StoresMenu=menu,Player=player,
        Threads=runtime.Threads,Subscriptions=runtime.Subscriptions,Events=runtime.Events}
    client.Stores,state.StoresClientCore=runtime.Stores,api
    return api
end
