local T=dofile('tests/kernel_keybind_profile_harness.lua');local N=dofile('tests/kernel_native_foundation_harness.lua')
local req=N.loader();local create=req('kernel.entry.native_foundation_entry');local H=T.H
for _,side in ipairs({'server','client'})do
 local r=T.new(side);local profile=r.profilePorts;local fp=side=='server'and r.seedPorts or r.seedUnit.seedPorts
 local env=profile.environment or fp.environment;local n=fp.native
 r.seed.Close()
 local old=profile.bootstrap;local root=old.context
 local reg=old.registration
 n.GetGameName=function()return side=='server'and'fxserver'or'fivem'end
 for _,name in ipairs({'AddEventHandler','RemoveEventHandler','RegisterNetEvent','RegisterCommand'})do n[name]=reg.native[name]end
 n.GetCurrentPedWeapon=n.GetCurrentPedWeapon or function()return false,0 end
 local priorRead=n.LoadResourceFile
 n.LoadResourceFile=function(resource,path)
  if resource=='forge-core'and(path:match('^kernel/')or path:match('^locale/'))then
   local file=io.open(path,'rb');if file then local text=file:read('*a');file:close();return text end
  end
  return priorRead(resource,path)
 end
 env.table.type=H.tableType;env.load=load;env.GetResourceKvpString=function()return nil end
 local observers,removed=0,0
 env.AddConvarChangeListener=function()observers=observers+1;return observers end
 env.RemoveConvarChangeListener=function()removed=removed+1 end
 -- Native Cfx functions outside exercised paths remain explicit test-only failing doubles.
 local schema=H.load('kernel/entry/'..side..'_engine_schema.lua',H.environment())()
 for _,target in pairs(schema)do if target:sub(1,1)~='$'and n[target]==nil then n[target]=function()error('unexercised native:'..target)end end end
 for name,value in pairs(n)do if rawget(env,name)==nil then env[name]=value end end
 local pr=profile.prCore;local raw={RPC=pr.forgeOwnedCallbacks,Services=profile.services};pr.forgeRawEntry=raw
 local foundationPorts={};for k,v in pairs(fp)do foundationPorts[k]=v end
 foundationPorts.side,foundationPorts.environment,foundationPorts.public=side,env,fp.public
 foundationPorts.registration={running=coroutine.running,getSource=reg.native.source,publishExport=reg.native.publishExport,
  available=reg.available,prCommand=reg.prCommand,oxCommand=reg.oxCommand}
 foundationPorts.adjuncts=profile.nativeAdjuncts;foundationPorts.pullLocale=root.locale.pullLocale
 local function bundle(f)
  local context={running=coroutine.running,onError=error,isCurrent=old.isCurrent,isReady=old.isReady}
  local domains,central,config
  if side=='client'then
   local d=root.runtimeContext.deliveryContext;local c=d.configurationContext;local m=c.mediaContext;local w=m.worker
   domains,config=w.domains.domains,w.domains.config
   local a=w.central;local ch=a.character
   central={library=a.library,rpc=raw.RPC,config=a.config,random=ch.random,strsplit=ch.strsplit,audio=a.helpers.audio,delivery=a.producers.delivery,
    notify=a.legacy.notify,notifyPosition=a.legacy.notifyPosition,searchInventory=a.legacy.searchInventory,globalState=a.runtime.globalState,
    streaming=ch.streaming,setPedAppearance=ch.setPedAppearance,defaultSpawn=ch.defaultSpawn,ui=ch.ui,characterIntegrations=ch.integrations,
    groupdigits=ch.groupdigits,consumptionIntegrations=a.consumption.integrations}
   central.library.table.type=H.tableType;central.library.print.warn=a.membership.warn
   context.public,context.input,context.callbacks=m.shutdown.public,m.shutdown.input,m.shutdown.callbacks
   context.media,context.delivery,context.configuration=m.media,d.delivery,c.configuration
  else
   local d=root.deliveryContext;local m=d.mediaContext;local s=m.supportContext;local c=s.configurationContext
   local v=c.vehicleContext;local b=v.bankingContext;local o=b.operationsContext;local i=o.inventoryContext;local life=i.startup.lifecycle;local g=life.worker.graph
   domains,config=g.domains,g.config
   local library=life.callbacks.securityLibrary
   for k,vv in pairs(g.central.session.player.library)do if library[k]==nil then library[k]=vv end end
   library.callback.await=raw.RPC.Ox.await
   library.checkDependency=g.central.runtime.library.checkDependency
   central={parts=g.central,library=library,database=g.central.session.player.db,platform=g.central.session.player.platform}
   context.public,context.callbacks,context.bootstrap=life.public,life.callbacks,life.worker.bootstrap
   context.inventory,context.operations,context.banking,context.vehicles=i.inventory,o.operations,b.banking,v.vehicles
   context.shared,context.configuration,context.loggingDelivery=c.shared,c.configuration,s.delivery
   context.hooks,context.logger,context.media,context.delivery=s.hooks,s.logger,m.media,d.delivery
   context.resourceState,context.databaseReady=i.startup.resourceState,i.startup.databaseReady
   context.helpers=g.helpers
  end
  local libraries={};for name,p in pairs(domains)do libraries[name]=p.library or central.library end
  return{config=config,central=central,domain={domains=domains,libraries=libraries},context=context,helpers=context.helpers}
 end
 local p={};for k,v in pairs(profile)do p[k]=v end
 p.public=foundationPorts.public;p.environment=env
 local entry=create(raw,{prCore=pr,isCurrent=function()return r.nativeCurrent end,foundation=foundationPorts,profile=p,buildProviders=bundle})
 assert(not pcall(create,raw,{prCore=pr,isCurrent=function()return true end}))
 assert(not entry.Start());local ok,reason=entry.Prepare('pt-br');assert(ok,tostring(reason))
 assert(entry.Profile.Seed==entry.Foundation.Seed and pr.forgeNativeSeed==entry.Foundation.Seed)
 assert(entry.Bootstrap.Graph and entry.Bootstrap.Graph.Core==entry.Foundation.Base or side=='server'and entry.Bootstrap.Graph.Base==entry.Foundation.Base)
 assert(observers==0);r.surface.Open();assert(entry.Install());assert(observers==1)
 entry.Stop();r.clock.advance(1200000);assert(entry.Poll());assert(removed==1 and pr.forgeNativeFoundation==nil and pr.forgeNativeSeed==nil)
 assert(pr.forgeOwnedCallbacks==raw.RPC and raw.RPC.Owners.native.IsReady())
 local refused=create(raw,{prCore=pr,isCurrent=function()return r.nativeCurrent end,foundation=foundationPorts,profile=p,buildProviders=function()return nil end})
 local accepted,why=refused.Prepare();assert(not accepted and tostring(why):find('native provider bundle required',1,true))
 assert(refused.Progress().complete and pr.forgeNativeFoundationEntry==nil and pr.forgeNativeSeed==nil)
 r.platform.Close();if r.utilities then r.utilities.Close()end;r.finishProfile()
end
print('PASS189 real179 foundation/188 trees/181 profiles on server and client;one seed/base/RPC;Prepare/Install/Stop;raw125 identity contract controlled;no real boot')
