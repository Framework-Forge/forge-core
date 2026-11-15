local T=dofile('tests/kernel_keybind_profile_harness.lua')
do local r=T.new('client');local p=r.allocate166();assert(not p.Install()and not p.Start());assert(p.Stop()and not p.Prepare());r.finishProfile()end
do local r=T.new('client');local held={};r.profilePorts.prCore.forgeKeybindScope=held
assert(not pcall(r.allocate166));assert(r.profilePorts.prCore.forgeKeybindScope==held);r.profilePorts.prCore.forgeKeybindScope=nil;r.finishProfile()end
do local r=T.new('client');r.seedUnit.seedPorts.native.RegisterKeyMapping=nil
assert(not pcall(r.allocate166));assert(r.seed.IsCurrent());r.finishProfile()end
do local r=T.new('client');local p=r.open166();r.fireStop158('forge-core');assert(not p.IsCurrent());r.clock.advance(120000)
assert(p.Poll()and p.Progress().complete);r.finishProfile()end
print('PASS166 four order/foreign owner/missing native/native stop checks;borrowed seed preserved')
