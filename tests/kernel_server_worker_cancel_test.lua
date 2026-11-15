local T=dofile('tests/kernel_server_worker_harness.lua');local r=T.new();r.prepare();r.begin()
assert(r.api.Progress().initialization.inFlight);r.api.Close();r.resume()
assert(not r.outcome[1]and r.api.Progress().context=='closed')
assert(not r.graph.Central.Parts.Jobs.started,'cancel at Begin prevents original21 service suffix')
r.clock.advance(10000);assert(#r.errors==0 and r.api.Progress().quiescent)
local pending=T.new();pending.readyHook=function()coroutine.yield('readiness')end;pending.prepare();pending.begin();pending.api.Close();pending.resume()
assert(not pending.outcome[1]and pending.api.Progress().scheduled==0,'yielded server readiness cannot start services after cancel')
local replaced=T.new();replaced.prepare();replaced.fixture.base.ServerWorkerContext={}
assert(not pcall(replaced.api.Start)and replaced.api.Progress().scheduled==0)
local mutated=T.new();mutated.prepare();mutated.api.Bootstrap.Services[1].name='JobService'
assert(not pcall(mutated.api.Start)and mutated.api.Progress().scheduled==0,'service descriptor rename invalidates canonical startup')
local changed=T.new();changed.prepare();changed.graph.PlayerCore.Producers.Status.Threads[2]=function()error('foreign worker')end
assert(not pcall(changed.api.Start)and changed.api.Progress().scheduled==0,'static worker list growth invalidates context')
local malformed=T.new();malformed.ports.graph.helpers.native=nil
assert(not pcall(malformed.factory,malformed.fixture.base,malformed.ports))
assert(not pcall(malformed.factory,malformed.fixture.base,malformed.ports)and #malformed.clock.queue==0,'failed construction cannot be adopted/retried')
print('PASS lot59 server cancellation before21 services/readiness/replacement;no partial startup replay, known task revocation only, no rollback/teardown claim')
