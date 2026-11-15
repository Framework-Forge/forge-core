local H=dofile('tests/kernel_harness.lua');local T=dofile('tests/kernel_keybind_profile_harness.lua')
local factory=H.load('kernel/entry/native_server_context_tree.lua',H.environment());local r=T.new('server')
local old=r.profilePorts.bootstrap;local c=old.context;local d=c.deliveryContext;local m=d.mediaContext;local s=m.supportContext
local config=s.configurationContext;local v=config.vehicleContext;local bank=v.bankingContext;local ops=bank.operationsContext;local inv=ops.inventoryContext
local startup=inv.startup;local life=startup.lifecycle
local factories={tasks=life.worker.createTasks,inventory=inv.createInventoryProvider,operations=ops.createOperations,banking=bank.createBanking,
 keys=v.createVehicles,configuration=config.createConfiguration,logging=s.createDelivery,media=m.createMedia,delivery=d.createDelivery,imports=c.createImports}
local f={Side='server',IsCurrent=function()return true end,Events=r.events,RegistrationInput=old.registration,
 Locales={Ports=c.locale,CreateLocale=c.createLocale},NativeCache={Cache=c.imports.nativeCache},Factories={Get=function(name)return assert(factories[name],name)end}}
local p={graph=life.worker.graph,public=life.public,callbacks=life.callbacks,bootstrap=life.worker.bootstrap,inventory=inv.inventory,
 operations=ops.operations,banking=bank.banking,vehicles=v.vehicles,shared=config.shared,configuration=config.configuration,
 loggingDelivery=s.delivery,hooks=s.hooks,logger=s.logger,media=m.media,delivery=d.delivery,running=coroutine.running,onError=error,
 isReady=old.isReady,isCurrent=old.isCurrent,resourceState=startup.resourceState,databaseReady=startup.databaseReady}
local tree=factory(f,p);assert(tree.registration==old.registration)
for _,key in ipairs({'graph','public','callbacks','bootstrap','inventory','operations','banking','vehicles','shared','configuration','loggingDelivery','hooks','logger','media','delivery','resourceState','databaseReady'})do
 local bad={};for k,vv in pairs(p)do bad[k]=vv end;bad[key]=nil;assert(not pcall(factory,f,bad),key)
end
r.profilePorts.bootstrap=tree;local q=r.allocate166();assert(q.Prepare('pt-br'));r.surface.Open();assert(q.Install())
r.emit('onResourceStart','forge-core');r.begin();if coroutine.status(r.co)~='dead'then r.resume()end
assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[3]or r.outcome[2]))
assert(q.Bootstrap.Graph.PlayerCore==r.fixture.base.PlayerCore)
q.Stop();r.clock.advance(1200000);assert(q.Poll());r.platform.Close();r.finishProfile()
print('PASS183 server tree runs actual166/74 graph;one PlayerCore/raw services;missing mandatory leaves refused')
