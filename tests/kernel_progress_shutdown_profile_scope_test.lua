local T=dofile('tests/kernel_progress_shutdown_profile_harness.lua');local cases=0
do local r=T.new('client');local p=r.allocate158();assert(not p.Start()and not p.Install());assert(p.Stop()and not p.Prepare());r.finishProfile();cases=cases+1 end
do local r=T.new('client');r.profilePorts.progress=nil;assert(not pcall(r.allocate158));assert(r.seed.IsCurrent());r.finishProfile();cases=cases+1 end
do local r=T.new('client');local held={};r.profilePorts.prCore.forgeProgressScope=held
assert(not pcall(r.allocate158));assert(r.profilePorts.prCore.forgeProgressScope==held);r.profilePorts.prCore.forgeProgressScope=nil;r.finishProfile();cases=cases+1 end
do local r=T.new('client');local p=r.open158(false);local prior=r.bootstrapPorts.registration.native
assert(prior==r.profilePorts.bootstrap.registration.native and prior~=p.StopBoundary.Bootstrap.registration.native)
r.fireStop158('foreign');assert(p.Progress().phase=='installed'and p.ProgressScope.Progress().phase=='open');p.Stop();r.finishProfile();cases=cases+1 end
do local r=T.new('client');r.seedUnit.current=false;assert(not pcall(r.allocate158));r.seedUnit.current=true;r.finishProfile();cases=cases+1 end
assert(cases==5);print('PASS158 five scope checks:order,missing ports,foreign slot,borrowed registration/foreign stop,stale')
