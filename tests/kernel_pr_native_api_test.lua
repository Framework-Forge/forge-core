local T=dofile('tests/kernel_pr_native_api_harness.lua')
for _,side in ipairs({'server','client'})do
    local r=T.new(side);r.makeProxy();assert(not pcall(r.proxy.API.core.GetJobs));assert(r.nativeAPI.Install());assert(r.proxy.Prepare())
    r.bindingPorts.api=r.proxy.API;r.makeBindings();assert(r.bindings.Prepare()and r.bindings.Attach())
    if side=='server'then
        assert(r.pr.forgeNormalizedFacade.GetIdentifier(2)=='LATE114')
        assert(r.proxy.API.framework.GetPlayer(2)==r.graph.PlayerCore.State.Players[2])
        assert(r.pr.forgeLateBinding.NativeHost.GetCoreObject().Players==r.graph.PlayerCore.State.Players)
    else assert(r.adapterFixture.active()==9 and r.adapterFixture.source.pulls==0)end
    T.H.same(r.proxy.API.core.GetJobs(),r.catalog.Resolve('GetJobs')(),'canonical jobs')
    local held=r.surface.exports.ForgePrCall;assert(r.bindings.Close());assert(r.nativeAPI.Close())
    assert(held('native118-'..side,'core','GetJobs')==nil);assert(r.api.IsCurrent());r.finish()
end
print('PASS lot118 authenticated native API through actual publication,proxy117/116/114;canonical Player/QB map,client passive cache,closed ingress')
