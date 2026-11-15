local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local T=dofile('tests/kernel_qb_binding_context_harness.lua')
for _,side in ipairs({'server','client'})do
 for _,disabled in ipairs({false,true})do
 local r=side=='server'and T.server()or T.client();r.qb.Close();r.qbBackend.Close()
 local invoker='qbx_core';local open=false
 local original=function()return invoker end
 local originOwner=req('kernel.entry.activation_origin')({running=coroutine.running,getInvokingResource=original,isCurrent=r.api.IsCurrent})
 local entry={Bootstrap={Graph=r.graph,Transport={Public=r.surface.ports,Events=r.events},Progress=function()return{phase='installed'}end},
 IsCurrent=r.api.IsCurrent,ActivationOriginOwner=originOwner}
 local owner=req('kernel.entry.activation_compatibility')(r.graph,side,entry,{generation='compat244',
 barrier={CanServe=function()return open end},getInvokingResource=original,aliasAvailable=r.bindingPorts.aliasAvailable,
 makePorts=function(_,_,_,origin)
  local p={};for k,v in pairs(r.qbPorts)do p[k]=v end
  p.native={};for k,v in pairs(r.qbPorts.native)do p.native[k]=v end;p.native.GetInvokingResource=origin.GetInvokingResource
  if disabled then p.native.GetConvar=function(_,fallback)return'false'end end
  if side=='client'then p.sharedConfig=r.qbBackendPorts.sharedConfig end
  return p
 end})
 assert(owner.Graph==r.graph and owner.Origin==originOwner.Origin)
 assert(owner.Install()and owner.IsReady());assert(r.surface.exports.ForgeQbxCompatDescribe()==nil)
 open=true;local d=r.surface.exports.ForgeQbxCompatDescribe()
 assert(d.authority=='forge-core'and d.generation=='compat244')
 local object=owner.GetCoreObject and owner.GetCoreObject()
 assert(disabled and object==nil or not disabled and object~=nil)
 if side=='server'then
  assert(r.surface.exports.ForgeQbxCompatCall('compat244','GetPlayer','legacy',2)==r.graph.PlayerCore.State.Players[2])
  if object then assert(object.Players==r.graph.PlayerCore.State.Players)end
 else
  assert(r.surface.exports.ForgeQbxCompatCall('compat244','GetPlayerData','legacy')==r.graph.Central.Parts.Legacy.Functions.GetPlayerData())
 end
 invoker='intruder';assert(not pcall(r.surface.exports.ForgeQbxCompatDescribe));invoker='qbx_core'
 assert(not pcall(r.surface.exports.ForgeQbxCompatCall,'old','GetPlayer','legacy',2))
 local held=r.surface.exports.ForgeQbxCompatDescribe
 assert(owner.Close()and owner.Progress().complete);assert(held()==nil and r.api.IsCurrent())
 assert(originOwner.IsCurrent());originOwner.Close()
 if side=='client'then r.api.Stop();r.clock.advance(120000);r.api.Poll()else r.close()end
 end
end
print('PASS244 actual QB95/gateway/publication both sides,one graph;barrier/auth/stale generation/cleanup;platform and origin fixture virtual')
