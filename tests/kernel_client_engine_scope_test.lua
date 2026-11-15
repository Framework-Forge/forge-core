local H=dofile('tests/kernel_harness.lua');local W=dofile('tests/kernel_worker_harness.lua')
local clock=W.clock();local listeners={};local nextId=0;local removed=0;local actions=0;local disabled,destroyed=0,0
local env={CreateThread=clock.native.CreateThread,SetTimeout=clock.native.SetTimeout,Wait=clock.native.Wait,Citizen={x=7},PRBridgeEditorCamera='original'}
local f={IsCurrent=function()return true end,Events={markNetwork=function()return true end,listen=function(_,fn)nextId=nextId+1;listeners[nextId]=fn;return nextId end,
 remove=function(id)listeners[id]=nil;removed=removed+1;return true end}}
local pr={forgeKeybindScope={Library={addKeybind=function()return{disable=function()disabled=disabled+1 end,destroy=function()destroyed=destroyed+1 end}end}}}
local api=H.load('../pr_bridge/bridge/delivery/forge_client_engine_scope.lua',H.environment())({foundation=f,prCore=pr,environment=env,
 createTasks=W.create,running=coroutine.running,onError=error})
assert(api.Open(function(e)
 assert(e~=env and e._G==e and e.Citizen.x==7);e._G.PRBridgeEditorCamera='private'
 e.RegisterNetEvent('demo',function()actions=actions+1 end);e.PRAddKeybind({})
 e.Citizen.CreateThread(function()e.Wait(50);actions=actions+10 end)
 api.AddCleanup('stop',function()actions=actions+100 end)
end))
local retained=listeners[1];retained();assert(actions==1 and env.PRBridgeEditorCamera=='original')
assert(api.Close());retained();clock.advance(100);assert(actions==101 and removed==1 and disabled>=1 and destroyed==1)
assert(not pcall(api.Invoke,function()end,false))
print('PASS223 private globals/Citizen scheduler;owned events/keybinds;queued work cancelled;selective drain/retained callbacks')
