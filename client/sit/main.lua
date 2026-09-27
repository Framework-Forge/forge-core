ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Sit = {
	cooldown = false,
	active = false,
	current = nil,
}

local Lean = {
	cooldown = false,
	active = false,
	entering = false,
	exiting = false,
	current = nil,
}

ForgeCore.Client.Sit = Sit
ForgeCore.Client.Lean = Lean

local function t(key, params)
	return ForgeCore.t(key, params)
end

local function notify(description, notifyType)
	if pr_lib and pr_lib.Notify then
		pr_lib.Notify({
			title = t("sit.title"),
			description = description,
			type = notifyType or "inform",
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
	coords = type(coords) == "table" and coords or {}
	return vector3(
		tonumber(coords.x or coords[1]) or 0.0,
		tonumber(coords.y or coords[2]) or 0.0,
		tonumber(coords.z or coords[3]) or 0.0
	)
end

local function normaliseVector(value)
	local magnitude = math.sqrt(value.x * value.x + value.y * value.y + value.z * value.z)
	if magnitude < 0.0001 then
		return vector3(0.0, 0.0, 0.0)
	end

	return vector3(value.x / magnitude, value.y / magnitude, value.z / magnitude)
end

local function safeGroundZ(coords)
	local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
	return found and groundZ or coords.z
end

local function raycast(startPos, endPos, ignore)
	local ray = StartShapeTestRay(
		startPos.x,
		startPos.y,
		startPos.z,
		endPos.x,
		endPos.y,
		endPos.z,
		31,
		ignore or PlayerPedId(),
		0
	)
	local _, hit, hitCoords, normal, entity = GetShapeTestResult(ray)

	if hit ~= 1 then
		return nil
	end

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
				if zOff > highestHitZOff then
					highestHitZOff = zOff
				end

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
		if not groundHit then
			return nil
		end

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
			local topHit = raycast(
				vector3(testPoint.x, testPoint.y, hitCoords.z + 1.5),
				vector3(testPoint.x, testPoint.y, hitCoords.z - 1.0),
				ped
			)

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
		if #(coords - hitCoords) >= 1.0 then
			return nil
		end

		bestTop = vector3(hitCoords.x, hitCoords.y, hitCoords.z)
		isLeanFallback = true
	end

	local isFallLedge = false
	if not isGround then
		local downHit =
			raycast(vector3(bestTop.x, bestTop.y, bestTop.z + 0.1), vector3(bestTop.x, bestTop.y, bestTop.z - 2.5), ped)
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
	if not Sit.active then
		return false
	end

	local ped = PlayerPedId()
	FreezeEntityPosition(ped, false)
	SetEntityCollision(ped, true, true)

	if Sit.current and Sit.current.style == "edge_fall" and Sit.current.originalCoords then
		local coords = Sit.current.originalCoords
		SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
		if Sit.current.originalHeading then
			SetEntityHeading(ped, Sit.current.originalHeading)
		end
	end

	ClearPedTasks(ped)

	Sit.active = false
	Sit.current = nil
	LocalPlayer.state:set("forgeCoreSitData", nil, true)
	startCooldown()
	return true
end

function Sit.sit()
	if not PR.Sit or PR.Sit.Enabled == false or Sit.cooldown or Sit.active or Lean.active or Lean.exiting then
		return false
	end

	local ped = PlayerPedId()
	if IsPedInAnyVehicle(ped, false) then
		notify(t("sit.vehicle_blocked"), "error")
		return false
	end

	local data = detectSurface()
	if not data then
		notify(t("sit.no_surface"), "error")
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
		style = "lean"
	elseif data.cameFromSweep or data.cameFromStanding then
		style = "ledge"
	elseif data.isFallLedge then
		style = "edge_fall"
	elseif data.isGround then
		style = "ground"
	else
		style = "ledge"
	end

	local offset = PR.Sit.Offsets[style] or PR.Sit.Offsets.ledge
	local forwardOffset = style == "lean" and 0.12 or offset.forward
	if style == "edge_fall" then
		forwardOffset = 0.25
	end

	local spawnPos = vector3(
		data.hitCoords.x + normal.x * forwardOffset,
		data.hitCoords.y + normal.y * forwardOffset,
		data.edge.z - (offset.z or 0.0)
	)

	if style == "lean" then
		spawnPos = vector3(spawnPos.x, spawnPos.y, playerCoords.z)
	elseif style == "ground" then
		spawnPos = vector3(spawnPos.x, spawnPos.y, safeGroundZ(playerCoords) - (offset.z or 0.0))
	end

	local heading = GetHeadingFromVector_2d(normal.x, normal.y)
	if style == "edge_fall" then
		heading = (heading + 180.0) % 360.0
	end

	local scenario
	if style == "ledge" or style == "edge_fall" then
		local scenarios = PR.Sit.Scenarios or {}
		scenario = #scenarios > 0 and scenarios[math.random(#scenarios)] or "WORLD_HUMAN_SEAT_LEDGE"

		FreezeEntityPosition(ped, true)
		SetEntityCollision(ped, false, false)
		SetEntityHeading(ped, heading)
		SetEntityCoords(ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false)
		Wait(50)
		TaskStartScenarioInPlace(ped, scenario, 0, true)
		SetEntityCollision(ped, true, true)
	elseif style == "lean" then
		scenario = "WORLD_HUMAN_LEANING"
		TaskStartScenarioAtPosition(ped, scenario, spawnPos.x, spawnPos.y, spawnPos.z, heading, 0, true, true)
	else
		scenario = "WORLD_HUMAN_PICNIC"
		TaskStartScenarioAtPosition(ped, scenario, spawnPos.x, spawnPos.y, spawnPos.z, heading, 0, true, true)
	end

	Sit.active = true
	Sit.current = {
		style = style,
		originalCoords = playerCoords,
		originalHeading = playerHeading,
	}

	LocalPlayer.state:set("forgeCoreSitData", {
		coords = toStateCoords(spawnPos),
		heading = heading,
		scenario = scenario,
		inPlace = style == "ledge" or style == "edge_fall",
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
	pr_lib.addCommand(PR.Sit.Command or "sit", {
		help = t("commands.sit_help"),
	}, function()
		Sit.sit()
	end)

	pr_lib.addCommand(PR.Sit.StandCommand or "stand", {
		help = t("commands.stand_help"),
	}, function()
		Sit.stand()
	end)
end

if PR.Sit and PR.Sit.Enabled ~= false and pr_lib and pr_lib.addKeybind then
	pr_lib.addKeybind({
		name = "forge_core_toggle_sit",
		description = t("keybind.toggle_sit"),
		key = PR.Sit.Keybind or "C",
		keys = PR.Sit.Keybind or "C",
		defaultKey = PR.Sit.Keybind or "C",
		onPressed = function()
			Sit.toggle()
		end,
	})
end

-- Vehicle lean ---------------------------------------------------------------

local LEAN_DEFAULTS = {
	Enabled = true,
	Keybind = "O",
	Cooldown = 1000,
	SearchRadius = 2.2,
	SideOffset = 0.28,
	SurfaceOffset = 0.22,
	EntryOffset = 0.42,
	RearInset = 0.35,
	WalkSpeed = 1.0,
	ApproachTimeout = 3500,
	ArriveDistance = 0.65,
	SettleTime = 100,
	EnterTailCutMs = 1100,
	IdleMinMs = 5500,
	IdleMaxMs = 10500,
}

local LEAN_ANIMS = {
	female = {
		{
			name = "holding_elbow",
			enter = { dict = "amb@world_human_leaning@female@wall@back@holding_elbow@enter", anim = "enter_front" },
			base = { dict = "amb@world_human_leaning@female@wall@back@holding_elbow@base", anim = "base" },
			idles = {
				{ dict = "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a", anim = "idle_a" },
				{ dict = "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a", anim = "idle_b" },
			},
			exit = { dict = "amb@world_human_leaning@female@wall@back@holding_elbow@exit", anim = "exit_front" },
		},
	},
	male = {
		{
			name = "foot_up",
			enter = { dict = "amb@world_human_leaning@male@wall@back@foot_up@enter", anim = "enter_back" },
			base = { dict = "amb@world_human_leaning@male@wall@back@foot_up@base", anim = "base" },
			idles = {
				{ dict = "amb@world_human_leaning@male@wall@back@foot_up@idle_a", anim = "idle_b" },
				{ dict = "amb@world_human_leaning@male@wall@back@foot_up@idle_b", anim = "idle_e" },
			},
			exit = { dict = "amb@world_human_leaning@male@wall@back@foot_up@exit", anim = "exit_front" },
		},
		{
			name = "legs_crossed",
			enter = { dict = "amb@world_human_leaning@male@wall@back@legs_crossed@enter", anim = "enter_back" },
			base = { dict = "amb@world_human_leaning@male@wall@back@legs_crossed@base", anim = "base" },
			idles = {
				{ dict = "amb@world_human_leaning@male@wall@back@legs_crossed@idle_a", anim = "idle_a" },
				{ dict = "amb@world_human_leaning@male@wall@back@legs_crossed@idle_a", anim = "idle_c" },
			},
			exit = { dict = "amb@world_human_leaning@male@wall@back@legs_crossed@exit", anim = "exit_front" },
		},
	},
}

local function leanCfg(key)
	local cfg = PR.Lean or {}
	local value = cfg[key]
	if value == nil then
		value = LEAN_DEFAULTS[key]
	end
	return value
end

local function requestAnimDict(dict)
	if HasAnimDictLoaded(dict) then
		return true
	end

	RequestAnimDict(dict)
	local timeout = GetGameTimer() + 3000
	while not HasAnimDictLoaded(dict) do
		if GetGameTimer() >= timeout then
			return false
		end
		Wait(0)
	end

	return true
end

local function animDurationMs(dict, anim, fallback)
	if not HasAnimDictLoaded(dict) and not pr_lib.fivem.streaming.requestAnimDict(dict, 3000) then
		return fallback or 1000
	end

	local duration = GetAnimDuration(dict, anim)
	if not duration or duration <= 0.0 then
		return fallback or 1000
	end
	return math.max(250, math.floor(duration * 1000.0))
end

local function playLeanAnim(ped, data, looped)
	if not data then
		return false
	end

	local played = pr_lib.fivem.streaming.playAnim({
		pedEntity = ped,
		dict = data.dict,
		clip = data.anim,
		duration = -1,
		flags = looped and 1 or 0,
		blendIn = 4.0,
		blendOut = -4.0,
		wait = false,
	})

	return played == true
end

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function getClampedVehicleSideY(minDim, maxDim, localY)
	local halfLength = math.max(0.0, (maxDim.y - minDim.y) * 0.5)
	local rearInset = math.min(tonumber(leanCfg("RearInset")) or 0.35, halfLength * 0.9)
	return clamp(localY, minDim.y + rearInset, maxDim.y - rearInset)
end

local function distanceToVehicleSide(vehicle, pedCoords)
	local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
	local localPed = GetOffsetFromEntityGivenWorldCoords(vehicle, pedCoords.x, pedCoords.y, pedCoords.z)
	local sideX = localPed.x >= 0.0 and maxDim.x or minDim.x
	local sideY = getClampedVehicleSideY(minDim, maxDim, localPed.y)
	local sidePoint = GetOffsetFromEntityInWorldCoords(vehicle, sideX, sideY, 0.0)

	return #(pedCoords - sidePoint)
end

local function closestVehicle(maxDistance)
	local pedCoords = GetEntityCoords(PlayerPedId())
	local bestVehicle, bestDistance

	for _, vehicle in ipairs(GetGamePool("CVehicle")) do
		if DoesEntityExist(vehicle) then
			local distance = distanceToVehicleSide(vehicle, pedCoords)
			if distance <= maxDistance and (not bestDistance or distance < bestDistance) then
				bestVehicle = vehicle
				bestDistance = distance
			end
		end
	end

	return bestVehicle, bestDistance
end

local function raycastVehicleSurface(vehicle, pedCoords)
	local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
	local localPed = GetOffsetFromEntityGivenWorldCoords(vehicle, pedCoords.x, pedCoords.y, pedCoords.z)
	local useRight = localPed.x >= 0.0
	local vehicleForward = normaliseVector(GetEntityForwardVector(vehicle))
	local vehicleRight = normaliseVector(vector3(vehicleForward.y, -vehicleForward.x, 0.0))
	local outward = useRight and vehicleRight or vehicleRight * -1.0
	local vehicleLength = math.max(0.1, maxDim.y - minDim.y)
	local rearMargin = math.max(tonumber(leanCfg("RearInset")) or 0.35, vehicleLength * 0.20)
	local frontMargin = math.max(tonumber(leanCfg("RearInset")) or 0.35, vehicleLength * 0.25)
	local sideY = clamp(localPed.y, minDim.y + rearMargin, maxDim.y - frontMargin)
	local anchor = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, sideY, 0.0)
	local heights = { 0.70, 0.90, 0.50, 1.10 }

	for i = 1, #heights do
		local z = pedCoords.z + heights[i]
		local startPos = vector3(anchor.x + outward.x * 4.0, anchor.y + outward.y * 4.0, z)
		local endPos = vector3(anchor.x - outward.x * 1.0, anchor.y - outward.y * 1.0, z)
		local handle = StartShapeTestLosProbe(
			startPos.x,
			startPos.y,
			startPos.z,
			endPos.x,
			endPos.y,
			endPos.z,
			2,
			PlayerPedId(),
			7
		)
		local expires = GetGameTimer() + 250
		local status, hit, hitCoords, normal, entity

		repeat
			status, hit, hitCoords, normal, entity = GetShapeTestResult(handle)
			if status == 1 then
				Wait(0)
			end
		until status ~= 1 or GetGameTimer() >= expires

		if status == 2 and hit == 1 and entity == vehicle then
			local horizontalNormal = normaliseVector(vector3(normal.x, normal.y, 0.0))
			if #horizontalNormal > 0.5 then
				if horizontalNormal.x * outward.x + horizontalNormal.y * outward.y < 0.0 then
					horizontalNormal = horizontalNormal * -1.0
				end

				return {
					coords = hitCoords,
					normal = horizontalNormal,
				}
			end
		end
	end

	return nil
end
local function getBoundingBoxLeanTransform(vehicle, pedCoords)
	local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
	local localPed = GetOffsetFromEntityGivenWorldCoords(vehicle, pedCoords.x, pedCoords.y, pedCoords.z)
	local useRight = localPed.x >= 0.0
	local sideX = useRight and maxDim.x or minDim.x
	local sideY = getClampedVehicleSideY(minDim, maxDim, localPed.y)
	local surface = GetOffsetFromEntityInWorldCoords(vehicle, sideX, sideY, 0.0)
	local vehicleForward = normaliseVector(GetEntityForwardVector(vehicle))
	local vehicleRight = normaliseVector(vector3(vehicleForward.y, -vehicleForward.x, 0.0))

	return vector3(surface.x, surface.y, surface.z), useRight and vehicleRight or vehicleRight * -1.0
end

local function getLeanTransform(vehicle, pedCoords)
	local surface = raycastVehicleSurface(vehicle, pedCoords)
	local surfaceCoords
	local outward

	if surface then
		surfaceCoords = surface.coords
		outward = surface.normal
	else
		surfaceCoords, outward = getBoundingBoxLeanTransform(vehicle, pedCoords)
	end

	local surfaceOffset = tonumber(leanCfg("SurfaceOffset")) or 0.22
	local restWorld = surfaceCoords + outward * surfaceOffset
	local _, restGround = pr_lib.fivem.streaming.findGroundZ(
		vector3(restWorld.x, restWorld.y, pedCoords.z),
		{ ignoreEntity = vehicle }
	)
	local restCoords = restGround or vector3(restWorld.x, restWorld.y, pedCoords.z)
	local entryWorld = restCoords + outward * (tonumber(leanCfg("EntryOffset")) or 0.42)
	local _, entryGround = pr_lib.fivem.streaming.findGroundZ(
		vector3(entryWorld.x, entryWorld.y, pedCoords.z),
		{ ignoreEntity = vehicle }
	)
	local entryCoords = entryGround or vector3(entryWorld.x, entryWorld.y, restCoords.z)
	local heading = GetHeadingFromVector_2d(outward.x, outward.y)

	return entryCoords, restCoords, heading
end

local function isCurrentLean(token)
	return Lean.active and not Lean.exiting and Lean.current and Lean.current.token == token
end
local function setLeanState(animData)
	LocalPlayer.state:set("forgeCoreLeanData", animData, true)
end
local function isCurrentLean(token)
	return Lean.active and not Lean.exiting and Lean.current and Lean.current.token == token
end

local function playLeanEntry(ped, current)
	local fullDuration = animDurationMs(current.profile.enter.dict, current.profile.enter.anim, 1250)
	local duration = math.max(350, fullDuration - (tonumber(leanCfg("EnterTailCutMs")) or 1100))
	local played, result = pr_lib.fivem.streaming.playInteraction({
		vehicle = current.vehicle,
		pedEntity = ped,
		position = {
			coords = current.coords,
			heading = current.heading,
			moveTo = true,
			timeout = tonumber(leanCfg("ApproachTimeout")) or 3500,
			speed = tonumber(leanCfg("WalkSpeed")) or 1.0,
			arriveDistance = tonumber(leanCfg("ArriveDistance")) or 0.65,
			maxDistance = math.max((tonumber(leanCfg("ArriveDistance")) or 0.65) + 0.65, 1.25),
			settleTime = tonumber(leanCfg("SettleTime")) or 100,
			clearBeforeAnim = true,
		},
		animation = {
			dict = current.profile.enter.dict,
			clip = current.profile.enter.anim,
			duration = duration,
			flags = 0,
			blendIn = 4.0,
			blendOut = -4.0,
			advanced = false,
			wait = true,
		},
		cleanup = {
			clearTasks = false,
		},
		onBeforeMove = function()
			return isCurrentLean(current.token) and DoesEntityExist(current.vehicle)
		end,
		onBeforeStart = function()
			return isCurrentLean(current.token) and DoesEntityExist(current.vehicle)
		end,
		onStart = function(_, _, coords, heading)
			setLeanState({
				dict = current.profile.enter.dict,
				anim = current.profile.enter.anim,
				coords = toStateCoords(coords),
				heading = heading or current.heading,
				duration = duration,
				advanced = false,
				looped = false,
			})
		end,
	})

	if not played or not isCurrentLean(current.token) then
		return false, result
	end

	local entityCoords = GetEntityCoords(ped)
	local restCoords = current.restCoords or entityCoords
	SetEntityCoordsNoOffset(ped, restCoords.x, restCoords.y, entityCoords.z, false, false, false)
	SetEntityHeading(ped, current.heading)

	current.coords = GetEntityCoords(ped)
	current.heading = result and result.heading or current.heading
	return true, result
end

local function leanStartCooldown()
	Lean.cooldown = true
	SetTimeout(leanCfg("Cooldown"), function()
		Lean.cooldown = false
	end)
end

local function returnToLeanBase()
	if not Lean.active or Lean.exiting or not Lean.current then
		return false
	end

	local ped = PlayerPedId()
	local current = Lean.current
	if not playLeanAnim(ped, current.profile.base, true) then
		return false
	end

	Wait(0)
	current.coords = GetEntityCoords(ped)
	SetEntityHeading(ped, current.heading)
	FreezeEntityPosition(ped, true)

	setLeanState({
		dict = current.profile.base.dict,
		anim = current.profile.base.anim,
		coords = toStateCoords(current.coords),
		heading = current.heading,
		looped = true,
	})
	return true
end
local function startLeanIdleLoop(token)
	CreateThread(function()
		while Lean.active and not Lean.exiting and Lean.current and Lean.current.token == token do
			local minMs = tonumber(leanCfg("IdleMinMs")) or 5500
			local maxMs = tonumber(leanCfg("IdleMaxMs")) or 10500
			if maxMs < minMs then
				minMs, maxMs = maxMs, minMs
			end
			Wait(math.random(minMs, maxMs))

			if not Lean.active or Lean.exiting or not Lean.current or Lean.current.token ~= token then
				break
			end

			local idles = Lean.current.profile.idles or {}
			if #idles > 0 then
				local idle = idles[math.random(#idles)]
				local ped = PlayerPedId()
				if playLeanAnim(ped, idle, false) then
					setLeanState({
						dict = idle.dict,
						anim = idle.anim,
						coords = toStateCoords(Lean.current.coords),
						heading = Lean.current.heading,
						looped = false,
					})

					Wait(animDurationMs(idle.dict, idle.anim, 2500))
					returnToLeanBase()
				end
			end
		end
	end)
end

local function resetLean(ped, withCooldown)
	Lean.active = false
	Lean.entering = false
	Lean.exiting = false

	FreezeEntityPosition(ped, false)
	SetEntityCollision(ped, true, true)
	ClearPedTasks(ped)
	setLeanState(nil)

	Lean.current = nil
	if withCooldown then
		leanStartCooldown()
	end
end

function Lean.stop(skipExit)
	if (not Lean.active and not Lean.entering and not Lean.exiting) or not Lean.current then
		return false
	end
	if Lean.exiting then
		return false
	end

	local ped = PlayerPedId()
	local current = Lean.current

	if Lean.entering or skipExit then
		resetLean(ped, true)
		return true
	end

	Lean.exiting = true
	Lean.active = false
	FreezeEntityPosition(ped, false)

	if current.profile and current.profile.exit and playLeanAnim(ped, current.profile.exit, false) then
		setLeanState({
			dict = current.profile.exit.dict,
			anim = current.profile.exit.anim,
			coords = toStateCoords(current.coords),
			heading = current.heading,
			looped = false,
		})
		Wait(animDurationMs(current.profile.exit.dict, current.profile.exit.anim, 1250))
	end

	resetLean(ped, true)
	return true
end

function Lean.start()
	if leanCfg("Enabled") == false or Lean.cooldown or Lean.active or Lean.entering or Lean.exiting or Sit.active then
		return false
	end

	local ped = PlayerPedId()
	if IsPedInAnyVehicle(ped, false) then
		notify(t("sit.vehicle_blocked"), "error")
		return false
	end

	if IsPedRagdoll(ped) or IsPedFalling(ped) or IsPedDeadOrDying(ped, true) then
		return false
	end

	local vehicle = closestVehicle(tonumber(leanCfg("SearchRadius")) or 2.2)
	if not vehicle then
		notify(t("sit.lean_no_vehicle"), "error")
		return false
	end

	local gender = IsPedMale(ped) and "male" or "female"
	local profiles = LEAN_ANIMS[gender]
	if not profiles or #profiles == 0 then
		return false
	end

	local profile = profiles[math.random(#profiles)]
	local entryPos, restPos, targetHeading = getLeanTransform(vehicle, GetEntityCoords(ped))
	local token = GetGameTimer()

	Lean.current = {
		token = token,
		vehicle = vehicle,
		profile = profile,
		coords = entryPos,
		restCoords = restPos,
		heading = targetHeading,
		gender = gender,
	}
	Lean.active = true
	Lean.entering = true

	FreezeEntityPosition(ped, false)
	SetEntityCollision(ped, true, true)

	local entered, reason = playLeanEntry(ped, Lean.current)
	if not entered then
		if Lean.current and Lean.current.token == token then
			resetLean(ped, true)
			if type(reason) == "string" and reason:find("move_timeout", 1, true) then
				notify(t("sit.lean_path_blocked"), "error")
			end
		end
		return false
	end

	if not isCurrentLean(token) then
		return true
	end

	Lean.entering = false
	if not returnToLeanBase() then
		resetLean(ped, true)
		return false
	end

	startLeanIdleLoop(token)
	leanStartCooldown()
	return true
end
function Lean.toggle()
	if Lean.active or Lean.exiting then
		return Lean.stop()
	end
	return Lean.start()
end

if leanCfg("Enabled") ~= false and pr_lib and pr_lib.addKeybind then
	pr_lib.addKeybind({
		name = "forge_core_toggle_vehicle_lean",
		description = t("keybind.toggle_vehicle_lean"),
		defaultKey = leanCfg("Keybind"),
		onPressed = function()
			Lean.toggle()
		end,
	})
end

local MOVEMENT_CONTROLS = { 32, 33, 34, 35 }

local function movementJustPressed()
	for i = 1, #MOVEMENT_CONTROLS do
		local control = MOVEMENT_CONTROLS[i]
		if IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control) then
			return true
		end
	end

	return false
end

CreateThread(function()
	while true do
		if Lean.active and not Lean.exiting then
			if movementJustPressed() then
				Lean.stop(true)
			end
			Wait(0)
		else
			Wait(200)
		end
	end
end)

AddEventHandler("onResourceStop", function(resourceName)
	if resourceName ~= GetCurrentResourceName() then
		return
	end

	if Lean.active or Lean.entering or Lean.exiting then
		resetLean(PlayerPedId(), false)
	end
end)

AddStateBagChangeHandler("forgeCoreLeanData", nil, function(bagName, _, value)
	local player = GetPlayerFromStateBagName(bagName)
	if player == 0 or player == PlayerId() then
		return
	end

	local ped = GetPlayerPed(player)
	if not DoesEntityExist(ped) then
		return
	end

	if not value then
		FreezeEntityPosition(ped, false)
		ClearPedTasks(ped)
		return
	end

	local coords = fromStateCoords(value.coords)
	local heading = tonumber(value.heading) or GetEntityHeading(ped)
	local dict = tostring(value.dict or "")
	local anim = tostring(value.anim or "")
	if dict == "" or anim == "" then
		return
	end

	if value.advanced == true then
		pr_lib.fivem.streaming.playInteraction({
			pedEntity = ped,
			position = {
				coords = coords,
				heading = heading,
				moveTo = false,
				clearBeforeAnim = true,
				settleTime = 0,
			},
			animation = {
				dict = dict,
				clip = anim,
				duration = tonumber(value.duration) or -1,
				flags = value.looped and 1 or 0,
				blendIn = 4.0,
				blendOut = -4.0,
				advanced = true,
				rotZ = heading,
				wait = false,
			},
			cleanup = {
				clearTasks = false,
			},
		})
		return
	end

	SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
	SetEntityHeading(ped, heading)
	pr_lib.fivem.streaming.playAnim({
		pedEntity = ped,
		dict = dict,
		clip = anim,
		duration = -1,
		flags = value.looped and 1 or 0,
		blendIn = 4.0,
		blendOut = -4.0,
		wait = false,
	})
end)

AddStateBagChangeHandler("forgeCoreSitData", nil, function(bagName, _, value)
	local player = GetPlayerFromStateBagName(bagName)
	if player == 0 or player == PlayerId() then
		return
	end

	local ped = GetPlayerPed(player)
	if not DoesEntityExist(ped) then
		return
	end

	if value then
		local coords = fromStateCoords(value.coords)
		SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
		SetEntityHeading(ped, tonumber(value.heading) or GetEntityHeading(ped))

		if value.inPlace then
			TaskStartScenarioInPlace(ped, tostring(value.scenario or "WORLD_HUMAN_SEAT_LEDGE"), 0, true)
		else
			TaskStartScenarioAtPosition(
				ped,
				tostring(value.scenario or "WORLD_HUMAN_PICNIC"),
				coords.x,
				coords.y,
				coords.z,
				tonumber(value.heading) or 0.0,
				0,
				true,
				true
			)
		end
		return
	end

	ClearPedTasks(ped)
end)
