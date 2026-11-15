local T=dofile('tests/kernel_server_startup_harness.lua')
local function runPause(field)
    local r=T.new();r.prepareStartup();r.startupInstall();r[field]=function()coroutine.yield('virtual-await')end;r.begin()
    assert(r.api.Progress().phase=='starting');r.api.Stop();r.resume();r.clock.advance(120000);r.api.Poll()
    assert(not r.outcome[2]and r.api.Progress().phase=='closed'and not r.graph.Central.Parts.Jobs.started)
    assert(r.surface.exports.GetJobs()==nil,'cancelled startup never opens public gate');return r
end
local ping=runPause('pingHook');assert(#ping.sqlTrace==0,'cancelled ping cannot begin DDL')
local ddl=runPause('sqlHook');assert(#ddl.sqlTrace==1,'accepted DDL may remain but second statement cannot begin')
local inspect=runPause('inspectHook');assert(#inspect.sqlTrace==2 and not inspect.api.Progress().schema.verified,'cancelled inspection cannot commit readiness')
local native=T.new();native.prepareStartup();native.startupInstall();native.sqlHook=function()coroutine.yield()end;native.begin()
native.emit('onResourceStop','forge-core');native.resume();native.clock.advance(120000);native.api.Poll()
assert(native.api.Progress().phase=='closed'and #native.sqlTrace==1,'native stop closes pending schema epoch')
local failed=T.new();failed.prepareStartup();failed.startupInstall();failed.sqlFalse=true;failed.begin()
assert(not failed.outcome[2]and #failed.sqlTrace==1 and not failed.graph.Central.Parts.Jobs.started,'SQL refusal prevents services')
local replaced=T.new();replaced.prepareStartup();replaced.startupInstall();replaced.fixture.base.ServerStartupContext={}
assert(not replaced.api.Start()and #replaced.sqlTrace==0,'replaced startup owner cannot execute schema')
local late=T.new();late.prepareStartup();late.startupInstall();late.graph.Parts.World.State.publish('stores',{value=1})
late.begin();assert(not late.outcome[2]and #late.sqlTrace==0,'late World hydration refused before first DDL')
local provider=T.new();provider.prepareStartup();provider.startupInstall();provider.fixture.central.db.query.await=function()error('foreign DB')end
provider.begin();assert(not provider.outcome[2]and #provider.sqlTrace==0,'replaced DB provider refused before DDL')
print('PASS lot61 cancellation during ping/DDL/inspection/native stop, refused SQL/replaced owner;no second DDL or service suffix/retry;no rollback of accepted schema')
