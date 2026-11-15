local T=dofile('tests/kernel_owned_rpc_harness.lua');local R,H=T.R,T.H
local w=T.new();local hosts={};local host=dofile('tests/kernel_callback_public_host_fixture.lua')
for _,side in ipairs({'server','client'})do
 hosts[side]=host(H,w[side],side)
 w.ports[side].environment.exports={pr_bridge=hosts[side].proxy}
end
local r=R.T.new()
r.server.central.library.callback.register=w.scopes.server.Owners.native.CaptureRegister
w.scopes.server.Owners.securityLibrary=r.server.central.library
local graph=r.server.mount()
local binding=H.load('kernel/server/callback_registration.lua',R.env())(graph,w.scopes.server.Owners)
w.open();assert(binding.Install())
local declared=0
for name in pairs(graph.RawCallbacks.Character)do
 declared=declared+1;assert(hosts.server.registry.exists(name),'public host missing '..name)
end
-- Groups are a supplemental registration in the canonical player core.
local owner=w.scopes.server.Owners.ox
for name,fn in pairs(graph.PlayerCore.Groups.Callbacks)do
 if not hosts.server.registry.exists(name)then local lease=owner.Reserve(name);assert(owner.Bind(lease,fn))end
end
local groups=w.scopes.client.Ox.await('qbx_core:server:getGroups',false)
assert(type(groups.jobs)=='table'and type(groups.gangs)=='table')
local chars,slots,details=w.scopes.client.Ox.await('qbx_core:server:getCharacters',false)
assert(type(chars)=='table'and type(slots)=='number'and type(details)=='table','character RPC did not return the actual contract')
assert(binding.Dispose())
for name in pairs(graph.RawCallbacks.Character)do assert(not hosts.server.registry.exists(name),'public host leaked '..name)end
assert(w.scopes.server.Close());assert(w.scopes.client.Close())
print('PASS full server callback graph/public PR validation: '..declared..' character contracts, real groups/getCharacters response and owned cleanup; SQL/rendering virtual')
