local T=dofile('tests/kernel_native_context_harness.lua');local count=0
local r=T.server();local old=r.originalContext.deliveryContext.mediaContext.supportContext.configurationContext
local new=r.bootstrapPorts.context.deliveryContext.mediaContext.supportContext.configurationContext
assert(old~=new and old.shared~=new.shared and new.shared==r.configAssembly.Shared);count=count+1
local oldLife=old.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle
local newLife=new.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle
assert(oldLife.worker.graph.central.session.player.db~=newLife.worker.graph.central.session.player.db)
assert(r.installedDB==r.servicesFixture.api.Public.database and newLife.worker.graph.central.session.player.db==r.databaseAssembly.Database)
assert(newLife.callbacks.securityLibrary.callback.register==oldLife.callbacks.securityLibrary.callback.register and #r.databaseCalls==0);count=count+1
assert(not pcall(T.binder.Server,r.originalContext,{Configuration={}},r.databaseAssembly));count=count+1
r.databaseAssembly.Close();r.configAssembly.Close();r.seed.Close();r.servicesFixture.api.Close();r.servicesFixture.wire.close()
local c=T.client();local oldC=c.originalContext.runtimeContext.deliveryContext.configurationContext;local newC=c.bootstrapPorts.context.runtimeContext.deliveryContext.configurationContext
assert(oldC~=newC and oldC.configuration~=newC.configuration and newC.configuration==c.configAssembly.Configuration);count=count+1
local before=#c.uiFixture.scope.bus;assert(c.uiAssembly.Progress().phase=='allocated'and before==0 and c.active()==0)
assert(newC.mediaContext.worker.central.library.callback==oldC.mediaContext.worker.central.library.callback)
assert(newC.mediaContext.worker.central.library.Notify==c.uiAssembly.Library.notify);count=count+1
assert(not pcall(T.binder.Client,c.originalContext,c.configAssembly,{}));count=count+1
c.uiAssembly.Close();c.configAssembly.Close();c.seed.Close();c.seedUnit.finishSeed();c.uiFixture.finish()
assert(count==6);print('PASS lot134 six pure binding/input identity/same123 DB/CaptureRegister/client UI/invalid contract checks;zero bind SQL/listeners')
