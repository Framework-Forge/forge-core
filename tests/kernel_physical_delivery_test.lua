local T=dofile('tests/kernel_physical_delivery_harness.lua')
local entries={'modules/lib.lua','modules/utils.lua','modules/playerdata.lua','shared/locale.lua'}
local manifest=T.read('fxmanifest.lua');assert(manifest:find("provide 'qb%-core'")and manifest:find("version '0.1.0'",1,true))
assert(not manifest:find('server/main.lua',1,true)and not manifest:find('client/character',1,true))
for _,side in ipairs({'server','client'})do
    local r=T.new(side);local count=r.active and r.active()
    r.physicalPublishHook=function(_,fn)assert(not pcall(fn),'no native wrapper opens before joint commit')end
    r.loadPhysical();local n=0;for _ in pairs(r.published)do n=n+1 end
    assert(n==(side=='server'and 106 or 24)and #r.physicalEvents==1)
    if side=='server'then
        assert(r.active()==count);local core=r.lookup('GetCoreObject')()
        assert(core.Players==r.graph.PlayerCore.State.Players)
        assert(r.published.SetField('physical107',{same=true})and r.graph.PlayerCore.State.physical107.same)
    end
    local a,b=r.consumer(),r.consumer()
    for _,c in ipairs({a,b})do
        for _,entry in ipairs(entries)do assert(c.loadEntry(entry)==true)end
        local scope=assert(c.target[T.key]);assert(scope.Progress().phase=='installed'and #c.physicalEvents==1)
        assert(c.loadEntry('modules/lib.lua')and c.target.qbx.string.trim(' physical ')=='physical')
        if side=='client'then assert(c.target.QBX.PlayerData==r.published.GetPlayerData()and c.active()==2)
        else assert(c.target.QBX==c.oldQBX and c.active()==0)end
        assert(#c.reads==0 and c.nativeCalls==0,'no old QBX loader or provider fallback')
        for _,path in ipairs(c.physicalReads)do assert(path=='compat/consumer.lua'or path=='compat/entry.lua'or path:match('^kernel/'))end
    end
    assert(a.target.qbx~=b.target.qbx);local aScope=a.target[T.key];a.stopPhysical()
    assert(aScope.Progress().complete and rawget(a.target,T.key)==nil and a.target.QBX==a.oldQBX and a.target.qbx.foreign)
    assert(b.target.qbx.string.trim(' alive ')=='alive'and r.api.IsCurrent())
    local retained=r.published.GetPlayerData or r.published.GetPlayers;r.stopPhysical();assert(not pcall(retained))
    assert(r.api.IsCurrent(),'shim stop must preserve Forge');b.stopPhysical();r.finish()
end
local disabled=T.new('server',false);disabled.loadPhysical();assert(disabled.published.SetField==nil);disabled.finish()
print('PASS lot107 physical candidate:105/24+optional SetField,joint commit,one shim stop,all four public imports,local sources,consumer-local PlayerData and owned cleanup;server/client virtual only')
