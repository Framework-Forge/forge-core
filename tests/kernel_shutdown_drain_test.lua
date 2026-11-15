local T=dofile('tests/kernel_shutdown_harness.lua');local r=T.new();r.prepareShutdown();assert(r.install()and r.api.Start())
-- Enter only actual Jobs bootstrap (last worker); other27 bodies remain queued.
r.clock.step(#r.clock.queue);assert(r.clock.waits[#r.clock.waits]==1500)
local stores=r.graph.Parts.Stores.Stores;local prior=stores.payload
assert(r.graph.Client.WorldState.apply({generation=58,states={stores={generation=58,revision=1,
    data={settings={enabled=false},stores={},late58=true}}},ready=false}))
local ok,why=r.api.Stop();assert(not ok and why=='workers_pending')
assert(r.api.Progress().phase=='draining'and #r.api.Progress().ledger==0)
r.clock.advance(10000);assert(r.api.Poll()and r.api.Progress().complete and #r.errors==0)
assert(stores.payload==prior,'queued World subscription cannot recreate scene after shutdown')
assert(not r.api.Start()and not r.worker.Start())
-- Native stop uses the same bodies once, but reports its in-flight worker honestly.
local native=T.new();native.prepareShutdown();assert(native.install()and native.api.Start())
native.clock.step(#native.clock.queue);native.emit('onResourceStop','pr_bridge')
assert(native.api.Progress().phase=='running','foreign resource does not close context')
native.emit('onResourceStop','forge-core')
local p=native.api.Progress();assert(p.nativeBestEffort and not p.complete and #p.ledger==16)
native.clock.advance(10000);assert(native.api.Poll()and #native.errors==0)
-- Cancellation during initializer/readiness must not teardown before Start unwinds.
local starting=T.new();starting.prepareShutdown();assert(starting.install())
starting.readyHook=function()coroutine.yield('readiness')end
local co=coroutine.create(starting.api.Start);assert(coroutine.resume(co));starting.api.Stop()
assert(#starting.api.Progress().ledger==0);assert(coroutine.resume(co));assert(starting.api.Poll())
-- Actual54 entity bag resolution entered before Stop must drain before domain teardown.
local bag=T.new();bag.fixture.central.library.waitFor=function()coroutine.yield('entity resolution');return 20 end
bag.prepareShutdown();assert(bag.install())
local entered=coroutine.create(function()bag.keys.emit('initVehicle','entity:58',true)end)
assert(coroutine.resume(entered)and bag.api.Progress().ingressPending==1)
assert(not bag.api.Stop()and #bag.api.Progress().ledger==0)
assert(coroutine.resume(entered)and bag.api.Progress().ingressPending==0)
assert(bag.api.Poll()and bag.api.Progress().complete,'entered statebag drained before teardown')
print('PASS lot58 actual Jobs.Wait drain before manual teardown; native stop best effort/in-flight reported; cancelling56 during readiness waits for Start unwind; no live engine teardown')
