local T=dofile('tests/kernel_native_library_harness.lua');local count=0
local function case(fn)local r=T.new();fn(r);r.finish();count=count+1 end
case(function(r)r.public.cache={};assert(not pcall(r.allocate))end)
case(function(r)r.ports.nativeCache={resource='other'};assert(not pcall(r.allocate))end)
case(function(r)r.ports.rpc.Side='client';assert(not pcall(r.allocate))end)
case(function(r)r.allocate();r.current=false;assert(not r.api.Prepare())end)
case(function(r)r.allocate();r.loadHook=function(path)if path:find('library/init',1,true)then r.api.Close()end end;assert(not r.api.Prepare()and r.public.cache==nil)end)
case(function(r)r.allocate();assert(r.api.Prepare());local foreign={};r.public.library=foreign;assert(not r.api.IsCurrent());r.api.Close();assert(r.public.library==foreign)end)
assert(count==6);print('PASS lot128 six slot/native-cache/side/current/Close/foreign ownership cases;no fake native cache or second callback engine')
