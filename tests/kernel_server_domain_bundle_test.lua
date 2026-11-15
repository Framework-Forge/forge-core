local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local fn=function()return true end;local t=setmetatable({},{__index=function()return fn end})
local lib={math=math};local clock={time=os.time,date=os.date};local raw={Operations={Raw=t,IsReady=fn,ResourceState=fn,ReadShopFile=fn},Inventory={},Keys={Integration=t}}
local int={Prison=t,Ace=t,Skill=t,Progression=t,Webhook=t,CatalogFile=t,Purchases=t,Management=t}
local a=req('kernel.entry.server_domain_bundle')({Side='server',IsCurrent=fn,Seed={IO={Codec={}}}}, {},{Clock=clock,Compile=fn},lib,int,
 {services=raw,config={},translate=fn,environment={print=fn}})
local count=0;for name,p in pairs(a.domains)do count=count+1;assert(a.libraries[name]==lib and next(p.native)==nil and p.config==nil)end
assert(count==18 and a.domains.Skills.progression==int.Progression and a.domains.Staff.aceIntegration==int.Ace)
assert(a.domains.Stores.inventoryIntegration.onPurchaseResult==int.Purchases.onPurchaseResult)
assert(a.domains.AutoMedic.inventoryIntegration.clearInventoryRaw==raw.Operations.Raw.ClearInventory)
assert(a.domains.Vehicles.vehicleIntegration==raw.Keys.Integration)
print('PASS205 all18 domain inputs,local ownership untouched and canonical raw/PR integrations reused')
