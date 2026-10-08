local H=dofile('tests/cache_harness.lua')
local r=H.new(false);local e=r.env
e.ForgeCore.State={copy=H.copy};e.ForgeCore.Session={isLoaded=function() return true end}
e.ForgeCore.t=function(key) return key end
e.RegisterCommand=function() end;e.PlayerId=function() return 1 end;e.PlayerPedId=function() return 11 end
e.GetPlayerFromServerId=function(id) return id==2 and 0 or -1 end
e.GetPlayerPed=function(index) return index==0 and 22 or 11 end
e.DoesEntityExist=function() return true end;e.vector3=function(x,y,z) return {x=x,y=y,z=z} end
e.HasAnimDictLoaded=function() return true end;e.GetEntityHeading=function() return 0 end
local revision=1;local publications={};local tasks,animations,freezes=0,0,{}
e.ForgeCore.Posture={isCurrent=function(_,rev,ped) return rev==revision and ped==22 end,
    set=function(kind,value) publications[kind]=value or false;return true end}
e.SetEntityCoordsNoOffset=function() end;e.SetEntityCoords=function() end;e.SetEntityHeading=function() end
e.SetEntityCollision=function() end;e.FreezeEntityPosition=function(ped,value) freezes[ped]=value end
e.ClearPedTasks=function() tasks=tasks+1 end
e.TaskStartScenarioInPlace=function(ped,scenario) assert(ped==22 and scenario=='WORLD_HUMAN_SEAT_LEDGE');animations=animations+1 end
e.TaskStartScenarioAtPosition=function() animations=animations+1 end
e.pr_lib.fivem={streaming={playAnim=function(data) assert(data.pedEntity==22);animations=animations+1 end}}
e.IsControlJustPressed=function() return false end;e.IsDisabledControlJustPressed=function() return false end
local dead=false;e.IsPedDeadOrDying=function() return dead end
r.load('shared/sit.lua');r.load('shared/posture.lua');r.load('client/sit/main.lua')
local profile=e.ForgeCore.PostureContract.anims.male[1].base
r.fire('forge-core:posture:changed',nil,2,'lean',{coords={x=0,y=0,z=0},dict=profile.dict,anim=profile.anim,heading=0,looped=true},1)
assert(animations==1)
revision=2
r.fire('forge-core:posture:changed',nil,2,'lean',{coords={x=0,y=0,z=0},dict=profile.dict,anim=profile.anim,heading=0},1)
assert(animations==1,'Late animation cannot render over a newer posture')
r.fire('forge-core:posture:changed',nil,2,'sit',{coords={x=0,y=0,z=0},heading=0,scenario='WORLD_HUMAN_SEAT_LEDGE',inPlace=true},2)
assert(animations==2)
r.fire('forge-core:posture:changed',nil,2,'sit',nil,2);assert(tasks==1 and freezes[22]==false)
local sit,lean=e.ForgeCore.Client.Sit,e.ForgeCore.Client.Lean
sit.active=true;sit.current={};lean.active=true;lean.current={}
dead=true;r.advance(200)
assert(not sit.active and not lean.active and freezes[11]==false and publications.sit==false and publications.lean==false)
sit.active=true;sit.current={};r.fire('forge-core:session:changed',nil,nil)
assert(not sit.active and not sit.current)
r.fire('onResourceStop',nil,'forge-core')
print('PASS posture rendering: real sit/lean handlers, player index zero, revision guard, clear/unfreeze, death/session/resource cleanup')
