local R=dofile('tests/kernel_callback_registration_harness.lua');local H=R.H
local r=R.new();local w=r.transport;local s,c=r.prepare();r.install()
local ox,native=0,0
for _,d in ipairs(c.Describe())do
 assert(not d.protected,'client callbacks stay raw')
 if d.protocol=='ox'then ox=ox+1;assert(d.owner=='Central.Main'or d.owner=='Central.Status'or d.owner=='Central.Events')else native=native+1 end
end
assert(ox==4 and native==9,'all thirteen client callbacks classified by actual owner')
local status=w.server.api.ox.await('qbx_core:client:getStatusSnapshot',2)
assert(type(status)=='table','same Status producer through installed ox protocol')
local lease=w.client.owners.native.Reserve('roundtrip');local calls=0
w.client.owners.native.Bind(lease,function(...)calls=calls+1;return false,nil,... end)
H.same(table.pack(w.server.api.native.await(2,'roundtrip',10000,'a',nil,8)),table.pack(false,nil,'a',nil,8),'server-to-client native signature has no extra source')
w.client.owners.native.Release(lease)
-- Check installed adapter throttle, deadline, cancellation, malformed source and nil/error semantics.
local token=w.server.owners.ox.Reserve('throttled');w.server.owners.ox.Bind(token,function()calls=calls+1;return true end)
assert(w.client.api.ox.await('throttled',1000)==true,'installed throttle first call')
local before=calls;assert(w.client.api.ox.await('throttled',1000)==nil and calls==before,'installed throttle blocks same window')
w.clock=1001;assert(w.client.api.ox.await('throttled',1000)==true,'installed throttle expires')
local result;w.client.hold=true
local key=w.client.api.native.trigger('missing',function(...)result=table.pack(...)end)
assert(w.client.api.native.getPending()[key],'request tracked by installed engine')
w.client.dispatch('pr_bridge:callback:response','',key,'forged')
assert(result==nil and w.client.api.native.getPending()[key],'empty/local response origin refused')
w.client.api.native.cancel(key);assert(w.client.api.native.getPending()[key]==nil and result==nil,'native cancellation clears callback request without fabricating success')
local thread=coroutine.create(function()return w.client.api.native.await('missing',25)end)
assert(coroutine.resume(thread));w.expire()
local values=table.pack(coroutine.resume(thread));H.same(values,table.pack(true,nil,'timeout'),'native timeout return preserved')
local oxThread=coroutine.create(function()return w.client.api.ox.await('missing-ox',false)end)
assert(coroutine.resume(oxThread));w.expire()
local good,error=coroutine.resume(oxThread);assert(not good and tostring(error):find('timed out'),'ox timeout rejection remains distinct')
w.client.hold=false
local record=w.client.find('__ox_cb_qbx_core:client:getStatusSnapshot')
local old=r.clientGraph.Parts.Work;r.clientGraph.Parts.Work={}
assert(w.server.api.ox.await('qbx_core:client:getStatusSnapshot',2)==nil,'client graph replacement blocks stale callback')
r.clientGraph.Parts.Work=old
assert(c.Dispose(),'client callbacks removed explicitly')
for _,d in ipairs(c.Describe())do assert(not w.client.find(d.protocol=='ox'and'__ox_cb_'..d.name or d.name),'client listener leaked')end
c.State='installed';record.handler('forge-core','stale');assert(record.removed,'public field cannot resurrect disposed client callback')
assert(s.Dispose(),'server cleanup');w.server.owners.ox.Release(token)
print('PASS client callback registration:13 real callbacks/four ox/nine native; source/nil returns, throttle, timeout/cancel, canonical guards and owned cleanup; virtual time/network')
