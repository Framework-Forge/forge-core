return function(ports)
    local PR,library,native=assert(ports.config),assert(ports.library),assert(ports.native)
    local world,Menu,translate,player=assert(ports.world),assert(ports.menu),assert(ports.translate),assert(ports.player)
    local api={Threads={},Events={},Subscriptions={}}
    local function describeThread(fn)api.Threads[#api.Threads+1]=fn end
    local function listen(name,handler)api.Events[#api.Events+1]={name=name,handler=handler,network=false}end
    local function subscribe(key,handler)api.Subscriptions[#api.Subscriptions+1]={key=key,handler=handler}end
    local DoesBlipExist=assert(native.DoesBlipExist)
    local RemoveBlip=assert(native.RemoveBlip)
    local AddBlipForCoord=assert(native.AddBlipForCoord)
    local SetBlipSprite=assert(native.SetBlipSprite)
    local SetBlipDisplay=assert(native.SetBlipDisplay)
    local SetBlipScale=assert(native.SetBlipScale)
    local SetBlipColour=assert(native.SetBlipColour)
    local SetBlipAsShortRange=assert(native.SetBlipAsShortRange)
    local BeginTextCommandSetBlipName=assert(native.BeginTextCommandSetBlipName)
    local AddTextComponentSubstringPlayerName=assert(native.AddTextComponentSubstringPlayerName)
    local EndTextCommandSetBlipName=assert(native.EndTextCommandSetBlipName)
    local Wait=assert(native.Wait)
    local SetTimeout=assert(native.SetTimeout)
    local GetCurrentResourceName=assert(native.GetCurrentResourceName)
    local vec3=assert(native.vec3)
local Stores = {
    zones = {},
    blips = {},
    payload = nil,
    ready = false,
}

api.Stores = Stores

local function t(key, params)
    return translate(key, params)
end

local function notify(data)
    if library and library.Notify then
        library.Notify({
            title = data.title or t('stores.title'),
            description = data.description,
            type = data.type,
            position = PR.NotifyPos,
        })
    end
end

local function coordsVector(value)
    if type(value) ~= 'table' then return nil end
    local ok, vector = pcall(library.math.toVector, value)
    if ok and type(vector) == 'vector3' then return vector end
end

local function currentCitizenId()
    if not library or not player or not player.GetPlayerIdentifier then return '' end
    local ok, citizenid = pcall(player.GetPlayerIdentifier)
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
    if library and library.target and library.target.removeZone then
        for i = 1, #Stores.zones do
            library.target.removeZone(Stores.zones[i])
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
    if not library or not library.target or not library.target.addBoxZone then return false end

    point = type(point) == 'table' and point or {}
    local coords = coordsVector(point.coords or point)
    if not coords then return false end
    local options = {
        {
            name = ('forge_core_store_buy_%s_%s'):format(store.id, pointIndex),
            icon = 'cart-fill',
            label = tostring(store.targetLabel or '') ~= '' and store.targetLabel or t('menu.stores.open_inventory_store'),
            distance = PR.Stores.Defaults.targetDistance or 2.0,
            onSelect = function()
                if Menu and Menu.openStoreInventory then
                    Menu.openStoreInventory(store.id)
                else
                    notify({ description = t('notify.stores.menu_unavailable'), type = 'error' })
                end
            end,
        },
    }

    local function openStorefront()
        if Menu and Menu.openStorefront then
            Menu.openStorefront(store.id)
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

    local ok, zoneId = pcall(library.target.addBoxZone, {
        name = ('forge_core_store_%s_%s'):format(store.id, pointIndex),
        coords = coords,
        size = PR.Stores.Defaults.targetSize or vec3(0.8, 0.8, 1.4),
        rotation = tonumber(point.rotation or point.heading or store.rotation) or 0.0,
        debug = PR.Debug == true,
        options = options,
    })

    if not ok or not zoneId then
        print(('[forge-core:stores] falha no target %s/%s: %s'):format(store.id, pointIndex, tostring(zoneId)))
        return false
    end
    Stores.zones[#Stores.zones + 1] = zoneId
    if pointIndex == 1 then createBlip(store, coords) end
    return true
end

local function equal(a, b)
    if a == b then return true end
    if type(a) ~= 'table' or type(b) ~= 'table' then return false end
    for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end

local zoneFields = { 'id', 'enabled', 'label', 'targetLabel', 'owner', 'managers',
    'saleListed', 'purchasePrice', 'points', 'coords', 'rotation', 'blip' }
local function sameZones(previous, nextPayload)
    if type(previous) ~= 'table' or type(nextPayload) ~= 'table' then return false end
    if not equal((previous.settings or {}).enabled, (nextPayload.settings or {}).enabled) then return false end
    local oldStores, newStores = previous.stores or {}, nextPayload.stores or {}
    if #oldStores ~= #newStores then return false end
    for index, store in ipairs(newStores) do
        for _, field in ipairs(zoneFields) do
            if not equal((oldStores[index] or {})[field], store[field]) then return false end
        end
    end
    return true
end

function Stores.refresh(payload)
    if Stores.ready and sameZones(Stores.payload, payload) then
        Stores.payload = payload
        return -- Financial/stock updates must not recreate every target and blip.
    end
    clearZones()
    clearBlips()

    payload = type(payload) == 'table' and payload or {}
    Stores.payload = payload
    Stores.ready = true

    local settings = type(payload.settings) == 'table' and payload.settings or {}
    if settings.enabled == false then return end

    local storeCount, pointCount = 0, 0
    for _, store in ipairs(type(payload.stores) == 'table' and payload.stores or {}) do
        if type(store) == 'table' and store.enabled ~= false then
            storeCount = storeCount + 1
            local points = type(store.points) == 'table' and store.points or {}
            if #points == 0 and store.coords then points = { { coords = store.coords, rotation = store.rotation } } end
            for pointIndex, point in ipairs(points) do
                pointCount = pointCount + 1
                if not addStoreZone(store, point, pointIndex) then Stores.ready = false end
            end
        end
    end
    if storeCount > 0 then
        print(('[forge-core:stores] lojas=%s pontos=%s targets=%s pronto=%s'):format(
            storeCount, pointCount, #Stores.zones, tostring(Stores.ready)))
    end
end

subscribe('stores', function(value)
    Stores.refresh(value)
end)

describeThread(function()
    Wait(2000)
    Stores.refresh(world.get('stores'))
end)

-- Rehydrate on lifecycle events only; no recurring scans or network polling.
listen('pr_bridge:client:OnPlayerLoaded', function()
    Stores.refresh(world.get('stores'))
end)
listen('onClientResourceStop', function(resource)
    if resource ~= 'pr_bridge' then return end
    Stores.zones = {}
    Stores.ready = false
    clearBlips()
end)
listen('onClientResourceStart', function(resource)
    if resource ~= 'pr_bridge' then return end
    SetTimeout(0, function() Stores.refresh(world.get('stores') or Stores.payload) end)
end)

listen('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    clearZones()
    clearBlips()
end)
    return api
end
