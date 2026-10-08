local H=dofile('tests/cache_harness.lua')
local r=H.new(false);local e=r.env
e.ForgeCore.t=function(key) return key end
e.PlayerPedId=function() return 11 end;e.PlayerId=function() return 1 end
local coords,health,frozen,invincible={x=0,y=0,z=0},100,false,false
local faded,animReady,dead=false,true,false
local tasks,released,keybinds={}, {}, {}
e.GetEntityCoords=function() return coords end
e.DoesEntityExist=function() return true end
e.NetworkResurrectLocalPlayer=function(x,y,z) coords={x=x,y=y,z=z} end
e.SetEntityCoordsNoOffset=function(_,x,y,z) coords={x=x,y=y,z=z} end
e.SetEntityCoords=function(_,x,y,z) coords={x=x,y=y,z=z+1} end -- native ped-origin calibration
e.FreezeEntityPosition=function(_,value) frozen=value end
e.SetEntityInvincible=function(_,value) invincible=value end
e.SetPedCanRagdoll=function() end;e.ClearPedTasks=function() end;e.SetEntityHeading=function() end
e.RequestCollisionAtCoord=function() end;e.HasCollisionLoadedAroundEntity=function() return true end
e.RequestAnimDict=function() end;e.HasAnimDictLoaded=function() return animReady end
e.DoScreenFadeOut=function() faded=true end;e.DoScreenFadeIn=function() faded=false end
e.IsScreenFadedOut=function() return faded end;e.IsScreenFadedIn=function() return not faded end
e.TaskPlayAnim=function(_,dict,clip) tasks[#tasks+1]=dict..'/'..clip end
e.IsPedDeadOrDying=function() return dead end
e.TriggerServerEvent=function(name,token) released[#released+1]={name,token} end
e.pr_lib.ShowTextUI=function() end;e.pr_lib.HideTextUI=function() end
e.pr_lib.addKeybind=function(data) keybinds[data.name]=data end
r.load('shared/automedic.lua');r.load('client/automedic/hospital.lua')
local hospital=e.ForgeCore.Hospital
local payload={token='token',bed={coords={x=10,y=20,z=30},heading=90,exit={x=10,y=21,z=29},exitHeading=180}}
assert(hospital.recover(payload,function() health=110 end));r.advance(1)
assert(hospital.isRecovering() and frozen and invincible and health==110 and not faded)
assert(coords.z==31,'pose must use the same ped-origin calibration as the PR Bridge editor')
assert(tasks[1]:find('body_search',1,true))
assert(keybinds.forge_core_leave_hospital_bed.onPressed());assert(not hospital.leave())
r.advance(5001)
assert(not hospital.isRecovering() and not frozen and not invincible and coords.z==29)
assert(tasks[2]:find('sleep_getup_rubeyes',1,true))
assert(released[#released][2]=='token')
assert(hospital.recover(payload,function() health=110 end));r.advance(1)
r.fire('forge-core:session:changed',nil,nil);assert(not hospital.isRecovering() and not frozen)
-- A late animation load must not resurrect a character after logout.
animReady=false;assert(hospital.recover(payload,function() health=110 end));r.advance(1)
r.fire('forge-core:session:changed',nil,nil);r.advance(5001)
assert(not hospital.isRecovering() and not frozen and not faded)
animReady=true;assert(hospital.recover(payload,function() health=110 end));r.advance(1)
r.fire('onResourceStop',nil,'forge-core');assert(not hospital.isRecovering() and not frozen and not invincible)
-- Exercise the real NPC failure -> callback -> hospital event routing.
local originalCreate=e.CreateThread;local mainThread
e.CreateThread=function(fn) mainThread=fn;return originalCreate(fn) end
local originalWait=e.Wait;e.Wait=function(ms) return originalWait(math.max(10,ms or 0)) end
local metadata={isdead=true};health=100
e.joaat=function() return 1 end;e.IsEntityDead=function() return health<=100 end
e.IsPedFatallyInjured=e.IsEntityDead;e.GetEntityHealth=function() return health end
e.GetEntityMaxHealth=function() return 200 end;e.SetEntityHealth=function(_,value) health=value end
e.GetEntityHeading=function() return 0 end
e.GetPedCauseOfDeath=function() return 0 end;e.GetWeapontypeGroup=function() return 0 end
e.GetCloudTimeAsInt=function() return math.floor(r.now/1000) end
e.RequestModel=function() end;e.HasModelLoaded=function() return false end
e.IsControlJustPressed=function() return false end;e.IsDisabledControlJustPressed=function() return false end
for _,name in ipairs({'SetEntityVisible','SetEntityCanBeDamaged','ClearPedTasksImmediately','ClearPedBloodDamage','ResetPedVisibleDamage'}) do e[name]=function() end end
e.exports.qbx_core={GetPlayerData=function() return {metadata=metadata} end,GetStatus=function() return {hunger=100,thirst=100} end}
e.pr_lib.framework.IsPlayerDead=function() return metadata.isdead end;e.pr_lib.Notify=function() end
local fallbackCalls=0
e.pr_lib.callback.await=function(name,_,token,reason)
    if name==e.PR.AutoMedic.Callbacks.getStatus then return true,{enabled=true,cooldown=0,reviveHealthPercent=10,deathAt=math.floor(r.now/1000)} end
    if name==e.PR.AutoMedic.Callbacks.requestTreatment then return true,{token='npc-failed'} end
    if name==e.PR.AutoMedic.Callbacks.recoverHospital then
        assert(token=='npc-failed' and reason=='model_failed');fallbackCalls=fallbackCalls+1
        metadata.isdead=false;local response=H.copy(payload);response.token=token
        r.fire(e.PR.AutoMedic.Events.revive,65535,response)
        return true,{hospital=true}
    end
    if name==e.PR.AutoMedic.Callbacks.cancelTreatment then return true end
    error('Unexpected callback '..name)
end
r.load('client/automedic/main.lua')
local dispatch
for index=1,30 do local name,value=debug.getupvalue(mainThread,index);if not name then break end;if name=='dispatchMedic' then dispatch=value end end
assert(dispatch,'Actual main loop must route E through dispatchMedic')
e.CreateThread(dispatch);r.advance(11000)
assert(fallbackCalls==1 and hospital.isRecovering() and health>100 and not faded)
hospital.clear(true)
e.PR.AutoMedic.Npc.wakeup.enabled=false
r.fire(e.PR.AutoMedic.Events.revive,65535);r.advance(20)
assert(health>100 and not hospital.isRecovering() and not faded,'on-site revival must remain separate from hospital recovery')
print('PASS hospital client: calibrated lying pose, E exit animation, safe standing exit, session/stop/late-animation cleanup')
