-- Private port of installed QBX bridge/qb/client/functions.lua; see NOTICE-90.md and LICENSE-QBX.
-- Includes installed modified Overextended vehicle property setter, preserved verbatim behind ports.
return function(ports)
for _,key in ipairs({'core','inventory','library','helpers','native','cache'})do assert(type(ports[key])=='table','QB client port required: '..key)end
assert(type(ports.core.GetPlayerData)=='function'and type(ports.core.Notify)=='function','canonical PlayerData/Notify required')
-- Canonical core services supplied explicitly.
local functions = {}

-- Player

---@deprecated import PlayerData using module 'qbx_core:playerdata' https://docs.qbox.re/resources/qbx_core/modules/playerdata
---@param cb? fun(playerData: PlayerData)
---@return PlayerData? playerData
function functions.GetPlayerData(cb)
    if not cb then return ports.core.GetPlayerData() end
    cb(ports.core.GetPlayerData())
end

---@deprecated use the ports.native.GetEntityCoords and ports.native.GetEntityHeading natives directly
functions.GetCoords = function(entity) -- luacheck: ignore
    local coords = ports.native.GetEntityCoords(entity)
    return ports.native.vec4(coords.x, coords.y, coords.z, ports.native.GetEntityHeading(entity))
end

---@deprecated use https://coxdocs.dev/ox_inventory/Functions/Client#search
functions.HasItem = function(items, amount)
    amount = amount or 1
    local count = ports.inventory.search('count', items)
    if type(items) == 'table' and type(count) == 'table' then
        for _, v in pairs(count) do
            if v < amount then
                return false
            end
        end
        return true
    end
    return count >= amount
end

-- Utility

---@deprecated use ports.helpers.drawText2d from modules/ports.library.lua
functions.DrawText = function(x, y, width, height, scale, r, g, b, a, text)
    ports.helpers.drawText2d({
        text = text,
        coords = ports.native.vec2(x, y),
        scale = scale,
        font = 4,
        color = ports.native.vec4(r, g, b, a),
        width = width,
        height = height,
    })
end

---@deprecated use ports.helpers.drawText3d from modules/ports.library.lua
functions.DrawText3D = function(x, y, z, text)
    ports.helpers.drawText3d({
        text = text,
        coords = ports.native.vec3(x, y, z),
        scale = 0.35,
        font = 4,
        color = ports.native.vec4(255, 255, 255, 215)
    })
end

---@deprecated use ports.library.requestAnimDict from ox_lib
functions.RequestAnimDict = ports.library.requestAnimDict

---@deprecated use ports.library.requestAnimDict from ox_lib, and the TaskPlayAnim and RemoveAnimDict natives directly
functions.PlayAnim = function(animDict, animName, upperbodyOnly, duration)
    local flags = upperbodyOnly and 16 or 0
    local runTime = duration or -1
    ports.library.playAnim(ports.cache.ped, animDict, animName, 8.0, 3.0, runTime, flags, 0.0, false, false, true)
end

---@deprecated use ports.library.requestModel from ox_lib
functions.LoadModel = ports.library.requestModel

---@deprecated use ports.library.requestAnimSet from ox_lib
functions.LoadAnimSet = ports.library.requestAnimSet

