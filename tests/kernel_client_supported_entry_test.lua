local T=dofile('tests/kernel_keybind_profile_harness.lua');local N=dofile('tests/kernel_native_foundation_harness.lua')
local req=N.loader();local create=req('kernel.entry.client_supported_entry');local H=T.H
for _,side in ipairs({'client'})do
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
 n.ExecuteCommand=function()end
 n.GetResourceMetadata=function(_,key)return key=='version'and'3.50.0'or nil end
 local resourceState=n.GetResourceState;n.GetResourceState=function(name)if name=='ox_lib'then return 'missing'end;if name=='pr_bridge'or name=='oxmysql'or name=='ox_inventory'or name=='forge-loadscreen'then return'started'end;return resourceState(name)end
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
 local w=root.runtimeContext.deliveryContext.configurationContext.mediaContext.worker
 local a=w.central;local caps={};for _,name in ipairs({'target','raycast','devtools','devlaser','getNearbyVehicles','setVehicleProperties','playAnim','openVisualAdminMenu'})do
  caps[name]=a.library[name]or w.domains.domains.Zones.library[name]or function()error('unexercised client capability:'..name)end
 end
 caps.fivem={};for _,name in ipairs({'blips','drawtext','gizmo','getVehicleProperties'})do caps.fivem[name]=(a.library.fivem or{})[name]or{}end
 local providerScope
 local invEnv={ActiveBridges={inventory='ox'},exports={ox_inventory={}}}
 raw.Services.Public.inventory=fp.loadPR('@pr_bridge/bridge/inventories/ox/client',invEnv)
 local rawPhase='allocated';local rawProgress=raw.Services.Progress
 raw.Services.Open=function()rawPhase='open';return true end
 raw.Services.Progress=function()local v=rawProgress and rawProgress()or{};v.phase=rawPhase;return v end
 local function bundle(f,services,support)
  providerScope=req('kernel.entry.client_provider_bundle')(f,support,{services=services,rpc=raw.RPC,prCore=pr,capabilities=caps,native=n,external=external,loadPR=fp.loadPR,environment=env,
   isCurrent=function()return r.nativeCurrent end,isReady=old.isReady,running=coroutine.running,onError=error})
  return providerScope.Bundle
 end
 local support={native=n,external=external,environment=env,loadPR=fp.loadPR,running=coroutine.running,onError=error}
 local installed=fp.loadPR('@pr_bridge/bridge/utils/tables',env)
 local tables=fp.loadPR('@pr_bridge/bridge/delivery/forge_graph_table_compat',env)(installed)
 local frozen=tables.freeze({a=1});local parent=tables.freeze({child=frozen,plain={a=2}})
 assert(parent.child==frozen and not pcall(function()parent.child.a=3 end))
 local cloned=tables.clone(parent);cloned.child.a=9;assert(parent.child.a==1 and cloned.child.a==9)
 local entry=create(raw,{prCore=pr,isCurrent=function()return r.nativeCurrent end,foundation=foundationPorts,profile=p,support=support,providers={native=n,external=external,environment=env,loadPR=fp.loadPR,prCore=pr,capabilities=caps,isCurrent=function()return r.nativeCurrent end,isReady=old.isReady,running=coroutine.running,onError=error}})
 assert(not pcall(create,raw,{prCore=pr,isCurrent=function()return true end}))
 assert(not entry.Start());local ok,reason=entry.Prepare('pt-br');assert(ok,tostring(reason))
 assert(entry.Profile.Seed==entry.Foundation.Seed and pr.forgeNativeSeed==entry.Foundation.Seed)
 assert(entry.Bootstrap.Graph and entry.Bootstrap.Graph.Core==entry.Foundation.Base or side=='server'and entry.Bootstrap.Graph.Base==entry.Foundation.Base)
 providerScope=entry.Providers;assert(observers==0);r.surface.Open();assert(raw.Services.Open());local installed,installReason=entry.Install()
 assert(installed,tostring(installReason));assert(observers==1)
 assert(providerScope and #entry.Bootstrap.Graph.Order==23 and entry.Bootstrap.Graph.Core.PlayerData==entry.Foundation.Base.PlayerData)
 external['forge-loadscreen']={FinishLoadingScreen=function()coroutine.yield('minimum-duration');return true end}
 local waiting=coroutine.create(providerScope.Integrations.Character.finishLoadingScreen)
 local started,signal=coroutine.resume(waiting);assert(started and signal=='minimum-duration')
 assert(not entry.Stop());r.clock.advance(1200000);assert(not entry.Poll())
 assert(pr.forgeNativeSeed==entry.Foundation.Seed and not entry.Entry.Support.Utilities.Progress().closed)
 assert(coroutine.resume(waiting));entry.Poll()
 local drained=entry.Poll()
 if not drained then local function dump(t,path,seen)seen=seen or{};if seen[t]then return end;seen[t]=true;for k,v in pairs(t)do if type(v)=='table'then dump(v,path..'.'..tostring(k),seen)elseif type(v)~='function'and(path:find('failure')or path:find('error')or tostring(k):find('Error')or k=='reason'or k=='lastError')then print(path..'.'..tostring(k)..'='..tostring(v))end end end;dump(entry.Progress(),'entry')end
 assert(drained);assert(providerScope.Progress().complete and pr.forgeNativeSeed==nil)
 r.platform.Close();if r.utilities then r.utilities.Close()end;r.finishProfile()
end
print('PASS218 client entry Prepare/Install/Stop/Poll closes provider/library/support/foundation in order; borrowed raw/RPC preserved')
