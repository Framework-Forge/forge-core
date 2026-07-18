ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Sit = {
    cooldown = false,
    active = false,
    current = nil,
}

ForgeCore.Client.Sit = Sit

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function notify(description, notifyType)
    if pr_lib and pr_lib.notify and pr_lib.notify.Notify then
        pr_lib.notify.Notify({
            title = t('sit.title'),
            description = description,
            type = notifyType or 'inform',
            position = PR.NotifyPos,
        })
    end
end

local function toStateCoords(coords)
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
    }
end

local function fromStateCoords(coords)
    coords = type(coords) == 'table' and coords or {}
    return vector3(tonumber(coords.x or coords[1]) or 0.0, tonumber(coords.y or coords[2]) or 0.0, tonumber(coords.z or coords[3]) or 0.0)
end

local function normaliseVector(value)
    local magnitude = math.sqrt(value.x * value.x + value.y * value.y + value.z * value.z)
    if magnitude < 0.0001 then return vector3(0.0, 0.0, 0.0) end

    return vector3(value.x / magnitude, value.y / magnitude, value.z / magnitude)
end

local function safeGroundZ(coords)
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
    return found and groundZ or coords.z
end

local function raycast(startPos, endPos, ignore)
    local ray = StartShapeTestRay(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos.z, 31, ignore or PlayerPedId(), 0)
    local _, hit, hitCoords, normal, entity = GetShapeTestResult(ray)

    if hit ~= 1 then return nil end

    return {
        coords = hitCoords,
        normal = normal,
        entity = entity ~= 0 and entity or 0,
    }
end

local function detectSurface()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local right = vector3(-forward.y, forward.x, 0.0)
    local bestHit
    local highestHitZOff = 0.0
    local shortestDist = 999.0
    local heights = { -0.5, -0.4, -0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3, 0.5, 0.7, 1.0, 1.5 }

    for _, zOff in ipairs(heights) do
        for _, sideOffset in ipairs({ 0.0, -0.15, 0.15 }) do
            local startPos = vector3(coords.x + right.x * sideOffset, coords.y + right.y * sideOffset, coords.z + zOff)
            local hit = raycast(startPos, startPos + forward * (PR.Sit.RayDistance or 0.8), ped)

            if hit then
                if zOff > highestHitZOff then highestHitZOff = zOff end

                local distance = #(coords - hit.coords)
                if distance < shortestDist then
                    shortestDist = distance
                    bestHit = {
                        hitCoords = hit.coords,
                        normal = hit.normal,
                        entity = hit.entity,
                        highestHitZOff = highestHitZOff,
                        cameFromSweep = true,
                    }
                end
            end
        end
    end

    if not bestHit then
        local edgeStart = vector3(coords.x, coords.y, coords.z + 0.5)
        local edgeHit = raycast(edgeStart, edgeStart + forward * 0.7 + vector3(0.0, 0.0, -1.0), ped)

        if edgeHit then
            local groundStart = edgeStart + forward * 1.0
            local groundHit = raycast(groundStart, groundStart + vector3(0.0, 0.0, -2.0), ped)

            if not groundHit then
                bestHit = {
                    hitCoords = edgeHit.coords,
                    edge = edgeHit.coords,
                    normal = -forward,
                    entity = edgeHit.entity,
                    highestHitZOff = 0.0,
                    cameFromStanding = true,
                }
            end
        end
    end

    if not bestHit then
        local foundFloorOnce = false
        local scanDistance = tonumber(PR.Sit.GroundScanDistance) or 1.5

        for i = -10, math.floor(scanDistance * 10) do
            local distance = i * 0.1
            local scanStart = coords + forward * distance + vector3(0.0, 0.0, 0.45)
            local hit = raycast(scanStart, scanStart + vector3(0.0, 0.0, -2.2), ped)

            if hit then
                foundFloorOnce = true
            elseif foundFloorOnce and distance >= 0.05 then
                local finalEdge

                for back = 1, 10 do
                    local subDistance = distance - back * 0.01
                    local subStart = coords + forward * subDistance + vector3(0.0, 0.0, 0.45)
                    local subHit = raycast(subStart, subStart + vector3(0.0, 0.0, -1.2), ped)

                    if subHit then
                        finalEdge = coords + forward * subDistance
                        break
                    end
                end

                finalEdge = finalEdge or coords + forward * (distance - 0.1)
                bestHit = {
                    hitCoords = finalEdge,
                    edge = finalEdge,
                    normal = -forward,
                    entity = 0,
                    highestHitZOff = 0.0,
                }
                break
            end
        end
    end

    local isGround = false
    if not bestHit then
        local groundHit = raycast(coords + vector3(0.0, 0.0, 0.5), coords + vector3(0.0, 0.0, -1.0), ped)
        if not groundHit then return nil end

        bestHit = {
            hitCoords = groundHit.coords,
            normal = forward * -1.0,
            entity = 0,
            edge = groundHit.coords,
            highestHitZOff = 0.0,
        }
        isGround = true
    end

    local hitCoords = bestHit.hitCoords
    local bestTop = bestHit.edge

    if not isGround and not bestTop then
        local highestZ = -99.0

        for i = 0, 18 do
            local depth = (i - 3) * 0.04
            local testPoint = hitCoords + forward * depth
            local topHit = raycast(vector3(testPoint.x, testPoint.y, hitCoords.z + 1.5), vector3(testPoint.x, testPoint.y, hitCoords.z - 1.0), ped)

            if topHit then
                local heightDiff = topHit.coords.z - hitCoords.z
                if topHit.coords.z > highestZ and heightDiff < 0.8 and heightDiff > -0.4 then
                    highestZ = topHit.coords.z
                    bestTop = topHit.coords
                end
            end
        end
    end

    local isLeanFallback = false
    if not bestTop then
        if #(coords - hitCoords) >= 1.0 then return nil end

        bestTop = vector3(hitCoords.x, hitCoords.y, hitCoords.z)
        isLeanFallback = true
    end

    local isFallLedge = false
    if not isGround then
        local downHit = raycast(vector3(bestTop.x, bestTop.y, bestTop.z + 0.1), vector3(bestTop.x, bestTop.y, bestTop.z - 2.5), ped)
        local fallDistance = downHit and #(vector3(bestTop.x, bestTop.y, bestTop.z + 0.1) - downHit.coords) or 3.0
        isFallLedge = not downHit or fallDistance > 0.9
    end

    return {
        hitCoords = hitCoords,
        edge = bestTop,
        normal = bestHit.normal,
        entity = bestHit.entity,
        isLeanFallback = isLeanFallback,
        highestHitZOff = bestHit.highestHitZOff or 0.0,
        isFallLedge = isFallLedge,
        cameFromSweep = bestHit.cameFromSweep == true,
        cameFromStanding = bestHit.cameFromStanding == true,
        isGround = isGround,
    }
