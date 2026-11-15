local T=dofile('tests/kernel_keybind_profile_harness.lua');local N=dofile('tests/kernel_native_foundation_harness.lua')
local req=N.loader();local create=req('kernel.entry.client_owned_entry_v3');local H=T.H
for _,side in ipairs({'client'})do
 local r=T.new(side);local profile=r.profilePorts;local fp=side=='server'and r.seedPorts or r.seedUnit.seedPorts
 local env=profile.environment or fp.environment;local n=fp.native
 local cfx=dofile('tests/kernel_cfx_player_fixture.lua')()
 env.LocalPlayer=cfx.LocalPlayer
 profile.progress.localPlayer=cfx.LocalPlayer
 local envIndex=getmetatable(env).__index;env.os=nil;getmetatable(env).__index=function(t,k)if k=='os'then return nil end;return envIndex(t,k)end
 local legacyLoadPR=fp.loadPR
 fp.loadPR=function(path,target)
  if path:sub(1,12)=='@forge-core/'then return H.load(path:sub(13):gsub('%.lua$','')..'.lua',target or env)end
  return legacyLoadPR(path,target or env)
 end
 profile.loadPR=fp.loadPR
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
 env.PRCore=pr
 pr.load=function(path,target)
  if path:sub(1,12)=='@forge-core/'then return H.load(path:sub(13):gsub('%.lua$','')..'.lua',target or env)end
  return fp.loadPR(path,target or env)
 end
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
 n.ExecuteCommand=function()end
 n.GetResourceMetadata=function(_,key)return key=='version'and'3.50.0'or nil end
 local resourceState=n.GetResourceState;n.GetResourceState=function(name)if name=='ox_lib'then return 'missing'end;if name=='pr_bridge'or name=='oxmysql'or name=='ox_inventory'or name=='forge-loadscreen'then return'started'end;return resourceState(name)end
 n.GetInvokingResource=function()return'virtual-consumer'end
 n.AddStateBagChangeHandler=function()return 100 end;n.RemoveStateBagChangeHandler=function()return true end
 for _,name in ipairs({'RequestScriptAudioBank','GetSoundId','PlaySoundFromCoord','PlaySoundFromEntity','PlaySoundFrontend','ReleaseSoundId'})do n[name]=function()return 1 end end
 assert(env.os==nil)
 env.string.strsplit=function(sep,text)return text end
 local external={};if r.servicesFixture then for k,v in pairs(r.servicesFixture.external)do external[k]=v end end;for k,v in pairs(p.external)do external[k]=v end
 local sharedCache={}
 external.pr_bridge={accessCacheState=function(_,operation,key,value)
  if operation=='get'then return sharedCache[key]end
  if operation=='set'then sharedCache[key]=value;return true,value end
  if operation=='patch'then local target=sharedCache[key]or{};for k,v in pairs(value)do target[k]=v end;sharedCache[key]=target;return true,target end
  if operation=='clear'then sharedCache[key]=nil;return true end
  if operation=='clearPrefix'then for k in pairs(sharedCache)do if k:sub(1,#key)==key then sharedCache[k]=nil end end;return true end
  error('unexpected passive cache operation:'..tostring(operation))
 end};external.pr_3dsound={}
 for _,name in ipairs({'addBoxZone','removeZone','addLocalEntity','removeLocalEntity','disableTargeting'})do external.pr_bridge[name]=function()end end
 env.exports=external
 for _,name in ipairs({'PlayNativeSound','PlayNativeSoundFromEntity','PlayNativeSoundFromCoords','PlayLocalNativeSound','PlayLocalNativeSoundFromEntity','PlayLocalNativeSoundFromCoords','PlaySharedNativeSoundFromEntity','PlaySharedNativeSoundFromCoords'})do external.pr_3dsound[name]=function()return true end end
 n.GetPlayerIdentifiers=n.GetPlayerIdentifiers or function()return{}end
 env.GlobalState={}
 env.GetGameBuildNumber=function()return 3258 end;env.GetHashKey=n.joaat
 env.vec2=function(x,y)return{x=x,y=y}end
 for _,name in ipairs({'GetPickupObject','GetPickupCoords','GetPickupHash','GetEntityType','NetworkGetEntityIsNetworked','NetworkGetNetworkIdFromEntity','GetEntityModel'})do
  if rawget(env,name)==nil then env[name]=n[name]or function()error('unexercised native:'..name)end end
 end
 env.DoesPickupExist=function()return false end
 for _,name in ipairs({'SendNUIMessage','SetNuiFocus','SetNuiFocusKeepInput'})do env[name]=function()end end
 local support={native=n,external=external,environment=env,loadPR=fp.loadPR,running=coroutine.running,onError=error}
 local installed=fp.loadPR('@pr_bridge/bridge/utils/tables',env)
 local tables=fp.loadPR('@pr_bridge/bridge/delivery/forge_graph_table_compat',env)(installed)
 local frozen=tables.freeze({a=1});local parent=tables.freeze({child=frozen,plain={a=2}})
 assert(parent.child==frozen and not pcall(function()parent.child.a=3 end))
 local cloned=tables.clone(parent);cloned.child.a=9;assert(parent.child.a==1 and cloned.child.a==9)
 local Replay=dofile('tests/kernel_runtime_consumer_replay_harness.lua')
 local inventoryFile=assert(io.open('../../../../.planning/migration/staging/boot-1807-20261028/CLIENT-NATIVES.json','rb'))
 local inventory=test_decode_json(inventoryFile:read('*a'));inventoryFile:close();local allowed={}
 for _,name in ipairs(inventory.names)do allowed[name]=true end
 local mutableCaller='ox_inventory';n.GetInvokingResource=function()return mutableCaller end
 local origin=req('kernel.entry.activation_origin')({running=coroutine.running,getInvokingResource=n.GetInvokingResource,isCurrent=function()return r.nativeCurrent end})
 local assembly,candidate,entry;local exported
 local profileConfig=H.load('kernel/pr_integration/activation_profile.lua',H.environment())({
  authority='forge-core',generation='global268',qbEnabled=true,consumers={{name='ox_inventory',client={instance='ox_inventory:client',inventory=false}}}})
 local nativeProxy={
  ForgePrDescribe=function()return assert(r.surface.exports.ForgePrDescribe)()end,
  ForgePrCall=function(_,...)return assert(r.surface.exports.ForgePrCall)(...)end,
  ForgePrConsumerState=function(_,...)return assert(r.surface.exports.ForgePrConsumerState)(...)end}
 local consumer=Replay.new('client','ox_inventory',nativeProxy,function()
  return{generation='global268',stage=assembly and assembly.Barrier.Progress().stage or 0,
   ingressOpen=assembly and assembly.Barrier.IsIngressOpen()or false,phase=candidate and candidate.Progress().phase or'prepared'}
 end,'global268')
 local consumerFixture=consumer.Fixture
 local host={Close=consumer.Close,Progress=function()return consumer.Service.Progress()end}
 exported=function(...)return consumer.Control(...)end
 assert(consumer.Control('Describe').phase=='prepared')
 local remote=H.load('kernel/pr_integration/activation_remote_control.lua',env)({
  native={GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return false end},
  external={ox_inventory={ForgePrActivationControl=function(_,...)return exported(...)end}},resource='ox_inventory',
  generation='global268',instance='ox_inventory:client',isCurrent=function()return r.nativeCurrent end})
 local conditions={decisions=true,environment=true,oxHooks=false,catalogs=false,banking=false,keys=false}
 local externalProofs={}
 for name in pairs(conditions)do externalProofs[name]=function(g,e,rawProvider)
  entry=entry or e;assert(g=='global268'and e==entry and rawProvider==raw)
  if name=='catalogs'then return conditions[name]and #e.Bootstrap.Graph.Order==23 end
  return conditions[name]
 end end
 assembly=req('kernel.entry.activation_assembly_v2')({side='client',generation='global268',getCandidate=function()return candidate end,
 isCurrent=function()return r.nativeCurrent end,consumers={{name='ox_inventory',control=remote}},external=externalProofs,
 getInvokingResource=n.GetInvokingResource,loadPR=function(path)return fp.loadPR(path:sub(1,1)=='@'and path or'@pr_bridge/'..path:gsub('%.lua$',''),env)end,
 createCompatibility=function(graph,which,prepared)
  local file=assert(io.open('kernel/entry/compatibility_physical_ports_v5.lua','rb'));local code=file:read('*a');file:close()
  for name in code:gmatch('"([%w_]+)"')do if allowed[name]and rawget(env,name)==nil then env[name]=function()error('unexercised compatibility Cfx:'..name)end end end
  local make=req('kernel.entry.compatibility_physical_ports_v5')({environment=env,isCurrent=function()return r.nativeCurrent end,
  getRaw=function()return raw end,sharedConfig=req('kernel.config.shared')({vec4=n.vec4})})
  return req('kernel.entry.activation_compatibility')(graph,which,prepared,{generation='global268',barrier=assembly.Barrier,makePorts=make,
  getInvokingResource=n.GetInvokingResource,aliasAvailable=function(name)return reg.available('event',name)end})
 end})
 p.barrier=assembly.Barrier
 p.onError=error
 local captureEnv={math=math,coroutine=coroutine,json=fp.json,load=load,exports=external,
  LocalPlayer=cfx.LocalPlayer,promise={new=function()error('unexercised promise')end},Citizen={Await=function()error('unexercised await')end}}
 setmetatable(captureEnv,{__index=function(_,name)
  if not allowed[name]then return nil end
  return n[name]or rawget(env,name)or function()error('unexercised client capture native:'..name)end
 end})
 local captured=req('kernel.entry.physical_boot_options_v5')({environment=captureEnv,prCore=pr,public=fp.public,
  registration=foundationPorts.registration,barrier=assembly.Barrier,isCurrent=function()return r.nativeCurrent end,
  isReady=old.isReady,inventoryBridgeProbe=fp.inventoryBridgeProbe,pullLocale=foundationPorts.pullLocale,onError=error,
  targetSelection='native',originOwner=origin})('client')
 assert(captured.foundation.native.SaveResourceFile==nil)
 n=captured.foundation.native
 foundationPorts.native=n;support.native=n
 foundationPorts.adjuncts=captured.foundation.adjuncts;p.nativeAdjuncts=captured.profile.nativeAdjuncts
 assert(env.os==nil and captured.profile.nativeAdjuncts.time==nil and captured.profile.nativeAdjuncts.date==nil)
 p.progress=captured.profile.progress
 -- v5 has already bound the caller once; keep that exact options identity.
 local options=captured
 options.foundation,options.profile,options.support=foundationPorts,p,support
 options.providers={native=n,external=external,loadPR=fp.loadPR,environment=env,prCore=pr,targetSelection='native',isCurrent=function()return r.nativeCurrent end,isReady=old.isReady,running=coroutine.running,onError=error}
 assert(origin.Owns(options))
 options.bootstrap={registration={available=foundationPorts.registration.available}}

 if raw.Services.Close then assert(raw.Services.Close())end
 assert(raw.RPC.Close());pr.forgeRawEntry=nil
 local rawResourceState=n.GetResourceState
 n.GetResourceState=function(name)if name=='Renewed-Banking'or name=='pr_carkeys'then return'started'end;return rawResourceState(name)end
 for key,value in pairs(n)do env[key]=value end
 env.PRCore=pr;env.exports=external;env.TriggerServerEvent=rawget(env,'TriggerServerEvent')or function()error('server-only test')end
 env.Debug=function()end;env.Lang={t=function(_,key)return key end};env.coroutine=coroutine
 env.DoesPlayerExist=nil;env.TriggerClientEvent=nil;env.SaveResourceFile=nil
 -- Virtual server wire replies exercise the real client transports without a FiveM server.
 local wire={};local add=n.AddEventHandler;local remove=n.RemoveEventHandler
 n.AddEventHandler=function(name,fn)local token=add(name,fn);wire[name]=wire[name]or{};wire[name][token]=fn;return token end
 n.RemoveEventHandler=function(token)for _,list in pairs(wire)do list[token]=nil end;return remove(token)end
 n.TriggerServerEvent=function(name,a,b)
  if name=='ox_lib:validateCallback'then return end
  local response,key='pr_bridge:callback:response',a
  if name:sub(1,8)=='__ox_cb_'then response='__ox_cb_forge-core';key=b end
  local payload=name=='qbx_core:server:getGroups'and{jobs={},gangs={}}or{}
  for _,fn in pairs(wire[response]or{})do fn(key,payload)end
 end
 env.promise={new=function()return{resolve=function(self,value)self.value=value end,reject=function(_,reason)error(reason)end}end}
 env.Citizen={Await=function(value)assert(value.value,'virtual server response absent');return value.value end}
 env.AddEventHandler=n.AddEventHandler;env.RemoveEventHandler=n.RemoveEventHandler;env.TriggerServerEvent=n.TriggerServerEvent
 local absent={source=true,os=true,DoesPlayerExist=true,TriggerClientEvent=true,SaveResourceFile=true}
 local priorIndex=getmetatable(env).__index;getmetatable(env).__index=function(t,k)if absent[k]then return nil end;return priorIndex(t,k)end
 pr.load=function(path,target)
  if path:sub(1,12)=='@forge-core/'then return H.load(path:sub(13):gsub('%.lua$','')..'.lua',target or env)end
  local name=path:gsub('^@pr_bridge/',''):gsub('%.lua$','')
  return fp.loadPR('@pr_bridge/'..name,target or env)
 end
 external.pr_bridge=external.pr_bridge or{}
 external.pr_bridge.oxService=dofile('tests/kernel_callback_registry_fixture.lua')(H).oxService
 local file=assert(io.open('kernel/pr_integration/raw_entry.lua','rb'))
 local rawText=file:read('*a');file:close();local rawFactory=assert(load(rawText,'@@raw-entry125','t',env))()
 local providers={constructionApproved=true,installApproved=true,startApproved=true,localeKey='pt-br',activation=assembly.Plan,
 buildInput=assert(load('return function()return options end','@@cfx/virtual-options','t',{options=options}))()}
 --Cfx functions and IO are virtual;provenance is normalized for this harness only.
 candidate=req('kernel.entry.coordinated_boot_preparation_v8')({side='client',originOwner=origin,providers=providers,
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
 local data=entry.Bootstrap.Graph.Core.PlayerData
 assert(assembly.Publication.IsInstalled()and type(consumerFixture.pr.forgeNormalizedFacade.GetPlayerData())=='table')
 assert(data==entry.Foundation.Base.PlayerData)
 local providers=entry.Providers
 external['forge-loadscreen']={FinishLoadingScreen=function()coroutine.yield('minimum-duration');return true end}
 local waiting=coroutine.create(function()return origin.Origin.Run('consumer',providers.Integrations.Character.finishLoadingScreen)end)
 local started,signal=coroutine.resume(waiting);assert(started and signal=='minimum-duration')
 assert(not candidate.Stop());r.clock.advance(1200000);assert(not candidate.Poll())
 assert(pr.forgeNativeSeed==seed)
 assert(coroutine.resume(waiting));r.clock.advance(1200000)
 assert(candidate.Poll())
 assert(candidate.Poll()and candidate.Progress().complete and raw.Progress().complete)
 assert(host.Close()and host.Progress().complete)
 r.clock.advance(1200000)
 consumerFixture.finish();r.platform.Close();if r.utilities then r.utilities.Close()end;r.finishProfile()

end
print('PASS installed Cfx LocalPlayer state and client without os, installed physical A-F client with actual raw125,entryv3,compat,API and host;one seed;pending F and loadscreen drain;Cfx/external effects virtual')
