local H=dofile('tests/kernel_harness.lua');local W=dofile('tests/kernel_worker_harness.lua')
local N=dofile('tests/kernel_native_foundation_harness.lua');local create=N.loader()('kernel.entry.native_context_support')
for _,side in ipairs({'server','client'})do
 local clock=W.clock();local n={};for k,v in pairs(clock.native)do n[k]=v end
 local env=H.environment({os={time=os.time,date=os.date,microtime=function()return clock.now*1000 end}})
 env.string.strsplit=function(sep,text)return text end
 local requests,events,removed={}, {},0;local removeAllowed=false;local callbacks={}
 n.GetResourceState=function(name)return name=='ox_lib'and'missing'or'started'end
 n.GetResourceMetadata=function(_,key)return key=='version'and'1.2.3'or nil end
 n.GetCurrentResourceName=function()return'forge-core'end;n.GetInvokingResource=function()return'consumer'end
 n.GetConvar=function(key,default)return({['ox:logger']='fivemanage',['fivemanage:key']='test-only'})[key]or default end
 n.GetPlayerName=function()return'Virtual'end;n.GetNumPlayerIdentifiers=function()return 0 end;n.GetPlayerIdentifier=function()end
 n.GetGameTimer=function()return clock.now end;n.PerformHttpRequest=function(url,cb)requests[#requests+1]=cb end
 for _,name in ipairs({'TriggerEvent','TriggerClientEvent','SetVehicleDoorsLocked','GetVehicleNumberPlateText','vec4','joaat',
 'RequestScriptAudioBank','GetSoundId','PlaySoundFromCoord','PlaySoundFromEntity','PlaySoundFrontend','ReleaseSoundId'})do n[name]=function()return 1 end end
 n.AddStateBagChangeHandler=function(_,_,callback)callbacks[#callbacks+1]=callback;return #callbacks end
 n.RemoveStateBagChangeHandler=function()if removeAllowed then removed=removed+1;return true end;return false end
 local external={pr_bridge={accessCacheState=function()return true end},pr_3dsound={},ox_inventory={},['Renewed-Banking']={},pr_carkeys={}}
 local names=side=='server'and{'PlayNativeSound','PlayNativeSoundFromEntity','PlayNativeSoundFromCoords'}or{
 'PlayLocalNativeSound','PlayLocalNativeSoundFromEntity','PlayLocalNativeSoundFromCoords','PlaySharedNativeSoundFromEntity','PlaySharedNativeSoundFromCoords'}
 for _,name in ipairs(names)do external.pr_3dsound[name]=function()return true end end
 local f={Side=side,IsCurrent=function()return true end,NativeCache={Cache={}},Base={},
 Seed={Execution={IsCurrent=function()return true end,Bind=function(fields)local out={};for _,name in ipairs(fields)do out[name]=assert(n[name],name)end;return out end},
  IO={Codec={encode=function()return'virtual-json'end},Files={LoadResourceFile=function()end}},
  Library={Cache={resource='forge-core'},Library={print={warn=function()end,error=function()end}}}},
 Events={listen=function(name,fn)local token={name=name,fn=fn};events[#events+1]=token;return token end,remove=function()return true end,source=function()return 3 end},
 Factories={Get=function(name)assert(name=='tasks');return W.create end}}
 local pr={}
 local a=create(f,{prCore=pr,services={Keys={Pr={}},Public={inventory={},banking={},vehicle_key={}}},native=n,external=external,
  environment=env,loadPR=function(path,target)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end,
  running=coroutine.running,onError=error})
 assert(#events==0 and #clock.queue==0 and #requests==0)
 local c=a.Context({isCurrent=function()return true end,isReady=function()return false end,public={},callbacks={}})
 assert(not c.isReady()and c.delivery.cache==f.Seed.Library.Cache and c.delivery.cache~=f.NativeCache.Cache)
 local library=a.MakeLibrary({await=function()end},{}, {},{'math.round','table.clone'})
 assert(library.math.round(3.7)==4 and library.framework==nil);assert(a.Open())
 if side=='server'then
  assert(#events==1 and c.inventory.custom==external.ox_inventory)
  local log=H.load('../pr_bridge/bridge/logging/forge_delivery.lua',H.environment())(c.loggingDelivery);assert(log.Open())
  log.LibraryLogger(3,'context198','test');clock.advance(500);assert(#requests==1)
  assert(not a.Close()and not a.Utilities.Progress().closed and not a.Cache.Progress().closed)
  requests[1](200,'',{},'');assert(a.Close());log.Close()
 else
  local fired=0;c.input.addBag('x',nil,function()fired=fired+1 end);callbacks[1]();assert(fired==1)
  assert(not a.Close()and not a.Utilities.Progress().closed);callbacks[1]();assert(fired==1)
  removeAllowed=true;assert(a.Close()and removed==1)
 end
 assert(a.Progress().complete and not pcall(library.math.round,2))
 assert(not a.Open())
end
print('PASS198 installed PR support on both sides;passive cache/explicit readiness;pending HTTP/refused statebag retain upstream;reverse close and library revocation')
