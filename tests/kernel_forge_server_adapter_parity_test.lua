local T=dofile('tests/kernel_forge_server_adapter_harness.lua');local H,P=T.H,T.P;local count=0;local covered={}
local callback=function()end
local calls={{'RegisterCallback','x',callback},{'GetWeapon',1,'item'},{'GetIdentifier',1},{'getPlayerFromId','1'},
    {'GetPlayerFromIdentifier','C81'},{'GetOfflinePlayer','C81'},{'getPlayerName',1},{'getPlayerHeight',1},{'GetCoords',1,true},{'GetCoords',1,false},
    {'getPlayerDOB',1},{'getPlayerSex',1},{'getPlayerMetadata',1,'hunger'},{'setPlayerMetadata',1,'hunger',75},
    {'GetPlayerStatus','1','hunger'},{'SetPlayerStatus','1','hunger',75},{'AddPlayerStatus','1','hunger',5},
    {'getPlayerStatus','1','hunger'},{'setPlayerStatus',1,'hunger',1},{'addPlayerStatus',1,'hunger',2},
    {'addSocietyBalance','police',10},{'removeSocietyBalance','police',5},{'RegisterUsableItem','item',callback},
    {'GetPlayer',1},{'GetPlayerData',1},{'HasPermission',1,'admin'},{'getItemByName',1,'item'},
    {'CreateWeaponData',1,{weapon='gun'},{label='Gun'}},{'RemoveWeapon',1,{weapon='gun'}},{'AddWeapon',1,{weapon='gun'}},
    {'getPlayerGroup',1},{'getPlayerJob',1,'label'},{'getPlayerJob',1,'name'},{'getPlayerJob',1,'grade'},{'getPlayerJob',1,'gradeLabel'},
    {'GetPlayerJob',1},{'SetPlayerJob',1,'police','2'},{'SetPlayerDuty',1,1},{'AddPlayerToJob','C81','police','2'},
    {'RemovePlayerFromJob','C81','police'},{'SetPlayerPrimaryJob','C81','police'},{'AddPlayerToGang','C81','ballas','1'},
    {'RemovePlayerFromGang','C81','ballas'},{'SetPlayerPrimaryGang','C81','ballas'},{'PlayerHasJob',1,'POLICE',2},
    {'PlayerHasJob',1,'police',3},{'getPlayerMoney',1,'money'},{'getPlayerMoney',1,'black_money'},
    {'addPlayerMoney',1,'money',5},{'removePlayerMoney',1,'black_money',5},
    {'InventoryManagement',1,{type='valid'}},{'InventoryManagement',1,{type='label',item='x'}},
    {'InventoryManagement',1,{type='count',item='x'}},{'InventoryManagement',1,{type='weight'}},
    {'InventoryManagement',1,{type='add',item='x',amount=1}},{'InventoryManagement',1,{type='remove',item='x',amount=1}},
    {'GetOwnedVehicleOwner','P81'},{'GetOwnedVehicleData','P81'},{'DeleteOwnedVehicle','P81'},
    {'InsertOwnedVehicle','ignored',1,'vehicle'},{'GetPlayerNameByIdentifier','C81'},{'takeMoney',1,20,'r'},
    {'takeMoney',1,80,'r'},{'takeMoney',1,200,'r'},{'addMoney',1,5,'bank','r'}}
for _,mode in ipairs({'normal','inventory','missing','nil','false','error','absent'})do
    for _,entry in ipairs(calls)do
        local a,b=T.new(true,mode),T.new(false,mode);local name=entry[1]
        local aa=table.pack(pcall(a.framework[name],table.unpack(entry,2)));local bb=table.pack(pcall(b.framework[name],table.unpack(entry,2)))
        if not aa[1]and not bb[1]then aa[2]=tostring(aa[2]):gsub('^.-:%d+: ','');bb[2]=tostring(bb[2]):gsub('^.-:%d+: ','')end
        H.same(P.snapshot(aa),P.snapshot(bb),mode..':'..name);H.same(a.trace,b.trace,mode..':'..name..':ports')
        covered[name]=true;count=count+1
    end
end
local a,b=T.new(true),T.new(false)
H.same(table.pack(a.framework.getPlayerSourceFromPlayer(a.player)),table.pack(b.framework.getPlayerSourceFromPlayer(b.player)))
covered.getPlayerSourceFromPlayer=true;count=count+1
local methods=0;for name in pairs(b.framework)do assert(covered[name],'untested installed adapter method '..name);methods=methods+1 end
for name in pairs(a.framework)do assert(b.framework[name],'unexpected adapter method '..name)end
assert(a.framework.getPlayerStatus==a.framework.GetPlayerStatus and a.framework.setPlayerStatus==a.framework.SetPlayerStatus)
print('PASS lot81 server:'..count..' whole installed adapter comparisons/'..methods..' methods including aliases,all port traces/tuples/absence/errors,PR inventory/bank/DB/native priority and legacy takeMoney refusal;virtual only')
