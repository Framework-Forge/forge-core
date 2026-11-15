local T=dofile('tests/kernel_server_startup_harness.lua');local r=T.new();local before=r.fixture.snapshot();r.prepareStartup()
T.H.same(r.fixture.snapshot(),before,'startup construction inert');assert(r.active()==0 and #r.sqlTrace==0)
assert(r.startupInstall());assert(#r.sqlTrace==0,'Install never prepares schema')
assert(r.surface.exports.GetJobs()==nil,'public ingress gated before startup commit')
r.emit('onResourceStart','forge-core');assert(#r.sqlTrace==0,'early resource event only queued')
r.begin();assert(#r.sqlTrace==2 and r.api.Progress().schema.verified,'awaited users/column precede first initializer yield')
-- Independently compare both SQL payloads with installed QBX, not duplicated test literals.
for i,name in ipairs({'server/storage/players.lua','server/events.lua'})do
    local file=assert(io.open(T.H.qbx..name,'rb'));local source=file:read('*a'):gsub('\r\n','\n');file:close()
    -- Lua long strings omit their initial newline when evaluated by the installed source.
    local sql=assert(source:match('MySQL%.query%(%[%[([%s%S]-)%]%]%)'),'installed SQL payload'):gsub('^\n','')
    assert(r.sqlTrace[i]==sql,'installed QBX schema payload preserved exactly')
end
assert(not r.graph.Central.Parts.Jobs.started,'schema precedes21 services')
r.resume();assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]));assert(r.api.Progress().phase=='running')
assert(r.surface.exports.GetJobs()==r.graph.PlayerCore.Groups.GetJobs(),'public ingress opens at startup commit on same state')
assert(#r.sqlTrace==2 and r.api.Context.Progress().ownStartDelivered,'queued own resource-start does not repeat DDL')
r.emit('onResourceStart','forge-core');assert(#r.sqlTrace==2)
assert(r.graph.PlayerCore==r.fixture.base.PlayerCore and r.graph.Security==r.fixture.base.Callbacks)
r.api.Stop();r.clock.advance(120000);r.api.Poll();assert(r.api.Progress().lifecycle.complete)
assert(r.surface.exports.GetJobs()==nil and #r.errors==0)
print('PASS lot61 actual context60/graph48, awaited exact users/userId before59/21 services, own resource event without DDL replay, gated public ingress and owned stop;SQL/providers virtual')
