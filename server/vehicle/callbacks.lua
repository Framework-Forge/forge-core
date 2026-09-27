ForgeCore = ForgeCore or {}

ForgeCore.Callbacks.register(PR.Vehicles.Callbacks.getAll, function(source)
    if not ForgeCore.VehicleService.canManage(source) then return false, 'no_permission' end
    return true, ForgeCore.VehicleService.getPayload()
end)

ForgeCore.Callbacks.register(PR.Vehicles.Callbacks.save, function(source, data)
    if not ForgeCore.VehicleService.canManage(source) then return false, 'no_permission' end
    local ok, result = ForgeCore.VehicleService.upsert(data)
    if ok then
        local name = result.name or result.model
        if pr_lib and pr_lib.notify and pr_lib.notify.NotifyPlayer then
            pr_lib.notify.NotifyPlayer(source, {
                title = ForgeCore.t('menu.vehicles.title'),
                description = ForgeCore.t('notify.vehicles.saved', { vehicle = name }),
                type = 'success',
                position = PR.NotifyPos,
            })
        end
    end
    return ok, result
end)

ForgeCore.Callbacks.register(PR.Vehicles.Callbacks.remove, function(source, model)
    if not ForgeCore.VehicleService.canManage(source) then return false, 'no_permission' end
    local ok, result = ForgeCore.VehicleService.remove(model)
    if ok and pr_lib and pr_lib.notify and pr_lib.notify.NotifyPlayer then
        pr_lib.notify.NotifyPlayer(source, {
            title = ForgeCore.t('menu.vehicles.title'),
            description = ForgeCore.t('notify.vehicles.removed', { vehicle = tostring(model) }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end
    return ok, result
end)

ForgeCore.Callbacks.register(PR.Vehicles.Callbacks.setActive, function(source, model, active)
    if not ForgeCore.VehicleService.canManage(source) then return false, 'no_permission' end
    local ok, result = ForgeCore.VehicleService.setActive(model, active)
    if ok and pr_lib and pr_lib.notify and pr_lib.notify.NotifyPlayer then
        pr_lib.notify.NotifyPlayer(source, {
            title = ForgeCore.t('menu.vehicles.title'),
            description = ForgeCore.t(active == true and 'notify.vehicles.activated' or 'notify.vehicles.deactivated', {
                vehicle = result.name or result.model,
            }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end
    return ok, result
end)

ForgeCore.Callbacks.register(PR.Vehicles.Callbacks.reload, function(source)
    if not ForgeCore.VehicleService.canManage(source) then return false, 'no_permission' end
    local ok, result = ForgeCore.VehicleService.reload()
    if ok and pr_lib and pr_lib.notify and pr_lib.notify.NotifyPlayer then
        pr_lib.notify.NotifyPlayer(source, {
            title = ForgeCore.t('menu.vehicles.title'),
            description = ForgeCore.t('notify.vehicles.reloaded', { count = tostring(result or 0) }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end
    return ok, result
end)

ForgeCore.Callbacks.register(PR.Vehicles.Callbacks.importDefinition, function(source, snippet)
    if not ForgeCore.VehicleService.canManage(source) then return false, 'no_permission' end
    local ok, result = ForgeCore.VehicleService.importDefinition(snippet)
    if ok and pr_lib and pr_lib.notify and pr_lib.notify.NotifyPlayer then
        pr_lib.notify.NotifyPlayer(source, {
            title = ForgeCore.t('menu.vehicles.title'),
            description = ForgeCore.t('notify.vehicles.imported', { count = tostring(result or 0) }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end
    return ok, result
end)
local function giveSpawnKey(source, plate, netId)
    local vehicleKey = pr_lib and pr_lib.vehicle_key
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

ForgeCore.Callbacks.register(PR.Vehicles.Callbacks.spawn, function(source, model, plate, netId)
    if not ForgeCore.VehicleService.canManage(source) then return false, 'no_permission' end

    local vehicle = ForgeCore.VehicleService.getEntry(model)
    if not vehicle then return false, 'not_found' end
    if vehicle.active == false then return false, 'vehicle_inactive' end

    plate = tostring(plate or ''):upper():gsub('%s+', '')
    if plate == '' or #plate > 8 or not plate:match('^[%w]+$') then return false, 'invalid_plate' end

    local ok, keyErr = giveSpawnKey(source, plate, tonumber(netId) or 0)
    if not ok then return false, keyErr end

    if pr_lib and pr_lib.notify and pr_lib.notify.NotifyPlayer then
        pr_lib.notify.NotifyPlayer(source, {
            title = ForgeCore.t('menu.vehicles.title'),
            description = ForgeCore.t('notify.vehicles.spawned', { vehicle = vehicle.name or vehicle.model, plate = plate }),
            type = 'success',
            position = PR.NotifyPos,
        })
    end

    return true
end)

local function notifyAdminCar(source, description, notificationType)
    if source == 0 or not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end
    pr_lib.notify.NotifyPlayer(source, {
        title = ForgeCore.t('menu.vehicles.title'),
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

    local payload = ForgeCore.VehicleService.getPayload()
    for index = 1, #(payload.vehicles or {}) do
        local entry = payload.vehicles[index]
        if joaat(entry.model) == modelHash then return entry.model end
    end

    return nil
end

local function rollbackOwnedVehicle(insertId)
    if not insertId or not pr_lib or not pr_lib.database or type(pr_lib.database.execute) ~= 'function' then return end
    pcall(pr_lib.database.execute, 'DELETE FROM player_vehicles WHERE id = ?', { insertId })
end

local function registerAdminCar(source, target, snapshot, expectedModel, requireOccupant)
    if not ForgeCore.VehicleService.canManage(source) then return false, 'no_permission' end
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

    local database = pr_lib and pr_lib.database
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

    local player = exports.qbx_core:GetPlayer(target)
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

    if not GetResourceState('pr_carkeys'):find('start') then
        rollbackOwnedVehicle(insertId)
        return false, 'vehicle_key_unavailable'
    end

    local keyOk, keyResult = pcall(function()
        return exports.pr_carkeys:BuyOriginalKey(target, plate)
    end)
    if not keyOk or type(keyResult) ~= 'table' or keyResult.success ~= true then
        rollbackOwnedVehicle(insertId)
        return false, type(keyResult) == 'table' and keyResult.reason or 'vehicle_key_failed'
    end

    if GetResourceState('qbx_core'):find('start') then
        pcall(function() exports.qbx_core:EnablePersistence(vehicle) end)
    end
    if GetResourceState('forge-garage'):find('start') then
        TriggerClientEvent('forge_garage:client:registerExistingPersistentVehicle', -1, plate, netId)
    end

    local vehicleLabel = modelName
    local catalogEntry = ForgeCore.VehicleService.getEntry(modelName)
    if catalogEntry then vehicleLabel = catalogEntry.name or catalogEntry.model end

    notifyAdminCar(target, ForgeCore.t('notify.vehicles.admin_car_received', {
        vehicle = vehicleLabel,
        plate = plate,
    }))
    if source ~= target then
        notifyAdminCar(source, ForgeCore.t('notify.vehicles.admin_car_given', {
            vehicle = vehicleLabel,
            plate = plate,
            player = GetPlayerName(target) or tostring(target),
        }))
    end

    return true, { id = insertId, plate = plate, model = modelName, target = target }
end

ForgeCore.Callbacks.register(PR.Vehicles.Callbacks.adminCar, function(source, model, netId, props)
    local entry = ForgeCore.VehicleService.getEntry(model)
    if not entry then return false, 'not_found' end
    if entry.active == false then return false, 'vehicle_inactive' end

    return registerAdminCar(source, source, {
        netId = netId,
        props = props,
    }, entry.model, false)
end)

ForgeCore.Callbacks.register(PR.Vehicles.Callbacks.adminCarCurrent, function(source, target)
    if not ForgeCore.VehicleService.canManage(source) then return false, 'no_permission' end
    target = tonumber(target)
    if not target or not GetPlayerName(target) then return false, 'invalid_player' end
    if not pr_lib or not pr_lib.callback or type(pr_lib.callback.awaitClient) ~= 'function' then
        return false, 'client_callback_unavailable'
    end

    local snapshot, clientError = pr_lib.callback.awaitClient(
        target,
        PR.Vehicles.Callbacks.getCurrentVehicle,
        7000
    )
    if type(snapshot) ~= 'table' then return false, clientError or 'player_not_in_vehicle' end

    return registerAdminCar(source, target, snapshot, nil, true)
end)