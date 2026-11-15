local T=dofile('tests/kernel_engine_ports_harness.lua');local count=0
local function check(fn)local r=T.new('server');fn(r);r.finish146();count=count+1 end
check(function(r)r.port146.side='client';assert(not pcall(r.mount146))end)
check(function(r)r.mount146();assert(not pcall(r.engine.Select,{raw='RegisterNetEvent'}))end)
check(function(r)r.mount146();assert(not pcall(r.engine.Select,{bad='MissingEngine146'}))end)
check(function(r)r.mount146();local fn=r.engine.Select({name='GetPlayerName'}).name;r.current=false;assert(not pcall(fn,2))end)
check(function(r)r.mount146();local fn=r.engine.Select({name='GetPlayerName'}).name;r.native.GetPlayerName=function()return'other'end;assert(not pcall(fn,2))end)
check(function(r)r.mount146();local fn=r.engine.Select({time='$time'}).time;assert(fn()==101);r.port146.time=function()return 9 end;assert(not pcall(fn))end)
check(function(r)r.native.Engine146Wait=function()coroutine.yield('accepted');return nil,false,17 end;r.mount146();local fn=r.engine.Select({run='Engine146Wait'}).run
    local co=coroutine.create(fn);assert(coroutine.resume(co));assert(not r.engine.Close());local ok,a,b,c=coroutine.resume(co);assert(ok and a==nil and b==false and c==17 and r.engine.Progress().complete)end)
assert(count==7);print('PASS146 seven side/raw-registration/missing/stale/replacement/adjunct/pending-close checks;no native effects')
