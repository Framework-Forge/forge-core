local T=dofile('tests/kernel_engine_ports_harness.lua');local make=T.H.load('kernel/entry/client_engine_schema.lua',T.H.environment());local schema=make();local other=make()
assert(schema~=other);schema.time='changed';assert(other.time=='GetGameTimer')
local r=T.new('client',other);local e=r.mount146();assert(not pcall(e.Select,{capture='CaptureRegister'}))
assert(not pcall(e.Select,{optional='SetTrafficLightsState2'}));r.current=false;assert(not pcall(e.Select,other));r.current=true
local p=e.Select({thread='CreateThread',timer='SetTimeout'});local called=0;p.thread(function()called=called+1 end);p.timer(1,function()called=called+1 end)
e.Close();r.clock.advance(2);assert(called==0 and r.api.IsCurrent());r.finish146()
local s=T.new('server');s.mount146();local c=T.new('client',other);c.mount146();c.engine.Close();assert(s.engine.IsCurrent());s.finish146();c.finish146()
print('PASS147 six schema/registration/optional/stale/queued-close/side-isolation checks;borrowed execution remains open')
