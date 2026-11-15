local V=dofile('tests/kernel_vehicle_integration_harness.lua');local H=V.H
local r=V.new();r.mount();assert(#r.calls==0 and #r.sql==0 and #r.messages==0,'vehicle constructor inert')
assert(r.api.Open());assert(#r.calls==0 and #r.sql==0,'Open never buys key')
local out=r.api.Integration.buyOriginalKey(2,' ab 12 ',90)
assert(out.success and out.barcode=='KEY1'and #r.sql==1 and #r.items==1)
local row=r.cache.KEY1;assert(row.plate=='AB12'and row.key_type=='temporary'and row.expires_at==1090,'installed duration and sanitization preserved')
assert(r.calls[1].args.n==3 and r.calls[1].args[2]==' ab 12 ','raw arguments are not normalized by bridge')
r.itemResult=false;assert(r.api.Integration.buyOriginalKey(2,'FAIL').success and #r.items==2,'installed original-key false success remains explicit')
r.insertResult=false;local failed=r.api.Integration.buyOriginalKey(2,'DB');assert(not failed.success and failed.reason=='db_error'and #r.items==2)
r.identifier=function()return nil end;assert(r.api.Pr.buyOriginalKey(2,'NO').reason=='player_not_found')
r.identifier=function(src)return'C'..src end;assert(r.api.Pr.buyOriginalKey(2,nil).reason=='invalid_plate')
-- Compare the actual installed PR delegates, including zero tuples and nil holes.
local count=0
for _,name in ipairs({'GiveTempKeys','RemoveTempKeys','GiveKeyItem','RemoveKeyItem','HaveTemporaryKey','HavePermanentKey'})do
    for _,mode in ipairs({'normal','false','tuple','error'})do
        r.modes={};local value=mode=='false'and table.pack(false)or mode=='tuple'and table.pack(nil,'reason',nil)
        local raw=({GiveTempKeys='GiveTempKey',RemoveTempKeys='RemoveTempKey',GiveKeyItem='CreateTempKeyItem',
            RemoveKeyItem='RemoveTempKeyItem',HaveTemporaryKey='HasVehicleAccess',HavePermanentKey='HasVehicleAccess'})[name]
        if mode~='normal'then r.modes[raw]=mode=='error'and'error'or value end
        local expected=table.pack(pcall(r.public[name],2,'TEST',501))
        local actual=table.pack(pcall(r.api.VehicleKey[name],2,'TEST',501))
        if mode=='error'then assert(expected[1]==false and actual[1]==false)else H.same(actual,expected,'installed PR key tuples')end
        count=count+1
    end
end
assert(count==24);r.modes={};r.api.VehicleKey.GiveKeyItem(2,'TEST',501)
local call=r.calls[#r.calls];assert(call.name=='CreateTempKeyItem'and call.args.n==3 and call.args[3]=='carkey_temp','public key item ignores netId')
assert(table.pack(r.api.Pr.giveTempKey(2,'TEST')).n==0,'raw logical key zero tuple')
r.api.Pr.createTempKeyItem(2,'TEST');assert(r.calls[#r.calls].args.n==2,'raw config item has no injected third argument')
r.insertResult=32;r.itemResult=true
local S=dofile('tests/kernel_support_harness.lua');local config=S.config(true,'server')
config.ports.getResourceState=r.api.Integration.resourceState;config.ports.vehicleKeys.pr=r.api.Pr
config.api=H.load('kernel/config/server.lua',H.environment())(config.ports)
assert(config.api.giveVehicleKeys(2,' TEST ',101)=='TEMP','config06 temporary item through PR raw')
assert(config.api.giveVehicleKeys(2,' TEST ',101,'permanent').success,'config06 permanent through PR raw')
config.api.setVehicleLock(101,'lock');call=r.calls[#r.calls];assert(call.name=='SetLockState'and call.args[2]==2)
local g=V.garage();r.sendHook=function(name,target,plate,netId)assert(target==-1);g.receive(plate,netId)end
assert(table.pack(r.api.Integration.registerExistingPersistentVehicle(-1,'TEST',501)).n==0,'garage fire-and-forget has no ack')
assert(g.spawnedVehs[501]==101 and g.spawnedPlates.TEST==101 and g.cache['persistent:veh:TEST']==101 and g.state.pr_carkeys_skipRevPed)
g.exists=false;r.api.Integration.registerExistingPersistentVehicle(-1,'MISSING',501)
assert(g.spawnedPlates.MISSING==nil,'installed garage silently misses entity without retry')
local missing=V.new();missing.mount();missing.states.pr_carkeys='stopped';assert(not missing.api.Open()and #missing.calls==0)
local wrong=V.new();wrong.mount();wrong.selected='default';assert(not wrong.api.Open())
local starting=V.new();starting.mount();starting.states.pr_carkeys='starting';starting.states['forge-garage']='stopped'
assert(starting.api.Open(),'starting keys and absent optional garage preserve consumer policy')
print('PASS lot65 provider:24 installed PR key comparisons;whole installed shop success/failure/duration/ignored item refusal;config06 raw;installed garage handler present/absent no ack;all effects virtual')
