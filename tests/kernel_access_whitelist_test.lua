local A=dofile('tests/kernel_access_harness.lua')
local n=0
local function case(name,fn,options)A.case(name,fn,options);n=n+1 end
case('check-missing-denied',function(r)local ok=r.w.check(1);assert(not ok and r.buckets[1]==1001)end)
case('check-disabled',function(r)r.m.seed(r.config.Whitelist.Storage.configFile,{enabled=false});assert(r.w.check(1)and r.buckets[1]==nil)end)
case('check-db-unavailable',function(r)r.ready=false;local ok,c=r.w.check(1);assert(not ok and c.pendingReason=='database_unavailable')end)
case('check-citizen',function(r)r.records.C1={citizen='C1'};assert(r.w.check(1)and r.buckets[1]==0)end)
for _,key in ipairs({'playerLicense','license','license2','primaryLicense','discord','fivem'})do
    case('shared-'..key,function(r)
        local values={playerLicense='player-license:1',license='license:1',license2='license2:1',primaryLicense='license2:1',discord='discord:1',fivem='fivem:1'}
        local row={citizen='OTHER'};row[key=='discord'and'discord'or key=='fivem'and'fivem'or'license']=values[key]
        r.records.OTHER=row;assert(r.w.check(1))
    end)
end
case('offline-record-join',function(r)r.offline.C1={citizenid='C1',license='other-license'};r.records.OTHER={citizen='OTHER',license='other-license'};assert(r.w.check(1))end)
case('player-wait-missing',function(r)
    r.players[1]=nil;local result;local co=coroutine.create(function()result=table.pack(r.w.check(1))end)
    assert(coroutine.resume(co));for i=1,40 do assert(coroutine.resume(co))end
    assert(result[2].pendingReason=='player_not_loaded')
end)
case('player-arrives-after-wait',function(r)
    local player=r.players[1];r.players[1]=nil;r.records.C1={citizen='C1'}
    local co=coroutine.create(function()assert(r.w.check(1))end);assert(coroutine.resume(co));r.players[1]=player;assert(coroutine.resume(co))
end)
case('numeric-citizen-means-source',function(r)r.players[2].PlayerData.citizenid='999'
    local ok,why=r.w.add(1,'999');assert(not ok and why=='invalid_player')end)
case('lookup-throws-protected',function(r)r.lookupError=true;local ok,e=r.w.add(1,2);assert(not ok and e=='invalid_player')end)
case('late-db-bucket-new-session',function(r)
    r.records.C1={citizen='C1'}
    r.scalarHook=function(sql)if sql:find('SELECT `citizen`',1,true)then r.players[1]={PlayerData={source=1,citizenid='NEW',metadata={}}};return table.pack('C1')end end
    assert(r.w.check(1)and r.players[1].PlayerData.citizenid=='NEW'and r.buckets[1]==0)
end)
case('identifier-native-fallback',function(r)r.library.identifiers=nil;r.records.C1={citizen='C1'};assert(r.w.check(1))end)
case('list-players',function(r)r.listRows={{citizenid='C1',charinfo=r.m.codec.encode({firstname='One',lastname='Test'}),whitelisted='C1'},
    {citizenid='OFF',name='Offline'}};local ok,c=r.w.listPlayers(1);assert(ok and c.whitelisted==1 and c.pending==1 and c.players[1].online)end)
case('list-db-missing',function(r)r.ready=false;local ok,e=r.w.listPlayers(1);assert(not ok and e=='database_unavailable')end)
case('list-query-fails-nil',function(r)r.queryHook=function()return table.pack(nil)end;local ok,c=r.w.listPlayers(1);assert(ok and #c.players==0)end)
case('add-online',function(r)local ok,c=r.w.add(1,2);assert(ok and c=='C2'and r.records.C2 and r.buckets[2]==0)end)
case('add-self-internal',function(r)r.manage=false;assert(r.w.add(1)and r.records.C1)end)
case('add-target-denied',function(r)r.manage=false;local ok,e=r.w.add(1,2);assert(not ok and e=='no_permission')end)
case('add-offline',function(r)r.offline.OFF={citizenid='OFF',license='license:off',name='Offline'};assert(r.w.add(0,'OFF')and r.records.OFF)end)
case('add-db-zero-ignored',function(r)r.noApply=true;r.updateResult=0;assert(r.w.add(1,2)and not r.records.C2 and r.buckets[2]==0)end)
case('add-rpc-false-ignored',function(r)r.rpcResult=false;assert(r.w.add(1,2))end)
case('add-rpc-error-after-write',function(r)r.rpcHook=function()error('fixture-rpc',0)end;assert(not pcall(r.w.add,1,2));assert(r.records.C2 and r.buckets[2]==0)end)
case('remove-online',function(r)r.records.C2={citizen='C2'};assert(r.w.remove(1,2)and not r.records.C2 and r.buckets[2]==1002)end)
case('remove-retains-shared-access',function(r)r.records.C1={citizen='C1'};r.records.OTHER={citizen='OTHER',license='license:1'}
    assert(r.w.remove(1,1));assert(r.w.check(1),'shared identifier survives citizen-only removal')end)
case('remove-sql-failure',function(r)r.records.C2={citizen='C2'};r.noApply=true;r.updateResult=false;assert(r.w.remove(1,2)and r.records.C2 and r.buckets[2]==1002)end)
case('ban-permanent',function(r)assert(r.w.ban(1,{source=2,reason='Fixture'}));assert(r.bans[1][6]==2147483647 and #r.drops==1)end)
case('ban-duration',function(r)assert(r.w.ban(0,{citizenid='C2',hours=1,days=1,months=1}));assert(r.bans[1][6]==r.time+3600+86400+2629743)end)
case('ban-sql-failure-still-drops',function(r)r.noApply=true;r.updateResult=0;assert(r.w.ban(1,{source=2})and #r.bans==0 and #r.drops==1)end)
case('ban-remove-denied-ignored',function(r)
    local calls=0;r.services.JobService.canManage=function()calls=calls+1;return calls==1 end
    assert(r.w.ban(1,{source=2})and #r.bans==1 and #r.drops==1)
end)
case('record-online',function(r)r.records.C2={citizen='C2',whitelisted_at=9,added_by='admin'};r.answers.C2={answers=r.m.codec.encode({email={value='fixture'}}),submitted_at=8}
    local ok,c=r.w.getPlayerRecord(1,2);assert(ok and c.whitelisted and c.answers.email.value=='fixture')end)
case('record-malformed-answer',function(r)r.answers.C2={answers='bad'};local ok,c=r.w.getPlayerRecord(1,2);assert(ok and next(c.answers)==nil)end)
case('record-invalid',function(r)local ok,e=r.w.getPlayerRecord(1,'missing');assert(not ok and e=='invalid_player')end)
print('PASS whitelist service differentials '..n)
