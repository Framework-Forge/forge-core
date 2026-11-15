local T=dofile('tests/kernel_qbx_delivery_harness.lua');local H=T.H
for _,side in ipairs({'server','client'})do
    local r=T.new(side);local api=r.package;assert(#r.reads==0)
    local info=api.Describe();assert(#info.files==14 and not info.manifestApplied and not info.operationalReady)
    assert(api.Prepare());local relay=api.AttachRelay(r.relayPorts);assert(relay.Prepare()and relay.Install())
    assert(r.published.GetJobs()==r.catalog.Resolve('GetJobs')(),'compiled relay uses same canonical groups')
    if side=='client'then r.deliver.consumerPorts.getPlayerData=function()return r.published.GetPlayerData()end end
    local consumer=api.AttachConsumer('script104',r.deliver.deliveryPorts);assert(consumer.Prepare()and consumer.Install())
    local list=consumer.Describe().files;assert(#list==13)
    for _,file in ipairs(list)do local found=false;for _,asset in ipairs(info.files)do if file==asset then found=true end end;assert(found)end
    for _,entry in ipairs({'modules.lib','modules.utils','shared.locale','modules.playerdata'})do assert(consumer.ExecuteEntry(entry))end
    if side=='client'then assert(r.deliver.target.QBX.PlayerData==r.fixture.state.PlayerData and r.deliver.active()==2)
    else assert(r.deliver.target.QBX==r.deliver.oldQBX and r.deliver.active()==0)end
    assert(consumer.Progress().phase=='installed');assert(not pcall(api.AttachConsumer,'script104',r.deliver.deliveryPorts))
    assert(not pcall(api.AttachRelay,r.relayPorts))
    assert(api.Close());assert(not pcall(r.published.GetJobs));assert(consumer.Progress().complete and r.api.IsCurrent())
    assert(not pcall(consumer.ExecuteEntry,'modules.lib'));assert(r.gateway.IsCurrent(),'package must not close Forge gateway');r.finish()
end
print('PASS lot104 delivered relay source compiled in separate environment,105/24 native exports,consumer79 exact13 files/four entries,same canonical client PlayerData,14 package files,owned closure preserves Forge;virtual IO/SQL/natives')
