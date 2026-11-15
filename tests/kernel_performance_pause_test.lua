local now,queries,threads,events,commands=0,0,{},{},{}
local loaded,dead=true,false
local e=setmetatable({},{__index=function(_,k)error('Missing pause test port '..k)end})
for _,k in ipairs({'type','pairs','ipairs','tonumber','tostring','pcall','math','string','table','assert'})do e[k]=_G[k]end
e.Config={Command='pause',Filters={}};e.PauseBlipModels=false;e.GetGameTimer=function()return now end
e.PlayerPedId=function()return 1 end;e.PlayerId=function()return 1 end;e.GetPlayerServerId=function()return 1 end
e.GetPlayerName=function()return'Player'end;e.IsEntityDead=function()return dead end
for _,name in ipairs({'IsPauseMenuActive','IsNuiFocused','IsPlayerSwitchInProgress'})do e[name]=function()return false end end
e.GetResourceKvpString=function()return nil end;e.GetCurrentResourceName=function()return'forge-pause'end
e.pr_lib={framework={IsPlayerLoaded=function()queries=queries+1;return loaded end,GetPlayer=function()return{}end,
 GetJobInfo=function()return{}end,GetMoney=function()return 0 end}}
e.PauseOptions={values=function()return{}end,info=function()return{}end}
for _,name in ipairs({'pause','resume','apply'})do e.PauseOptions[name]=function()end end
e.PauseEnvironment={hud=function()end};e.ForgePortrait={start=function()end,stop=function()end};e.ForgeMap={stop=function()end}
e.PauseSettings={validate=function(v)return v end,apply=function()end}
for _,name in ipairs({'SendNUIMessage','SetNuiFocus','SetNuiFocusKeepInput','TriggerEvent','DisableControlAction','DisableAllControlActions','DisablePlayerFiring','RegisterNUICallback'})do e[name]=function()end end
e.IsDisabledControlJustReleased=function()return false end
e.AddEventHandler=function(name,fn)events[name]=fn end;e.RegisterNetEvent=e.AddEventHandler
e.RegisterCommand=function(name,fn)commands[name]=fn end;e.CreateThread=function(fn)threads[#threads+1]=fn end
e.Wait=coroutine.yield
assert(loadfile('../forge-pause/client/main.lua','t',e))()
e.PauseMenu.applySettings({revision=1,settings={}});commands.pause();assert(e.PauseMenu.isOpen()and queries==1)
local co=coroutine.create(threads[#threads]);assert(coroutine.resume(co))
for i=1,60 do now=i*16;assert(coroutine.resume(co))end
assert(queries==1,'per-frame framework polling')
now=1000;assert(coroutine.resume(co));assert(queries==2)
events['QBCore:Client:OnPlayerUnload']();assert(not e.PauseMenu.isOpen(),'logout must close immediately')
now=1500;commands.pause();dead=true;assert(coroutine.resume(co));assert(not e.PauseMenu.isOpen(),'death must close immediately')
dead=false;now=2000;commands.pause();loaded=false;now=3000;assert(coroutine.resume(co));assert(not e.PauseMenu.isOpen(),'fallback reconciliation')
print('PASS pause: 60 frames without framework polling, one-second reconciliation, immediate logout/death')
