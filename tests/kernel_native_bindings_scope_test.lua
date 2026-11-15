local T=dofile('tests/kernel_native_bindings_harness.lua');local count=0
local function one(fn)local r=T.new('server',true);fn(r);r.finish();count=count+1 end
one(function(r)r.boundAPI.getCoreObject=nil;assert(not pcall(r.makeBindings))end)
one(function(r)r.makeBindings();assert(r.bindings.Prepare());r.boundReady=false;assert(not r.bindings.Attach()and next(r.pr)==nil)end)
one(function(r)r.moduleHook=function(name)if name:find('consumer_schema',1,true)then local s=T.H.load('../pr_bridge/'..name..'.lua',T.H.environment());s.server.normalized.Missing117='Missing117';return s end end
    r.makeBindings();assert(r.bindings.Prepare());assert(not r.bindings.Attach()and r.bindings.Progress().complete)end)
one(function(r)r.makeBindings();assert(r.bindings.Prepare());r.servicesHook=function()r.bindings.Close()end
    assert(not r.bindings.Attach()and r.bindings.Progress().complete)end)
one(function(r)r.makeBindings();assert(r.bindings.Prepare()and r.bindings.Attach());r.ox.refuseRemove=true
    assert(not r.bindings.Close());r.ox.refuseRemove=false;assert(r.bindings.Close()and r.bindings.Progress().complete)end)
one(function(r)r.makeBindings();assert(r.bindings.Prepare());r.pr.forgeRouting={foreign=true}
    assert(not r.bindings.Attach()and r.pr.forgeRouting.foreign)end)
assert(count==6)
print('PASS lot117 six cases:missing declared QB getter,unready provider,schema mismatch,Close in raw-provider load,removal retry,foreign routing slot')
