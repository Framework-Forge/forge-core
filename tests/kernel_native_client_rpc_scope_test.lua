local T=dofile('tests/kernel_native_client_rpc_harness.lua');local r=T.M.client();local original=r.profilePorts.bootstrap.context;local rpc=r.seedUnit.wire.scopes.client
local bound=T.bind(original,rpc);local old=original.runtimeContext.deliveryContext.configurationContext.mediaContext;local new=bound.runtimeContext.deliveryContext.configurationContext.mediaContext
assert(bound~=original and new.shutdown~=old.shutdown and new.shutdown.callbacks.native==rpc.Owners.native)
assert(old.shutdown.callbacks.native~=new.shutdown.callbacks.native and new.worker.central.character~=old.worker.central.character)
assert(new.worker.central.character.callbacks==rpc.Ox and new.worker.domains.domains.Work.library.callback==rpc.Native)
assert(not pcall(T.bind,original,{Side='server'}));rpc.Close();assert(not pcall(T.bind,original,rpc));r.finishProfile()
print('PASS lot136 five cloned-input/descriptor-owner/character-request/domain-request/side-and-closed checks;no bind registration')
