local A=dofile('tests/kernel_automedic_harness.lua')
local n=0
local function case(label,fn,opt)A.case(label,fn,opt);n=n+1 end
for _,reason in ipairs({'model_failed','spawn_failed','unreachable','alignment_failed','npc_lost','animation_failed','untrusted'})do
    case('hospital reason '..reason,function(r)
        r.start();local token=r.approve();return r.api.recoverHospital(1,token,reason)
    end)
end
case('nearest/occupied/none',function(r)
    r.start();local a=r.approve(1);assert(r.api.recoverHospital(1,a,'unreachable'))
    assert(r.api.recoveries[1].bed.id=='near')
    local b=r.approve(2);assert(r.api.recoverHospital(2,b,'model_failed'));assert(r.api.recoveries[2].bed.id=='far')
    local c=r.approve(3);return r.api.recoverHospital(3,c,'npc_lost')
end)
case('separate buckets',function(r)
    r.start();local a=r.approve(1);assert(r.api.recoverHospital(1,a,'unreachable'))
    r.bucket=2;local b=r.approve(2);assert(r.api.recoverHospital(2,b,'unreachable'));assert(r.api.recoveries[2].bed.id=='near')
    return r.api.occupiedBeds
end)
case('prison isolates beds',function(r)
    r.start();r.jailed=true;local token=r.approve()
    local ok,e=r.api.recoverHospital(1,token,'unreachable');assert(not ok and e=='no_hospital_beds')
    assert(r.api.saveBed(0,A.bed('prison',10,true)));return r.api.recoverHospital(1,token,'unreachable')
end)
case('stale occupancy freed by character',function(r)
    r.start();local a=r.approve(1);assert(r.api.recoverHospital(1,a,'unreachable'))
    r.players[1].PlayerData.citizenid='NEW'
    local b=r.approve(2);assert(r.api.recoverHospital(2,b,'unreachable'));assert(r.api.recoveries[2].bed.id=='near');return true
end)
case('release token guard',function(r)
    r.start();local a=r.approve();assert(r.api.recoverHospital(1,a,'unreachable'))
    assert(not r.api.releaseHospital(1,'fake')and r.api.recoveries[1]);assert(r.api.releaseHospital(1,a));return r.api.releaseHospital(1)
end)
case('disabled fallback',function(r)r.start();local token=r.approve();r.api.settings.hospitalFallback=false;return r.api.recoverHospital(1,token,'unreachable')end)
case('no ped cannot pick bed',function(r)r.start();local token=r.approve();r.pedMissing=true;return r.api.recoverHospital(1,token,'unreachable')end)
for _,result in ipairs({false,'nil','throw','stopped'})do
    case('inventory ack '..tostring(result),function(r)
        r.start();local token=r.approve(1,'gunshot');r.now=r.now+10
        if result=='nil'then r.clearResult=table.pack(nil)
        elseif result=='throw'then r.clearError=true
        elseif result=='stopped'then r.inventoryState='stopped'
        else r.clearResult=table.pack(result)end
        return r.api.completeTreatment(1,token)
    end)
end
case('hospital failed clear refunds releases bed',function(r)
    r.start();local token=r.approve(1,'gunshot');r.clearResult=table.pack(false)
    local before=r.balances.cash;local ok,e=r.api.recoverHospital(1,token,'unreachable')
    assert(not ok and e=='inventory_clear_failed'and r.balances.cash==before and r.api.recoveries[1]==nil)
    return true
end)
case('refund false ignored',function(r)
    r.start();local token=r.approve(1,'gunshot');r.now=r.now+10;r.clearResult=table.pack(false);r.addResult=false
    local ok,e=r.api.completeTreatment(1,token);assert(not ok and e=='inventory_clear_failed'and r.balances.cash==100)
    return true
end)
case('refund throws leaves processing',function(r)
    r.start();local token=r.approve(1,'gunshot');r.now=r.now+10;r.clearResult=table.pack(false);r.refundError=true
    return r.api.completeTreatment(1,token)
end)
case('metadata exception after charged/inventory-cleared',function(r)
    r.start();local token=r.approve(1,'gunshot');r.now=r.now+10;r.metadataError=true
    local ok=pcall(r.api.completeTreatment,1,token);assert(not ok and r.api.treatments[1].processing and r.balances.cash==100)
    return true
end)
case('price and loss settings evaluated at completion',function(r)
    r.start();local token=r.approve(1,'collapse');r.now=r.now+10
    r.api.settings.treatmentPrice=150;r.api.settings.loseInventory.collapse=true
    return r.api.completeTreatment(1,token)
end)
case('settings save deletes occupied definition but reservation remains',function(r)
    r.start();local token=r.approve();assert(r.api.recoverHospital(1,token,'unreachable'))
    assert(r.api.deleteBed(0,'near'));assert(r.api.occupiedBeds['0:near']);return r.api.recoveries[1]
end)
case('provider yield allows logout/new session before revive',function(r)
    r.start();local token=r.approve(1,'gunshot');r.now=r.now+10
    r.clearHook=function()r.event('QBCore:Server:OnPlayerUnload',1);r.players[1].PlayerData.citizenid='NEW'end
    assert(r.api.completeTreatment(1,token));assert(not r.players[1].PlayerData.metadata.isdead)
    return true
end)
print('PASS AutoMedic hospital/inventory differentials '..n)

