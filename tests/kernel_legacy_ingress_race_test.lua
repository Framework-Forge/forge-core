-- Real PR host/transport + Forge compatibility/gateways and physical ingress decorator.
local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local T=dofile('tests/kernel_qb_binding_context_harness.lua');local H=T.H
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
for _,side in ipairs({'server','client'})do
 local r=side=='server'and T.server()or T.client();r.qb.Close();r.qbBackend.Close()
 local current=true;local invoking='pr_bridge';local generation='race1849';local clock=0
 local probes={};for _,n in ipairs({'allocations','rawProviders','bootstrap','nativeAPI','compatIdentity','consumerBindings',
  'oxHooks','catalogs','banking','keys','decisions','environment'})do probes[n]=function()return true end end
 local barrier=req('kernel.entry.activation_barrier')({generation=generation,isCurrent=function()return current end,consumers={'consumer'},probes=probes})
 assert(barrier.ConsumerState(generation,'consumer','prepared'))
 for stage=1,4 do assert(barrier.Advance(stage))end
 local physical={};local registration={native={publishExport=function(name,fn)physical[name]=fn;return true end}}
 local guarded=req('kernel.entry.ingress_ports')(barrier,registration)
 local public={};for k,v in pairs(r.surface.ports)do public[k]=v end
 public.publishExport=guarded.native.publishExport
 local original=function()return invoking end
 local originOwner=req('kernel.entry.activation_origin')({running=coroutine.running,getInvokingResource=original,isCurrent=r.api.IsCurrent})
 local entry={Bootstrap={Graph=r.graph,Transport={Public=public,Events=r.events},Progress=function()return{phase='installed'}end},
  IsCurrent=r.api.IsCurrent,ActivationOriginOwner=originOwner}
 local compat=req('kernel.entry.activation_compatibility')(r.graph,side,entry,{generation=generation,barrier=barrier,
  getInvokingResource=original,aliasAvailable=r.bindingPorts.aliasAvailable,makePorts=function(_,_,_,origin)
   local p={};for k,v in pairs(r.qbPorts)do p[k]=v end;p.externalQBAliases=true
   p.native={};for k,v in pairs(r.qbPorts.native)do p.native[k]=v end;p.native.GetInvokingResource=origin.GetInvokingResource
   if side=='client'then p.sharedConfig=r.qbBackendPorts.sharedConfig end
   return p
  end})
 assert(compat.Install()and compat.IsReady())
 assert(physical.ForgeQbxCompatDescribe()==nil,'actual physical export remains closed before stage6')
 local reads=0;local core={ForgeRuntimeStatus=function()return{generation=generation,stage=barrier.Progress().stage,
  ingressOpen=barrier.IsIngressOpen(),phase='running'}end}
 for name,fn in pairs(physical)do core[name]=function(_,...)reads=reads+1
  return fn(...)
 end end
 local events={};local caller='third-party'
 local e=setmetatable({PRCore={},GetCurrentResourceName=function()return'pr_bridge'end,
  IsDuplicityVersion=function()return side=='server'end,GetInvokingResource=function()return caller end,
  GetConvar=function(_,v)return v end,GetConvarInt=function(_,v)return v end,GetGameTimer=function()return clock end,
  AddEventHandler=function(name,fn)events[name]=fn end,exports={['forge-core']=core},
  LoadResourceFile=function(resource,path)assert(resource=='pr_bridge');return read('../pr_bridge/'..path)end,
  Wait=function(ms)
   assert(reads==0,'no early descriptor or data reads');clock=clock+ms
   if barrier.Progress().stage==4 then
    assert(barrier.ConsumerState(generation,'consumer','attaching'));assert(barrier.ConsumerState(generation,'consumer','committed'));assert(barrier.Advance(5))
   elseif barrier.Progress().stage==5 then assert(barrier.Advance(6))else error('unexpected wait')end
  end},{__index=_G})
 assert(load(read('../pr_bridge/bridge/compat/qbx/host.lua'),'@@pr_bridge/bridge/compat/qbx/host.lua','t',e))()
 assert(reads==0 and clock==0,'host import must remain passive')
 local object=e.PRCore.forgeLegacyCompatibility.CallQB('GetCoreObject')
 assert(object==compat.GetCoreObject()and clock==50 and reads==3,'wait4→5→6 then use the same canonical object')
 local remote=core.ForgeQbxCompatCall
 assert(not pcall(remote,core,'stale','GetPlayer','third-party',2),'stale generation still refused')
 invoking='intruder';assert(not pcall(core.ForgeQbxCompatDescribe,core),'wrong native caller still refused');invoking='pr_bridge'
 caller=nil;assert(not pcall(e.PRCore.forgeLegacyCompatibility.CallQB,'GetCoreObject'),'missing original caller refused');caller='third-party'
 events[side=='server'and'onResourceStop'or'onClientResourceStop']('forge-core')
 assert(not pcall(e.PRCore.forgeLegacyCompatibility.CallQB,'GetCoreObject'),'stopped host remains closed')
 assert(compat.Close());originOwner.Close();current=false;assert(barrier.Close())
 if side=='client'then r.api.Stop();r.clock.advance(120000);r.api.Poll()else r.close()end
end
print('PASS legacy readiness race both sides: real PR host/transport→Forge gateway→physical ingress; stages4/5 wait,6 canonical object; caller/epoch/stop retained')
