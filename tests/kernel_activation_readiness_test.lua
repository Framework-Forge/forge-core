local req=dofile('tests/kernel_native_foundation_harness.lua').loader()
local seed={};local phase='prepared';local publication=false;local attached=false;local prepared=true;local facts={}
local entry={IsCurrent=function()return true end,Foundation={Seed=seed},Profile={Seed=seed},
 Bootstrap={Progress=function()return{phase=phase}end}}
local rawPhase='allocated';local raw={Services={Progress=function()return{phase=rawPhase}end}}
local c={GetPreparedEntry=function()return entry end,GetPreparedRaw=function()return raw end}
local external={};for _,key in ipairs({'oxHooks','catalogs','banking','keys','decisions','environment'})do
 facts[key]=false;external[key]=function(g,e,r)assert(g=='236'and e==entry and r==raw);return facts[key]end
end
local p={generation='236',getCandidate=function()return c end,
 publication={IsInstalled=function()return publication end,CompatibilityReady=function()return publication end},
 consumers={IsPrepared=function()return prepared end,IsAttached=function()return attached end},external=external}
local a=req('kernel.entry.activation_readiness')(p)
assert(a.Probes.allocations('236'));assert(not a.Probes.allocations('old'))
local barrier=req('kernel.entry.activation_barrier')({generation='236',isCurrent=function()return true end,consumers={'ox_inventory'},probes=a.Probes})
assert(barrier.ConsumerState('236','ox_inventory','prepared'));assert(barrier.Advance(1))
assert(not barrier.Advance(2));rawPhase='open';assert(barrier.Advance(2))
assert(not barrier.Advance(3));phase='installed';assert(barrier.Advance(3))
publication=true;assert(barrier.Advance(4));assert(barrier.ConsumerState('236','ox_inventory','attaching'))
attached=true;assert(barrier.ConsumerState('236','ox_inventory','committed'));assert(barrier.Advance(5))
assert(a.Arm(c));assert(not barrier.Advance(6))
for name in pairs(facts)do facts[name]=true end;assert(barrier.Advance(6)and barrier.IsIngressOpen())
entry.Profile.Seed={};assert(not a.Probes.bootstrap('236'));entry.Profile.Seed=seed
assert(a.Close()and a.Progress().complete);assert(not a.Probes.environment('236'))
external.environment=function()coroutine.yield('probe-pending');return true end
local b=req('kernel.entry.activation_readiness')(p);assert(b.Arm(c))
local thread=coroutine.create(function()return b.Probes.environment('236')end)
local ok,value=coroutine.resume(thread);assert(ok and value=='probe-pending')
assert(not b.Close()and not b.Progress().complete)
ok,value=coroutine.resume(thread);assert(ok and value==false);assert(b.Close()and b.Progress().complete)
external.keys=nil;assert(not pcall(req('kernel.entry.activation_readiness'),p))
print('PASS236 actual barrier observes structural owners; F waits explicit six probes; stale seed/generation/missing probe refused')