end

local function startCooldown()
    Sit.cooldown = true
    SetTimeout(PR.Sit.Cooldown or 1500, function()
        Sit.cooldown = false
    end)
end

function Sit.stand()
    if not Sit.active then return false end

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)

    if Sit.current and Sit.current.style == 'edge_fall' and Sit.current.originalCoords then
        local coords = Sit.current.originalCoords
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        if Sit.current.originalHeading then
            SetEntityHeading(ped, Sit.current.originalHeading)
        end
    end

    ClearPedTasks(ped)

    Sit.active = false
    Sit.current = nil
    LocalPlayer.state:set('forgeCoreSitData', nil, true)
    startCooldown()
    return true
end

function Sit.sit()
    if not PR.Sit or PR.Sit.Enabled == false or Sit.cooldown or Sit.active then return false end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        notify(t('sit.vehicle_blocked'), 'error')
        return false
    end

    local data = detectSurface()
    if not data then
        notify(t('sit.no_surface'), 'error')
        return false
    end

    local playerCoords = GetEntityCoords(ped)
    local playerHeading = GetEntityHeading(ped)
    local diff = vector3(playerCoords.x - data.hitCoords.x, playerCoords.y - data.hitCoords.y, 0.0)
    local normal = normaliseVector(diff)

    if #diff < 0.01 then
        normal = GetEntityForwardVector(ped) * -1.0
    end

    local style
    if not data.isGround and not data.isFallLedge and data.highestHitZOff >= 1.0 then
        style = 'lean'
    elseif data.cameFromSweep or data.cameFromStanding then
        style = 'ledge'
    elseif data.isFallLedge then
        style = 'edge_fall'
    elseif data.isGround then
        style = 'ground'
    else
        style = 'ledge'
    end

    local offset = PR.Sit.Offsets[style] or PR.Sit.Offsets.ledge
    local forwardOffset = style == 'lean' and 0.12 or offset.forward
    if style == 'edge_fall' then forwardOffset = 0.25 end

    local spawnPos = vector3(
        data.hitCoords.x + normal.x * forwardOffset,
        data.hitCoords.y + normal.y * forwardOffset,
        data.edge.z - (offset.z or 0.0)
    )

    if style == 'lean' then
        spawnPos = vector3(spawnPos.x, spawnPos.y, playerCoords.z)
    elseif style == 'ground' then
        spawnPos = vector3(spawnPos.x, spawnPos.y, safeGroundZ(playerCoords) - (offset.z or 0.0))
    end

    local heading = GetHeadingFromVector_2d(normal.x, normal.y)
    if style == 'edge_fall' then
        heading = (heading + 180.0) % 360.0
    end

    local scenario
    if style == 'ledge' or style == 'edge_fall' then
        local scenarios = PR.Sit.Scenarios or {}
        scenario = #scenarios > 0 and scenarios[math.random(#scenarios)] or 'WORLD_HUMAN_SEAT_LEDGE'

        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
        SetEntityHeading(ped, heading)
        SetEntityCoords(ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false)
        Wait(50)
        TaskStartScenarioInPlace(ped, scenario, 0, true)
        SetEntityCollision(ped, true, true)
    elseif style == 'lean' then
        scenario = 'WORLD_HUMAN_LEANING'
        TaskStartScenarioAtPosition(ped, scenario, spawnPos.x, spawnPos.y, spawnPos.z, heading, 0, true, true)
    else
        scenario = 'WORLD_HUMAN_PICNIC'
        TaskStartScenarioAtPosition(ped, scenario, spawnPos.x, spawnPos.y, spawnPos.z, heading, 0, true, true)
    end

    Sit.active = true
    Sit.current = {
        style = style,
        originalCoords = playerCoords,
        originalHeading = playerHeading,
    }

    LocalPlayer.state:set('forgeCoreSitData', {
        coords = toStateCoords(spawnPos),
        heading = heading,
        scenario = scenario,
        inPlace = style == 'ledge' or style == 'edge_fall',
    }, true)

    startCooldown()
    return true
