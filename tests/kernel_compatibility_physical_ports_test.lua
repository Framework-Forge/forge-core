local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local T=dofile('tests/kernel_qb_binding_context_harness.lua')
for _,side in ipairs({'server','client'})do
 local r=side=='server'and T.server()or T.client();r.qb.Close();r.qbBackend.Close()
 local environment=setmetatable({},{__index=function()return function()end end})
 for k,v in pairs(r.qbPorts.native)do environment[k]=v end
 local original=function()return 'qbx_core'end
 local originOwner=req('kernel.entry.activation_origin')({running=coroutine.running,getInvokingResource=original,isCurrent=r.api.IsCurrent})
 local seed={Library={Library=r.qbPorts.lib or r.qbPorts.library}}
 local f={Side=side,Seed=seed,Events={source=function()return 2 end},IsCurrent=r.api.IsCurrent}
 local entry={Bootstrap={Graph=r.graph},Foundation=f,IsCurrent=r.api.IsCurrent,ActivationOriginOwner=originOwner}
 local searched
 local raw={Services={Public={inventory={Search=function(...)searched=table.pack(...);return 9 end}},
 Progress=function()return{phase='prepared'}end}}
 local p={environment=environment,isCurrent=r.api.IsCurrent,getRaw=function()return raw end,
 legacyConversion={convertItems=function()error('must not convert implicitly')end,inventoryItems={},legacyItems={}},
 sharedConfig=side=='client'and r.qbBackendPorts.sharedConfig or nil}
 local ports=req('kernel.entry.compatibility_physical_ports')(p)(r.graph,side,entry,originOwner.Origin)
 assert(ports.inventory.search(2,'count','bread')==9 and searched[3]=='bread')
 assert(ports.native.GetInvokingResource==originOwner.Origin.GetInvokingResource and ports.native.source()==2)
 ports.origin=originOwner.Origin
 local owner=req('kernel.entry.'..side..'_compatibility_factory')(r.graph,ports)
 assert(owner.GetCoreObject()and owner.Close())
 raw.Services.Public.inventory.Search=nil
 assert(not pcall(req('kernel.entry.compatibility_physical_ports')(p),r.graph,side,entry,originOwner.Origin))
 originOwner.Close();if side=='client'then r.api.Stop();r.clock.advance(120000);r.api.Poll()else r.close()end
end
print('PASS245 physical port capture builds real QB factories;inventory only through PR;no implicit legacy conversion;missing Search refused')
