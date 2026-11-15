local A=dofile('tests/kernel_automedic_harness.lua')
local n=0
local function case(label,fn,opt)A.case(label,fn,opt);n=n+1 end
case('native<=100 confirms death',function(r)
    r.start();r.players[1].PlayerData.metadata={};return r.api.getStatus(1)
end)
case('alive rejects report/request',function(r)
    r.start();r.health=200;r.players[1].PlayerData.metadata={}
    return table.pack(r.api.reportDeath(1,{})),table.pack(r.api.requestTreatment(1))
end)
case('no player rejects report/request',function(r)r.start();r.players[1]=nil;return r.api.reportDeath(1,{}),r.api.requestTreatment(1)end)
case('disabled refuses request',function(r)r.start();r.api.settings.enabled=false;return r.api.requestTreatment(1)end)
case('passive session unload refuses request',function(r)r.start();r.event('pr_bridge:server:OnPlayerUnloaded',1);return r.api.requestTreatment(1)end)
for _,offset in ipairs({-31,-30,0,30,31})do
    case('reported timestamp '..offset,function(r)
        r.start();assert(r.api.reportDeath(1,{timestamp=r.now+offset,deathCause='123'}));return r.api.getStatus(1)
    end)
end
case('timestamp cache and cooldown',function(r)
    r.start();r.players[1].PlayerData.metadata.deathTimeStamp=r.now-20;r.api.settings.cooldown=100
    local status=r.api.getStatus(1);assert(status.remaining==80)
    return r.api.requestTreatment(1)
end)
for _,category in ipairs({'gunshot','collapse','other','bad'})do
    case('category '..category,function(r)r.start();return r.api.requestTreatment(1,category)end)
end
case('bleeding nested changes classification',function(r)
    r.start();r.players[1].PlayerData.metadata.injuries={body={leg={bleeding=2}}}
    local _,p=r.approve(1,'other');assert(p.category=='collapse'and not p.loseInventory);return p
end)
case('client can request collapse category',function(r)
    r.start();local _,p=r.approve(1,'collapse');assert(p.category=='collapse'and not p.loseInventory);return p
end)
case('active and expiry boundary',function(r)
    r.start();r.approve();local ok,e=r.api.requestTreatment(1);assert(not ok and e=='already_active')
    r.now=r.now+115;ok,e=r.api.requestTreatment(1);assert(not ok and e=='already_active')
    r.now=r.now+1;return r.api.requestTreatment(1)
end)
case('minimum treatment duration',function(r)
    r.start();local token=r.approve();local ok,e=r.api.completeTreatment(1,token);assert(not ok and e=='treatment_too_fast')
    r.now=r.now+8;assert(r.api.completeTreatment(1,token));return r.balances
end)
case('cash payment/full bank fallback',function(r)
    r.start();r.balances.cash=30;r.balances.bank=50
    local token=r.approve();r.now=r.now+10;local ok,p=r.api.completeTreatment(1,token)
    assert(ok and p.paymentAccount=='bank'and r.balances.bank==-50 and r.balances.cash==30);return p
end)
case('cash removal false bank fallback',function(r)
    r.start();r.removeResults.cash=false;local token=r.approve();r.now=r.now+10
    return r.api.completeTreatment(1,token)
end)
case('payment false clears processing/retry',function(r)
    r.start();r.removeResults.cash=false;r.removeResults.bank=false;local token=r.approve();r.now=r.now+10
    local ok,e=r.api.completeTreatment(1,token);assert(not ok and e=='payment_failed'and not r.api.treatments[1].processing)
    r.removeResults.bank=true;return r.api.completeTreatment(1,token)
end)
case('missing money integration',function(r)
    r.start();local token=r.approve();r.now=r.now+10;return r.api.completeTreatment(1,token)
end,function(r)r.moneyMissing=true end)
case('free no money integration',function(r)
    r.start();r.api.settings.treatmentPrice=0;local token=r.approve();r.now=r.now+10
    return r.api.completeTreatment(1,token)
end,function(r)r.moneyMissing=true end)
case('needs only below minimum, false ignored',function(r)
    r.start();r.statusOverride={hunger=10,thirst=8};r.setStatusResult=false;r.setMetadataResult=false
    local token=r.approve();r.now=r.now+10;return r.api.completeTreatment(1,token)
end)
case('token replay/character switch',function(r)
    r.start();local token=r.approve();r.now=r.now+10
    local ok,e=r.api.completeTreatment(1,'fake');assert(not ok and e=='invalid_treatment')
    r.players[1].PlayerData.citizenid='REUSED';return r.api.completeTreatment(1,token)
end)
case('payment exception leaves processing',function(r)
    r.start();local token=r.approve();r.now=r.now+10;r.moneyError=true
    local ok=pcall(r.api.completeTreatment,1,token);assert(not ok and r.api.treatments[1].processing)
    r.moneyError=false;return r.api.completeTreatment(1,token)
end)
case('cancel wrong token and processing',function(r)
    r.start();local token=r.approve();assert(r.api.cancelTreatment(1,'fake')and r.api.treatments[1])
    r.api.treatments[1].processing=true;local ok,e=r.api.cancelTreatment(1,token);assert(not ok and e=='already_active')
    r.api.treatments[1].processing=false;assert(r.api.cancelTreatment(1,token));return r.api.treatments[1]
end)
case('same-second token reused after cancellation',function(r)
    r.start();local a=r.approve();assert(r.api.cancelTreatment(1,a));local b=r.approve();assert(a==b);return b
end)
case('source changes while payment running not rechecked',function(r)
    r.start();local token=r.approve();r.now=r.now+10
    r.moneyHook=function()r.players[1].PlayerData.citizenid='NEW_PLAYER'end
    assert(r.api.completeTreatment(1,token));assert(r.players[1].PlayerData.citizenid=='NEW_PLAYER'and not r.players[1].PlayerData.metadata.isdead)
    return true
end)
print('PASS AutoMedic treatment differentials '..n)

