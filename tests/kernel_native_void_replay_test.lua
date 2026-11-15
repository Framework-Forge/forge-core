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
 local register=n.RegisterCommand
 n.RegisterCommand=function(...)register(...);return false end -- native void has no success result
 reg.native.RegisterCommand=n.RegisterCommand
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
 env.PRCore=pr;pr.load=function(path,target)return fp.loadPR(path,target or env)end
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
 -- Model the physical PR alias: Cfx reports started and resolves PR metadata.
 local manifest=assert(io.open('../pr_bridge/fxmanifest.lua','rb'));local manifestText=manifest:read('*a');manifest:close()
 local prVersion=assert(manifestText:match('version%("([^"]+)"%)'))
 local prName=assert(manifestText:match('name%("([^"]+)"%)'))
 assert(manifestText:find('provide("ox_lib")',1,true))
 n.GetResourceMetadata=function(resource,key)
  if resource=='ox_lib'or resource=='pr_bridge'then return key=='version'and prVersion or key=='name'and prName or nil end
  return key=='version'and'3.50.0'or nil
 end
 local resourceState=n.GetResourceState;n.GetResourceState=function(name)if name=='ox_lib'then return 'started'end;if name=='pr_bridge'or name=='oxmysql'or name=='ox_inventory'then return'started'end;return resourceState(name)end
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

 local Replay=dofile('tests/kernel_runtime_consumer_replay_harness.lua')
 local mutableCaller='ox_inventory';n.GetInvokingResource=function()return mutableCaller end
 local origin=req('kernel.entry.activation_origin')({running=coroutine.running,getInvokingResource=n.GetInvokingResource,isCurrent=function()return r.nativeCurrent end})
 local assembly,candidate,entry;local exported
 local profileConfig=H.load('kernel/pr_integration/activation_profile.lua',H.environment())({
 authority='forge-core',generation='global265',qbEnabled=true,consumers={{name='ox_inventory',server={instance='ox_inventory:server',inventory=true}}}})
 local nativeProxy={
 ForgePrDescribe=function()return assert(r.surface.exports.ForgePrDescribe)()end,
 ForgePrCall=function(_,...)return assert(r.surface.exports.ForgePrCall)(...)end,
 ForgePrConsumerState=function(_,...)return assert(r.surface.exports.ForgePrConsumerState)(...)end}
 local consumer=Replay.new('server','ox_inventory',nativeProxy,function()
  return{generation='global265',stage=assembly and assembly.Barrier.Progress().stage or 0}
 end,'global265')
 local consumerFixture=consumer.Fixture
 local host={Close=consumer.Close,Progress=function()return consumer.Service.Progress()end}
 exported=function(...)return consumer.Control(...)end
 local declaration=consumer.Control('Describe')
 assert(declaration.phase=='prepared'and declaration.providersReady==true,'actual PR entry must prepare the consumer before A')
 local remote=H.load('kernel/pr_integration/activation_remote_control.lua',env)({
 native={GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return true end},
 external={ox_inventory={ForgePrActivationControl=function(_,...)return assert(exported)(...)end}},
 resource='ox_inventory',generation='global265',instance='ox_inventory:server',isCurrent=function()return r.nativeCurrent end})
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
 getInvokingResource=n.GetInvokingResource,loadPR=function(path)
  if path:sub(1,1)~='@'then path='@pr_bridge/'..path end
  return pr.load(path,env)
 end,
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
 -- Use the installed operational namespace, not the fixture's always-free list.
 local foreignCommands={{name='me',resource='forge-chat'}}
 local priorState=n.GetResourceState
 n.GetResourceState=function(name)
  if name=='forge-chat'or name=='Renewed-Banking'or name=='pr_carkeys'then return'started'end
  return priorState(name)
 end
 local nativeExports=setmetatable({
  ox_inventory={ForgeOwnedHookSnapshot=function()return{owner='forge-core',generation='global265'}end},
  ['Renewed-Banking']={ForgeBankingReadiness=function()return{generation='global265',phase='loading'}end},
  pr_carkeys={ForgeKeysReadiness=function()return{generation='global265',ready=true}end}},
  {__call=function(_,name,fn)return reg.native.publishExport(name,fn)end})
 local meta=n.GetResourceMetadata;local installReads=0
 local configured=H.environment({GetCurrentResourceName=function()return'forge-core'end,
  IsDuplicityVersion=function()return true end,GetResourceState=function(name)return n.GetResourceState(name)end,
  GetResourceMetadata=function(resource,key,index)if resource=='forge-core'and key=='forge_kernel_bootstrap'then return'owned/1'end;return meta(resource,key,index)end,
  GetNumResourceMetadata=function()return 0 end,GetRegisteredCommands=function()
   if candidate and candidate.Progress().phase=='installing'then
    assert(candidate.GetPreparedEntry(),'prepared identity remains readable during B')
    assert(candidate.GetPreparedRaw()==nil and candidate.GetPreparedBarrier()==nil,'no additional raw/barrier capability during B')
    installReads=installReads+1
   end
   return foreignCommands
  end,exports=nativeExports})
 for key,value in pairs(env)do if rawget(configured,key)==nil then configured[key]=value end end
 configured.PRAce=false
 configured.Bridge=fp.public
 configured.IsPrincipalAceAllowed=function()return false end
 configured.pr_lib=fp.public
 configured.PRCore={forgeCoreBootstrap={Public=fp.public},load=function(path,target)
  if path:sub(1,12)=='@forge-core/'then return H.load(path:sub(13)..'.lua',target)end
  return fp.loadPR(path,target)
 end}
 local runtimeConfiguration=H.load('kernel/pr_integration/core_runtime_configuration.lua',H.environment())({
  environment=configured,profile=profileConfig,getCandidate=function()return candidate end})
 assert(runtimeConfiguration.Ready(),'operational readiness with virtual provider receipts')
 local operational=runtimeConfiguration.PhysicalOptions.registration
 for _,key in ipairs({'available','publishExport','prCommand','oxCommand'})do
  reg[key]=operational[key];foundationPorts.registration[key]=operational[key]
 end
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
 candidate=req('kernel.entry.coordinated_boot_preparation_v8')({side='server',originOwner=origin,providers=providers,
 inspectFunction=function(fn)local d=debug.getinfo(fn,'S');if d.source:find('tests/',1,true)then return{source='@@cfx/virtual-provider'}end;return d end,
 createRaw=function(input)
  raw=rawFactory(input);local prepare=raw.Prepare
  raw.Prepare=function()local ok,why=prepare();if not ok then print('raw125:'..tostring(why))end;return ok,why end
  return raw
 end})
 assert(candidate.GetPreparedEntry()==nil,'no entry before A')
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
 assert(assembly.Barrier.Progress().stage==5 and candidate.Progress().phase=='running',
  'stage='..tostring(assembly.Barrier.Progress().stage)..' phase='..tostring(candidate.Progress().phase)..' error='..tostring(assembly.Plan and candidate.Coordinator.Progress().lastError))
 assert(entry.Bootstrap.Progress().phase=='running'and assembly.Consumers.IsAttached())
 local seed=entry.Foundation.Seed
 for name in pairs(conditions)do conditions[name]=true end
 assert(advance());assert(assembly.Barrier.IsIngressOpen()and candidate.GetPreparedEntry().Foundation.Seed==seed)
 local data=entry.Bootstrap.Graph.PlayerCore.State.Players
 assert(assembly.Publication.IsInstalled()and type(consumerFixture.pr.forgeNormalizedFacade.GetIdentifier)=='function')
 local delegated=entry.Bootstrap.Graph.Base.PublicRegistration.GetDelegatedCommands()
 assert(installReads>0,'operational namespace used the real candidate during B')
 assert(#delegated==1 and delegated[1].name=='me'and delegated[1].externalOwner=='forge-chat')
 assert(r.surface.commands.me==nil,'Forge must not publish or run a duplicate /me')
 assert(foreignCommands[1].name=='me'and foreignCommands[1].resource=='forge-chat')
 assert(candidate.Stop()or candidate.Poll())
 assert(runtimeConfiguration.Close())
 assert(candidate.Poll()and candidate.Progress().complete and raw.Progress().complete)
 assert(candidate.GetPreparedEntry()==nil,'no retained entry after Close')
 assert(host.Close()and host.Progress().complete)
 r.clock.advance(1200000)
 consumerFixture.finish();r.platform.Close();if r.utilities then r.utilities.Close()end;r.finishProfile()

end
print('PASS native void=false plus operational namespace with external forge-chat /me and PR alias before full A-F server:installed raw_entry/preparer/entry/compat/API/admission/host,one seed;F pending then commit;Cfx/SQL/external effects virtual')
