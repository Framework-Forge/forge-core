local T=dofile('tests/kernel_public_registration_harness.lua');local H,n=T.H,0
local function check(value,label)n=n+1;assert(value,label)end
local factory=H.load('kernel/shared/public_registration.lua',T.env())
local e=T.surface('server');local owner={};local valid=true;local calls={}
local function receive(...)calls[#calls+1]=table.pack(...);return false,nil,8 end
local propertyCalls=0
local function property(...)propertyCalls=propertyCalls+1;return true end
local entries={{kind='export',name='Read',owner='one',handler=receive},{kind='export',name='read',owner='alias',handler=receive},
 {kind='command',name='native',mode='native',restricted=true,owner='one',handler=receive},
 {kind='command',name='parsed',mode='pr',owner='one',properties={params={{name='amount',type='number'}},restricted=true},handler=receive},
 {kind='command',name='compat',mode='ox',owner='one',properties={params={{name='amount',type='number'}},restricted=true},handler=receive},
 {kind='command',name='guarded',mode='pr',owner='one',properties={canAccess=property,suggestionAccess=property,onError=property},handler=receive}}
local api=factory({owner=owner,side='server',entries=entries,isCurrent=function()return valid end},e.ports)
check(#e.trace==0 and api.State=='prepared-inactive','surface constructor inert')
local description=api.Describe();description[4].properties.params[1].type='string'
check(api.Describe()[4].properties.params[1].type=='number','description options copied')
entries[1].handler=function()error('mutated input')end;entries[4].properties.params[1].type='string'
e.Open();e.onPublish=function(fn)check(fn(2,{},'early')==nil,'wrappers inactive during publication')end
check(api.Install(),'surface installed explicitly');e.onPublish=nil
H.same(table.pack(e.exports.Read('a',nil,5)),table.pack(false,nil,8),'export returns/nils preserved')
H.same(calls[1],table.pack('a',nil,5),'export payload unmodified')
check(e.exports.read~=nil and api.Counts.exports==2,'case-sensitive export aliases preserved')
e.run('parsed',2,{'17'},'parsed 17')
check(calls[#calls][2].amount==17 and calls[#calls][2][1].value==17,'installed PR indexed descriptors/scalar named values preserved')
e.run('compat',2,{'19'},'compat 19')
check(calls[#calls][2].amount==19,'installed ox named values preserved')
local before=#calls;e.run('parsed',1,{'20'});e.run('compat',1,{'20'});e.run('native',1,{})
check(#calls==before,'PR/ox/native restricted commands denied')
e.whitelist[1]=true;e.run('parsed',1,{'20'});check(#calls==before+1,'PR whitelist policy preserved')
e.run('compat',1,{'20'});check(#calls==before+1,'ox strictAce does not inherit PR whitelist bypass')
before=#calls;e.run('parsed',2,{'bad'});check(#calls==before,'installed parser refuses invalid typed input')
e.run('native',2,{'raw'},'native raw');H.same(calls[#calls],table.pack(2,{'raw'},'native raw'),'native command shape unchanged')
valid=false;before=#calls;e.exports.Read('stale');e.run('parsed',2,{'3'});check(#calls==before,'canonical replacement blocks public wrappers')
valid=true;check(api.Dispose()and api.State=='revoked','explicit public revocation')
local propertiesBefore=propertyCalls;e.run('guarded',2,{});e.pr.getSuggestions(2)
check(propertyCalls==propertiesBefore,'access/error/suggestion callbacks cannot reach core after revocation')
check(e.exports.Read~=nil and e.commands.parsed~=nil and api.PhysicalUnregistration==false,'revocation is not physical native unregistration')
api.State='installed';e.exports.Read('stale');e.run('native',2,{});check(#calls==before,'State mutation cannot resurrect revoked surface')
check(not api.Install()and not api.Dispose(),'revoked surface never installed again')
local f=T.surface('server');f.exports.Foreign=function()return'foreign'end
local blocker=factory({owner={},side='server',isCurrent=function()return true end,entries={
 {kind='export',name='First',owner='one',handler=receive},{kind='export',name='Foreign',owner='one',handler=receive}}},f.ports)
check(not blocker.Install()and f.exports.First==nil and f.exports.Foreign()=='foreign','complete preflight preserves foreign export')
local failed=T.surface('server');failed.failAt=2
local partial=factory({owner={},side='server',isCurrent=function()return true end,entries={
 {kind='export',name='First',owner='one',handler=receive},{kind='export',name='Second',owner='one',handler=receive}}},failed.ports)
check(not partial.Install()and partial.State=='install-failed-revoked','partial native failure reported and revoked')
before=#calls;failed.exports.First('disabled');check(#calls==before and not partial.Install(),'partially published wrapper never reactivated')
check(partial.Dispose(),'failed surface can finish logical cleanup')
check(not pcall(factory,{owner={},side='server',isCurrent=function()return true end,entries={
 {kind='command',mode='native',name='Alias',owner='a',handler=receive},{kind='command',mode='native',name='alias',owner='b',handler=receive}}},e.ports),'case-insensitive command alias collision refused')
local y=T.surface('client');local yielding=factory({owner={},side='client',isCurrent=function()return true end,entries={
 {kind='export',name='Yield',owner='one',handler=function(...)local args=table.pack(...);coroutine.yield('wait');return table.unpack(args,1,args.n)end},
 {kind='export',name='Error',owner='one',handler=function()error('preserved error',0)end}}},y.ports)
check(yielding.Install(),'yield fixture installed');check(not pcall(y.exports.Error),'export errors preserved')
local co=coroutine.create(function()return y.exports.Yield(nil,4)end);local ok,wait=coroutine.resume(co)
check(ok and wait=='wait','export yield preserved');yielding.Dispose()
H.same(table.pack(coroutine.resume(co)),table.pack(true,nil,4),'inflight export may finish after revocation')
local client=T.surface('client');local clientArgs
local clientRegistration=factory({owner={},side='client',isCurrent=function()return true end,entries={
 {kind='command',mode='pr',name='client',owner='client',properties={params={{name='amount',type='number'}}},handler=function(...)clientArgs=table.pack(...)end}}},client.ports)
client.Open();check(clientRegistration.Install(),'client command provider installed explicitly')
client.run('client',2,{'23'},'client 23')
check(type(clientArgs[1])=='table'and clientArgs[1][1].value==23 and clientArgs[2]=='client 23','client PR callback gets params/raw without server source')
clientRegistration.Dispose()
local wire=T.R.wire();wire.Initialize();local se=T.surface('server');se.ports.rpc=wire.server.owners.ox
local rpcRegistration=factory({owner={},side='server',isCurrent=function()return true end,entries={},callbacks={
 {name='supplemental',owner='one',handler=receive}}},se.ports)
check(rpcRegistration.Install(),'supplemental owned callback installed')
local record=wire.server.find('__ox_cb_supplemental');wire.server.failRemove=record
check(not rpcRegistration.Dispose()and rpcRegistration.State=='revoke-failed','RPC cleanup failure remains retryable')
before=#calls;record.handler('forge-core','stale');check(#calls==before,'RPC wrapper disabled before failed cleanup')
wire.server.failRemove=nil;check(rpcRegistration.Dispose()and not rpcRegistration.Install(),'retry only remaining owned RPC cleanup')
print('PASS public surface '..n..' checks; installed PR/ox parsing and ACL, preflight, revocation/errors/yields; no live registration')
