local T=dofile('tests/kernel_native_platform_harness.lua');local count=0
local function case(side,fn)local r=T.new(side);fn(r);r.finish();count=count+1 end
case('server',function(r)r.ports137.side='client';assert(not pcall(r.mount))end)
case('client',function(r)r.mount();assert(not pcall(r.platform.Player))end)
case('server',function(r)r.mount();assert(not pcall(r.platform.Select,{'AddEventHandler'}))end)
case('server',function(r)r.mount();assert(not pcall(r.platform.Select,{'Unknown137'}))end)
case('server',function(r)r.mount();r.current=false;assert(not pcall(r.platform.Select,{'Wait'}))end)
case('server',function(r)r.mount();local held=r.platform.Select({'time'}).time;r.platform.Close();assert(not pcall(held))end)
assert(count==6);print('PASS lot137 six side/Player-side/raw-listener/missing/stale/closed-port cases;no discovery/fallback')
