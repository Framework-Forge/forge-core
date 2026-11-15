local T=dofile('tests/kernel_forge_adapter_harness.lua');local H,P=T.H,T.P;local cases=0
local scenarios={empty=function()end,snapshot=function(r)r.emit('QBCore:Player:SetPlayerData',T.data())end,
    cached=function(r)r.cached=T.data()end,unauthenticated=function(r)r.cached=T.data();r.session={authenticated=false}end,
    dirty=function(r)r.cached=T.data();r.dirty=15;r.ready=true end,
    readyError=function(r)r.readyHook=function()error('readiness unavailable',0)end end}
for label,setup in pairs(scenarios)do
    local a,b=T.new(true),T.new(false);setup(a);setup(b)
    for _,entry in ipairs({{'GetPlayer'},{'GetPlayerData'},{'GetMoney','cash'},{'GetMoney','bank'},{'GetMoney','black'},
        {'GetMoney','unknown'},{'GetJobInfo'},{'GetPlayerJob'},{'PlayerHasJob','POLICE'},{'PlayerHasJob','police',3},
        {'PlayerHasJob','police',1},{'IsPlayerLoaded'},{'IsSessionReady'},{'getPlayerMetadata','hunger'}})do
        local name=entry[1];local aa=table.pack(a.framework[name](table.unpack(entry,2)));local bb=table.pack(b.framework[name](table.unpack(entry,2)))
        H.same(P.snapshot(aa),P.snapshot(bb),label..':'..name);cases=cases+1
    end
    H.same(a.trace,b.trace,label..':ports');assert(a.pulls==b.pulls)
end
local function events(r)
    for name,d in pairs(r.events)do assert(d.network==(name~='qbx_core:client:statusChanged'))end
    r.emit('QBCore:Client:OnPlayerLoaded',{PlayerData=T.data()})
    r.emit('qbx_core:client:statusChanged',{health=80,armor=0,hunger=0,thirst=10,stress=2,oxygen=3,extra=1})
    r.emit('QBCore:Client:OnJobUpdate',{name='ambulance',grade={level=1,name='Medic'}})
    r.emit('QBCore:Client:OnGangUpdate',{name='ballas'});r.emit('QBCore:Client:SetDuty',1)
    r.emit('qbx_core:client:setGroups',{ambulance=1});r.emit('hud:client:OnMoneyChange','cash',7,true)
    return P.snapshot(r.view)
end
H.same(events(T.new(true)),events(T.new(false)),'nine installed event policies/payloads');cases=cases+1
for _,event in ipairs({'QBCore:Client:OnPlayerUnload','QBCore:Player:SetPlayerData'})do
    local a,b=T.new(true),T.new(false);a.emit(event,nil);b.emit(event,nil);H.same(a.view,b.view,event);cases=cases+1
end
local a,b=T.new(true),T.new(false);a.cached=T.data();b.cached=T.data()
for _,wear in ipairs({true,false})do
    local outfits={Female={hat=2},Male={hat=1}}
    H.same(table.pack(a.framework.toggleOutfit(wear,outfits)),table.pack(b.framework.toggleOutfit(wear,outfits)),'outfit ignored transport return');cases=cases+1
end
H.same(a.trace,b.trace,'outfit exact events');local count=0;for _ in pairs(a.framework)do count=count+1 end;assert(count==10)
print('PASS lot80 adapter:'..cases..' whole installed qbx/client comparisons,ten methods/nine event policies,passive cache/auth/name/money/jobs/metadata/readiness/outfit return tuples;virtual only')
