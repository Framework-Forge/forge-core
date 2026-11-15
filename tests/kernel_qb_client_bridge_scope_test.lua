local T=dofile('tests/kernel_qb_client_bridge_harness.lua');local n=0
local r=T.new(true);r.trace={};r.ready=false
assert(not pcall(r.api.GetCoreObject)and not pcall(r.fire,'QBCore:Command:CallCommand','cmd')and #r.trace==0);n=n+1
r.ready=true;r.readyHook=function()coroutine.yield('ready')end
local co=coroutine.create(r.api.GetCoreObject);assert(coroutine.resume(co));assert(r.api.Progress().pending==1)
r.api.Close();assert(not r.api.Progress().complete);r.readyHook=nil
local ok,err=coroutine.resume(co);assert(not ok and tostring(err):find('qb_client_bridge_replaced',1,true))
assert(r.api.Progress().complete and r.object.PlayerData==r.state.PlayerData);n=n+1
-- Accepted KeyPressed is tracked through queue/Wait and may hide later shared provider text after Close.
local r=T.new(true);r.trace={};r.exported.KeyPressed();assert(r.api.Progress().tasks==1)
r.yielding=true;local status,delay=r.runTask();assert(status=='suspended'and delay==500)
r.library.showTextUI('other text');r.api.Close();assert(not r.api.Progress().complete)
r.yielding=false;assert(r.runTask()=='dead');assert(r.trace[#r.trace].kind=='hide'and r.api.Progress().complete)
assert(not pcall(r.exported.KeyPressed));n=n+1
local r=T.new(true);r.ports.scheduler.createThread=function(fn)r.tasks[#r.tasks+1]=coroutine.create(fn);error('fixture_uncertain_publication',0)end
assert(not pcall(r.exported.KeyPressed));assert(r.api.Progress().tasks==1 and r.api.Progress().uncertainPublication)
r.api.Close();assert(not r.api.Progress().complete);assert(r.runTask()=='dead'and r.api.Progress().complete);n=n+1
local r=T.new(true);r.trace={};r.keyHook=function()coroutine.yield('keys')end
local co=coroutine.create(function()r.fire('QBCore:Client:VehicleInfo',{netId=1,seat=0,event='Entered'})end)
assert(coroutine.resume(co));assert(r.api.Progress().pending==1);r.api.Close();assert(not r.api.Progress().complete)
assert(coroutine.resume(co));assert(r.api.Progress().complete and r.trace[#r.trace].kind=='event');n=n+1
local r=T.new(true);r.trace={};r.readyHook=function()coroutine.yield('ready')end
local co=coroutine.create(function()r.fire('QBCore:Command:CallCommand','cmd')end);assert(coroutine.resume(co));r.current=false;r.readyHook=nil
assert(not coroutine.resume(co)and #r.trace==0);n=n+1
local H=T.H
local closed=false
local minimal={IsCurrent=function()return true end,Close=function()closed=true end,Progress=function()return{complete=closed}end}
local disabled=H.load('kernel/compat/qb/client_main.lua',T.environment())(minimal,{
    native={GetConvar=function()return'false'end},isCurrent=function()return true end,isReady=function()error('disabled bridge must not request readiness')end})
assert(not disabled.Enabled and next(disabled.Exports)==nil and #disabled.Events==0)
disabled.Close();assert(disabled.Progress().complete);n=n+1
print('PASS lot92 scope:'..n..' checks;readiness/owner/Close,queued500ms tasks/uncertain publication and accepted key-await effects tracked;disabled bridge needs no providers,retained object not globally revoked')
