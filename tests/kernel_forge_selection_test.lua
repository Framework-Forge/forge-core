local I=dofile('tests/kernel_compat_identity_harness.lua');local A=dofile('tests/kernel_adapter_binding_harness.lua');local H=I.H
local function physical(side,adapter,slot)
    local root='../../../../.planning/migration/staging/111/pr_bridge/bridge/frameworks/forge/'
    local file=assert(io.open(root..side..'.lua','rb'));local source=file:read('*a');file:close()
    local pr={context=side,forgeAdapterSetup=adapter.ports,forgeAdapterBinding=slot,
        load=function(path)assert(path=='bridge.frameworks.forge.consumer_binding');return H.load(A.path,H.environment())end}
    local env=H.environment({PRCore=pr,ActiveBridges={frameworks='forge'}})
    return function()return assert(load(source,'@@pr_bridge/bridge/frameworks/forge/'..side..'.lua','t',env))()end,pr
end
for _,side in ipairs({'client','server'})do
    local r=I.new(side);local selector=H.load('../pr_bridge/bridge/frameworks/forge/selection_factory.lua',H.environment())({side=side,identity=r.identity,isCurrent=function()return r.identityCurrent end})
    assert(selector.Select('frameworks','auto')==nil and selector.Select('targets','forge')==nil)
    local d=selector.Select('frameworks','forge');assert(d.path=='bridge.frameworks.forge.'..side and d.resource=='forge-core'and d.compatibilityVersion=='0.1.0')
    local a=A.new(side);local open,pr=physical(side,a);local framework=open()
    assert(framework==a.target.framework and framework==a.aliases.framework and pr.forgeAdapterBinding.Framework==framework)
    if side=='server'then assert(framework.GetIdentifier(1)=='C81')else assert(a.active()==9 and a.source.pulls==0)end
    assert(not pcall(open));assert(pr.forgeAdapterBinding.Close());assert(selector.Close());r.finish()
end
local count=0;local function one(fn)local r=I.new('client');fn(r);r.finish();count=count+1 end
one(function(r)r.metadata.name='qbx_core';local p={side='client',identity=r.identity,isCurrent=function()return true end}
    local s=H.load('../pr_bridge/bridge/frameworks/forge/selection_factory.lua',H.environment())(p);assert(not pcall(s.Select,'frameworks','forge'));s.Close()end)
one(function(r)local a=A.new();local open,pr=physical('client',a,{foreign=true});assert(not pcall(open)and pr.forgeAdapterBinding.foreign)end)
one(function(r)local a=A.new();local open,pr=physical('client',a);pr.forgeAdapterSetup=nil;assert(not pcall(open)and pr.forgeAdapterBinding==nil)end)
one(function(r)local a=A.new();local open,pr=physical('client',a);a.listenHook=function()pr.forgeAdapterBinding={foreign=true}end
    assert(not pcall(open)and pr.forgeAdapterBinding.foreign and a.active()==0)end)
one(function(r)local s=H.load('../pr_bridge/bridge/frameworks/forge/selection_factory.lua',H.environment())({side='client',identity=r.identity,isCurrent=function()return true end})
    local hit=false;r.metadataHook=function(_,v)if not hit then hit=true;coroutine.yield('select111')end;return v end
    local co=coroutine.create(function()assert(not pcall(s.Select,'frameworks','forge'))end);assert(coroutine.resume(co));assert(not s.Close()and s.Progress().pending==1);assert(coroutine.resume(co));assert(s.Progress().complete)end)
assert(count==5)
print('PASS lot111 explicit selection/client-server physical entries,real80/81/83,no fallback/pulls,owned bindings and five refusal/cleanup cases')
