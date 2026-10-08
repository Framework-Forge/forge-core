-- Actual service; mocked QBX, native I/O and players. No production files.
local H=dofile('tests/cache_harness.lua')
local r=H.new(true);local e=r.env
e.ForgeCore.t=function(key) return key end
e.os={time=function() return math.floor(r.now/1000) end}
e.DoesEntityExist=function() return true end
e.GetEntityHealth=function() return 100 end
local chargeCount,paid,cleared=0,true,0
e.pr_lib.framework.getPlayerMoney=function() return 10000 end
e.pr_lib.framework.removePlayerMoney=function() chargeCount=chargeCount+1;return paid end
e.pr_lib.framework.addPlayerMoney=function() return true end
e.exports.qbx_core={
    GetPlayer=function(_,src) return r.players[src] end,
    GetStatus=function() return 100 end,SetStatus=function() end,
    SetMetadata=function(_,src,key,value)
        local meta=r.players[src].PlayerData.metadata;local previous=meta[key];meta[key]=value
        r.fire('qbx_core:server:onSetMetaData',nil,key,previous,value,src)
    end,
}
e.exports.ox_inventory={ClearInventory=function() cleared=cleared+1;return true end}
local jailed=false
e.ForgeCore.PrisonService={canChangeJobs=function() return not jailed end}
for src=1,3 do r.players[src]={PlayerData={citizenid='C'..src,metadata={isdead=true}}} end
r.positions[1]={x=1,y=0,z=0};r.positions[2]={x=1,y=0,z=0};r.positions[3]={x=1,y=0,z=0}
r.load('shared/automedic.lua');r.load('server/automedic/service.lua')
local S=e.ForgeCore.AutoMedicService;S.start()
local settings=S.getSettings();settings.cooldown=0;settings.treatmentPrice=100
assert(S.save(0,settings))
local function bed(id,x,prison)
    return {id=id,label=id,model='v_med_bed1',coords={x=x,y=0,z=1},heading=0,
        exit={x=x,y=1,z=0},exitHeading=90,prison=prison}
end
assert(S.saveBed(0,bed('near',0)));assert(S.saveBed(0,bed('far',50)))
e.IsPlayerAceAllowed=function() return false end
assert(not S.saveBed(1,bed('unauthorized',5)));e.IsPlayerAceAllowed=function() return true end
local invalid=bed('bad',0);invalid.coords.x=0/0;assert(not S.saveBed(0,invalid))
invalid=bed('bad',0);invalid.model='untrusted';assert(not S.saveBed(0,invalid))
local old=S.settings;e.SaveResourceFile=function() return 0 end
assert(not S.saveBed(0,bed('rejected',10)));assert(S.settings==old and #S.settings.beds==2)
e.SaveResourceFile=function() return 1 end
local ok,approval=S.requestTreatment(1,'collapse');assert(ok)
local token=approval.token
assert(not S.recoverHospital(1,'forged','unreachable'));assert(chargeCount==0)
assert(S.recoverHospital(1,token,'unreachable'))
assert(chargeCount==1 and cleared==0)
assert(S.recoveries[1].bed.id=='near')
local event=r.out[#r.out];assert(event.name==e.PR.AutoMedic.Events.revive and event.args[1].bed.id=='near')
assert(not S.recoverHospital(1,token,'unreachable'));assert(chargeCount==1,'duplicate must not charge twice')
ok,approval=S.requestTreatment(2,'collapse');assert(ok)
assert(S.recoverHospital(2,approval.token,'model_failed'));assert(S.recoveries[2].bed.id=='far')
ok,approval=S.requestTreatment(3,'collapse');assert(ok)
local before=chargeCount;local success,reason=S.recoverHospital(3,approval.token,'unreachable')
assert(not success and reason=='no_hospital_beds' and chargeCount==before)
assert(not S.releaseHospital(1,'forged'));assert(S.recoveries[1])
assert(S.releaseHospital(1,token));assert(not S.recoveries[1])
paid=false;success,reason=S.recoverHospital(3,approval.token,'alignment_failed')
assert(not success and reason=='payment_failed' and not S.recoveries[3])
paid=true;assert(S.recoverHospital(3,approval.token,'animation_failed'))
r.fire('playerDropped',2);assert(not S.recoveries[2] and not S.occupiedBeds['0:far'])
S.releaseHospital(3)
jailed=true;r.players[1].PlayerData.metadata.isdead=true
assert(S.reportDeath(1,{timestamp=e.os.time()}))
ok,approval=S.requestTreatment(1,'collapse');assert(ok)
success,reason=S.recoverHospital(1,approval.token,'unreachable')
assert(not success and reason=='no_hospital_beds','a prisoner must not escape to a public hospital')
assert(S.saveBed(0,bed('prison',10,true)))
assert(S.recoverHospital(1,approval.token,'unreachable'));assert(S.recoveries[1].bed.id=='prison')
S.releaseHospital(1);jailed=false;r.players[1].PlayerData.metadata.isdead=true
assert(S.reportDeath(1,{timestamp=e.os.time()}));ok,approval=S.requestTreatment(1,'collapse');assert(ok)
r.players[1].PlayerData.citizenid='REUSED'
assert(not S.recoverHospital(1,approval.token,'unreachable'),'token must bind to the original character')
S.cancelTreatment(1,approval.token)
ok,approval=S.requestTreatment(1,'gunshot');assert(ok)
r.advance(10000)
local chargedBefore=chargeCount
assert(S.completeTreatment(1,approval.token),'ordinary on-site treatment must still work')
assert(chargeCount==chargedBefore+1 and cleared==1 and not S.recoveries[1])
assert(r.out[#r.out].args[1]==nil,'on-site treatment must not include a hospital destination')
assert(not S.completeTreatment(1,approval.token))
print('PASS AutoMedic server: saved beds, nearest/occupied bed, prison isolation, payment rejection, replay/character guards, drop cleanup')
