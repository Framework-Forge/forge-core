local C=dofile('tests/kernel_character_harness.lua')
local H,count=C.H,0
local function test(name,fn) C.compareSlots(name,fn);count=count+1 end
test('defaults/cache/copied public settings',function(r)
    local first=r.api.getSettings();assert(first.maxSlots==3 and first.requireItem and first.minimumAge==18)
    first.starterItems[1].amount=90;assert(r.api.getSettings().starterItems[1].amount==2)
    r.ready[1]();return r.api.getSettings()
end)
test('ready explicit idempotent',function(r) r.ready[1]();local before=#r.trace;r.ready[1]();assert(#r.trace==before) end)
test('bad encoded defaults',function(r) r.encoded='bad';return r.api.getSettings() end)
for _,value in ipairs({0,-5,1,10,100,'6','bad'}) do test('slot clamp '..tostring(value),function(r) r.settings({maxSlots=value,slotsPerItem=99,minimumAge=101});return r.api.getSettings() end) end
for _,value in ipairs({true,false,'true','1','yes','sim','false','0','no',3}) do test('booleans '..tostring(value),function(r)
    r.settings({requireItem=value,loseSlotOnDelete=value,minimumAgeEnabled=value,termsEnabled=value});return r.api.getSettings()
end) end
test('text trimming/limits',function(r)
    r.settings({firstNamePlaceholder=' '..string.rep('x',70)..' ',lastNamePlaceholder=' ',termsTitle=string.rep('t',150),termsText=string.rep('a',8100),termsVersion=string.rep('v',60)})
    local settings=r.api.getSettings();assert(#settings.firstNamePlaceholder==50 and #settings.termsText==8000)
    return settings
end)
test('starter item normalization',function(r)
    r.settings({starterItems={{name='water',amount='2.8'},{name='water',amount=8},{name='zero',amount=0},{name='huge',amount=math.huge},
        {name='nan',amount=0/0},{name='limit',amount=2000000},{name='bad',amount='bad'},false,{name=2,amount=1}}})
    local settings=r.api.getSettings();assert(#settings.starterItems==2 and settings.starterItems[1].amount==2 and settings.starterItems[2].amount==1000000)
    return settings
end)
for _,value in ipairs({1,0,false}) do test('save result '..tostring(value),function(r) r.updateResult=value;return r.api.saveSettings({maxSlots=8,requireItem=false}) end) end
test('save nil fails',function(r) r.updateResult=nil;return r.api.saveSettings({maxSlots=8}) end)
test('save cache update',function(r) r.api.getSettings();assert(r.api.saveSettings({maxSlots=4}));return r.api.getSettings() end)
test('state invalid player',function(r) return r.api.getState('bad') end)
test('state account missing',function(r) r.users={};return r.api.getState(1) end)
test('license fallback',function(r) r.users.L2=nil;return r.api.getState('1') end)
test('identifiers absent',function(r) r.noIdentifiers=true;return r.api.getState(1) end)
test('existing character entitlement migrated',function(r)
    r.characters={{citizenid='A',charinfo={cid=7}},{citizenid='B',charinfo={}}};r.blocked[7]={[1]=true,[7]=true}
    local value=r.api.getState(1);assert(value.displaySlots==7 and value.unlocked[1] and value.unlocked[7] and value.blocked[1])
    return value
end)
test('no item required',function(r) r.settings({maxSlots=4,requireItem=false});return r.api.getState(1) end)
for _,birthdate in ipairs({'2008-10-19','20/10/2008','2008-10-18','2000-02-29','2001-02-29','bad','2027-01-01','2000-13-01','2000-01-32',''}) do
    test('age '..birthdate,function(r) return r.api.validateAge(birthdate) end)
end
test('age disabled',function(r) r.settings({minimumAgeEnabled=false});return r.api.validateAge(nil) end)
local accepted={termsAccepted=true,birthdate='2000-01-01'}
for _,cid in ipairs({0,-1,1,2,4,1.5,'bad'}) do test('canCreate '..tostring(cid),function(r) return r.api.canCreate(1,cid,accepted) end) end
test('create purchased',function(r) r.purchased[7]={[2]=true};return r.api.canCreate(1,2,accepted) end)
test('create blocked first',function(r) r.blocked[7]={[1]=true};return r.api.canCreate(1,1,accepted) end)
test('create occupied',function(r) r.characters={{charinfo={cid=1}}};return r.api.canCreate(1,1,accepted) end)
test('create terms missing',function(r) return r.api.canCreate(1,1,{birthdate='2000-01-01'}) end)
test('create young',function(r) return r.api.canCreate(1,1,{termsAccepted=true,birthdate='2010-01-01'}) end)
test('create no terms/age/items',function(r) r.settings({termsEnabled=false,minimumAgeEnabled=false,requireItem=false});return r.api.canCreate(1,2,nil) end)
test('record terms',function(r) return r.api.recordTermsAcceptance(1) end)
test('terms disabled',function(r) r.settings({termsEnabled=false});return r.api.recordTermsAcceptance(1) end)
test('terms account absent',function(r) r.users={};return r.api.recordTermsAcceptance(1) end)
test('terms insert nil ignored',function(r) r.insertResult=nil;return r.api.recordTermsAcceptance(1) end)
for _,requested in ipairs({0,-1,1,2,100,'bad'}) do test('unlock '..tostring(requested),function(r) return r.api.unlock(1,requested) end) end
test('unlock excludes suspended',function(r) r.blocked[7]={[2]=true};return r.api.unlock(1,2) end)
test('unlock maximum',function(r) r.purchased[7]={[2]=true,[3]=true};return r.api.unlock(1,1) end)
test('unlock disabled',function(r) r.settings({requireItem=false});return r.api.unlock(1,1) end)
test('unlock transaction false releases lock',function(r) r.txResult=false;assert(not r.api.unlock(1,1));r.txResult=true;return r.api.unlock(1,1) end)
test('unlock transaction error releases lock',function(r) r.txError=true;assert(not r.api.unlock(1,1));r.txError=false;return r.api.unlock(1,1) end)
test('has slot available',function(r) return r.api.hasAvailableSlot(1) end)
test('has slot none',function(r) r.blocked[7]={[2]=true,[3]=true};return r.api.hasAvailableSlot(1) end)
test('has slot disabled',function(r) r.settings({requireItem=false});return r.api.hasAvailableSlot(1) end)
for _,slot in ipairs({0,1,2,4,1.5,'bad'}) do test('specific '..tostring(slot),function(r) return r.api.setSpecificSlot(1,slot,true) end) end
test('specific suspend entitlement unchanged',function(r)
    r.purchased[7]={[2]=true};local ok,value=r.api.setSpecificSlot(1,2,false);assert(value.blocked[2] and value.unlocked[2]);return ok,value
end)
test('specific lift without new grant',function(r) r.blocked[7]={[2]=true};local ok,value=r.api.setSpecificSlot(1,2,true);assert(not value.unlocked[2]);return ok,value end)
for _,logout in ipairs({false,true}) do test('suspend active '..tostring(logout),function(r)
    r.players[1]={PlayerData={charinfo={cid=1}}};r.logoutResult=logout;return r.api.setSpecificSlot(1,1,false)
end) end
test('specific transaction fails',function(r) r.txResult=false;return r.api.setSpecificSlot(1,2,false) end)
test('specific transaction error propagates',function(r) r.txError=true;return pcall(r.api.setSpecificSlot,1,2,false) and true or false end)
test('load allowed',function(r) return r.api.canLoad(1,{charinfo={cid=2}}) end)
test('load suspended',function(r) r.blocked[7]={[2]=true};return r.api.canLoad(1,{cid=2}) end)
test('load bad slot',function(r) return r.api.canLoad(1,{}) end)
test('load no account',function(r) r.users={};return r.api.canLoad(1,{cid=2}) end)
for _,value in ipairs({false,{},{userId=7,cid=1},{userId='7',charinfo={cid=2}}}) do test('deleted slot',function(r)
    r.purchased[7]={[2]=true};r.api.handleCharacterDeleted(value or nil);return r.purchased
end) end
test('deleted entitlement kept by config',function(r) r.settings({loseSlotOnDelete=false});r.api.handleCharacterDeleted({userId=7,cid=2}) end)
test('unlock same account busy across await',function(r)
    r.txHook=function() coroutine.yield('transaction pending') end
    local first=coroutine.create(function() return r.api.unlock(1,1) end)
    assert(coroutine.resume(first));local ok,reason=r.api.unlock(1,1);assert(not ok and reason=='operation_in_progress')
    assert(coroutine.resume(first));return r.api.hasAvailableSlot(1)
end)
test('pre-lock stale state inherited race',function(r)
    local suspendNext=false
    r.queryHook=function(_,_,rows) if suspendNext then suspendNext=false;coroutine.yield('stale read') end;return rows end
    r.txHook=function() coroutine.yield('tx') end
    local first=coroutine.create(function() return r.api.unlock(1,1) end);assert(coroutine.resume(first))
    suspendNext=true;local second=coroutine.create(function() return r.api.unlock(1,1) end);assert(coroutine.resume(second))
    assert(coroutine.resume(first));r.txHook=nil
    local ok,success,payload=coroutine.resume(second);assert(ok and success and payload.slots[1]==2,'Snapshot taken before lock is retained as in origin')
end)
local r=C.slots(true);local total=0;for _ in pairs(r.exports) do total=total+1 end;assert(total==6 and r.api==r.service)
print('PASS character slots: '..count..' differential cases; 11 methods/six exports, exact SQL/normalization/calendar/entitlements/suspension/terms, guarded transaction and inherited pre-lock race')
