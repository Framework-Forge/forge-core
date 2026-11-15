local T=dofile('tests/kernel_native_foundation_harness.lua');local req=T.loader();local builder=req('kernel.entry.native_bootstrap_builder')
local H=T.H;local C=dofile('tests/kernel_client_domains_harness.lua');local r=C.new();local old=r.central.ports
-- Full client construction through185/187/182 using actual graph factories;only environment-facing providers are virtual.
local native=old.native
local f={Side='client',IsCurrent=function()return true end,NativeCache={Cache=old.cache},Seed={IO={Codec=old.character.json}},
 Locale=old.runtime.locale,EngineInputs={Describe=function()return{}end,Select=function()return native end}}
local K=dofile('tests/kernel_keybind_profile_harness.lua');local k=K.new('client')
local root=k.profilePorts.bootstrap.context;local d=root.runtimeContext.deliveryContext;local cfg=d.configurationContext;local media=cfg.mediaContext
f.Events=k.events;f.RegistrationInput=k.profilePorts.bootstrap.registration
f.Locales={Ports=root.locale,CreateLocale=root.createLocale}
local factories={media=media.createMedia,tasks=media.worker.createTasks,imports=root.runtimeContext.createImports,delivery=d.createDelivery,configuration=cfg.createConfiguration}
f.Factories={Get=function(name)return assert(factories[name],name)end}
local p={config=r.ports.config,domain={domains=r.ports.domains,libraries={}},context={public=media.shutdown.public,input=media.shutdown.input,callbacks=media.shutdown.callbacks,
 media=media.media,delivery=d.delivery,configuration=cfg.configuration,running=coroutine.running,onError=error,
 isCurrent=k.profilePorts.bootstrap.isCurrent,isReady=k.profilePorts.bootstrap.isReady},
 central={library=old.library,rpc={Side='client',Ox=old.character.callbacks},config={Inventory=r.ports.config.Inventory},random=old.character.random,
 strsplit=old.character.strsplit,audio=old.helpers.audio,delivery=old.producers.delivery,notify=old.legacy.notify,
 notifyPosition=old.legacy.notifyPosition,searchInventory=old.legacy.searchInventory,globalState=old.runtime.globalState,
 streaming=old.character.streaming,setPedAppearance=old.character.setPedAppearance,defaultSpawn=old.character.defaultSpawn,
 ui=old.character.ui,characterIntegrations=old.character.integrations,groupdigits=old.character.groupdigits,consumptionIntegrations=old.consumption.integrations}}
p.central.library.table=p.central.library.table or{};p.central.library.table.type=H.tableType
p.central.library.print=p.central.library.print or{};p.central.library.print.warn=old.membership.warn
for name,part in pairs(r.ports.domains)do p.domain.libraries[name]=part.library or old.library end
local tree,audit=builder(f,p);assert(audit.domains==23)
local worker=tree.context.runtimeContext.deliveryContext.configurationContext.mediaContext.worker
assert(worker.central.config.Client==nil and worker.domains.config==p.config and next(worker.domains.client)==nil)
assert(worker.central.character.callbacks==p.central.rpc.Ox)
local bad={};for name,v in pairs(p)do bad[name]=v end;bad.central=nil;assert(not pcall(builder,f,bad))
k.platform.Close();k.utilities.Close();k.finishProfile()
print('PASS188 native leaf builders185/187 composed with complete client tree182;canonical config/RPC/holder retained;missing central refused')
