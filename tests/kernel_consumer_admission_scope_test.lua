local T=dofile('tests/kernel_consumer_admission_harness.lua');local count=0
local function case(fn)local r=T.new();fn(r);r.finish();count=count+1 end
for _,caller in ipairs({'forge-core','qbx_core','foreign',''})do case(function(r)r.prepareAdmission();r.nativeCaller=caller
    assert(not pcall(r.surface.exports.ForgePrConsumerState,'barrier119',r.consumerInstance,'attaching'))end)end
case(function(r)r.prepareAdmission();r.nativeCaller=nil;assert(not pcall(r.surface.exports.ForgePrConsumerState,'barrier119',r.consumerInstance,'attaching'))end)
case(function(r)r.prepareAdmission();assert(not r.surface.exports.ForgePrConsumerState('stale',r.consumerInstance,'attaching'))end)
case(function(r)r.prepareAdmission();assert(not r.surface.exports.ForgePrConsumerState('barrier119',r.consumerInstance,'committed'))end)
case(function(r)r.prepareAdmission();r.describeHook=function(d)d.phase='closed'end;assert(not r.admission.IsAllowed(r.boundResource,'describe'))end)
case(function(r)assert(r.bindings.Prepare());r.describeHook=function(d)d.resource='foreign'end;assert(not r.admission.ObservePrepared());assert(r.policy.Progress().consumers[r.boundResource]=='declared')end)
case(function(r)r.prepareAdmission();r.makeProxy();assert(r.proxy.Prepare());r.describeHook=function()r.admission.Close()end
    assert(not r.surface.exports.ForgePrConsumerState('barrier119',r.consumerInstance,'attaching'))end)
case(function(r)r.prepareAdmission();r.makeProxy();assert(r.proxy.Prepare());assert(r.surface.exports.ForgePrConsumerState('barrier119',r.consumerInstance,'attaching'))
    assert(not r.surface.exports.ForgePrConsumerState('barrier119',r.consumerInstance,'attaching'))end)
assert(count==11);print('PASS lot124 eleven native caller/epoch/phase/descriptor/instance/reentry/duplicate cases;foreign payload cannot choose consumer')