---@deprecated use ports.library.progressBar from ox_lib
---@param label string
---@param duration integer ms
---@param useWhileDead boolean
---@param canCancel boolean
---@param disableControls? {disableMovement: boolean, disableCarMovement: boolean, disableCombat: boolean, disableMouse: boolean}
---@param animation? {animDict: string, anim: string, flags: unknown}
---@param prop? {model: string, bone?: number, coords?: vector3|table, rotation?: vector3|table}
---@param propTwo? {model: string, bone?: number, coords?: vector3|table, rotation?: vector3|table}
---@param onFinish fun()
---@param onCancel fun()
function functions.Progressbar(_, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    local props

    if (prop and prop.model) then
        local propData = {
            model = prop.model,
            bone = prop.bone,
            pos = prop.coords,
            rot = prop.rotation,
        }

        if (propTwo and propTwo.model) then
            props = {
                propData,
                {
                    model = propTwo.model,
                    bone = propTwo.bone,
                    pos = propTwo.coords,
                    rot = propTwo.rotation,
                },
            }
        else
            props = propData
        end
    end

    if ports.library.progressBar({
        duration = duration,
        label = label,
        useWhileDead = useWhileDead,
        canCancel = canCancel,
        disable = {
            move = (disableControls and disableControls.disableMovement),
            car = (disableControls and disableControls.disableCarMovement),
            combat = (disableControls and disableControls.disableCombat),
            mouse = (disableControls and disableControls.disableMouse),
        },
        anim = {
            dict = (animation and animation.animDict),
            clip = (animation and animation.anim),
            flags = (animation and animation.flags)
        },
        prop = props,
    }) then
        if onFinish then
            onFinish()
        end
    else
        if onCancel then
            onCancel()
        end
    end
end

-- Getters

---@param pool string
---@param ignoreList? integer[]
---@return integer[]
local function getEntities(pool, ignoreList) -- luacheck: ignore
    ignoreList = ignoreList or {}
    local ents = ports.native.GetGamePool(pool)
    local entities = {}
    local ignoreMap = {}
    for i = 1, #ignoreList do
        ignoreMap[ignoreList[i]] = true
    end

    for i = 1, #ents do
        local entity = ents[i]
        if not ignoreMap[entity] then
            entities[#entities + 1] = entity
        end
    end
    return entities
end

---@deprecated use the ports.native.GetGamePool('CVehicle') native directly
functions.GetVehicles = function()
    return ports.native.GetGamePool('CVehicle')
end

---@deprecated use the ports.native.GetGamePool('CObject') native directly
functions.GetObjects = function()
    return ports.native.GetGamePool('CObject')
end

---@deprecated use the GetActivePlayers native directly
functions.GetPlayers = ports.native.GetActivePlayers

---@deprecated use the ports.native.GetGamePool('CPed') native directly
functions.GetPeds = function(ignoreList)
    return getEntities('CPed', ignoreList)
end

---@param entities integer[]
---@param coords vector3? if unset uses player coords
---@return integer closestObj or -1
---@return number closestDistance or -1
local function getClosestEntity(entities, coords) -- luacheck: ignore
    coords = type(coords) == 'table' and ports.native.vec3(coords.x, coords.y, coords.z) or coords or ports.native.GetEntityCoords(ports.cache.ped)
    local closestDistance = -1
    local closestEntity = -1
    for i = 1, #entities do
        local entity = entities[i]
        local entityCoords = ports.native.GetEntityCoords(entity)
        local distance = #(entityCoords - coords)
        if closestDistance == -1 or closestDistance > distance then
            closestEntity = entity
            closestDistance = distance
        end
    end
    return closestEntity, closestDistance
end

---@deprecated use ports.library.getClosestPed from ox_lib
---Use GetClosestPlayer if wanting to ignore non-player peds
functions.GetClosestPed = function(coords, ignoreList)
    return getClosestEntity(getEntities('CPed', ignoreList), coords)
end

---@deprecated use ports.helpers.isWearingGloves from modules/ports.library.lua
functions.IsWearingGloves = ports.helpers.isWearingGloves

---@deprecated use ports.library.getClosestPlayer from ox_lib
functions.GetClosestPlayer = function(coords) -- luacheck: ignore
    coords = type(coords) == 'table' and ports.native.vec3(coords.x, coords.y, coords.z) or coords or ports.native.GetEntityCoords(ports.cache.ped)
    local playerId, _, playerCoords = ports.library.getClosestPlayer(coords, 5, false)
    local closestDistance = playerCoords and #(playerCoords - coords) or nil
    return playerId or -1, closestDistance or -1
end

---@deprecated use ports.library.getNearbyPlayers from ox_lib
functions.GetPlayersFromCoords = function(coords, radius)
    coords = type(coords) == 'table' and ports.native.vec3(coords.x, coords.y, coords.z) or coords or ports.native.GetEntityCoords(ports.cache.ped)
    local players = ports.library.getNearbyPlayers(coords, radius or 5, true)

    -- This is for backwards compatability as beforehand it only returned the PlayerId, where Lib returns PlayerPed, PlayerId and PlayerCoords
    for i = 1, #players do
        players[i] = players[i].id
    end

    return players
end

---@deprecated use ports.library.getClosestVehicle from ox_lib
functions.GetClosestVehicle = function(coords)
    return getClosestEntity(ports.native.GetGamePool('CVehicle'), coords)
end

---@deprecated use ports.library.getClosestObject from ox_lib
functions.GetClosestObject = function(coords)
    return getClosestEntity(ports.native.GetGamePool('CObject'), coords)
end

---@deprecated use the ports.native.GetWorldPositionOfEntityBone native and calculate distance directly
functions.GetClosestBone = function(entity, list)
    local playerCoords = ports.native.GetEntityCoords(ports.cache.ped)

    ---@type integer | {id: integer} | {id: integer, type: string, name: string}, vector3, number
    local bone, coords, distance
    for _, element in pairs(list) do
        local boneCoords = ports.native.GetWorldPositionOfEntityBone(entity, element.id or element)
        local boneDistance = #(playerCoords - boneCoords)
        if not coords or distance > boneDistance then
            bone = element
            coords = boneCoords
            distance = boneDistance
        end
    end
    if not bone then
        bone = {id = ports.native.GetEntityBoneIndexByName(entity, 'bodyshell'), type = 'remains', name = 'bodyshell'}
        coords = ports.native.GetWorldPositionOfEntityBone(entity, bone.id)
        distance = #(coords - playerCoords)
    end
    return bone, coords, distance
end

---@deprecated use the ports.native.GetWorldPositionOfEntityBone native and calculate distance directly
functions.GetBoneDistance = function(entity, boneType, bone)
    local boneIndex = boneType == 1 and ports.native.GetPedBoneIndex(entity, bone --[[@as integer]]) or ports.native.GetEntityBoneIndexByName(entity, bone --[[@as string]])
    local boneCoords = ports.native.GetWorldPositionOfEntityBone(entity, boneIndex)
    local playerCoords = ports.native.GetEntityCoords(ports.cache.ped)
    return #(playerCoords - boneCoords)
end

---@deprecated use the ports.native.AttachEntityToEntity native directly
functions.AttachProp = function(ped, model, boneId, x, y, z, xR, yR, zR, vertex)
    local modelHash = type(model) == 'string' and ports.native.joaat(model) or model
    local bone = ports.native.GetPedBoneIndex(ped, boneId)
    ports.library.requestModel(modelHash)
    local prop = ports.native.CreateObject(modelHash, 1.0, 1.0, 1.0, true, true, false)
    ports.native.AttachEntityToEntity(prop, ped, bone, x, y, z, xR, yR, zR, true, true, false, true, not vertex and 2 or 0, true)
    ports.native.SetModelAsNoLongerNeeded(modelHash)
    return prop
end

-- Vehicle

---@deprecated use ports.helpers.spawnVehicle from modules/ports.library.lua
---@param model string|number
---@param cb? fun(vehicle: number)
---@param coords? vector4 player position if not specified
---@param isnetworked? boolean defaults to true
---@param teleportInto boolean teleport player to driver seat if true
function functions.SpawnVehicle(model, cb, coords, isnetworked, teleportInto)
    local playerCoords = ports.native.GetEntityCoords(ports.cache.ped)
    local combinedCoords = ports.native.vec4(playerCoords.x, playerCoords.y, playerCoords.z, ports.native.GetEntityHeading(ports.cache.ped))
    coords = type(coords) == 'table' and ports.native.vec4(coords.x, coords.y, coords.z, coords.w or combinedCoords.w) or coords or combinedCoords
    model = type(model) == 'string' and ports.native.joaat(model) or model
    if not ports.native.IsModelInCdimage(model) then return end

    isnetworked = isnetworked == nil or isnetworked
    ports.library.requestModel(model)
    local veh = ports.native.CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
    local netid = ports.native.NetworkGetNetworkIdFromEntity(veh)
    ports.native.SetVehicleHasBeenOwnedByPlayer(veh, true)
    ports.native.SetNetworkIdCanMigrate(netid, true)
    ports.native.SetVehicleNeedsToBeHotwired(veh, false)
    ports.native.SetVehRadioStation(veh, 'OFF')
    ports.native.SetVehicleFuelLevel(veh, 100.0)
    ports.native.SetModelAsNoLongerNeeded(model)
    if teleportInto then ports.native.TaskWarpPedIntoVehicle(ports.cache.ped, veh, -1) end
    if cb then cb(veh) end
end

---@deprecated use ports.helpers.deleteVehicle from modules/ports.library.lua
functions.DeleteVehicle = ports.helpers.deleteVehicle

---@deprecated use ports.helpers.getVehiclePlate from modules/ports.library.lua
functions.GetPlate = function(vehicle)
    if vehicle == 0 then return end
    return ports.helpers.getVehiclePlate(vehicle)
end

---@deprecated use ports.helpers.getVehicleDisplayName from modules/ports.library.lua
functions.GetVehicleLabel = function(vehicle)
    if vehicle == nil or vehicle == 0 then return end
    return ports.helpers.getVehicleDisplayName(vehicle)
end

---@deprecated use ports.library.getNearbyVehicles from ox_lib
functions.SpawnClear = function(coords, radius)
    coords = type(coords) == 'table' and ports.native.vec3(coords.x, coords.y, coords.z) or coords or ports.native.GetEntityCoords(ports.cache.ped)
    radius = radius or 5
    local vehicles = ports.native.GetGamePool('CVehicle')
    local closeVeh = {}
    for i = 1, #vehicles do
        local vehicleCoords = ports.native.GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)
        if distance <= radius then
            closeVeh[#closeVeh + 1] = vehicles[i]
        end
    end
    return #closeVeh == 0
end

---@deprecated use ports.library.getVehicleProperties from ox_lib
function functions.GetVehicleProperties(vehicle)
    local props = ports.library.getVehicleProperties(vehicle)
    if not props then return end

    local tireHealth = {}
        for i = 0, 3 do
            tireHealth[i] = ports.native.GetVehicleWheelHealth(vehicle, i)
        end

    local tireBurstState = {}
    local tireBurstCompletely = {}

    for i = 0, 7 do
        local damage = props.tyres[i]
        tireBurstState[i] = damage == 1 or damage == 2
        tireBurstCompletely[i] = damage == 2
    end

    local windowStatus = {}
    for i = 0, 7 do
        windowStatus[i] = ports.native.IsVehicleWindowIntact(vehicle, i)
    end

    local doorStatus = {}
    for i = 0, 5 do
        doorStatus[i] = ports.native.IsVehicleDoorDamaged(vehicle, i) == 1
    end

    -- qb properties not in ox
    props.tireHealth = tireHealth
    props.tireBurstState = tireBurstState
    props.tireBurstCompletely = tireBurstCompletely
    props.windowStatus = windowStatus
    props.doorStatus = doorStatus
    props.headlightColor = ports.native.GetVehicleHeadlightsColour(vehicle)
    props.modKit17 = props.modNitrous
    props.modKit19 = props.modSubwoofer
    props.modKit21 = props.modHydraulics
    props.modKit47 = props.modDoorR
    props.modKit49 = props.modLightbar
    props.liveryRoof = props.modRoofLivery

    return props
end

local gameBuild = ports.native.GetGameBuildNumber()

---@deprecated use ports.library.setVehicleProperties from ox_lib
function functions.SetVehicleProperties(vehicle, props)
    if props.tireHealth and not props.tyres then
        for wheelIndex, health in pairs(props.tireHealth) do
            ports.native.SetVehicleWheelHealth(vehicle, wheelIndex, health)
        end
    end
    if props.headlightColor then
        ports.native.SetVehicleHeadlightsColour(vehicle, props.headlightColor)
    end

    if (props.tireBurstCompletely or props.tireBurstState) and not props.tyres then
        props.tyres = {}
        for i = 0, 7 do
            props.tyres[i] = props.tireBurstCompletely and props.tireBurstCompletely[i] and 2 or props.tireBurstState and props.tireBurstState[i] and 1 or nil
        end
    end

    local numWindowsDamaged = 0
    if props.windowStatus and not props.windows then
        props.windows = {}
        for i, isDamaged in pairs(props.windowStatus) do
            if isDamaged then
                numWindowsDamaged = numWindowsDamaged + 1
                props.windows[numWindowsDamaged] = i
            end
        end
    end

    local numDoorsDamaged = 0
    if props.doorStatus and not props.doors then
        props.doors = {}
        for i, isDamaged in pairs(props.doorStatus) do
            if isDamaged then
                numDoorsDamaged = numDoorsDamaged + 1
                props.doors[numDoorsDamaged] = i
            end
        end
    end

    -- qb properties converted to ox
    props.modNitrous = props.modNitrous or props.modKit17
    props.modSubwoofer = props.modSubwoofer or props.modKit17
    props.modHydraulics = props.modHydraulics or props.modKit21
    props.modDoorR = props.modDoorR or props.modKit47
    props.modLightbar = props.modLightbar or props.modKit49
    props.modRoofLivery = props.modRoofLivery or props.liveryRoof

    --- ports.library.setVehicleProperties copied and pasted from Overextended below so that we can remove the error so that setting properties is best effort
    assert(ports.native.DoesEntityExist(vehicle), ('Unable to set vehicle properties for "%s" (entity does not exist)'):format(vehicle))

    if ports.native.NetworkGetEntityIsNetworked(vehicle) and ports.native.NetworkGetEntityOwner(vehicle) ~= ports.cache.playerId then
        ports.library.print.warn('setting vehicle properties on non entity owner client. This may cause certain properties to fail to set. entity:', vehicle)
    end

    local colorPrimary, colorSecondary = ports.native.GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = ports.native.GetVehicleExtraColours(vehicle)

    ports.native.SetVehicleModKit(vehicle, 0)
    -- ports.native.SetVehicleAutoRepairDisabled(vehicle, true)

    if props.extras then
        for id, disable in pairs(props.extras) do
            ports.native.SetVehicleExtra(vehicle, tonumber(id) --[[@as number]], disable == 1)
        end
    end

    if props.plate then
        ports.native.SetVehicleNumberPlateText(vehicle, props.plate)
    end

    if props.plateIndex then
        ports.native.SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
    end

    if props.bodyHealth then
        ports.native.SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
    end

    if props.engineHealth then
        ports.native.SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
    end

    if props.tankHealth then
        ports.native.SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
    end

    if props.fuelLevel then
        ports.native.SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
    end

    if props.oilLevel then
        ports.native.SetVehicleOilLevel(vehicle, props.oilLevel + 0.0)
    end

    if props.dirtLevel then
        ports.native.SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
    end

    if props.color1 then
        if type(props.color1) == 'number' then
            ports.native.ClearVehicleCustomPrimaryColour(vehicle)
            ports.native.SetVehicleColours(vehicle, props.color1 --[[@as number]], colorSecondary --[[@as number]])
        else
            if props.paintType1 then ports.native.SetVehicleModColor_1(vehicle, props.paintType1, colorPrimary, pearlescentColor) end

            ports.native.SetVehicleCustomPrimaryColour(vehicle, props.color1[1], props.color1[2], props.color1[3])
        end
    end

    if props.color2 then
        if type(props.color2) == 'number' then
            ports.native.ClearVehicleCustomSecondaryColour(vehicle)
            ports.native.SetVehicleColours(vehicle, props.color1 or colorPrimary --[[@as number]], props.color2 --[[@as number]])
        else
            if props.paintType2 then ports.native.SetVehicleModColor_2(vehicle, props.paintType2, colorSecondary) end

            ports.native.SetVehicleCustomSecondaryColour(vehicle, props.color2[1], props.color2[2], props.color2[3])
        end
    end

    if props.pearlescentColor or props.wheelColor then
        ports.native.SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor or wheelColor)
    end

    if props.interiorColor then
        ports.native.SetVehicleInteriorColor(vehicle, props.interiorColor)
    end

    if props.dashboardColor then
        ports.native.SetVehicleDashboardColor(vehicle, props.dashboardColor)
    end

    if props.wheels then
        ports.native.SetVehicleWheelType(vehicle, props.wheels)
    end

    if props.wheelSize then
        ports.native.SetVehicleWheelSize(vehicle, props.wheelSize)
    end

    if props.wheelWidth then
        ports.native.SetVehicleWheelWidth(vehicle, props.wheelWidth)
    end

    if props.windowTint then
        ports.native.SetVehicleWindowTint(vehicle, props.windowTint)
    end

    if props.neonEnabled then
        for i = 1, #props.neonEnabled do
            ports.native.SetVehicleNeonLightEnabled(vehicle, i - 1, props.neonEnabled[i])
        end
    end

    if props.windows then
        for i = 1, #props.windows do
            ports.native.RemoveVehicleWindow(vehicle, props.windows[i])
        end
    end

    if props.doors then
        for i = 1, #props.doors do
            ports.native.SetVehicleDoorBroken(vehicle, props.doors[i], true)
        end
    end

    if props.tyres then
        for tyre, state in pairs(props.tyres) do
            ports.native.SetVehicleTyreBurst(vehicle, tonumber(tyre) --[[@as number]], state == 2, 1000.0)
        end
    end

    if props.neonColor then
        ports.native.SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end

    if props.modSmokeEnabled ~= nil then
        ports.native.ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled)
    end

    if props.tyreSmokeColor then
        ports.native.SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end

    if props.modSpoilers then
        ports.native.SetVehicleMod(vehicle, 0, props.modSpoilers, false)
    end

    if props.modFrontBumper then
        ports.native.SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
    end

    if props.modRearBumper then
        ports.native.SetVehicleMod(vehicle, 2, props.modRearBumper, false)
    end

    if props.modSideSkirt then
        ports.native.SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
    end

    if props.modExhaust then
        ports.native.SetVehicleMod(vehicle, 4, props.modExhaust, false)
    end

    if props.modFrame then
        ports.native.SetVehicleMod(vehicle, 5, props.modFrame, false)
    end

    if props.modGrille then
        ports.native.SetVehicleMod(vehicle, 6, props.modGrille, false)
    end

    if props.modHood then
        ports.native.SetVehicleMod(vehicle, 7, props.modHood, false)
    end

    if props.modFender then
        ports.native.SetVehicleMod(vehicle, 8, props.modFender, false)
    end

    if props.modRightFender then
        ports.native.SetVehicleMod(vehicle, 9, props.modRightFender, false)
    end

    if props.modRoof then
        ports.native.SetVehicleMod(vehicle, 10, props.modRoof, false)
    end

    if props.modEngine then
        ports.native.SetVehicleMod(vehicle, 11, props.modEngine, false)
    end

    if props.modBrakes then
        ports.native.SetVehicleMod(vehicle, 12, props.modBrakes, false)
    end

    if props.modTransmission then
        ports.native.SetVehicleMod(vehicle, 13, props.modTransmission, false)
    end

    if props.modHorns then
        ports.native.SetVehicleMod(vehicle, 14, props.modHorns, false)
    end

    if props.modSuspension then
        ports.native.SetVehicleMod(vehicle, 15, props.modSuspension, false)
    end

    if props.modArmor then
        ports.native.SetVehicleMod(vehicle, 16, props.modArmor, false)
    end

    if props.modNitrous then
        ports.native.SetVehicleMod(vehicle, 17, props.modNitrous, false)
    end

    if props.modTurbo ~= nil then
        ports.native.ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end

    if props.modSubwoofer ~= nil then
        ports.native.ToggleVehicleMod(vehicle, 19, props.modSubwoofer)
    end

    if props.modHydraulics ~= nil then
        ports.native.ToggleVehicleMod(vehicle, 21, props.modHydraulics)
    end

    if props.modXenon ~= nil then
        ports.native.ToggleVehicleMod(vehicle, 22, props.modXenon)
    end

    if props.xenonColor then
        ports.native.SetVehicleXenonLightsColor(vehicle, props.xenonColor)
    end

    if props.modFrontWheels then
        ports.native.SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomTiresF)
    end

    if props.modBackWheels then
        ports.native.SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomTiresR)
    end

    if props.modPlateHolder then
        ports.native.SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
    end

    if props.modVanityPlate then
        ports.native.SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
    end

    if props.modTrimA then
        ports.native.SetVehicleMod(vehicle, 27, props.modTrimA, false)
    end

    if props.modOrnaments then
        ports.native.SetVehicleMod(vehicle, 28, props.modOrnaments, false)
    end

    if props.modDashboard then
        ports.native.SetVehicleMod(vehicle, 29, props.modDashboard, false)
    end

    if props.modDial then
        ports.native.SetVehicleMod(vehicle, 30, props.modDial, false)
    end

    if props.modDoorSpeaker then
        ports.native.SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
    end

    if props.modSeats then
        ports.native.SetVehicleMod(vehicle, 32, props.modSeats, false)
    end

    if props.modSteeringWheel then
        ports.native.SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
    end

    if props.modShifterLeavers then
        ports.native.SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
    end

    if props.modAPlate then
        ports.native.SetVehicleMod(vehicle, 35, props.modAPlate, false)
    end

    if props.modSpeakers then
        ports.native.SetVehicleMod(vehicle, 36, props.modSpeakers, false)
    end

    if props.modTrunk then
        ports.native.SetVehicleMod(vehicle, 37, props.modTrunk, false)
    end

    if props.modHydrolic then
        ports.native.SetVehicleMod(vehicle, 38, props.modHydrolic, false)
    end

    if props.modEngineBlock then
        ports.native.SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
    end

    if props.modAirFilter then
        ports.native.SetVehicleMod(vehicle, 40, props.modAirFilter, false)
    end

    if props.modStruts then
        ports.native.SetVehicleMod(vehicle, 41, props.modStruts, false)
    end

    if props.modArchCover then
        ports.native.SetVehicleMod(vehicle, 42, props.modArchCover, false)
    end

    if props.modAerials then
        ports.native.SetVehicleMod(vehicle, 43, props.modAerials, false)
    end

    if props.modTrimB then
        ports.native.SetVehicleMod(vehicle, 44, props.modTrimB, false)
    end

    if props.modTank then
        ports.native.SetVehicleMod(vehicle, 45, props.modTank, false)
    end

    if props.modWindows then
        ports.native.SetVehicleMod(vehicle, 46, props.modWindows, false)
    end

    if props.modDoorR then
        ports.native.SetVehicleMod(vehicle, 47, props.modDoorR, false)
    end

    if props.modLivery then
        ports.native.SetVehicleMod(vehicle, 48, props.modLivery, false)
        ports.native.SetVehicleLivery(vehicle, props.modLivery)
    end

    if props.modRoofLivery then
        ports.native.SetVehicleRoofLivery(vehicle, props.modRoofLivery)
    end

    if props.modLightbar then
        ports.native.SetVehicleMod(vehicle, 49, props.modLightbar, false)
    end

    if props.bulletProofTyres ~= nil then
        ports.native.SetVehicleTyresCanBurst(vehicle, props.bulletProofTyres)
    end

    if gameBuild >= 2372 and props.driftTyres then
        ports.native.SetDriftTyresEnabled(vehicle, true)
    end

    return true
