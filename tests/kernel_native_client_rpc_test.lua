local T=dofile('tests/kernel_native_client_rpc_harness.lua');local r=T.new();local rpc=r.seedUnit.wire.scopes.client;local before=rpc.Progress().listeners
r.allocateClientProfile();assert(r.profile.Prepare('pt-br'));r.installClientProfile();r.runtimeImports.pollNative();local ok,reason=r.profile.Start();assert(ok,reason)
local count=r.fixture.state.CallbackRegistration.Count;assert(rpc.Progress().listeners==before+count,'unexpected callback listener count');assert(rpc.Progress().leases==count and count>0)
assert(r.active('onResourceStop')==1,'duplicate Stop')
local c=r.profilePorts.bootstrap.context.runtimeContext.deliveryContext.configurationContext.mediaContext.worker.central
assert(c.character.callbacks==rpc.Ox and c.library.callback==rpc.Ox)
local snapshot=r.seedUnit.wire.scopes.server.Ox.await('qbx_core:client:getStatusSnapshot',2)
assert(type(snapshot)=='table','installed server-to-client callback did not return status')
assert(r.profile.Stop());assert(rpc.Progress().leases==0 and rpc.Progress().listeners==before and rpc.Owners.native.IsReady()and rpc.Owners.ox.IsReady())
assert(#r.fixture.state.ClientMediaContext.Sequence.Progress().ledger==16);r.finishProfile()
print('PASS lot136 client101 installed with same122 owners/requests,exact callback listener/lease count restored on Stop,one engine per protocol/one Stop/16 cleanups;virtual only')
