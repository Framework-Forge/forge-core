-- Actual Starterpack source; isolated natives/PRBridge, no FXServer or disk writes.
local H = dofile('tests/cache_harness.lua')
local mt = {}
local function vec(x, y, z) return setmetatable({x=x, y=y, z=z}, mt) end
mt.__add = function(a,b) return vec(a.x+b.x,a.y+b.y,a.z+b.z) end
mt.__sub = function(a,b) return vec(a.x-b.x,a.y-b.y,a.z-b.z) end
mt.__mul = function(a,b) return vec(a.x*b,a.y*b,a.z*b) end
mt.__len = function(a) return math.sqrt(a.x^2+a.y^2+a.z^2) end

local function fixture(options)
    options = options or {}
    local r = H.new(false)
    local e = r.env
    local s = {entities={}, seats={}, vehicles={}, controls={}, entries={}, texts={}, targets={}, claims=0, player=11,
        playerCoords=vec(101,202,40.7)}
    e.vector3 = vec
    e.ForgeCore.t = function(key) return key end
    e.ForgeCore.State = {get=function() return nil end, onChange=function(_, fn) s.onChange=fn end}
    e.PlayerPedId = function() return s.player end
    e.PlayerId = function() return 1 end
    e.DoesEntityExist = function(id) return id==s.player or s.entities[id] ~= nil end
    e.GetEntityCoords = function(id) return id==s.player and s.playerCoords or assert(s.entities[id]).coords end
    e.GetEntityHeading = function(id) return assert(s.entities[id]).heading end
    e.SetEntityCoordsNoOffset = function(id,x,y,z)
        local entity = assert(s.entities[id])
        assert(z==40.7, 'editor origin must be reused without another model offset')
        entity.coords = vec(x,y,z)
    end
    e.SetEntityHeading = function(id, h) assert(s.entities[id]).heading=h end
    e.FreezeEntityPosition = function(id, freeze) assert(s.entities[id]).frozen=freeze end
    e.DeleteEntity = function(id) s.entities[id]=nil; s.seats[id]=nil end
    e.DeleteVehicle = e.DeleteEntity
    e.RequestCollisionAtCoord = function(x,y,z)
        assert(x==101 and y==202 and z==40.7); s.requests=(s.requests or 0)+1
    end
    e.HasCollisionLoadedAroundEntity = function(id)
        return not options.noCollision and r.now >= assert(s.entities[id]).collisionAt
    end
    e.SetVehicleOnGroundProperly = function(id)
        local entity = assert(s.entities[id])
        assert(not entity.frozen and e.HasCollisionLoadedAroundEntity(id), 'wait for collision before grounding')
        entity.attempts=entity.attempts+1
        if options.noGround or entity.attempts < 3 then return false end
        entity.coords=vec(101,202,40.4)
        entity.grounded=true
        return options.numericGround and 1 or true
    end
    e.SetVehicleDoorsLocked = function(id, state)
        assert(state==1, 'scene must never block NPC entry with a door lock')
        assert(s.entities[id]).lock=state
    end
    e.SetVehicleDoorsLockedForAllPlayers = function(_, locked) assert(not locked) end
    e.SetVehicleDoorsLockedForPlayer = function(_, _, locked) assert(not locked) end
    e.SetVehicleHandbrake = function(id, locked) assert(s.entities[id]).handbrake=locked end
    e.SetVehicleUndriveable = function(id, locked) assert(s.entities[id]).undriveable=locked end
    e.DisableControlAction = function(group,control,disabled)
        assert(disabled and (group==0 or group==2))
        s.controls[#s.controls+1]={time=r.now,group=group,control=control}
    end
    e.DisablePlayerFiring = function(_, disabled) assert(disabled) end
    e.IsPedDeadOrDying = function() return s.dead == true end
    e.IsPedInVehicle = function(ped, vehicle)
        for _, occupant in pairs(s.seats[vehicle] or {}) do if occupant==ped then return true end end
        return false
    end
    e.GetPedInVehicleSeat = function(vehicle,seat) return (s.seats[vehicle] or {})[seat] or 0 end
    e.TaskWarpPedIntoVehicle = function(ped,vehicle,seat)
        assert(s.entities[vehicle]); s.seats[vehicle]=s.seats[vehicle] or {};s.seats[vehicle][seat]=ped
    end
    e.TaskEnterVehicle = function(ped,vehicle,timeout,seat,speed,flag)
        assert(s.entities[vehicle].lock==1 and seat==0 and flag==1 and speed==1 and timeout==15000)
        s.entries[#s.entries+1]={ped=ped,vehicle=vehicle}
        if not options.failBoarding then
            e.SetTimeout(100, function()
                if s.entities[vehicle] and s.entities[ped] then e.TaskWarpPedIntoVehicle(ped,vehicle,seat) end
            end)
        end
    end
    e.TaskLeaveVehicle = function(ped,vehicle)
        for seat,occupant in pairs(s.seats[vehicle] or {}) do if occupant==ped then s.seats[vehicle][seat]=nil end end
    end
    e.GetGamePool = function() s.trafficCalls=(s.trafficCalls or 0)+1;return {} end
    e.GetEntityForwardVector = function() return vec(0,1,0) end
    e.AddBlipForCoord = function() return 5 end
    e.DoesBlipExist = function() return true end
    e.AddTextComponentSubstringPlayerName = function(text) s.texts[#s.texts+1]=text end
    for _, name in ipairs({
        'SetEntityAsMissionEntity','SetEntityInvincible','SetBlockingOfNonTemporaryEvents','SetPedCanRagdoll',
        'TaskStartScenarioInPlace','SetVehicleCanBreak','SetVehicleCanBeVisiblyDamaged','SetVehicleTyresCanBurst',
        'SetVehicleEngineCanDegrade','SetVehicleEngineOn','SetVehicleRadioEnabled','SetEntityProofs',
        'SetVehicleForwardSpeed','RenderScriptCams','SetCinematicModeActive','ClearPedTasksImmediately',
        'ClearPedTasks','BeginTextCommandPrint','EndTextCommandPrint','RemoveBlip','SetBlipSprite','SetBlipColour',
        'SetBlipRoute','SetBlipRouteColour','BeginTextCommandSetBlipName','EndTextCommandSetBlipName',
        'SetTrafficLightsState','SetTrafficLightsState2','TaskVehicleDriveToCoordLongrange','TaskVehicleDriveWander',
    }) do e[name]=function() end end
    e.pr_lib.target = {
        addLocalEntity=function(ped,targets) s.targets[ped]=targets end,
        removeLocalEntity=function(ped) s.targets[ped]=nil end,
    }
    e.pr_lib.fivem = {streaming={
        createVehicle=function(_,coords,heading,opts)
            assert(opts.networked==false and opts.freeze==true and opts.placeProperly==false and opts.collision==true)
            if options.modelDelay then e.Wait(100) end
            if options.zeroHandle then return 0 end
            local id=20+#s.vehicles
            s.entities[id]={coords=vec(coords.x,coords.y,coords.z+3),heading=heading,frozen=true,
                collisionAt=r.now+150,attempts=0}
            s.vehicles[#s.vehicles+1]=id
            return id
        end,
        createPed=function(_,coords,heading,opts)
            assert(coords.z==42.15 and heading==73 and opts.placementType=='ped', 'Lamar placement unchanged')
            local id=100+#s.vehicles
            s.entities[id]={coords=coords,heading=heading}
            return id
        end,
        deleteEntity=e.DeleteEntity,
    }}
    r.load('shared/starterpack.lua')
    e.pr_lib.callback.await = function(name)
        assert(name==e.PR.Starterpack.Callbacks.claim)
        s.claims=s.claims+1; return true
    end
    r.load('client/starterpack/main.lua')
    s.starter = e.ForgeCore.Client.Starterpack
    s.payload={prologue={enabled=true,vehicleModel='asea',lamarModel='ig_lamardavis',
        vehicleStart={coords={x=101,y=202,z=40.7},heading=137},
        lamarStart={coords={x=99,y=200,z=42.15},heading=73},
        stops={{id='stop_1',coords={x=101,y=202,z=40.4},cameraFrames={}}}}}
    s.start=function() e.CreateThread(function() r.fire(e.PR.Starterpack.Events.startTest,nil,s.payload) end) end
    s.board=function()
        e.CreateThread(function() s.starter.preparePrologue() end)
        r.advance(1)
        e.TaskWarpPedIntoVehicle(s.player,s.starter.vehicle,-1)
    end
    return r,e,s
end

do
    local r,e,s=fixture()
    e.ForgeCore.State.get=function() return s.payload end
    s.playerCoords=vec(10000,10000,1000)
    r.advance(3000)
    assert(#s.vehicles==0 and s.starter.preparationScheduled, 'distant login must not create floating cars')
    s.playerCoords=vec(101,202,40.7);r.advance(2000)
    assert(#s.vehicles==1 and s.entities[s.starter.vehicle].grounded and not s.starter.preparationScheduled)
    local requests=s.requests;r.advance(8000)
    assert(s.requests==requests and not s.trafficCalls, 'preparation timer must stop after success')
end

do
    local r,e,s=fixture({noGround=true})
    e.ForgeCore.State.get=function() return s.payload end
    r.advance(30000)
    assert(#s.vehicles==3 and not s.starter.vehicle and not s.starter.preparationScheduled)
    assert(s.starter.preparationAttempts==3 and next(s.entities)==nil, 'invalid floor must stop after bounded retries')
end

do
    local r,e,s=fixture({numericGround=true})
    s.start();r.advance(500)
    local vehicle=s.starter.vehicle
    assert(vehicle and #s.vehicles==1 and s.entities[vehicle].grounded and s.entities[vehicle].frozen)
    assert(s.entities[vehicle].coords.z==40.4 and s.entities[vehicle].heading==137)
    s.board();r.advance(310)
    assert(s.starter.routeActive and #s.entries==1 and s.entities[vehicle].lock==1)
    local disabled={};for _,c in ipairs(s.controls) do disabled[c.group..':'..c.control]=true end
    for _,control in ipairs({23,75,71,72,59,60,76,24}) do
        assert(disabled['0:'..control] and disabled['2:'..control], 'block exit, driving and combat each frame')
    end
    -- An externally forced exit is restored without closing doors or clearing the NPC entry task.
    e.TaskLeaveVehicle(s.player,vehicle);r.advance(2)
    assert(e.GetPedInVehicleSeat(vehicle,-1)==s.player)
    r.advance(4500)
    assert(not s.starter.routeActive and s.claims==1 and not s.entities[vehicle].undriveable)
    assert(not e.IsPedInVehicle(s.player,vehicle) and e.GetPedInVehicleSeat(vehicle,-1)==s.starter.lamar)
    local count=#s.controls;r.advance(50);assert(#s.controls==count, 'controls must release on completion')
    assert(s.trafficCalls==1, 'no added vehicle pool scan for grounding or boarding')
end

for _,failure in ipairs({'noCollision','noGround','zeroHandle'}) do
    local r,_,s=fixture({[failure]=true})
    s.start();r.advance(5500)
    assert(not s.starter.vehicle and not s.starter.lamar and not s.starter.preparingScene)
    assert(next(s.entities)==nil, 'failed grounding must not leave a floating scene behind')
    assert(s.requests<=102 and not s.trafficCalls, 'bounded preparation; no background scans')
end

for _,modelDelay in ipairs({false,true}) do
    local r,e,s=fixture({modelDelay=modelDelay})
    s.start();r.advance(60)
    local old=s.starter.vehicle
    assert(s.starter.preparingScene)
    r.fire('onResourceStop',nil,'forge-core') -- also exercises cancellation during the awaited native placement
    s.start();r.advance(500)
    assert(#s.vehicles==2 and s.starter.vehicle==s.vehicles[2] and not (old and s.entities[old]))
    assert(s.entities[s.starter.vehicle].grounded and not s.starter.preparingScene)
    assert(not s.trafficCalls, 'preparation must not scan the vehicle pool')
end

do
    local r,_,s=fixture()
    s.start();r.advance(50);s.start();r.advance(500)
    assert(#s.vehicles==1 and s.starter.vehicle and not s.starter.preparingScene, 'concurrent prepare must not duplicate entities')
end

do
    local r,_,s=fixture()
    s.start();r.advance(500);s.board();r.advance(5000)
    assert(not s.starter.routeActive and s.claims==1)
    local old=s.starter.vehicle
    s.onChange(s.payload);r.advance(2200)
    local newer=s.starter.vehicle
    assert(newer and newer~=old and s.entities[newer])
    r.advance(21000)
    assert(s.starter.vehicle==newer and s.entities[newer], 'old completion timer must not erase a new scene')
end

do
    local r,e,s=fixture({failBoarding=true})
    s.start();r.advance(500);s.board();r.advance(350)
    for _=1,31 do r.advance(1000) end
    assert(not s.starter.routeActive and s.claims==0 and s.targets[s.starter.lamar])
    assert(not s.entities[s.starter.vehicle].undriveable and s.entities[s.starter.vehicle].lock==1)
    local count=#s.controls;r.advance(100);assert(#s.controls==count, 'boarding failure must release controls')
end

for _,cancel in ipairs({'resource','death','ped_change','session'}) do
    local r,e,s=fixture()
    s.start();r.advance(500);s.board();r.advance(350)
    if cancel=='resource' then r.fire('onResourceStop',nil,'forge-core')
    elseif cancel=='session' then r.fire('forge-core:session:changed',nil,nil)
    elseif cancel=='death' then s.dead=true
    else s.player=12 end
    r.advance(3)
    local count=#s.controls;r.advance(1000)
    assert(not s.starter.routeActive and not s.starter.vehicle and #s.controls==count and s.claims==0)
end

print('PASS Starterpack: collision/ground retries, origin/heading, zero handle, cancellation, unlocked Lamar boarding, scene controls and release')
