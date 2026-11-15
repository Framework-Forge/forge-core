-- Whole nine administrative routes. Native world and external PR effects remain explicit.
return function(ports)
    local PR,library,native=assert(ports.config),assert(ports.library),assert(ports.native)
    local service,translate,kernel=assert(ports.service),assert(ports.translate),assert(ports.kernel)
    local integration,json=assert(ports.vehicleIntegration),assert(ports.json)
    assert(type(integration.resourceState)=='function' and type(integration.buyOriginalKey)=='function'
        and type(integration.registerExistingPersistentVehicle)=='function','PR original-key/garage integration required')
    local callbacks={}
    local function describeCallback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler,options={access='admin'}}end
    local joaat=assert(native.joaat)
    local GetPlayerName=assert(native.GetPlayerName)
    local NetworkGetEntityFromNetworkId=assert(native.NetworkGetEntityFromNetworkId)
    local GetGameTimer=assert(native.GetGameTimer)
    local DoesEntityExist=assert(native.DoesEntityExist)
    local Wait=assert(native.Wait)
    local GetEntityType=assert(native.GetEntityType)
    local GetPlayerPed=assert(native.GetPlayerPed)
    local GetVehiclePedIsIn=assert(native.GetVehiclePedIsIn)
    local GetEntityCoords=assert(native.GetEntityCoords)
    local GetEntityModel=assert(native.GetEntityModel)
    local GetVehicleNumberPlateText=assert(native.GetVehicleNumberPlateText)
    local SetVehicleNumberPlateText=assert(native.SetVehicleNumberPlateText)
describeCallback(PR.Vehicles.Callbacks.getAll, function(source)
    if not service.canManage(source) then return false, 'no_permission' end
    return true, service.getPayload()
end)

describeCallback(PR.Vehicles.Callbacks.save, function(source, data)
    if not service.canManage(source) then return false, 'no_permission' end
    local ok, result = service.upsert(data)
    if ok then
        local name = result.name or result.model
        if library and library.notify and library.notify.NotifyPlayer then
            library.notify.NotifyPlayer(source, {
                title = translate('menu.vehicles.title'),
                description = translate('notify.vehicles.saved', { vehicle = name }),
                type = 'success',
                position = PR.NotifyPos,
            })
        end
    end
    return ok, result
end)

