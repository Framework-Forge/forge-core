local T=dofile('tests/kernel_consumer_ports_harness.lua')
for _,side in ipairs({'server','client'})do
    local r=T.new(side);local c=r.consumerPorts();assert(rawget(c.target,'ForgeQbxConsumerPorts')==nil)
    assert(c.provider.Install()and not c.provider.Install());local settings=c.target.ForgeQbxConsumerPorts
    assert(settings.consumer.lib.cache==c.legacy.cache and settings.consumer.lib.library==c.legacy.library)
    local audio=settings.consumer.lib.audio[side=='server'and'PlayNativeSound'or'PlayLocalNativeSound']
    assert(audio({name='PR109'})==true and c.legacy.trace[#c.legacy.trace].kind:find('audio%-'))
    for _,name in ipairs({'modules/lib.lua','modules/utils.lua','shared/locale.lua','modules/playerdata.lua'})do assert(c.loadEntry(name))end
    assert(c.target.qbx.string.trim(' PR ')=='PR'and c.target.GetPlate(20)=='ABC')
    assert(c.target.HasItem('hamburger')==true,'inventory search remains a PR delegate')
    if side=='server'then assert(settings.consumer.lib.core.getVehiclesByHash()==r.catalog.Resolve('GetVehiclesByHash')())
    else assert(c.target.QBX.PlayerData==r.catalog.Resolve('GetPlayerData')()and c.active()==2)end
    assert(#c.reads==0 and c.nativeCalls==0);local fn=c.target.qbx.string.trim
    c.stopPhysical();assert(c.provider.Close()and c.provider.Progress().complete and rawget(c.target,'ForgeQbxConsumerPorts')==nil)
    assert(not pcall(fn,'closed')and r.api.IsCurrent());r.finish()
end
print('PASS lot109 PR-supplied ports feed all four physical107 imports;borrowed library/cache,PR Search/audio,canonical Forge data,consumer-local ownership,no framework discovery or old QBX IO')
