local G=dofile('tests/kernel_engine_profile_harness.lua');local P=dofile('tests/kernel_progress_harness.lua');local H=G.H
local r=G.new('client');local p=P.new(true);local original=r.profilePorts.bootstrap.context
local bind=H.load('kernel/entry/progress_context_ports.lua',H.environment());local out=bind(original,p.api)
local a=original.runtimeContext.deliveryContext.configurationContext.mediaContext.worker;local b=out.runtimeContext.deliveryContext.configurationContext.mediaContext.worker
assert(a~=b and a.central~=b.central and a.central.library~=b.central.library)
assert(b.central.library.progressBar==p.lib.progressBar and b.domains.domains.Farms.library.progressBar==p.lib.progressBar)
assert(b.domains.domains.AutoMedic.library.progressBar==b.central.library.progressBar and b.central.library.nativeProgress==p.lib)
assert(a.central.config==b.central.config and a.central.cache==b.central.cache and a.central.character.callbacks==b.central.character.callbacks)
assert(a.domains.domains.Farms.inventoryIntegration==b.domains.domains.Farms.inventoryIntegration)
assert(b.central.library.progressBar({duration=0})==false);assert(p.api.Close());r.finishProfile()
print('PASS152 client graph progress aliases share one engine;original config/cache/callback/inventory retained,no input mutation')
