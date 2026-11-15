local createMenu=require 'kernel.client.menu.vehicles'
return function(state,ports)
    local work,settings,producer=assert(state.WorkMenus),assert(state.ServerSettingsMenus),assert(state.ProducerCore)
    local client=assert(ports.client)
    assert(work.State==state and settings.State==state and producer.State==state,'canonical state required')
    assert(work.Client==client and settings.Client==client and work.Menu==settings.Menu and work.Shared==settings.Shared,'canonical settings Menu/Shared required')
    assert(state.VehicleMenus==nil,'vehicle menus already attached')
    for _,name in ipairs({'openVehiclesMenu','openVehiclesCategory','openVehicleDetails','openVehicleEditor'})do
        assert(work.Menu[name]==nil,'vehicle menu already attached: '..name)
    end
    local config=assert(ports.config)
    assert(config.Vehicles and config.Password==settings.Config.Password,'canonical config required')
    local api=createMenu({menu=work.Menu,shared=work.Shared,config=config,library=ports.library,native=ports.native,random=ports.random})
    api.State,api.Client,api.Producer,api.Settings,api.Config=state,client,producer,settings,config
    state.VehicleMenus=api
    return api
end
