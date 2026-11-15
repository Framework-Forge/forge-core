local V=dofile('tests/kernel_vehicle_integration_harness.lua');local r=V.context();local f=r.fixture
local before=f.snapshot();r.prepareVehicles();V.H.same(f.snapshot(),before,'context65 construction inert')
assert(#r.keys.calls==0 and #r.keys.sql==0 and #r.keys.messages==0)
assert(r.vehicleInstall());assert(#r.keys.calls==0,'Install never buys keys')
r.emit('onResourceStart','forge-core');r.begin();r.resume();assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]))
local pc=r.graph.PlayerCore;assert(pc==f.base.PlayerCore and r.graph.Parts.Helpers==f.base.Helpers)
pc.Players.CheckPlayerData(2,{citizenid='VEHICLE',license='license:test',userId=101})
r.keys.identifier=function(src)local player=pc.Lookup.GetPlayer(src);return player and player.PlayerData.citizenid end
local v=f.fixtures.Vehicles;local g=V.garage();local order={}
r.keys.sqlHook=function()order[#order+1]='key'end
r.keys.sendHook=function(name,target,plate,netId)
    assert(name=='forge_garage:client:registerExistingPersistentVehicle'and target==-1)
    local trace=f.helperFixture.trace;local persisted=false
    for _,e in ipairs(trace)do if e.kind=='state'and e.args[2]=='persisted'and e.args[3]==true then persisted=true end end
    assert(persisted,'local persistence precedes external garage delivery')
    order[#order+1]='garage';g.receive(plate,netId)
end
local function call(key,source,...)
    r.wire.playerSource=source
    return r.wire.client.api.native.await(f.config.Vehicles.Callbacks[key],10000,...)
end
local ok,data=call('adminCar',2,'sultan',501,{color1=2})
assert(ok and data.target==2 and data.plate=='TEST01',tostring(data))
assert(#r.keys.sql==1 and #r.keys.items==1 and r.keys.cache.KEY1.citizenid=='VEHICLE','admin ownership uses installed key shop via PR and canonical Player')
assert(order[1]=='key'and order[2]=='garage'and g.spawnedPlates.TEST01==101)
assert(#v.trace>0 and #r.keys.messages==1 and #r.keys.calls==1,'one original key and one garage delivery')
local temp=table.pack(call('spawn',2,'sultan','TEMP01',501));assert(temp[1]==true,'spawn accepts logical zero tuple and physical key item')
r.keys.modes.CreateTempKeyItem=table.pack(nil);local failed,why=call('spawn',2,'sultan','FAIL01',501)
assert(failed==false and why=='vehicle_key_item_failed'and r.keys.calls[#r.keys.calls].name=='RemoveTempKey','installed consumer revokes logical key after item failure')
r.keys.states['forge-garage']='stopped';r.keys.modes={};r.keys.sendHook=nil
assert(call('adminCar',2,'sultan',501,{})and #r.keys.messages==1,'optional unavailable garage is skipped')
r.keys.states.pr_carkeys='stopped';local bought=#r.keys.calls
local denied,reason=call('adminCar',2,'sultan',501,{})
assert(denied==false and reason=='vehicle_key_unavailable'and #r.keys.calls==bought,'missing key provider preserves ownership rollback path')
local deleted=false;for _,e in ipairs(v.trace)do if e.kind=='db-execute'and e.args[1]:find('DELETE FROM player_vehicles',1,true)then deleted=true end end
assert(deleted,'existing SQL rollback attempted virtually')
r.api.Stop();r.clock.advance(120000);r.api.Poll();assert(r.api.Progress().complete,'context65 drain includes64 and PR vehicles')
assert(r.api.Vehicles.Pr.buyOriginalKey(2,'LATE')==nil and #r.keys.calls==bought,'Stop revokes key mutations')
local fail=V.context();fail.prepareVehicles();fail.keys.selected='default';assert(not fail.vehicleInstall()and #fail.keys.calls==0)
local db=V.context();db.prepareVehicles();db.dbReady=false;assert(not db.vehicleInstall()and db.api.Progress().vehicles.complete)
local native=V.context();native.prepareVehicles();assert(native.vehicleInstall());native.begin();native.emit('onResourceStop','forge-core');native.resume()
native.clock.advance(120000);native.api.Poll();assert(native.api.Progress().phase=='closed'and native.api.Progress().vehicles.complete)
local stale=V.context();stale.prepareVehicles();assert(stale.vehicleInstall());stale.fixture.base.Helpers={}
assert(stale.api.Vehicles.Pr.giveTempKey(2,'STALE')==nil and #stale.keys.calls==0,'replaced Helpers refuses stale key mutation');stale.api.Stop()
print('PASS lot65 actual64/63/61/60/48:admin ownership original key/canonical Player/local persistence then garage;temporary failure cleanup;optional garage/unready keys;owned Stop/native/preflight/Helpers identity;virtual SQL and entities only')
