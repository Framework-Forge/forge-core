local T=dofile('tests/kernel_native_entry140_harness.lua');local r=T.client();r.allocate140();assert(not r.entry140.Start()and not r.entry140.Install())
assert(not pcall(r.factory140,r.raw,r.options140));r.nativeCurrent=false;assert(not r.entry140.Prepare());r.nativeCurrent=true
assert(r.entry140.Stop()and not r.entry140.Prepare());r.finish140()
local q=T.client();q.options140.locale=nil;q.allocate140();local ok=q.entry140.Prepare('pt-br');assert(not ok and q.entry140.Progress().complete and q.env140.PRCore.forgeNativeSeed==nil);q.finish140()
print('PASS lot140 five entry order/duplicate/stale/closed/missing-locale cleanup checks;no fallback or operational activation')
