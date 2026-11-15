-- Execute the installed loadscreen client and PR integration; only Cfx clock/exports are virtual.
local function scenario(seconds,elapsed,readyAt,useSpawn)
 local now,shutdown,nuiShutdown=0,0,0;local exportsMap,events,threads,messages={},{},{},{}
 local config={minimumLoadscreenSeconds=seconds,loadingElapsedMs=elapsed}
 local env=setmetatable({},{__index=_G})
 env.GetGameTimer=function()return now end
 env.Wait=function(ms)return coroutine.yield(ms)end
 env.CreateThread=function(fn)threads[#threads+1]=coroutine.create(fn)end
 env.exports=function(name,fn)exportsMap[name]=fn end
 env.AddEventHandler=function(name,fn)events[name]=fn end
 env.RegisterNetEvent=env.AddEventHandler
 env.RegisterNUICallback=function()end
 env.SetNuiFocus=function()end
 env.SendNUIMessage=function()end
 env.SendLoadingScreenMessage=function(payload)messages[#messages+1]=payload end
 env.json={encode=function(value)return value end}
 env.ShutdownLoadingScreen=function()shutdown=shutdown+1 end
 env.ShutdownLoadingScreenNui=function()nuiShutdown=nuiShutdown+1 end
 env.pr_lib={callback={await=function(name)
  assert(name=='forge-loadscreen:server:getConfig');return config
 end},addCommand=function()end}
 local file=assert(io.open('../forge-loadscreen/client.lua','rb'));local text=file:read('*a');file:close()
 assert(load(text,'@@forge-loadscreen/client.lua','t',env))()
 -- Publication of configuration alone must not close loading, even with 100% downloaded.
 local function resume(thread)
  local ok,wait=coroutine.resume(thread);assert(ok,tostring(wait));return wait
 end
 local configThread=table.remove(threads,1);assert(resume(configThread)==0);resume(configThread)
 assert(coroutine.status(configThread)=='dead'and shutdown==0 and nuiShutdown==0)
 now=readyAt
 local native={GetResourceState=function(name)assert(name=='forge-loadscreen');return'started'end,
  TriggerEvent=function()end,TriggerServerEvent=function()end,ExecuteCommand=function()end}
 local prFile=assert(io.open('../pr_bridge/bridge/delivery/forge_client_integrations.lua','rb'))
 local make=assert(load(prFile:read('*a'),'@@pr_bridge/bridge/delivery/forge_client_integrations.lua','t',_G))();prFile:close()
 local external={['forge-loadscreen']={FinishLoadingScreen=function()return exportsMap.FinishLoadingScreen()end}}
 local integration=make({foundation={Side='client',IsCurrent=function()return true end},native=native,external=external,
  environment={},loadPR=function(path,target)assert(path=='@pr_bridge/shared/progression');target.PRProgression={}end})
 local close
 if useSpawn then events.playerSpawned();close=table.remove(threads,1)
 else close=coroutine.create(integration.Character.finishLoadingScreen)end
 local expected=math.max(readyAt,seconds*1000-elapsed)
 local iterations=0
 while coroutine.status(close)~='dead'do
  local wait=resume(close);iterations=iterations+1;assert(iterations<1000)
  if coroutine.status(close)~='dead'then
   assert(shutdown==0 and nuiShutdown==0,'never close before duration finishes')
   assert(type(wait)=='number'and wait>=0);now=now+wait
  end
 end
 assert(now>=expected and now<=expected+100,'respect configured minimum without an infinite wait')
 assert(shutdown==1 and nuiShutdown==1)
 exportsMap.FinishLoadingScreen();assert(shutdown==1 and nuiShutdown==1,'repeat finish must not close again')
 events.playerSpawned();if useSpawn then assert(#threads==0,'repeat spawn must not schedule again')end
 assert(integration.Close())
 return #messages
end
assert(scenario(180,0,15000,false)>1) -- loaded in 15s, server requires 3 minutes
scenario(180,165000,15000,false) -- server-provided elapsed time already covers the minimum
scenario(0,0,15000,false)
scenario(5,0,15000,true)
print('PASS installed loadscreen through PR: 15s readiness waits configured 180s; elapsed/zero/expired duration and spawn path, no forced close at 100%')
