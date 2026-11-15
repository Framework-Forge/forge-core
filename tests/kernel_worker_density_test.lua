local T=dofile('tests/kernel_worker_harness.lua');local W=dofile('tests/kernel_world_harness.lua')
local fixture=W.client(true);local c=T.clock();local s,n=c.scope()
for key,value in pairs(fixture.native)do if n[key]==nil then n[key]=value end end
local density=T.H.load('kernel/client/density.lua',W.env())({config=fixture.config,native=n,world={peek=function()return nil end}})
assert(s.Open());local h1=s.Launch(n,density.Threads[1]);local h2=s.Launch(n,density.Threads[2])
c.advance(0);local effects=#fixture.trace;assert(effects>0 and s.Snapshot().running==2)
c.advance(2);assert(#fixture.trace>effects,'real density frame loop active');effects=#fixture.trace
s.Close();assert(not s.Snapshot().quiescent);c.advance(10000)
assert(#fixture.trace==effects,'real density loops have no effect after next owned Wait')
assert(s.Task(h1).status=='cancelled'and s.Task(h2).status=='cancelled'and s.Snapshot().quiescent and #c.errors==0)
assert(c.waits[1]==0 or c.waits[2]==0)
local long=false;for _,delay in ipairs(c.waits)do if delay==10000 then long=true end end;assert(long,'long interval preserved')
print('PASS lot57 actual Density35 frame/10000ms workers: effects before close, cooperative cancellation after Wait, no suffix effects; no world rollback or domain cleanup claimed')
