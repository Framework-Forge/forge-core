local T=dofile('tests/kernel_domain_profile_harness.lua')
local a=T.new('server');local p=a.allocate144();assert(not p.Start());assert(p.Stop()and p.Poll());assert(not p.Prepare());assert(a.seed.IsCurrent());a.finishProfile()
local b=T.new('client');b.profilePorts.domainConfigurationPorts.locale=nil;assert(not pcall(b.allocate144));assert(b.seed.IsCurrent());b.finishProfile()
local c=T.new('server');c.profilePorts.side='bad';assert(not pcall(c.allocate144));assert(c.seed.IsCurrent());c.finishProfile()
local d=T.new('client');d.seedUnit.current=false;assert(not pcall(d.allocate144));d.seedUnit.current=true;d.finishProfile()
local e=T.new('server');e.profilePorts.loadPR=function(path)if path:find('forge_domain_persistence',1,true)then error('missing installed PR port')end;return e.seedPorts.loadPR(path)end
assert(not pcall(e.allocate144)and e.seed.IsCurrent());e.finishProfile()
print('PASS144 five order/stale/missing-port/side checks;borrowed seed remains open after construction failure')