describeCallback(PR.Vehicles.Callbacks.remove, function(source, model)
    if not service.canManage(source) then return false, 'no_permission' end
    local ok, result = service.remove(model)
    if ok and library and library.notify and library.notify.NotifyPlayer then
        library.notify.NotifyPlayer(source, {
            title = translate('menu.vehicles.title'),
            description = translate('notify.vehicles.removed', { vehicle = tostring(model) }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end
    return ok, result
end)

describeCallback(PR.Vehicles.Callbacks.setActive, function(source, model, active)
    if not service.canManage(source) then return false, 'no_permission' end
    local ok, result = service.setActive(model, active)
    if ok and library and library.notify and library.notify.NotifyPlayer then
        library.notify.NotifyPlayer(source, {
            title = translate('menu.vehicles.title'),
            description = translate(active == true and 'notify.vehicles.activated' or 'notify.vehicles.deactivated', {
                vehicle = result.name or result.model,
            }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end
    return ok, result
end)

describeCallback(PR.Vehicles.Callbacks.reload, function(source)
    if not service.canManage(source) then return false, 'no_permission' end
    local ok, result = service.reload()
    if ok and library and library.notify and library.notify.NotifyPlayer then
        library.notify.NotifyPlayer(source, {
            title = translate('menu.vehicles.title'),
            description = translate('notify.vehicles.reloaded', { count = tostring(result or 0) }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end
    return ok, result
end)

describeCallback(PR.Vehicles.Callbacks.importDefinition, function(source, snippet)
    if not service.canManage(source) then return false, 'no_permission' end
    local ok, result = service.importDefinition(snippet)
    if ok and library and library.notify and library.notify.NotifyPlayer then
        library.notify.NotifyPlayer(source, {
            title = translate('menu.vehicles.title'),
            description = translate('notify.vehicles.imported', { count = tostring(result or 0) }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end
    return ok, result
end)
local function giveSpawnKey(source, plate, netId)
    local vehicleKey = library and library.vehicle_key
    if type(vehicleKey) ~= 'table' or type(vehicleKey.GiveTempKeys) ~= 'function' then
        return false, 'vehicle_key_unavailable'
    end

    local ok, result = pcall(vehicleKey.GiveTempKeys, source, plate)
    if not ok or result == false then return false, 'vehicle_key_failed' end

    if type(vehicleKey.GiveKeyItem) == 'function' then
        local itemOk, itemResult = pcall(vehicleKey.GiveKeyItem, source, plate, netId)
        if not itemOk or itemResult == false or itemResult == nil then
            if type(vehicleKey.RemoveTempKeys) == 'function' then
                pcall(vehicleKey.RemoveTempKeys, source, plate)
            end
            return false, 'vehicle_key_item_failed'
        end
    end

    return true
end

describeCallback(PR.Vehicles.Callbacks.spawn, function(source, model, plate, netId)
    if not service.canManage(source) then return false, 'no_permission' end

    local vehicle = service.getEntry(model)
    if not vehicle then return false, 'not_found' end
    if vehicle.active == false then return false, 'vehicle_inactive' end

    plate = tostring(plate or ''):upper():gsub('%s+', '')
    if plate == '' or #plate > 8 or not plate:match('^[%w]+$') then return false, 'invalid_plate' end

    local ok, keyErr = giveSpawnKey(source, plate, tonumber(netId) or 0)
    if not ok then return false, keyErr end

    if library and library.notify and library.notify.NotifyPlayer then
        library.notify.NotifyPlayer(source, {
            title = translate('menu.vehicles.title'),
            description = translate('notify.vehicles.spawned', { vehicle = vehicle.name or vehicle.model, plate = plate }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end

    return true
end)

local function notifyAdminCar(source, description, notificationType)
    if source == 0 or not library or not library.notify or not library.notify.NotifyPlayer then return end
    library.notify.NotifyPlayer(source, {
        title = translate('menu.vehicles.title'),
        description = description,
        type = notificationType or 'success',
        position = PR.NotifyPos,
    })
end

local function sanitizeOwnedPlate(value)
    value = tostring(value or ''):upper():gsub('%s+', '')
    if value == '' or #value > 8 or not value:match('^[%w]+$') then return nil end
    return value
end

local function resolveVehicleModel(modelHash, expectedModel, clientModel)
    expectedModel = tostring(expectedModel or ''):lower()
    clientModel = tostring(clientModel or ''):lower()

    if expectedModel ~= '' and joaat(expectedModel) == modelHash then return expectedModel end
    if clientModel ~= '' and joaat(clientModel) == modelHash then return clientModel end

    local payload = service.getPayload()
    for index = 1, #(payload.vehicles or {}) do
        local entry = payload.vehicles[index]
        if joaat(entry.model) == modelHash then return entry.model end
    end

    return nil
end

local function rollbackOwnedVehicle(insertId)
    if not insertId or not library or not library.database or type(library.database.execute) ~= 'function' then return end
    pcall(library.database.execute, 'DELETE FROM player_vehicles WHERE id = ?', { insertId })
end

local function registerAdminCar(source, target, snapshot, expectedModel, requireOccupant)
    if not service.canManage(source) then return false, 'no_permission' end
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return false, 'invalid_player' end
    if type(snapshot) ~= 'table' or type(snapshot.props) ~= 'table' then return false, 'invalid_vehicle_data' end

    local netId = tonumber(snapshot.netId) or 0
    local vehicle = netId > 0 and NetworkGetEntityFromNetworkId(netId) or 0
    -- Um spawn recente pode ainda estar em replicacao no servidor.
    local deadline = GetGameTimer() + 3000
    while netId > 0 and (vehicle == 0 or not DoesEntityExist(vehicle)) and GetGameTimer() < deadline do
        Wait(50)
        vehicle = NetworkGetEntityFromNetworkId(netId)
    end
    if vehicle == 0 or not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return false, 'vehicle_not_found'
    end

    local targetPed = GetPlayerPed(target)
    if requireOccupant then
        if targetPed == 0 or GetVehiclePedIsIn(targetPed, false) ~= vehicle then return false, 'player_not_in_vehicle' end
    else
        local sourcePed = GetPlayerPed(source)
        if sourcePed == 0 or #(GetEntityCoords(sourcePed) - GetEntityCoords(vehicle)) > 25.0 then
            return false, 'vehicle_too_far'
        end
    end

    local modelHash = GetEntityModel(vehicle)
    local modelName = resolveVehicleModel(modelHash, expectedModel, snapshot.modelName)
    if not modelName then return false, 'invalid_vehicle_model' end
    if tostring(expectedModel or '') ~= '' and joaat(tostring(expectedModel):lower()) ~= modelHash then
        return false, 'vehicle_model_mismatch'
    end

    local plate = sanitizeOwnedPlate(GetVehicleNumberPlateText(vehicle))
    if not plate then return false, 'invalid_plate' end

    local database = library and library.database
    if type(database) ~= 'table' or type(database.scalar) ~= 'function' or type(database.insert) ~= 'function' then
        return false, 'database_unavailable'
    end

    local duplicateOk, duplicateCount = pcall(
        database.scalar,
        'SELECT COUNT(*) FROM player_vehicles WHERE plate = ? OR fakeplate = ?',
        { plate, plate }
    )
    if not duplicateOk then return false, 'vehicle_database_check_failed' end
    if (tonumber(duplicateCount) or 0) > 0 then
        return false, 'vehicle_already_owned'
    end

    local player = kernel.getPlayer(target)
    if not player or not player.PlayerData then return false, 'invalid_player' end
    if not player.PlayerData.license or not player.PlayerData.citizenid then return false, 'missing_player_identity' end

    local props = snapshot.props
    props.model = modelHash
    props.plate = plate
    SetVehicleNumberPlateText(vehicle, plate)

    local encodedOk, encodedProps = pcall(json.encode, props)
    if not encodedOk or type(encodedProps) ~= 'string' then return false, 'vehicle_properties_failed' end
    if #encodedProps > 262144 then return false, 'vehicle_properties_too_large' end

    local insertOk, insertId = pcall(database.insert,
        'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            player.PlayerData.license,
            player.PlayerData.citizenid,
            modelName,
            modelHash,
            encodedProps,
            plate,
            0,
        }
    )
    if not insertOk or not insertId then return false, 'vehicle_insert_failed' end

    if not integration.resourceState('pr_carkeys'):find('start') then
        rollbackOwnedVehicle(insertId)
        return false, 'vehicle_key_unavailable'
    end

    local keyOk, keyResult = pcall(function()
        return integration.buyOriginalKey(target, plate)
    end)
    if not keyOk or type(keyResult) ~= 'table' or keyResult.success ~= true then
        rollbackOwnedVehicle(insertId)
        return false, type(keyResult) == 'table' and keyResult.reason or 'vehicle_key_failed'
    end

    if kernel.resourceState():find('start') then
        pcall(function() kernel.enablePersistence(vehicle) end)
    end
    if integration.resourceState('forge-garage'):find('start') then
        integration.registerExistingPersistentVehicle(-1, plate, netId)
    end

    local vehicleLabel = modelName
    local catalogEntry = service.getEntry(modelName)
    if catalogEntry then vehicleLabel = catalogEntry.name or catalogEntry.model end

    notifyAdminCar(target, translate('notify.vehicles.admin_car_received', {
        vehicle = vehicleLabel,
        plate = plate,
    }))
    if source ~= target then
        notifyAdminCar(source, translate('notify.vehicles.admin_car_given', {
            vehicle = vehicleLabel,
            plate = plate,
            player = GetPlayerName(target) or tostring(target),
        }))
    end

    return true, { id = insertId, plate = plate, model = modelName, target = target }
end

describeCallback(PR.Vehicles.Callbacks.adminCar, function(source, model, netId, props)
    local entry = service.getEntry(model)
    if not entry then return false, 'not_found' end
    if entry.active == false then return false, 'vehicle_inactive' end

    return registerAdminCar(source, source, {
        netId = netId,
        props = props,
    }, entry.model, false)
end)

describeCallback(PR.Vehicles.Callbacks.adminCarCurrent, function(source, target)
    if not service.canManage(source) then return false, 'no_permission' end
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return false, 'invalid_player' end
    if not library or not library.callback or type(library.callback.awaitClient) ~= 'function' then
        return false, 'client_callback_unavailable'
    end

    local snapshot, clientError = library.callback.awaitClient(
        target,
        PR.Vehicles.Callbacks.getCurrentVehicle,
        7000
    )
    if type(snapshot) ~= 'table' then return false, clientError or 'player_not_in_vehicle' end

    return registerAdminCar(source, target, snapshot, nil, true)
end)
    return {Callbacks=callbacks}
end
