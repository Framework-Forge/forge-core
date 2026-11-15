local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local T=dofile('tests/kernel_qb_client_bridge_harness.lua')
for _,disabled in ipairs({false,true})do
 local r=T.runtime();r.qb.Close();r.qbBackend.Close()
 local p={};for k,v in pairs(r.qbPorts)do p[k]=v end
 p.sharedConfig=r.qbBackendPorts.sharedConfig
 p.native={};for k,v in pairs(r.qbPorts.native)do p.native[k]=v end
 local origin=req('kernel.compat.qbx.call_origin')({running=coroutine.running,
 getInvokingResource=function()return 'client-consumer'end,isCurrent=p.isCurrent})
 p.origin=origin;p.native.GetInvokingResource=origin.GetInvokingResource
 if disabled then p.native.GetConvar=function(_,fallback)return'false'end end
 local owner=req('kernel.entry.client_compatibility_factory')(r.graph,p)
 assert(owner.Graph==r.graph and owner.IsCurrent())
 if disabled then assert(not owner.Enabled and owner.GetCoreObject==nil)
 else
  local qb=owner.GetCoreObject()
  assert(qb.Shared.Weapons==r.graph.Core.Shared.Weapons)
  assert(qb.Functions.GetPlayerData()==owner.Backend.Core.GetPlayerData())
  assert(qb.Config.hasKeys==r.graph.Core.ClientConfigurationContext.Config.Client.hasKeys)
 end
 assert(owner.Close()and owner.Progress().complete);assert(r.api.IsCurrent())
 origin.Close();r.api.Stop();r.clock.advance(120000);r.api.Poll()
end
print('PASS243 concrete client QB bridge/backend;canonical PlayerData/config/catalog;disabled branch;core survives compatibility cleanup')
