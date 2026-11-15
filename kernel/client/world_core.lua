-- The settings34 controller and one public world view, separate from the player producer.
local createWorld=require 'kernel.shared.world_state'
local createDensity=require 'kernel.client.density'
local createDensityMenu=require 'kernel.client.menu.density'
local createWeatherMenu=require 'kernel.client.menu.weather'
return function(state,ports)
    local work,settings,producer=assert(state.WorkMenus),assert(state.ServerSettingsMenus),assert(state.ProducerCore)
    local client=assert(ports.client)
    assert(work.State==state and settings.State==state and producer.State==state,'canonical state required')
    assert(client==work.Client and client==settings.Client and work.Menu==settings.Menu and work.Shared==settings.Shared,'canonical settings Menu/Shared required')
    assert(state.WorldClientCore==nil and client.WorldState==nil,'world client already attached')
    for _,name in ipairs({'openWeatherTimeMenu','openDensityMenu','openDensityGeneralEditor','openDensityValuesEditor','openDensityPopulationEditor','openDensityBlacklistEditor'})do
        assert(work.Menu[name]==nil,'world menu already attached: '..name)
    end
    local config,library,native=assert(ports.config),assert(ports.library),assert(ports.native)
    assert(config.Weather and config.Density and config.Password==settings.Config.Password and config.Afk==settings.Config.Afk,'canonical settings config required')
    local world=createWorld({library=library,native=native,server=false})
    local density=createDensity({config=config,native=native,world=world.State})
    local bindings={config=config,native=native,menu=work.Menu,shared=work.Shared,weatherAdminIntegration=ports.weatherAdminIntegration}
    -- Validate the external boundary before attaching either menu.
    local weatherMenu=createWeatherMenu(bindings)
    local densityMenu=createDensityMenu(bindings)
    local api={State=state,Client=client,Producer=producer,Settings=settings,Config=config,World=world,WorldState=world.State,
        Density=density,WeatherMenu=weatherMenu,DensityMenu=densityMenu,Menu=work.Menu,Shared=work.Shared,
        Events=world.Events,Callbacks=world.Callbacks,Threads={}}
    for _,handler in ipairs(world.Threads)do api.Threads[#api.Threads+1]=handler end
    for _,handler in ipairs(density.Threads)do api.Threads[#api.Threads+1]=handler end
    client.WorldState,state.WorldClientCore=world.State,api
    return api
end
