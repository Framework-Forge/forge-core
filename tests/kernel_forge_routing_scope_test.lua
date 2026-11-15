local H=dofile('tests/kernel_harness.lua');local current=true;local hook;local reads=0
local api=H.load('../pr_bridge/bridge/frameworks/forge/routing_factory.lua',H.environment())({active={frameworks='forge'},config={},contracts={},
    isCurrent=function()return current end,readDeclarations=function()reads=reads+1;if hook then hook()end;return{'forge'}end})
hook=function()coroutine.yield()end
local co=coroutine.create(function()assert(not pcall(api.assertAllowed,'qb','consumer'))end)
assert(coroutine.resume(co));api.Close();assert(not api.Progress().complete)
assert(coroutine.resume(co));assert(api.Progress().complete and reads==1)
assert(not pcall(api.getActive)and not pcall(api.forget,'consumer'))
local stale=H.load('../pr_bridge/bridge/frameworks/forge/routing_factory.lua',H.environment())({active={},config={},contracts={},
    isCurrent=function()return current end,readDeclarations=function()error('must not read')end})
current=false;assert(not pcall(stale.select,{'forge'}));stale.Close();assert(stale.Progress().complete)
print('PASS lot85 scope:metadata IO pending and late cache refusal,closed/stale route operations,explicit active/config references;no runtime routing or metadata mutation')
