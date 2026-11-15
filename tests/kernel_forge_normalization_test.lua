local T=dofile('tests/kernel_forge_normalization_harness.lua');local H,P=T.H,T.P;local count=0
for _,side in ipairs({'server','client'})do
    local a,b=T.new(true,side),T.new(false,side)
    if side=='client'then a.source.cached=T.C.data();b.source.cached=T.C.data()end
    local before={};for name in pairs(a.source.framework)do before[name]=true end
    local calls=side=='server'and{{'GetPlayerName',1},{'GetPlayerIdentifier',1},{'GetPlayerFromId',1},{'GetPlayerDob',1},{'GetPlayerGender',1},
        {'GetPhoneProfile','1'},{'GetPlayerMetadata',1,'hunger'},{'GetPlayerAccountBalance',1,'cash'},{'GetAccountBalance',1,'money'},
        {'GetFrameworkJobs'},{'GetFrameworkGangs'},{'GetAllPlayers'},{'GetJobCount','police'},
        {'GetVehiclesByHash'},{'GetVehicleData','car'},{'GetVehicleData',7},{'GetVehicleData',false},
        {'SetVehiclePersistence',10,true},{'SetVehiclePersistence',10,false},{'SetVehiclePersistence',0,true},
        {'AddItem',1,'item',2},{'GetItemCount',1,'item'},{'GetItemLabel','item'},{'GetJobAccountBalance','police'}}or
        {{'GetPlayerIdentifier'},{'GetPlayerName'},{'GetPlayerGender'},{'GetPlayerDob'},{'IsPlayerDead'},{'GetPlayerGroup'},
        {'getPlayerJob','name'},{'GetAccountBalance','cash'},{'GetVehiclesByHash'},{'GetVehicleData','car'},
        {'Notify','test','error',1000},{'ShowTextUI','text'},{'HideTextUI'},{'GetItemCount','item'}}
    for _,entry in ipairs(calls)do
        local name=entry[1];local aa=table.pack(a.framework[name](table.unpack(entry,2)));local bb=table.pack(b.framework[name](table.unpack(entry,2)))
        H.same(P.snapshot(aa),P.snapshot(bb),side..':'..name);count=count+1
    end
    H.same(a.trace,b.trace,side..':ports');H.same(a.source.trace,b.source.trace,side..':adapter ports')
    for name in pairs(a.source.framework)do assert(before[name],'normalization must not mutate source83')end
    for name in pairs(b.framework)do assert(a.framework[name]~=nil,'missing normalized method '..name)end
    assert(#b.deferred==3,'only final compat layers intentionally deferred in fixture')
    if side=='server'then assert(a.framework.GetPlayerIdentifier==a.framework.GetIdentifier and a.framework.GetAccountBalance==a.framework.getPlayerMoney)end
    a.api.Close();assert(a.api.Progress().complete and a.framework.GetResourceName()==nil)
end
local a,b=T.new(true,'server','framework-bank'),T.new(false,'server','framework-bank')
assert(a.framework.GetJobAccountBalance==nil and b.framework.GetJobAccountBalance==nil,'framework banking cycle avoided')
print('PASS lot84 normalization:'..count..' whole installed common/QBX body comparisons,alias identity/priority,phone/catalog/persistence/PR inventory-bank/UI,source not mutated;three final compat calls explicitly deferred;virtual only')