end

---@deprecated use ports.library.requestNamedPtfxAsset from ox_lib
functions.LoadParticleDictionary = ports.library.requestNamedPtfxAsset

---@deprecated use ParticleFx natives directly
functions.StartParticleAtCoord = function(dict, ptName, looped, coords, rot, scale, alpha, color, duration) -- luacheck: ignore
    coords = type(coords) == 'table' and ports.native.vec3(coords.x, coords.y, coords.z) or coords or ports.native.GetEntityCoords(ports.cache.ped)

    ports.library.requestNamedPtfxAsset(dict)
    ports.native.UseParticleFxAssetNextCall(dict)
    ports.native.SetPtfxAssetNextCall(dict)
    local particleHandle
    if looped then
        particleHandle = ports.native.StartParticleFxLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false, false)
        if color then
            ports.native.SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
        end
        ports.native.SetParticleFxLoopedAlpha(particleHandle, alpha or 10.0)
        if duration then
            ports.native.Wait(duration)
            ports.native.StopParticleFxLooped(particleHandle, false)
        end
    else
        ports.native.SetParticleFxNonLoopedAlpha(alpha or 1.0)
        if color then
            ports.native.SetParticleFxNonLoopedColour(color.r, color.g, color.b)
        end
        ports.native.StartParticleFxNonLoopedAtCoord(ptName, coords.x, coords.y, coords.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
    end
    return particleHandle
end

---@deprecated use ParticleFx natives directly
functions.StartParticleOnEntity = function(dict, ptName, looped, entity, bone, offset, rot, scale, alpha, color, evolution, duration) -- luacheck: ignore
    ports.library.requestNamedPtfxAsset(dict)
    ports.native.UseParticleFxAssetNextCall(dict)
    local particleHandle = nil
    ---@cast bone number
    local pedBoneIndex = bone and ports.native.GetPedBoneIndex(entity, bone) or 0
    ---@cast bone string
    local nameBoneIndex = bone and ports.native.GetEntityBoneIndexByName(entity, bone) or 0
    local entityType = ports.native.GetEntityType(entity)
    local boneID = entityType == 1 and (pedBoneIndex ~= 0 and pedBoneIndex) or (looped and nameBoneIndex ~= 0 and nameBoneIndex)
    if looped then
        if boneID then
            particleHandle = ports.native.StartParticleFxLoopedOnEntityBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale or 1.0, false, false, false)
        else
            particleHandle = ports.native.StartParticleFxLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
        end
        if evolution then
            ports.native.SetParticleFxLoopedEvolution(particleHandle, evolution.name, evolution.amount, false)
        end
        if color then
            ports.native.SetParticleFxLoopedColour(particleHandle, color.r, color.g, color.b, false)
        end
        ports.native.SetParticleFxLoopedAlpha(particleHandle, alpha or 1.0)
        if duration then
            ports.native.Wait(duration)
            ports.native.StopParticleFxLooped(particleHandle, false)
        end
    else
        ports.native.SetParticleFxNonLoopedAlpha(alpha or 1.0)
        if color then
            ports.native.SetParticleFxNonLoopedColour(color.r, color.g, color.b)
        end
        if boneID then
            ports.native.StartParticleFxNonLoopedOnPedBone(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneID, scale or 1.0, false, false, false)
        else
            ports.native.StartParticleFxNonLoopedOnEntity(ptName, entity, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
        end
    end
    return particleHandle
end

---@deprecated use ports.helpers.getStreetName from modules/ports.library.lua
functions.GetStreetNametAtCoords = ports.helpers.getStreetName

---@deprecated use ports.helpers.getZoneName from modules/ports.library.lua
functions.GetZoneAtCoords = ports.helpers.getZoneName

---@deprecated use ports.helpers.getCardinalDirection from modules/ports.library.lua
functions.GetCardinalDirection = function(entity)
    if not entity or not ports.native.DoesEntityExist(entity) then
        return 'Cardinal Direction Error'
    end

    return ports.helpers.getCardinalDirection(entity)
end

---@deprecated use the ports.native.GetClockMinutes and ports.native.GetClockHours natives and format the output directly
functions.GetCurrentTime = function()
    local obj = {}
    obj.min = ports.native.GetClockMinutes()
    obj.hour = ports.native.GetClockHours()

    if obj.hour <= 12 then
        obj.ampm = 'AM'
    elseif obj.hour >= 13 then
        obj.ampm = 'PM'
        obj.formattedHour = obj.hour - 12
    end

    if obj.min <= 9 then
        obj.formattedMin = ('0%s'):format(obj.min)
    end

    return obj
end

---@deprecated use the ports.native.GetGroundZFor_3dCoord native directly
functions.GetGroundZCoord = function(coords)
    if not coords then return end

    local retval, groundZ = ports.native.GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    if retval then
        return ports.native.vec3(coords.x, coords.y, groundZ)
    end

    ports.library.print.verbose('Couldn\'t find Ground Z Coordinates given 3D Coordinates:', coords)
    return coords
end

---Text box popup for player which dissappears after a set time.
---@param text table|string text of the notification
---@param notifyType? NotificationType informs default styling. Defaults to 'inform'
---@param duration? integer milliseconds notification will remain on screen. Defaults to 5000
---@param subTitle? string extra text under the title
---@param notifyPosition? NotificationPosition
---@param notifyStyle? table Custom styling. Please refer too https://coxdocs.dev/ox_lib/Modules/Interface/Client/notify#libnotify
---@param notifyIcon? string Font Awesome 6 icon name
---@param notifyIconColor? string Custom color for the icon chosen before
function functions.Notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    ports.core.Notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
end

return functions

end
