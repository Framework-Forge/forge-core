-- Explicit PR panel gap; never call external resources directly from the kernel.
return function(ports)
    local Menu,Shared,PR=assert(ports.menu),assert(ports.shared),assert(ports.config)
    local integration=assert(ports.weatherAdminIntegration)
    local GetCurrentResourceName=assert(assert(ports.native).GetCurrentResourceName)
    assert(type(integration.resourceState)=='function' and type(integration.openWeatherAdmin)=='function','PR weather admin integration required')
local t = Shared.t
local notify = Shared.notify

-- O construtor persistente do Renewed-Weathersync substitui a antiga fila
-- transitória da Forge Core. Este ponto permanece estável para os demais menus.
function Menu.openWeatherTimeMenu()
    local resource = PR.Weather.Resource or 'Renewed-Weathersync'
    if integration.resourceState(resource) ~= 'started' then
        notify({
            title = t('menu.weather.title'),
            description = t('notify.weather.load_failed'),
            type = 'error',
        })
        return false
    end

    local ok, opened = pcall(function()
        return integration.openWeatherAdmin(resource,'forge_core_server_settings', GetCurrentResourceName())
    end)

    if not ok or opened == false then
        notify({
            title = t('menu.weather.title'),
            description = t('notify.weather.load_failed'),
            type = 'error',
        })
        return false
    end

    return true
end
    return {Menu=Menu,Shared=Shared}
end
