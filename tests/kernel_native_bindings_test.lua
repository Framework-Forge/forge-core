local T=dofile('tests/kernel_native_bindings_harness.lua')
for _,side in ipairs({'server','client'})do
    local r=T.new(side,side=='server');r.makeBindings();assert(r.providerReads==0);assert(r.bindings.Prepare()and r.providerReads==0)
    local held=r.pr.forgeNormalizedFacade;assert(not pcall(held.GetPlayer,2));assert(r.bindings.Attach()and r.providerReads==1)
    assert(r.pr.forgeRouting.isNative('qbx')and r.pr.forgeRouting.getActive()=='forge')
    if side=='server'then assert(held.GetIdentifier(2)=='LATE114');r.ox.runTimers();assert(r.ox.records[2].owner=='LATE114')
        assert(r.pr.forgeLateBinding.NativeHost.GetCoreObject().Players==r.graph.PlayerCore.State.Players)
    else assert(r.adapterFixture.active()==9 and r.adapterFixture.source.pulls==0 and r.bindingPorts.view.PlayerData==r.catalog.Resolve('GetPlayerData')())end
    assert(r.bindings.Close()and r.bindings.Progress().complete and next(r.pr)==nil and r.api.IsCurrent());r.finish()
end
local schema=T.H.load('../pr_bridge/bridge/frameworks/forge/consumer_schema.lua',T.H.environment())
for _,side in ipairs({'server','client'})do local s=T.A.N.new(true,side)
    T.H.same(schema[side].framework,T.A.aliases(s.source.framework),'raw method schema')
    T.H.same(schema[side].normalized,T.A.aliases(s.framework),'normalized method schema')
end
print('PASS lot117 native117/116/114/80-86 composition;53/84 server and10/31 client methods/aliases,providers deferred,same Player/QB map,cache passive,nine client events')
