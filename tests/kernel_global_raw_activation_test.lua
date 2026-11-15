local T=dofile('tests/kernel_keybind_profile_harness.lua');local N=dofile('tests/kernel_native_foundation_harness.lua')
local req=N.loader();local create=req('kernel.entry.server_supported_entry_v2');local H=T.H
for _,side in ipairs({'server'})do
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
 local p={};for k,v in pairs(profile)do p[k]=v end
 p.public=foundationPorts.public;p.environment=env
 local supportRequests={}
 local getConvar=n.GetConvar;n.GetConvar=function(key,default)return ({['ox:logger']='fivemanage',['fivemanage:key']='test-only'})[key]or getConvar(key,default)end
 n.GetPlayerName=function()return 'Virtual'end;n.GetNumPlayerIdentifiers=function()return 0 end;n.GetPlayerIdentifier=function()end
 n.GetGameTimer=function()return r.clock.now end;n.PerformHttpRequest=function(_,callback)supportRequests[#supportRequests+1]=callback end
 n.TriggerEvent=function()end;n.TriggerClientEvent=function()end
 n.GetResourceMetadata=function(_,key)return key=='version'and'3.50.0'or nil end
 local resourceState=n.GetResourceState;n.GetResourceState=function(name)if name=='ox_lib'then return 'missing'end;if name=='pr_bridge'or name=='oxmysql'or name=='ox_inventory'then return'started'end;return resourceState(name)end
 n.GetInvokingResource=function()return'virtual-consumer'end
 n.AddStateBagChangeHandler=function()return 100 end;n.RemoveStateBagChangeHandler=function()return true end
 for _,name in ipairs({'RequestScriptAudioBank','GetSoundId','PlaySoundFromCoord','PlaySoundFromEntity','PlaySoundFrontend','ReleaseSoundId'})do n[name]=function()return 1 end end
 env.os={time=os.time,date=os.date,clock=os.clock,microtime=function()return r.clock.now*1000 end}
 env.string.strsplit=function(sep,text)return text end
 local external={};if r.servicesFixture then for k,v in pairs(r.servicesFixture.external)do external[k]=v end end;for k,v in pairs(p.external)do external[k]=v end
 external.pr_bridge={accessCacheState=function()return true end};external.pr_3dsound={}
 for _,name in ipairs({'PlayNativeSound','PlayNativeSoundFromEntity','PlayNativeSoundFromCoords','PlayLocalNativeSound','PlayLocalNativeSoundFromEntity','PlayLocalNativeSoundFromCoords','PlaySharedNativeSoundFromEntity','PlaySharedNativeSoundFromCoords'})do external.pr_3dsound[name]=function()return true end end
 n.GetPlayerIdentifiers=n.GetPlayerIdentifiers or function()return{}end
 env.GlobalState={}
 env.promise={new=assert(profile.nativeAdjuncts.newPromise)};env.Citizen={Await=assert(profile.nativeAdjuncts.awaitPromise)}
 local support={native=n,external=external,environment=env,loadPR=fp.loadPR,running=coroutine.running,onError=error}
 local installed=fp.loadPR('@pr_bridge/bridge/utils/tables',env)
 local tables=fp.loadPR('@pr_bridge/bridge/delivery/forge_graph_table_compat',env)(installed)
 local frozen=tables.freeze({a=1});local parent=tables.freeze({child=frozen,plain={a=2}})
 assert(parent.child==frozen and not pcall(function()parent.child.a=3 end))
 local cloned=tables.clone(parent);cloned.child.a=9;assert(parent.child.a==1 and cloned.child.a==9)

 local consumerFixture=dofile('tests/kernel_native_bindings_harness.lua').new('server',true)
 local mutableCaller='ox_inventory';n.GetInvokingResource=function()return mutableCaller end
 local origin=req('kernel.entry.activation_origin')({running=coroutine.running,getInvokingResource=n.GetInvokingResource,isCurrent=function()return r.nativeCurrent end})
 local assembly,candidate,entry;local exported
 local profileConfig=H.load('kernel/pr_integration/activation_profile.lua',H.environment())({
 authority='forge-core',generation='global265',qbEnabled=true,consumers={{name='ox_inventory',server={instance='inventory265',inventory=true}}}})
 local expected=H.load('../pr_bridge/bridge/runtime/forge/activation_api_expectations.lua',H.environment())('server',true)
 local consumerN=consumerFixture.bindingPorts.native;consumerN.GetInvokingResource=function()return'forge-core'end
 local nativeProxy={
 ForgePrDescribe=function()return assert(r.surface.exports.ForgePrDescribe)()end,
 ForgePrCall=function(_,...)return assert(r.surface.exports.ForgePrCall)(...)end,
 ForgePrConsumerState=function(_,...)return assert(r.surface.exports.ForgePrConsumerState)(...)end}
 local bindingPorts={};for k,v in pairs(consumerFixture.bindingPorts)do bindingPorts[k]=v end
 bindingPorts.api=nil;bindingPorts.isReady=function()return assembly and assembly.Barrier.CanServe()or false end
 local host=fp.loadPR('@pr_bridge/bridge/frameworks/forge/activation_consumer_host',env)({
 native=consumerN,prCore=consumerFixture.pr,external={['forge-core']=nativeProxy},generation='global265',instance='inventory265',expected=expected,
 bindingPorts=bindingPorts,isCurrent=function()return r.nativeCurrent end,
 load=function(path)return H.load('../pr_bridge/'..path..'.lua',H.environment())end,
 available=function()return exported==nil end,publishExport=function(_,fn)exported=fn end})
 assert(host.Install())
 local remote=fp.loadPR('@pr_bridge/bridge/frameworks/forge/activation_remote_control',env)({
 native={GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return true end},
 external={ox_inventory={ForgePrActivationControl=function(_,...)return assert(exported)(...)end}},
 resource='ox_inventory',generation='global265',instance='inventory265',isCurrent=function()return r.nativeCurrent end})
 local conditions={decisions=true,environment=true,oxHooks=false,catalogs=false,banking=false,keys=false}
 local externalProofs={}
 for name in pairs(conditions)do externalProofs[name]=function(g,e,rawProvider)
  entry=entry or e;assert(g=='global265'and e==entry and rawProvider==raw)
  if name=='catalogs'then
   local state=e.Bootstrap.Graph.Base.ServerWorkerContext.Progress().initialization
   return conditions[name]and state.phase=='initialized'
  end
  return conditions[name]
 end end
 assembly=req('kernel.entry.activation_assembly_v2')({side='server',generation='global265',getCandidate=function()return candidate end,
 isCurrent=function()return r.nativeCurrent end,consumers={{name='ox_inventory',control=remote}},external=externalProofs,
 getInvokingResource=n.GetInvokingResource,loadPR=function(path)return fp.loadPR('@pr_bridge/'..path:gsub('%.lua$',''),env)end,
 createCompatibility=function(graph,which,prepared)
  local file=assert(io.open('kernel/entry/compatibility_physical_ports_v5.lua','rb'));local code=file:read('*a');file:close()
  for name in code:gmatch('"([%w_]+)"')do if rawget(env,name)==nil then env[name]=function()error('unexercised compatibility Cfx:'..name)end end end
  local make=req('kernel.entry.compatibility_physical_ports_v5')({environment=env,isCurrent=function()return r.nativeCurrent end,
  getRaw=function()return raw end,legacyConversion={inventoryItems={},legacyItems={},convertItems=function()error('no conversion')end}})
  return req('kernel.entry.activation_compatibility')(graph,which,prepared,{generation='global265',barrier=assembly.Barrier,makePorts=make,
  getInvokingResource=n.GetInvokingResource,aliasAvailable=function(name)return reg.available('event',name)end})
 end})
 p.barrier=assembly.Barrier
 p.onError=error
 local options=origin.Bind({prCore=pr,isCurrent=function()return r.nativeCurrent end,foundation=foundationPorts,profile=p,support=support,providers={native=n,external=external,loadPR=fp.loadPR,environment=env,isCurrent=function()return r.nativeCurrent end,isReady=old.isReady,running=coroutine.running,onError=error}})
 options.bootstrap={registration={available=foundationPorts.registration.available}}

 assert(raw.Services.Close());assert(raw.RPC.Close());pr.forgeRawEntry=nil
 local rawResourceState=n.GetResourceState
 n.GetResourceState=function(name)if name=='Renewed-Banking'or name=='pr_carkeys'then return'started'end;return rawResourceState(name)end
 for key,value in pairs(n)do env[key]=value end
 env.PRCore=pr;env.exports=external;env.TriggerServerEvent=rawget(env,'TriggerServerEvent')or function()error('server-only test')end
 env.Debug=function()end;env.Lang={t=function(_,key)return key end};env.coroutine=coroutine
 local priorIndex=getmetatable(env).__index;getmetatable(env).__index=function(t,k)if k=='source'then return nil end;return priorIndex(t,k)end
 pr.load=function(path,target)
  local name=path:gsub('^@pr_bridge/',''):gsub('%.lua$','')
  return fp.loadPR('@pr_bridge/'..name,target or env)
 end
 local file=assert(io.open('../../../../.planning/migration/staging/125/pr_bridge/bridge/forge_raw_core.lua','rb'))
 local rawText=file:read('*a');file:close();local rawFactory=assert(load(rawText,'@@raw-entry125','t',env))()
 local providers={constructionApproved=true,installApproved=true,startApproved=true,localeKey='pt-br',activation=assembly.Plan,
 buildInput=assert(load('return function()return options end','@@cfx/virtual-options','t',{options=options}))()}
 --Cfx functions and IO are virtual;provenance is normalized for this harness only.
 candidate=req('kernel.entry.coordinated_boot_preparation_v8')({side='server',originOwner=origin,providers=providers,
 inspectFunction=function(fn)local d=debug.getinfo(fn,'S');if d.source:find('tests/',1,true)then return{source='@@cfx/virtual-provider'}end;return d end,
 createRaw=function(input)
  raw=rawFactory(input);local prepare=raw.Prepare
  raw.Prepare=function()local ok,why=prepare();if not ok then print('raw125:'..tostring(why))end;return ok,why end
  return raw
 end})
 local report=candidate.Inspect();if not report.accepted then for _,issue in ipairs(report.issues)do print(issue.path..':'..issue.reason)end end
 assert(report.accepted)
 assert(not candidate.Poll())
 r.surface.Open()
 local function advance()
  local t=coroutine.create(candidate.Activate)
  for i=1,200 do
   local ok,a,b=coroutine.resume(t);assert(ok,tostring(a))
   if coroutine.status(t)=='dead'then return a,b end
   r.clock.advance(0)
  end
  error('bounded activation exceeded')
 end
 local ok,why=advance()
 entry=candidate.GetPreparedEntry()
 assert(ok==false and entry,tostring(why))
 assert(assembly.Barrier.Progress().stage==5 and candidate.Progress().phase=='running')
 assert(entry.Bootstrap.Progress().phase=='running'and assembly.Consumers.IsAttached())
 local seed=entry.Foundation.Seed
 for name in pairs(conditions)do conditions[name]=true end
 assert(advance());assert(assembly.Barrier.IsIngressOpen()and candidate.GetPreparedEntry().Foundation.Seed==seed)
 local data=entry.Bootstrap.Graph.PlayerCore.State.Players
 assert(assembly.Publication.IsInstalled()and type(consumerFixture.pr.forgeNormalizedFacade.GetIdentifier)=='function')
 assert(candidate.Stop()or candidate.Poll())
 assert(candidate.Poll()and candidate.Progress().complete and raw.Progress().complete)
 assert(host.Close()and host.Progress().complete)
 r.clock.advance(1200000)
 consumerFixture.finish();r.platform.Close();if r.utilities then r.utilities.Close()end;r.finishProfile()

end
print('PASS266 full A-F server:real preparer/entry/compat/API/admission/host,one seed;F pending then commit;raw125 now actual;Cfx/SQL/external effects virtual')
