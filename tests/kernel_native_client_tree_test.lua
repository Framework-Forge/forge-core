local H=dofile('tests/kernel_harness.lua');local T=dofile('tests/kernel_keybind_profile_harness.lua')
local factory=H.load('kernel/entry/native_client_context_tree.lua',H.environment());local r=T.new('client')
local root=r.profilePorts.bootstrap.context;local media=root.runtimeContext.deliveryContext.configurationContext.mediaContext
local funcs={};local f={Side='client',IsCurrent=function()return true end,Events=r.events,RegistrationInput=r.profilePorts.bootstrap.registration,
 Locales={Ports=root.locale,CreateLocale=root.createLocale},NativeCache={Cache=root.runtimeContext.imports.nativeCache},
 Factories={Get=function(name)funcs[name]=(funcs[name]or 0)+1
 return ({media=media.createMedia,tasks=media.worker.createTasks,imports=root.runtimeContext.createImports,
 delivery=root.runtimeContext.deliveryContext.createDelivery,configuration=root.runtimeContext.deliveryContext.configurationContext.createConfiguration})[name]end}}
local ports={central=media.worker.central,domains=media.worker.domains,public=media.shutdown.public,input=media.shutdown.input,callbacks=media.shutdown.callbacks,
 media=media.media,delivery=root.runtimeContext.deliveryContext.delivery,configuration=root.runtimeContext.deliveryContext.configurationContext.configuration,
 running=coroutine.running,onError=error,isCurrent=r.profilePorts.bootstrap.isCurrent,isReady=r.profilePorts.bootstrap.isReady}
local tree=factory(f,ports);assert(tree.context~=root and tree.registration==f.RegistrationInput)
local worker=tree.context.runtimeContext.deliveryContext.configurationContext.mediaContext.worker
assert(worker.central==ports.central and worker.domains==ports.domains and worker.createTasks==media.worker.createTasks)
for _,key in ipairs({'central','domains','public','input','callbacks','media','delivery','configuration','onError'})do local p={};for k,v in pairs(ports)do p[k]=v end;p[key]=nil;assert(not pcall(factory,f,p),key)end
r.profilePorts.bootstrap=tree;local p=r.allocate166();assert(p.Prepare('pt-br'));r.surface.Open();assert(p.Install());r.runtimeImports.pollNative();assert(p.Start())
p.Stop();r.clock.advance(120000);assert(p.Poll());r.platform.Close();r.utilities.Close();r.finishProfile()
print('PASS182 constructed client tree runs actual166 full client graph with explicit leaves;missing ports refused;one central/domain holder')
