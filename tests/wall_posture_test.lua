local H=dofile('tests/cache_harness.lua')
local r=H.new(false);local e=r.env
local mt={}
local function vec(x,y,z) return setmetatable({x=x,y=y,z=z},mt) end
mt.__add=function(a,b) return vec(a.x+b.x,a.y+b.y,a.z+b.z) end
mt.__sub=function(a,b) return vec(a.x-b.x,a.y-b.y,a.z-b.z) end
mt.__mul=function(a,b) return vec(a.x*b,a.y*b,a.z*b) end
mt.__unm=function(a) return vec(-a.x,-a.y,-a.z) end
mt.__len=function(a) return math.sqrt(a.x^2+a.y^2+a.z^2) end
e.vector3=vec;e.vec3=vec
e.ForgeCore.t=function(key) return key end
e.ForgeCore.Session={isLoaded=function() return true end}
e.PlayerPedId=function() return 11 end;e.PlayerId=function() return 1 end
local coords=vec(0,0,1);local published,keybinds={},{}
e.ForgeCore.Posture={set=function(kind,data) published[kind]=data or false;return true end}
e.GetEntityCoords=function() return coords end;e.GetEntityHeading=function() return 0 end
e.GetEntityForwardVector=function() return vec(0,1,0) end
e.GetHeadingFromVector_2d=function() return 180 end
e.SetEntityCoordsNoOffset=function(_,x,y,z) coords=vec(x,y,z) end
e.SetEntityHeading=function() end;e.SetEntityCollision=function() end;e.FreezeEntityPosition=function() end
e.ClearPedTasks=function() end;e.IsPedInAnyVehicle=function() return false end
e.IsPedRagdoll=function() return false end;e.IsPedFalling=function() return false end;e.IsPedDeadOrDying=function() return false end
e.HasAnimDictLoaded=function() return true end;e.GetAnimDuration=function() return 1.5 end
e.IsPedMale=function() return true end;e.DoesEntityExist=function() return true end
e.IsControlJustPressed=function() return false end;e.IsDisabledControlJustPressed=function() return false end
e.GetGamePool=function() error('wall lean must not scan vehicles') end
local probes,read={},{}
e.StartShapeTestRay=function(x,y,z) probes[#probes+1]={x=x,y=y,z=z};return #probes end
e.GetShapeTestResult=function(handle)
    read[handle]=(read[handle] or 0)+1
    if read[handle]==1 then return 1,0,vec(0,0,0),vec(0,0,0),0 end
    return 2,1,vec(0,0.6,probes[handle].z),vec(0,-1,0),0
end
e.pr_lib.addCommand=function() end;e.pr_lib.addKeybind=function(data) keybinds[data.name]=data end
e.pr_lib.fivem={streaming={
    requestAnimDict=function() return true end,playAnim=function() return true end,
    playInteraction=function(data)
        assert(data.vehicle==nil and data.onBeforeMove() and data.onBeforeStart())
        local p=data.position.coords;coords=vec(p.x,p.y,p.z)
        data.onStart(nil,nil,coords,data.position.heading)
        return true,{heading=data.position.heading}
    end,
}}
r.load('shared/sit.lua');r.load('shared/posture.lua');r.load('client/sit/main.lua')
e.CreateThread(function() keybinds.forge_core_toggle_sit.onPressed() end);r.advance(10)
local sit,lean=e.ForgeCore.Client.Sit,e.ForgeCore.Client.Lean
assert(not sit.active and lean.active and lean.current.wall)
assert(published.lean and published.lean.dict:find('world_human_leaning',1,true) and not published.sit)
assert(#probes==2 and read[1]==2 and read[2]==2,'two awaited probes, not a continuous wall scan')
e.CreateThread(function() keybinds.forge_core_toggle_sit.onPressed() end);r.advance(1600)
assert(not lean.active and not lean.current and published.lean==false,'C must also stop a wall lean')
e.ForgeCore.Hospital={isRecovering=function() return true end}
assert(not sit.sit() and not lean.start(),'hospital recovery must block competing postures')
print('PASS wall posture: awaited on-demand probes, C uses the vehicle leaning catalog, C exit and bed guard')
