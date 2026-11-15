local T=dofile('tests/kernel_compat_identity_harness.lua')
for _,side in ipairs({'server','client'})do
    local r=T.new(side);local d=assert(r.identity.Probe())
    assert(d.framework=='forge'and d.authority=='forge-core'and d.publicResource=='qbx_core'and d.publicVersion=='0.1.0')
    assert(not d.nativeQbx and not d.operationalReady)
    local accepted,reason=r.installedVersion.checkDependency('qbx_core','1.18.1',false)
    assert(accepted==false and reason:find('0.1.0',1,true),'keep the real QBX version refusal,never spoof compatibility')
    local a,b=r.identifiedConsumer(),r.identifiedConsumer();assert(a.provider.Install()and b.provider.Install())
    for _,c in ipairs({a,b})do for _,path in ipairs({'modules/lib.lua','modules/utils.lua','modules/playerdata.lua','shared/locale.lua'})do assert(c.loadEntry(path))end end
    if side=='server'then assert(r.published.SetField('joint110',{same=true})and r.graph.PlayerCore.State.joint110.same)
    else assert(a.target.QBX.PlayerData==b.target.QBX.PlayerData and a.target.QBX.PlayerData==r.published.GetPlayerData())end
    assert(a.target.qbx~=b.target.qbx)
    r.shimState='stopped';assert(r.identity.Probe()==nil and not pcall(a.target.GetPlate,20))
    a.stopPhysical();assert(a.provider.Close()and rawget(a.target,'ForgeQbxConsumerPorts')==nil)
    r.shimState='started';assert(r.identity.Probe()and b.target.qbx.string.trim(' resumed ')=='resumed')
    assert(r.api.IsCurrent());r.finish()
end
print('PASS lot110 joint108/109/physical107/Forge graphs;explicit Forge identity,real own version,installed PR1.18.1 refusal preserved,two independent consumers,same PlayerData,late readiness revocation')
