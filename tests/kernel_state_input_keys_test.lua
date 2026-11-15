local T=dofile('tests/kernel_state_input_harness.lua');local r=T.new();r.prepare();r.api.Install()
local central=r.graph.Central;local consumption=central.Parts.Consumption
local describedWorkers=#consumption.Threads;local startedWorkers=#r.central.world.threads
local interact=consumption.Callbacks['forge-core:client:inventory:useInteraction'];local fixture=r.central.consumption
local function props()local count=0;for id in pairs(fixture.entities)do if id>=1000 then count=count+1 end end;return count end
local data={enabled=true,duration=0,animation={props={{model='burger_prop',bone=5,pos={1,2,3}}}}}
assert(interact('burger',data).completed==true and props()==1,'same actual consumption persistent prop')
local trace=#fixture.trace;r.key('forge_core_cancel_persistent_item');assert(props()==0 and #fixture.trace>trace,'PR press invokes canonical persistent cancellation')
r.key('forge_core_cancel_persistent_item',false)
local locked=T.H.copy(data);locked.canCancel=false;assert(interact('burger',locked).completed==true and props()==1)
r.key('forge_core_cancel_persistent_item');r.key('forge_core_cancel_persistent_item',false);assert(props()==1,'cannot-cancel interaction preserved')
-- Stop the old interaction through its actual same-item toggle before the next case.
interact('burger',data);assert(props()==0)
local h=r.graph.Parts.AutoMedic.Hospital.Hospital;local a=r.graphFixture.fixtures.AutoMedic
assert(h.current==nil);local queue=#a.queue;r.key('forge_core_leave_hospital_bed');r.key('forge_core_leave_hospital_bed',false);assert(#a.queue==queue,'leave without bed is no-op')
h.current={token='H54',bed={heading=90,exit={x=1,y=2,z=3},exitHeading=180}}
r.key('forge_core_leave_hospital_bed');r.key('forge_core_leave_hospital_bed',false)
assert(h.leaving and #a.queue==queue+1,'same hospital leave body queued through installed PR keybind')
assert(interact('burger',data).completed==true and props()==1)
local old=r.provider.get('forge_core_cancel_persistent_item');local stale=old.onPressed
assert(r.api.Dispose());stale();r.key('forge_core_cancel_persistent_item');assert(props()==1,'revoked key cannot change persistent interaction')
assert(r.provider.get('forge_core_cancel_persistent_item')==nil and old.disabled and not old.isPressed)
assert(consumption.Keybinds[1].combos==nil and #consumption.Threads==describedWorkers and #r.central.world.threads==startedWorkers,'no live provider mutations or worker starts')
local replaced=T.new();replaced.prepare();replaced.api.Install();local item=replaced.graph.Central.Parts.Consumption.Keybinds[1]
item.onPressed=function()error('replacement should revoke')end
replaced.key('forge_core_cancel_persistent_item');assert(#replaced.errors==0,'changed canonical descriptor never executes')
local only=T.new();local before=only.graphFixture.snapshot();only.prepare();T.H.same(only.graphFixture.snapshot(),before,'no construction effects')
only.api.Install();assert(#only.graph.Parts.AutoMedic.Hospital.Keybinds==1 and #only.graphFixture.fixtures.AutoMedic.queue==0)
assert(#only.graphFixture.fixtures.AutoMedic.initialThreads==0,'only audited descriptor initializer executed')
print('PASS lot54 keys: actual PR provider -> same canonical Consumption/Hospital; cancellable/locked items, bed/no-bed, revocation/canonical descriptor guard; hospital description only, no service start or inventory writes')
