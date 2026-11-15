local T=dofile('tests/kernel_worker_harness.lua');local r=T.new();r.prepare()
local player,shared=r.fixture.state.PlayerData,r.fixture.state.Shared
assert(r.api.Start(),'actual initialization then worker scheduling')
local p=r.api.Progress();assert(p.context=='running'and p.initialization.phase=='initialized'and p.scheduled>=27)
assert(r.readyCalls==1 and r.fixture.central.groupPulls==1 and #r.api.Describe()==27)
assert(r.fixture.state.PlayerData==player and r.fixture.state.Shared==shared and r.graph.Client.WorldState==r.graph.Parts.World.WorldState)
assert(not r.api.Start(),'context starts once')
-- All actual worker descriptors were queued by the platform; close before entry suppresses all.
assert(r.api.Close());local count=#r.clock.queue;assert(count>=27 and r.api.Progress().quiescent)
r.clock.advance(10000);assert(#r.errors==0 and #r.clock.queue==0 and r.api.Progress().cancelled>=27)
-- Readiness failure never launches static workers or replays the initializer prefix.
local cold=T.new();cold.ready=false;cold.prepare();assert(not pcall(cold.api.Start));assert(cold.api.Progress().scheduled==0 and not cold.api.Start())
-- A timer scheduled by the real Starterpack initializer belongs to this same context.
assert(p.scheduled>27,'real initializer scheduled dynamic task')
local stale=T.new();stale.prepare();stale.fixture.state.ClientWorkerContext={}
assert(not pcall(stale.api.Start)and stale.api.Progress().scheduled==0)
-- Dispose while readiness yields: no stage or worker can start afterwards.
local pending=T.new();pending.prepare();pending.readyHook=function()coroutine.yield('ready')end
local co=coroutine.create(pending.api.Start);assert(coroutine.resume(co));pending.api.Close()
local ok=coroutine.resume(co);assert(not ok and pending.api.Progress().scheduled==0)
-- Bootstrap uses standalone ports.wait rather than native.Wait: it must be owned too.
local jobs=T.new();jobs.prepare();jobs.api.Start();jobs.clock.step(#jobs.clock.queue)
assert(jobs.clock.waits[#jobs.clock.waits]==1500 and jobs.api.Progress().running==1)
jobs.api.Close();jobs.clock.advance(10000);assert(jobs.api.Progress().quiescent and #jobs.errors==0,'standalone Jobs.wait cancellation')
-- Error in an actual worker quarantines the scope and is visible at the context boundary.
local broken=T.new();broken.ports.domains.domains.Jobs.wait=function()error('actual bootstrap failure',0)end
broken.prepare();broken.api.Start();broken.clock.step(#broken.clock.queue)
assert(broken.api.Progress().context=='failed'and #broken.errors==1 and broken.api.Progress().quiescent)
broken.clock.advance(10000);assert(#broken.errors==1,'failed worker does not leave siblings active')
print('PASS lot57 actual client49/50: seven real initialization stages then27 static workers plus owned dynamic initializer task, pre-entry cancellation/readiness/replacement, same authorities; bodies not all entered and no real boot')
