ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Stores = {
    zones = {},
    blips = {},
    payload = nil,
}

ForgeCore.Client.Stores = Stores

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function notify(data)
    if pr_lib and pr_lib.Notify then
        pr_lib.Notify({
            title = data.title or t('stores.title'),
            description = data.description,
            type = data.type,
            position = PR.NotifyPos,
        })
    end
end

local function coordsVector(value)
    if type(value) ~= 'table' then return nil end
    local ok, vector = pcall(pr_lib.math.toVector, value)
    if ok and type(vector) == 'vector3' then return vector end
end

local function currentCitizenId()
    if not pr_lib or not pr_lib.framework or not pr_lib.framework.GetPlayerIdentifier then return '' end
    local ok, citizenid = pcall(pr_lib.framework.GetPlayerIdentifier)
    return ok and tostring(citizenid or '') or ''
end

local function hasStoreAccess(store)
    local citizenid = currentCitizenId()
    if citizenid == '' then return false end
    if tostring(store.owner or '') == citizenid then return true end

    for _, manager in ipairs(type(store.managers) == 'table' and store.managers or {}) do
        if type(manager) == 'table' and tostring(manager.citizenid or '') == citizenid then return true end
        if type(manager) == 'string' and manager == citizenid then return true end
    end

    return false
end

local function clearZones()
    if pr_lib and pr_lib.target and pr_lib.target.removeZone then
        for i = 1, #Stores.zones do
            pr_lib.target.removeZone(Stores.zones[i])
        end
    end

    Stores.zones = {}
end

local function clearBlips()
    for i = 1, #Stores.blips do
        if DoesBlipExist(Stores.blips[i]) then RemoveBlip(Stores.blips[i]) end
    end

    Stores.blips = {}
end

local function createBlip(store, coords)
    local blipData = type(store.blip) == 'table' and store.blip or nil
    if not blipData or blipData.enabled == false then return end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, tonumber(blipData.sprite or blipData.id) or 59)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, tonumber(blipData.scale) or 0.8)
    SetBlipColour(blip, tonumber(blipData.color or blipData.colour) or 69)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(store.label or store.id)
    EndTextCommandSetBlipName(blip)

    Stores.blips[#Stores.blips + 1] = blip
end

local function addStoreZone(store, point, pointIndex)
    if not pr_lib or not pr_lib.target or not pr_lib.target.addBoxZone then return end

    point = type(point) == 'table' and point or {}
    local coords = coordsVector(point.coords or point)
    if not coords then return end
    local options = {
        {
            name = ('forge_core_store_buy_%s_%s'):format(store.id, pointIndex),
            icon = 'cart-fill',
            label = tostring(store.targetLabel or '') ~= '' and store.targetLabel or t('menu.stores.open_inventory_store'),
            distance = PR.Stores.Defaults.targetDistance or 2.0,
            onSelect = function()
                if ForgeCore.Client.Menu and ForgeCore.Client.Menu.openStoreInventory then
                    ForgeCore.Client.Menu.openStoreInventory(store.id)
                else
                    notify({ description = t('notify.stores.menu_unavailable'), type = 'error' })
                end
            end,
        },
    }

    local function openStorefront()
        if ForgeCore.Client.Menu and ForgeCore.Client.Menu.openStorefront then
            ForgeCore.Client.Menu.openStorefront(store.id)
        else
            notify({ description = t('notify.stores.menu_unavailable'), type = 'error' })
        end
    end

    if tostring(store.owner or '') ~= '' then
        options[#options + 1] = {
            name = ('forge_core_store_manage_%s_%s'):format(store.id, pointIndex),
            icon = 'award-fill',
            label = t('menu.stores.owner_manage'),
            distance = PR.Stores.Defaults.targetDistance or 2.0,
            canInteract = function() return hasStoreAccess(store) end,
            onSelect = openStorefront,
        }
    end

    if tostring(store.owner or '') == '' or store.saleListed == true then
        options[#options + 1] = {
            name = ('forge_core_store_purchase_%s_%s'):format(store.id, pointIndex),
            icon = 'shop',
            label = t('menu.stores.buy_store', { price = tostring(store.purchasePrice or 0) }),
            distance = PR.Stores.Defaults.targetDistance or 2.0,
            canInteract = function() return not hasStoreAccess(store) end,
            onSelect = openStorefront,
        }
    end

    local zoneId = pr_lib.target.addBoxZone({
        coords = coords,
        size = PR.Stores.Defaults.targetSize or vec3(0.8, 0.8, 1.4),
        rotation = tonumber(point.rotation or point.heading or store.rotation) or 0.0,
        debug = PR.Debug == true,
        options = options,
    })

    if zoneId then Stores.zones[#Stores.zones + 1] = zoneId end
    if pointIndex == 1 then createBlip(store, coords) end
end

function Stores.refresh(payload)
    clearZones()
    clearBlips()

    payload = type(payload) == 'table' and payload or {}
    Stores.payload = payload

    local settings = type(payload.settings) == 'table' and payload.settings or {}
    if settings.enabled == false then return end

    for _, store in ipairs(type(payload.stores) == 'table' and payload.stores or {}) do
        if type(store) == 'table' and store.enabled ~= false then
            local points = type(store.points) == 'table' and store.points or {}
            if #points == 0 and store.coords then points = { { coords = store.coords, rotation = store.rotation } } end
            for pointIndex, point in ipairs(points) do
                addStoreZone(store, point, pointIndex)
            end
        end
    end
end

AddStateBagChangeHandler('forgeStores', 'global', function(_, _, value)
    Stores.refresh(value)
end)

CreateThread(function()
    Wait(2000)
    Stores.refresh(GlobalState.forgeStores)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearZones()
    clearBlips()
end)
