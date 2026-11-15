local M=dofile('tests/kernel_native_client_bootstrap_harness.lua');local r=M.new();local before=r.fixture.snapshot()
r.allocateBootstrap();M.H.same(r.fixture.snapshot(),before,'101 allocation inert');assert(r.active()==0 and #r.locales.reads==0)
r.prepareBootstrap();assert(r.api.Graph.Core==r.fixture.state)
local original=r.localePorts.runtimeContext.deliveryContext.configurationContext.mediaContext.shutdown.events
assert(original==r.events,'caller ports preserved');r.startBootstrap();assert(r.api.Progress().phase=='running'and not r.api.OperationalReady)
local data=r.fixture.state.PlayerData;data.citizenid='NATIVE101';data.metadata={};data.money={cash=7}
r.graph.Central.Parts.Producers.Cache.Producer.player(data,'test')
assert(r.cacheDelivery.host.get('playerData').citizenid=='NATIVE101')
assert(r.surface.exports.GetPlayerData()==data and r.active('onResourceStop')==1 and r.active('ox_lib:setLocale')==1)
r.emit('ox_lib:setLocale','en');assert(r.surface.exports.getLocale('error.not_online')=='Player not online')
assert(r.drain()and r.api.Progress().complete and r.active()==0)
assert(#r.fixture.state.ClientMediaContext.Sequence.Progress().ledger==16)
assert(r.surface.exports.GetPlayerData()==nil and r.surface.exports.getLocale('x')==nil)
print('PASS lot101 actual client75 through native99/common100:one canonical PlayerData/passive cache/locale,one Stop/16 cleanups,caller ports intact,ordered startup and owned drain;virtual only')
