local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local T=dofile('tests/kernel_qb_bridge_harness.lua')
for _,disabled in ipairs({false,true})do
 local r=T.runtime();r.qb.Close();r.qbBackend.Close()
 local native={};for k,v in pairs(r.qbPorts.native)do native[k]=v end
 local origin=req('kernel.compat.qbx.call_origin')({running=coroutine.running,getInvokingResource=native.GetInvokingResource,isCurrent=r.qbPorts.isCurrent})
 native.GetInvokingResource=origin.GetInvokingResource
 if disabled then native.GetConvar=function(key,fallback)return key=='qbx:enablebridge'and'false'or fallback end end
 local p={};for k,v in pairs(r.qbPorts)do p[k]=v end;p.native=native;p.origin=origin
 local owner=req('kernel.entry.server_compatibility_factory')(r.graph,p)
 assert(owner.Graph==r.graph and owner.Origin==origin and owner.IsCurrent())
 if disabled then assert(not owner.Enabled and owner.GetCoreObject==nil)
 else
  local qb=owner.GetCoreObject()
  assert(qb.Players==r.graph.PlayerCore.State.Players and qb.Shared.Vehicles==r.graph.PlayerCore.Shared.Vehicles)
  assert(qb.Functions.GetPlayer(2)==r.graph.PlayerCore.State.Players[2])
  assert(qb.Player_Buckets==r.graph.PlayerCore.State.Player_Buckets)
 end
 assert(owner.Close()and owner.Progress().complete);assert(r.api.IsCurrent());origin.Close();r.close()
end
print('PASS242 concrete server QB bridge/backend canonical Player/catalog/buckets;disabled branch and selective cleanup;virtual platform')