end

function Sit.toggle()
    if Sit.active then
        return Sit.stand()
    end

    return Sit.sit()
end

if PR.Sit and PR.Sit.Enabled ~= false and pr_lib and pr_lib.addCommand then
    pr_lib.addCommand(PR.Sit.Command or 'sit', {
        help = t('commands.sit_help'),
    }, function()
        Sit.sit()
    end)

    pr_lib.addCommand(PR.Sit.StandCommand or 'stand', {
        help = t('commands.stand_help'),
    }, function()
        Sit.stand()
    end)
end

if PR.Sit and PR.Sit.Enabled ~= false and pr_lib and pr_lib.addKeybind then
    pr_lib.addKeybind({
        name = 'forge_core_toggle_sit',
        description = t('keybind.toggle_sit'),
        key = PR.Sit.Keybind or 'C',
        keys = PR.Sit.Keybind or 'C',
        defaultKey = PR.Sit.Keybind or 'C',
        onPressed = function()
            Sit.toggle()
        end,
    })
end

AddStateBagChangeHandler('forgeCoreSitData', nil, function(bagName, _, value)
    local player = GetPlayerFromStateBagName(bagName)
    if player == 0 or player == PlayerId() then return end

    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then return end

    if value then
        local coords = fromStateCoords(value.coords)
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, tonumber(value.heading) or GetEntityHeading(ped))

        if value.inPlace then
            TaskStartScenarioInPlace(ped, tostring(value.scenario or 'WORLD_HUMAN_SEAT_LEDGE'), 0, true)
        else
            TaskStartScenarioAtPosition(ped, tostring(value.scenario or 'WORLD_HUMAN_PICNIC'), coords.x, coords.y, coords.z, tonumber(value.heading) or 0.0, 0, true, true)
        end
        return
    end

    ClearPedTasks(ped)
end)
