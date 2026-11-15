local T=dofile('tests/kernel_activation_package_harness.lua');local H=T.H
local package=test_decode_json(T.read('package.json'));local compiled=0
assert(not package.operationalReady and package.state=='prepared-inactive')
for _,f in ipairs(package.files)do if f.path:match('%.lua$')then assert(load(T.read(f.path),'@@package120/'..f.path,'t',{}));compiled=compiled+1 end end
assert(compiled==25)
for _,side in ipairs({'server','client'})do
    local r=T.new(side);r.enter();assert(r.providerReads==0 and #r.stopTokens==1 and not pcall(r.pr.forgeNormalizedFacade.GetPlayer,2))
    local held=r.pr.forgeNormalizedFacade;assert(r.nativeAPI.Install()and r.entry.Attach()and r.providerReads==1)
    if side=='server'then assert(held.GetIdentifier(2)=='LATE114');r.ox.runTimers();assert(r.ox.records[2].owner=='LATE114')
    else assert(r.adapterFixture.active()==9 and r.adapterFixture.source.pulls==0)end
    r.stopTokens[1].fn(r.boundResource);assert(r.entry.Progress().complete and r.pr.forgeConsumerEntry==nil and not pcall(held.GetPlayer,2)and r.api.IsCurrent());r.finish()
end
local M=dofile('tests/kernel_native_registration_harness.lua');local R=dofile('tests/kernel_callback_registration_harness.lua')
local barrier=T.barrier();local n=M.new();local wire=R.wire();wire.Initialize();local wrap=H.load('kernel/entry/ingress_ports.lua',H.environment())
local original=n.ports.native;local reg,rpc=wrap(barrier,n.ports,wire.server.owners);assert(n.ports.native==original and reg.native~=original)
n.ports=reg;local native=n.allocate();assert(native.Open());local calls=0;local function body(...)calls=calls+1;return ...end
native.Events.listen('game120',body);native.Events.listen('onResourceStop',body)
native.Public.publishExport('game120',body);native.Public.publishExport('ForgePrDescribe',function()return'handshake120'end)
native.Public.prCommand('pr120',{validate=body},body);native.Public.oxCommand('ox120',{},body);native.Public.nativeCommand('native120',body)
local leases={};for _,protocol in ipairs({'native','ox'})do local p=rpc[protocol];local lease=p.Reserve(protocol..'120');leases[protocol]=lease;assert(p.Bind(lease,body))end
assert(n.published.game120(1)==nil and n.published.ForgePrDescribe()=='handshake120')
n.fire('game120',2);assert(calls==0);n.fire('onResourceStop',0);assert(calls==1)
assert(n.commands.pr120.handler()==nil and n.commands.pr120.options.validate()==nil and n.commands.ox120.handler()==nil and n.commands.native120.handler()==nil)
pcall(wire.client.api.native.await,'native120',5000,'before');assert(calls==1)
T.open(barrier);local out=table.pack(n.published.game120(1,nil,3));assert(out.n==3 and out[3]==3)
H.same(table.pack(wire.client.api.native.await('native120',5000,false,nil,9)),table.pack(2,false,nil,9),'native52 gated tuple')
H.same(table.pack(wire.client.api.ox.await('ox120',false,false,nil,9)),table.pack(2,false,nil,9),'ox52 gated tuple')
local before=calls;assert(barrier.Close());assert(n.published.game120()==nil);n.fire('game120',3);assert(calls==before)
for k,lease in pairs(leases)do assert(rpc[k].Release(lease))end;assert(native.Close())
print('PASS lot120 package25 Lua,physical PR entries both sides,actual117/118/OX113;native99 and owned52 callbacks gated by119;real readiness remains unverified')
