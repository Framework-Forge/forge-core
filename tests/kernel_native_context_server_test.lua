local T=dofile('tests/kernel_native_context_harness.lua');local r=T.server();local before=#r.databaseCalls
r.allocateBootstrap();assert(r.api.Prepare('pt-br'));assert(r.graph==nil);r.graph=r.api.Graph
assert(r.fixture.base.PlayerCore==r.graph.PlayerCore);r.installNewPR();assert(r.servicesFixture.wire.scopes.server.Progress().leases==203)
r.emit('onResourceStart','forge-core');r.begin();if coroutine.status(r.co)~='dead'then r.resume()end
assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[3]or r.outcome[2]));assert(r.api.Progress().phase=='running'and #r.databaseCalls>before)
assert(r.fixture.base.ServerConfigurationContext.Config.Server.player.status.checkpointMinutes==15)
r.api.Stop();r.clock.advance(1200000);r.api.Poll();r.databaseAssembly.Close();r.configAssembly.Close();r.seed.Close();r.servicesFixture.api.Close();r.servicesFixture.wire.close()
print('PASS lot134 server100 with131 config/132 installed PR database and126 Forge startup,203 same122 leases;native platform/domain/logging/media still explicit fixtures')
