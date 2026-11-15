local T=dofile('tests/kernel_session_harness.lua')
local s=T.new(true,'server');s.load('status')
local api=s.core.Status
local p=s.core.Players[1].PlayerData
p.money={cash=50};p.metadata.isadmin=false
local session=api.ProtocolSnapshot(1)
local function send(state,who)
    s.dispatch('qbx_core:server:receiveStatusSnapshot',1,{
        _session=session._session,_character=who or session._character,
        extensions={clientState=state}},'manual')
end
send({housingHygiene={hygiene=42,pee=23,poop=17,soiled=true},drugState={remaining=15}})
assert(p.metadata.clientState.housingHygiene.hygiene==42)
send({housingHygiene={hygiene=90}},'OTHER')
assert(p.metadata.clientState.housingHygiene.hygiene==42,'stale character must not write')
send({housingHygiene={hygiene=60}})
assert(p.metadata.clientState.drugState.remaining==15,'inactive producer retained')
send({money={cash=99999},isadmin={enabled=true}})
assert(p.money.cash==50 and p.metadata.isadmin==false,'extension cannot overwrite authority')
local previous=p.metadata.clientState
local cyclic={};cyclic.self=cyclic
for _,invalid in ipairs({{bad=cyclic},{bad={value=0/0}},{bad={value=math.huge}},
    {bad={value=function()end}},{bad={value=string.rep('x',4097)}}}) do
    send(invalid);assert(p.metadata.clientState==previous,'invalid tree rejected atomically')
end
send({drugState={}})
assert(next(p.metadata.clientState.drugState)==nil,'explicit empty record clears extension')
local c=T.new(true,'client');c.load('status')
local calls=0;local late
c.listen('forge-core:client:collectCharacterState',function(submit)
    calls=calls+1;late=submit;submit('housingHygiene',{hygiene=77})
end)
local value=c.callbacks['qbx_core:client:getStatusSnapshot']()
assert(value.extensions.clientState.housingHygiene.hygiene==77)
late('late',{invalid=true});assert(value.extensions.clientState.late==nil,'late submit ignored')
c.dispatch('QBCore:Client:OnPlayerLoaded',0)
local before=calls
c.exported.FlushStatusSnapshot('client_cache')
assert(calls==before,'frequent HUD/status delivery does not collect character extensions')
c.exported.FlushStatusSnapshot('death');assert(calls==before+1,'death collects current state')
print('PASS character state: lifecycle collection, bounded serialization, inactive producer retention, stale session refusal, authority isolation')
