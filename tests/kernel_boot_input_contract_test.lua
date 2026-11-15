local H=dofile('tests/kernel_harness.lua');local c=H.load('kernel/entry/boot_input_contract.lua',H.environment())
local info=function()return{source='@installed/providers.lua'}end
local function options()
 local fn=function()error('provider must not execute during inspection')end
 return{base={},bootstrap={context={},registration={},isCurrent=fn,isReady=fn},public={},nativeCache={resource='forge-core'},
 events={listen=fn,remove=fn,markNetwork=fn,source=fn},domainLocale=fn,locale=fn,inventoryBridgeProbe=fn,isCurrent=fn,onError=fn,
 barrier={WrapIngress=fn,IsIngressOpen=fn}}
end
for _,side in ipairs({'client','server'})do
 local p=options();p.self=p;local r=c.Inspect(p,side,info);assert(r.accepted and r.fixtures==0 and not r.operationalReady and not r.semanticReadinessProven)
 for _,s in ipairs(c.Describe(side))do local x=options();x[s.name]=nil;assert(not c.Inspect(x,side,info).accepted,s.name)end
 local r2=c.Inspect(p,side,function()return{source='@tests/fixture.lua'}end);assert(not r2.accepted and r2.fixtures>0)
 local unknown=c.Inspect(p,side,function()error('unknown')end);assert(not unknown.accepted)
end
assert(not pcall(c.Inspect,{},'unknown',info))
print('PASS168 passive input contract:all10 client/11 server fields,missing/wrong provenance/cycles;providers never invoked')
