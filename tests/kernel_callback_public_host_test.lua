local T=dofile('tests/kernel_owned_rpc_harness.lua');local H=T.H
local host=dofile('tests/kernel_callback_public_host_fixture.lua')
local w=T.new();local hosts={}
for _,side in ipairs({'server','client'})do
 hosts[side]=host(H,w[side],side)
 w.ports[side].environment.exports={pr_bridge=hosts[side].proxy}
end
w.open()
local name='qbx_core:server:getGroups';local owner=w.scopes.server.Owners.ox
local lease=owner.Reserve(name);local calls=0
assert(owner.Bind(lease,function(source)assert(source==2);calls=calls+1;return{jobs={taxi={label='Taxi'}},gangs={none={}}}end))
local result=w.scopes.client.Ox.await(name,false)
assert(result.jobs.taxi.label=='Taxi'and calls==1,'actual groups response missing')
assert(hosts.server.registry.exists(name),'host must see the registered callback')
assert(not pcall(hosts.server.Service,'foreign','setValidCallback',name,true),'foreign claim replaced Forge')
assert(not pcall(hosts.server.Service,'foreign','setValidCallback',name,false),'foreign release removed Forge')
local clientOwner=w.scopes.client.Owners.ox;local clientLease=clientOwner.Reserve('client:tuple')
assert(clientOwner.Bind(clientLease,function(...)return nil,...,false end))
local tuple=table.pack(w.scopes.server.Ox.await('client:tuple',2,73))
assert(tuple.n==3 and tuple[1]==nil and tuple[2]==73 and tuple[3]==false)
assert(owner.Release(lease));assert(not hosts.server.registry.exists(name))
local ok,err=pcall(w.scopes.client.Ox.await,name,false)
assert(not ok and tostring(err):find("callback 'qbx_core:server:getGroups' does not exist",1,true),'missing callback must still reject')
assert(w.scopes.client.Close());assert(not hosts.client.registry.exists('client:tuple'))
assert(w.scopes.server.Close())
print('PASS real PR public validator + private Forge RPC: groups response, both directions, nil tuple, owner collision/release, missing rejection and close')
