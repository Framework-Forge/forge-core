ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local alertDialog = Shared.alertDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions
local boolValue = Shared.boolValue

local actionLocked = false

local function fetchPayload()
    local ok, payload = awaitServer(PR.Vehicles.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.vehicles.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.vehicles = type(payload.vehicles) == 'table' and payload.vehicles or {}
    return payload
end

local function runAction(callbackName, failureLocale, ...)
    if actionLocked then return false end
    actionLocked = true

    local ok, response = awaitServer(callbackName, ...)
    if not ok then notifyFailure(failureLocale or 'notify.vehicles.action_failed', response) end

    SetTimeout(650, function() actionLocked = false end)
    return ok, response
end

local function statusLabel(vehicle)
    return vehicle.active == false and t('menu.vehicles.status_inactive') or t('menu.vehicles.status_active')
end

local function typeOptions(current)
    local options = {}
    local exists = false
    for index = 1, #(PR.Vehicles.Types or {}) do
        local value = PR.Vehicles.Types[index]
        if value == current then exists = true end
        options[#options + 1] = { value = value, label = value }
    end
    if current and current ~= '' and not exists then
        options[#options + 1] = { value = current, label = current }
    end
    return options
end

local function classOptions()
    local options = {}
    for index = 1, #(PR.Vehicles.Classes or {}) do
        local value = PR.Vehicles.Classes[index]
        options[#options + 1] = { value = value, label = value }
    end
    return options
end

local categoryLabels = {
    compacts = 'Compactos', sedans = 'Sedans', suvs = 'SUVs', coupes = 'Cupês', muscle = 'Muscle',
    sportsclassics = 'Esportivos clássicos', sports = 'Sport', super = 'Super', motorcycles = 'Motocicletas',
    offroad = 'Off-road', industrial = 'Industrial', utility = 'Utilitário', vans = 'Vans', cycles = 'Bicicletas',
    boats = 'Barcos', helicopters = 'Helicópteros', planes = 'Aviões', service = 'Serviço',
    emergency = 'Emergência', military = 'Militar', commercial = 'Comercial', openwheel = 'Open wheel',
}

local typeLabels = {
    automobile = 'Automóvel', bike = 'Moto', boat = 'Barco', heli = 'Helicóptero', plane = 'Avião',
    submarine = 'Submarino', trailer = 'Reboque', train = 'Trem',
}

local function categoryOptions(current)
    local options = {}
    local exists = false
    for index = 1, #(PR.Vehicles.Categories or {}) do
        local value = PR.Vehicles.Categories[index]
        if value == current then exists = true end
        options[#options + 1] = { value = value, label = categoryLabels[value] or value }
    end
    if current and current ~= '' and not exists then
        options[#options + 1] = { value = current, label = current }
    end
    return options
end

local function formatCurrency(value)
    local text = tostring(math.max(0, math.floor(tonumber(value) or 0)))
    return text:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
end

local function vehicleMetadata(vehicle)
    return {
        { label = t('menu.vehicles.metadata_name'), value = vehicle.brand .. ' ' .. vehicle.name or vehicle.model or '-' },
        --{ label = t('menu.vehicles.metadata_brand'), value = vehicle.brand ~= '' and vehicle.brand or '-' },
        { label = t('menu.vehicles.metadata_price'), value = ('R$ %s'):format(formatCurrency(vehicle.price)) },
        { label = t('menu.vehicles.metadata_stock'), value = tostring(vehicle.stock or 0) },
        { label = t('menu.vehicles.metadata_category'), value = ('%s - %s'):format(categoryLabels[vehicle.category] or vehicle.category or '-', vehicle.class or PR.Vehicles.Defaults.class) },
        { label = t('menu.vehicles.metadata_type'), value = typeLabels[vehicle.type] or vehicle.type or '-' },
        { label = t('menu.vehicles.metadata_store'), value = vehicle.store or '-' },
    }
end

local function categoryContextId(category)
    return ('forge_core_vehicles_category_%s'):format(
        tostring(category or 'uncategorized'):gsub('[^%w_%-]', '_')
    )
end
local function vehicleTitle(vehicle)
    return vehicle.brand and vehicle.brand ~= '' and (vehicle.brand .. ' ' .. vehicle.name) or vehicle.name
end
local function vehicleOption(vehicle, category)
    return {
        title = vehicleTitle(vehicle),
        description = t('menu.vehicles.entry_description', {
            status = statusLabel(vehicle),
            model = vehicle.model,
            price = tostring(vehicle.price or 0),
            class = vehicle.class or PR.Vehicles.Defaults.class,
            stock = tostring(vehicle.stock or 0),
        }),
        image = pr_lib.fivem.blips.getVehicleImageUrl(vehicle.model),
        metadata = vehicleMetadata(vehicle),
        icon = vehicle.active == false and 'car-front' or 'car-front-fill',
        iconColor = vehicle.active == false and 'red' or nil,
        arrow = true,
        onSelect = function() Menu.openVehicleDetails(vehicle, category) end,
    }
end

local function getVehicleSnapshot(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil, 'vehicle_not_found' end
    if not pr_lib or not pr_lib.fivem or type(pr_lib.fivem.getVehicleProperties) ~= 'function' then
        return nil, 'vehicle_properties_unavailable'
    end

    if not NetworkGetEntityIsNetworked(vehicle) then NetworkRegisterEntityAsNetworked(vehicle) end
    local deadline = GetGameTimer() + 3000
    while (not NetworkGetEntityIsNetworked(vehicle) or NetworkGetNetworkIdFromEntity(vehicle) == 0)
        and DoesEntityExist(vehicle) and GetGameTimer() < deadline do Wait(0) end
    if not DoesEntityExist(vehicle) or not NetworkGetEntityIsNetworked(vehicle)
        or NetworkGetNetworkIdFromEntity(vehicle) == 0 then return nil, 'vehicle_network_timeout' end
    local props = pr_lib.fivem.getVehicleProperties(vehicle)
    if type(props) ~= 'table' then return nil, 'vehicle_properties_failed' end

    local modelName
    if type(GetEntityArchetypeName) == 'function' then
        modelName = GetEntityArchetypeName(vehicle)
    end

    return {
        netId = NetworkGetNetworkIdFromEntity(vehicle),
        modelName = modelName,
        props = props,
    }
end

pr_lib.callback.register(PR.Vehicles.Callbacks.getCurrentVehicle, function()
    local ped = PlayerPedId()
    local vehicle = ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
    if vehicle == 0 then return nil, 'not_in_vehicle' end
    return getVehicleSnapshot(vehicle)
end)

local function spawnAdminVehicle(vehicle, permanent)
    if not pr_lib or not pr_lib.fivem or not pr_lib.fivem.streaming or type(pr_lib.fivem.streaming.createVehicle) ~= 'function' then
        notifyFailure('notify.vehicles.spawn_failed', 'spawn_unavailable')
        return false
    end

    local ped = PlayerPedId()
    if not ped or ped == 0 then
        notifyFailure('notify.vehicles.spawn_failed', 'ped_unavailable')
        return false
    end

    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 6.0, 0.5)
    local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 5.0, false)
    if foundGround then coords = vector3(coords.x, coords.y, groundZ + 0.15) end

    local spawned, spawnError = pr_lib.fivem.streaming.createVehicle(vehicle.model, coords, GetEntityHeading(ped), {
        networked = true,
        missionEntity = true,
        freeze = false,
        collision = true,
        timeout = 5000,
        placeProperly = true,
        placementType = 'vehicle',
    })
    if not spawned or spawned == 0 or not DoesEntityExist(spawned) then
        notifyFailure('notify.vehicles.spawn_failed', spawnError or 'create_failed')
        return false
    end

    local plate = permanent
        and ('AD%06d'):format(math.random(0, 999999))
        or ('FG%02d%03d'):format(math.random(0, 99), GetGameTimer() % 1000)
    SetVehicleNumberPlateText(spawned, plate)
    SetVehicleDoorsLocked(spawned, 1)
    SetVehicleEngineOn(spawned, true, true, false)
    SetVehicleOnGroundProperly(spawned)

    local callbackName = permanent and PR.Vehicles.Callbacks.adminCar or PR.Vehicles.Callbacks.spawn
    local snapshot, snapshotError = getVehicleSnapshot(spawned)
    if permanent and not snapshot then
        DeleteEntity(spawned)
        notifyFailure('notify.vehicles.admin_car_failed', snapshotError)
        return false
    end

    local ok, response
    if permanent then
        ok, response = awaitServer(callbackName, vehicle.model, snapshot.netId, snapshot.props)
    else
        ok, response = awaitServer(callbackName, vehicle.model, plate, NetworkGetNetworkIdFromEntity(spawned))
    end
    if not ok then
        DeleteEntity(spawned)
        notifyFailure(permanent and 'notify.vehicles.admin_car_failed' or 'notify.vehicles.spawn_failed', response)
        return false
    end

    return true
end

function Menu.openVehiclesMenu()
    local payload = fetchPayload()
    if not payload then return Menu.openServerSettingsMenu() end

    local options = {
        {
            title = t('menu.vehicles.create'),
            description = t('menu.vehicles.create_description'),
            icon = 'plus-circle-fill',
            onSelect = function() Menu.openVehicleEditor() end,
        },
        {
            title = t('menu.vehicles.import'),
            description = t('menu.vehicles.import_description'),
            icon = 'clipboard-plus',
            onSelect = function()
                local result = inputDialog(t('menu.vehicles.import'), {
                    {
                        type = 'textarea',
                        label = t('inputs.vehicle_definition'),
                        required = true,
                        autosize = true,
                    },
                })
                if not result then return Menu.openVehiclesMenu() end

                runAction(PR.Vehicles.Callbacks.importDefinition, 'notify.vehicles.import_failed', result[1])
                SetTimeout(450, function() Menu.openVehiclesMenu() end)
            end,
        },
        {
            title = t('menu.vehicles.reload'),
            description = t('menu.vehicles.reload_description'),
            icon = 'arrow-clockwise',
            onSelect = function()
                runAction(PR.Vehicles.Callbacks.reload, 'notify.vehicles.reload_failed')
                SetTimeout(450, function() Menu.openVehiclesMenu() end)
            end,
        },
    }

    local categories = {}
    for index = 1, #payload.vehicles do
        local vehicle = payload.vehicles[index]
        local category = vehicle.category and vehicle.category ~= '' and vehicle.category or 'uncategorized'
        categories[category] = (categories[category] or 0) + 1
    end
    local categoryKeys = {}
    for category in pairs(categories) do
        categoryKeys[#categoryKeys + 1] = category
    end
    table.sort(categoryKeys, function(a, b)
        return (categoryLabels[a] or a):lower() < (categoryLabels[b] or b):lower()
    end)
    for index = 1, #categoryKeys do
        local category = categoryKeys[index]
        local count = categories[category]
        options[#options + 1] = {
            title = categoryLabels[category] or (category == 'uncategorized' and t('menu.vehicles.uncategorized') or category),
            description = t('menu.vehicles.category_description', { count = tostring(count) }),
            icon = 'collection-fill',
            arrow = true,
            onSelect = function() Menu.openVehiclesCategory(category) end,
        }
    end

    showContext({
        id = 'forge_core_vehicles',
        title = t('menu.vehicles.title_count', { count = tostring(#payload.vehicles) }),
        menu = 'forge_core_server_settings',
        options = options,
    })
end

function Menu.openVehiclesCategory(category)
    local payload = fetchPayload()
    if not payload then return Menu.openVehiclesMenu() end
    local vehicles = {}
    for index = 1, #payload.vehicles do
        local vehicle = payload.vehicles[index]
        local vehicleCategory = vehicle.category and vehicle.category ~= '' and vehicle.category or 'uncategorized'
        if vehicleCategory == category then
            vehicles[#vehicles + 1] = vehicle
        end
    end
    table.sort(vehicles, function(a, b)
        return vehicleTitle(a):lower() < vehicleTitle(b):lower()
    end)
    local options = {}
    for index = 1, #vehicles do
        options[#options + 1] = vehicleOption(vehicles[index], category)
    end
    showContext({
        id = categoryContextId(category),
        title = ('%s (%d)'):format(
            categoryLabels[category] or (category == 'uncategorized' and t('menu.vehicles.uncategorized') or category),
            #vehicles
        ),
        menu = 'forge_core_vehicles',
        options = options,
    })
end
function Menu.openVehicleDetails(vehicle, category)
    local nextActive = vehicle.active == false
    local displayName = vehicleTitle(vehicle)

    showContext({
        id = 'forge_core_vehicle_' .. vehicle.model,
        title = displayName,
        menu = category and categoryContextId(category) or 'forge_core_vehicles',
        options = {
            {
                title = t('menu.vehicles.info', { model = vehicle.model }),
                description = t('menu.vehicles.details', {
                    category = vehicle.category,
                    class = vehicle.class or PR.Vehicles.Defaults.class,
                    type = vehicle.type,
                    hash = tostring(vehicle.hash or vehicle.model),
                    store = vehicle.store or t('common.none'),
                }),
                metadata = vehicleMetadata(vehicle),
                icon = vehicle.active == false and 'toggle-off' or 'toggle-on',
                iconColor = vehicle.active == false and 'red' or nil,
                disabled = true,
            },
            {
                title = t('menu.vehicles.spawn'),
                description = t('menu.vehicles.spawn_description'),
                icon = 'car-front-fill',
                iconColor = 'green',
                disabled = vehicle.active == false,
                onSelect = function()
                    spawnAdminVehicle(vehicle, false)
                end,
            },
            {
                title = t('menu.vehicles.admin_car'),
                description = t('menu.vehicles.admin_car_description'),
                icon = 'car-front-fill',
                iconColor = '#f5c542',
                disabled = vehicle.active == false,
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('menu.vehicles.admin_car'),
                        content = t('menu.vehicles.admin_car_confirm', { vehicle = vehicleTitle(vehicle) }),
                        centered = true,
                        cancel = true,
                    })
                    if confirmed == 'confirm' then spawnAdminVehicle(vehicle, true) end
                end,
            },
            {
                title = nextActive and t('menu.vehicles.activate') or t('menu.vehicles.deactivate'),
                icon = nextActive and 'toggle-on' or 'toggle-off',
                iconColor = nextActive and 'green' or 'red',
                onSelect = function()
                    runAction(PR.Vehicles.Callbacks.setActive, 'notify.vehicles.action_failed', vehicle.model, nextActive)
                    SetTimeout(450, function()
                        if category then Menu.openVehiclesCategory(category) else Menu.openVehiclesMenu() end
                    end)
                end,
            },
            {
                title = t('menu.actions.edit'),
                description = t('menu.vehicles.edit_description'),
                icon = 'pen-fill',
                onSelect = function() Menu.openVehicleEditor(vehicle, category) end,
            },
            {
                title = t('menu.actions.remove'),
                description = t('menu.vehicles.remove_description'),
                icon = 'trash-fill',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_vehicle_header'),
                        content = t('dialogs.remove_vehicle_content', { vehicle = displayName }),
                        centered = true,
                        cancel = true,
                    })
                    if confirmed == 'confirm' then
                        runAction(PR.Vehicles.Callbacks.remove, 'notify.vehicles.remove_failed', vehicle.model)
                    end
                    SetTimeout(450, function()
                        if category then Menu.openVehiclesCategory(category) else Menu.openVehiclesMenu() end
                    end)
                end,
            },
        },
    })
end

function Menu.openVehicleEditor(vehicle, category)
    vehicle = type(vehicle) == 'table' and vehicle or {}
    local isEditing = vehicle.model ~= nil
    local currentType = tostring(vehicle.type or PR.Vehicles.Defaults.type)
    local currentClass = tostring(vehicle.class or PR.Vehicles.Defaults.class)

    local result = inputDialog(isEditing and t('menu.vehicles.edit') or t('menu.vehicles.create'), {
        { type = 'input', label = t('inputs.vehicle_model'), description = t('inputs.vehicle_model_description'), default = vehicle.model or '', disabled = isEditing, required = true },
        { type = 'input', label = t('inputs.vehicle_name'), default = vehicle.name or '', required = true },
        { type = 'input', label = t('inputs.vehicle_brand'), default = vehicle.brand or '', required = true },
        { type = 'number', label = t('inputs.vehicle_price'), default = tonumber(vehicle.price) or 0, min = 0, required = true },
        { type = 'select', label = t('inputs.vehicle_category'), options = categoryOptions(vehicle.category or PR.Vehicles.Defaults.category), default = vehicle.category or PR.Vehicles.Defaults.category, searchable = true, required = true },
        { type = 'select', label = t('inputs.vehicle_class'), options = classOptions(), default = currentClass, required = true },
        { type = 'select', label = t('inputs.vehicle_type'), options = typeOptions(currentType), default = currentType, required = true },
        { type = 'input', label = t('inputs.vehicle_hash'), description = t('inputs.vehicle_hash_description'), default = tostring(vehicle.hash or vehicle.model or ''), required = true },
        { type = 'number', label = t('inputs.vehicle_stock'), default = tonumber(vehicle.stock) or 0, min = 0, required = true },
        { type = 'input', label = t('inputs.vehicle_store'), description = t('inputs.vehicle_store_description'), default = vehicle.store or '' },
        { type = 'select', label = t('inputs.vehicle_active'), options = boolOptions(), default = boolDefault(vehicle.active ~= false), required = true },
    })
    if not result then
        if category then return Menu.openVehiclesCategory(category) end
        return Menu.openVehiclesMenu()
    end

    local payload = {
        model = vehicle.model or result[1],
        name = result[2],
        brand = result[3],
        price = tonumber(result[4]) or 0,
        category = result[5],
        class = result[6],
        type = result[7],
        hash = result[8],
        stock = tonumber(result[9]) or 0,
        store = result[10],
        active = boolValue(result[11]),
    }

    local ok = runAction(PR.Vehicles.Callbacks.save, 'notify.vehicles.save_failed', payload)
    SetTimeout(450, function()
        if ok then
            if category then Menu.openVehiclesCategory(category) else Menu.openVehiclesMenu() end
        else
            Menu.openVehicleEditor(vehicle, category)
        end
    end)
end