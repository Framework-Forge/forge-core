-- Attach local policies to the canonical graph; never initialize a second world controller.
local createWorld=require 'kernel.shared.world_state'
local createWeatherConfig=require 'kernel.config.forge_weather'
local createDensityConfig=require 'kernel.config.forge_density'
local createWeather=require 'kernel.server.weather'
local createDensity=require 'kernel.server.density'
local createDensityCallbacks=require 'kernel.server.density_callbacks'
return function(base,ports)
    local pc,catalog,groups=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.Groups)
    local transport,deps=assert(catalog.Transport),assert(catalog.Dependencies)
    local settings=assert(base.ServerSettingsCore,'settings34 required')
    assert(pc.Groups==groups and catalog.Groups==groups and base.Callbacks==transport.Security,'canonical state/Security required')
    assert(settings.Base==base and settings.Security==base.Callbacks and settings.Services.JobService==catalog.Service,'canonical settings/JobService required')
    assert(base.WorldCore==nil and deps.State==nil and deps.WeatherService==nil and deps.DensityService==nil,'world already attached')
    local cfg=ports.config or{}
    local config={Weather=cfg.Weather or createWeatherConfig(),Density=cfg.Density or createDensityConfig(),
        NotifyPos=cfg.NotifyPos,AdminAce=cfg.AdminAce}
    local library,native=assert(ports.library),assert(ports.native)
    local world=createWorld({library=library,native=native,server=true})
    local services={JobService=assert(catalog.Service)}
    local weather=createWeather({config=config,library=library,native=native,services=services})
    local density=createDensity({config=config,library=library,native=native,services=services,translate=ports.translate,world=world.State})
    local api={Base=base,PlayerCore=pc,Security=transport.Security,Settings=settings,World=world,Services=services,
        State=world.State,Config=config,Weather=weather,Density=density,Events={},Callbacks={},RawCallbacks=world.Callbacks}
    for _,entry in ipairs(world.Events)do api.Events[#api.Events+1]=entry end
    for _,entry in ipairs(density.Events)do api.Events[#api.Events+1]=entry end
    for _,entry in ipairs(weather.Callbacks)do api.Callbacks[#api.Callbacks+1]=entry end
    for _,entry in ipairs(createDensityCallbacks({config=config,service=density.Service}))do api.Callbacks[#api.Callbacks+1]=entry end
    deps.State,deps.WeatherService,deps.DensityService=world.State,weather.Service,density.Service
    base.WorldCore=api
    return api
end
