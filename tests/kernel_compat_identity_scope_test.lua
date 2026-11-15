local T=dofile('tests/kernel_compat_identity_harness.lua');local count=0
local function one(fn)local r=T.new('client');fn(r);r.finish();count=count+1 end
one(function(r)r.metadata.name='qbx_core';r.metadata.version='1.23.0';assert(r.identity.Probe()==nil)end)
one(function(r)r.metadata.forge_authority='foreign';assert(r.identity.Probe()==nil)end)
one(function(r)r.metadata.forge_compat_protocol='2';assert(r.identity.Probe()==nil)end)
one(function(r)r.metadataCounts.name=2;assert(r.identity.Probe()==nil)end)
one(function(r)r.metadataCounts.version=0;assert(r.identity.Probe()==nil)end)
one(function(r)r.metadata.version='unknown';assert(r.identity.Probe()==nil)end)
one(function(r)r.forgeState='starting';assert(r.identity.Probe()==nil)end)
one(function(r)local seen=0;r.metadataHook=function(key,value)if key=='version'then seen=seen+1;if seen==2 then return'0.2.0'end end;return value end
    assert(r.identity.Probe()==nil)end)
one(function(r)local seen=0;r.stateHook=function(name)if name=='qbx_core'then seen=seen+1;if seen==2 then r.shimState='stopped'end end end
    assert(r.identity.Probe()==nil)end)
one(function(r)r.identityCurrent=false;assert(r.identity.Probe()==nil)end)
one(function(r)r.metadataHook=function()error('metadata failure110')end;local d,why=r.identity.Probe();assert(d==nil and why:find('metadata failure110',1,true))end)
one(function(r)r.metadataHook=function(_,value)r.identity.Close();return value end;assert(r.identity.Probe()==nil and r.identity.Progress().complete)end)
one(function(r)local yielded=false;r.metadataHook=function(_,value)if not yielded then yielded=true;coroutine.yield('read110')end;return value end
    local task=coroutine.create(function()assert(r.identity.Probe()==nil)end);assert(coroutine.resume(task))
    assert(not r.identity.Close()and r.identity.Progress().pending==1);assert(coroutine.resume(task));assert(r.identity.Progress().complete)end)
assert(count==13)
print('PASS lot110 thirteen identity refusals:original QBX,authority/protocol,duplicate/missing/version,state,metadata/state drift,owner,error,Close/reentrant read and in-flight drain')
