ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared
local t = Shared.t
local notify = Shared.notify

-- O construtor persistente do Renewed-Weathersync substitui a antiga fila
-- transitória da Forge Core. Este ponto permanece estável para os demais menus.
function Menu.openWeatherTimeMenu()
    local resource = PR.Weather.Resource or 'Renewed-Weathersync'
    if GetResourceState(resource) ~= 'started' then
        notify({
            title = t('menu.weather.title'),
            description = t('notify.weather.load_failed'),
            type = 'error',
        })
        return false
    end

    local ok, opened = pcall(function()
        return exports[resource]:OpenWeatherAdmin('forge_core_server_settings', GetCurrentResourceName())
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