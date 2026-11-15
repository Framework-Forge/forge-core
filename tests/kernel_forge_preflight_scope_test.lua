local T=dofile('tests/kernel_forge_preflight_harness.lua');local count=0
local function case(fn)local r=T.probe();fn(r);count=count+1 end
case(function(r)r.descriptor=nil;assert(not r.api.Check()and r.pings==0)end)
case(function(r)r.descriptor.resource='foreign';assert(not r.api.Check())end)
case(function(r)r.descriptor.side='client';assert(not r.api.Check())end)
case(function(r)r.descriptor.phase='allocated';assert(not r.api.Check())end)
case(function(r)r.descriptor.current=false;assert(not r.api.Check())end)
case(function(r)r.version=false;assert(not r.api.Check()and r.pings==0)end)
case(function(r)r.onesync=0;assert(not r.api.Check())end)
case(function(r)r.db=false;assert(not r.api.Check()and r.pings==0)end)
case(function(r)r.describeHook=function()r.current=false end;local ok,report=r.api.Check();assert(not ok and report.cancelled and r.pings==0)end)
case(function(r)r.pingHook=function()r.current=false end;assert(not r.api.Check())end)
assert(count==10);print('PASS lot126 ten missing/foreign/phase/stale/dependency/onesync/database/reentry cases;no readiness inferred or fake qbx value')
