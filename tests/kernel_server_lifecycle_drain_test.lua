local T=dofile('tests/kernel_server_lifecycle_harness.lua')
local r=T.new();r.prepareLifecycle();assert(r.install());r.begin();assert(r.api.Worker.Progress().initialization.inFlight)
assert(not r.api.Stop(),'stop during Start drains prelude');r.resume();assert(not r.outcome[2]);r.clock.advance(120000);r.api.Poll()
assert(r.api.Progress().complete and not r.graph.Central.Parts.Jobs.started,'cancelled startup has no21-service suffix')
local native=T.new();native.prepareLifecycle();native.install();native.begin();native.resume();native.clock.advance(10)
native.emit('onResourceStop','other');assert(not native.api.Progress().nativeBestEffort,'foreign stop does not own shutdown')
native.emit('onResourceStop','forge-core');local p=native.api.Progress()
assert(p.nativeBestEffort and p.cleanupHadInFlight,'native stop records best effort with in-flight workers')
native.clock.advance(120000);native.api.Poll();assert(native.api.Progress().complete)
local entered=T.new();local library=entered.fixture.ports.domains.Stores.library;local withLock=library.withJsonLock
library.withJsonLock=function(...)if entered.yieldNow then coroutine.yield('purchase-lock')end;return withLock(...)end
entered.prepareLifecycle();entered.install();entered.begin();entered.resume();entered.yieldNow=true
-- Enter the actual Stores post-purchase body through its owned PR integration token.
local callback;for _,fn in pairs(entered.fixture.fixtures.Stores.purchaseListeners)do callback=fn;break end;assert(callback)
local co=coroutine.create(function()callback(false,{})end);assert(coroutine.resume(co))
assert(entered.api.Progress().ingress.entered==1 and not entered.api.Stop(),'entered purchase result drains before save/cleanup')
assert(#entered.api.Progress().ledger==0,'no domain teardown before purchase body returns')
assert(coroutine.resume(co));entered.clock.advance(120000);entered.api.Poll()
assert(entered.api.Progress().complete and #entered.errors==0)
local joined=T.new();joined.prepareLifecycle();joined.install();joined.begin();joined.resume();joined.emit('playerJoining')
joined.api.Stop();joined.clock.advance(120000);joined.api.Poll()
assert(joined.api.Progress().complete and #joined.errors==0,'joining timeout cannot run after stop')
local stale=T.new();stale.prepareLifecycle();stale.install();stale.fixture.base.ServerLifecycleContext={}
assert(not stale.api.Start());assert(stale.api.Progress().phase=='cleanup-failed','stale graph skips domain bodies')
local fault=T.new();fault.ports.graph.central.finance.native.wait=function()error('virtual VIP worker failure')end
fault.prepareLifecycle();fault.install();fault.begin();fault.resume();fault.clock.advance(10);fault.api.Poll()
assert(#fault.errors==1 and fault.api.Progress().ingress.phase=='closed','worker error revokes server ingress')
print('PASS lot60 Start cancellation/native best effort/foreign stop/joining timeout/stale owner;known work only, no rollback or physical hook cleanup')
