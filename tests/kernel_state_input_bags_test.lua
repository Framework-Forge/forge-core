local T=dofile('tests/kernel_state_input_harness.lua');local r=T.new();local g=r.graphFixture
local before=g.snapshot();local hospital=r.graph.Parts.AutoMedic.Hospital
assert(#hospital.Keybinds==0);r.prepare();T.H.same(g.snapshot(),before,'registry construction inert')
assert(#hospital.Keybinds==0 and r.adds==0 and #r.timers==0)
assert(r.api.Install()and #hospital.Keybinds==1,'explicit descriptor-only hospital preparation')
assert(#g.fixtures.AutoMedic.queue==0 and #g.fixtures.AutoMedic.binds==1,'no live fixture registration or session worker')
local d=r.api.Describe();assert(#d.bags==4 and d.bags[1].key=='PVPEnabled'and d.bags[2].key=='me'and d.bags[3].key=='initVehicle'and d.bags[4].key=='PlayerCount')
assert(r.bags[1].filter==nil and r.bags[2].filter==nil and r.bags[3].filter==''and r.bags[4].filter=='','nil and empty filters remain distinct')
local runtime=r.central.runtime;local n=r.central.native;local cache=r.central.ports.cache
local pvp={};n.SetCanAttackFriendly=function(...)pvp[#pvp+1]=table.pack(...)end
n.NetworkSetFriendlyFireOption=function(v)pvp.value=v end
r.emit('PVPEnabled','player:1',true);assert(#pvp==0)
r.emit('PVPEnabled','global',false);assert(pvp[1][1]==cache.ped and pvp[1][2]==false and pvp[1][3]==false and pvp.value==false,'actual PVP state handler and cache')
local presence;n.SetRichPresence=function(value)presence=value end
r.emit('PlayerCount','player:1',7);assert(presence==nil);r.emit('PlayerCount','global',7);assert(presence=='Players 7/64','same Discord state handler without app initialization')
local meWorkers={};n.GetPlayerFromStateBagName=function()return cache.playerId end
n.NetworkIsPlayerActive=function()return true end;n.DoesEntityExist=function()return true end
n.CreateThread=function(fn)meWorkers[#meWorkers+1]=fn end
r.emit('me','player:1',nil);assert(#meWorkers==0)
r.emit('me','player:1','Test54');assert(#meWorkers==1,'same me handler describes only its dispatched dynamic worker')
local deleted,grounded,clear={},{},{}
n.GetPedInVehicleSeat=function(vehicle,seat)assert(vehicle==200);if seat==-1 then return cache.ped elseif seat==0 then return 201 elseif seat==1 then return 202 end;return 0 end
n.NetworkGetEntityOwner=function(entity)return entity==202 and 999 or cache.playerId end
n.DeleteEntity=function(entity)deleted[#deleted+1]=entity end
n.IsEntityWaitingForWorldCollision=function()return false end
n.SetVehicleOnGroundProperly=function(vehicle)grounded[#grounded+1]=vehicle end
n.Entity=function(vehicle)assert(vehicle==200);return{state={set=function(_,...)clear[#clear+1]=table.pack(...)end}}end
local timers={};n.SetTimeout=function(ms,fn)timers[#timers+1]={ms,fn}end
r.net[44]=200;r.emit('initVehicle','entity:44',true)
assert(#deleted==1 and deleted[1]==201 and grounded[1]==200 and #timers==1,'same initVehicle seat/owner/collision implementation')
timers[1][2]();assert(clear[1].n==3 and clear[1][1]=='initVehicle'and clear[1][2]==nil and clear[1][3]==true)
local count=#grounded;r.emit('initVehicle','entity:44',false);assert(#grounded==count)
-- Installed Lib resolver + installed PR waitFor, suspended before entity creation.
r.yieldWait=true
local co=coroutine.create(function()r.emit('initVehicle','entity:55',true)end)
local ok,value=coroutine.resume(co);assert(ok and value=='waiting');r.net[55]=200;r.api.Dispose()
assert(coroutine.resume(co)and #grounded==count,'resolved entity cannot enter core after revocation')
assert(next(r.bags)==nil and #r.removed==4 and r.removed[1]==4 and r.removed[4]==1)
local late=T.new();late.prepare();late.api.Install();local fn
for _,b in pairs(late.bags)do if b.key=='PVPEnabled'then fn=b.handler end end
local events=late.graph.Central.Parts.Runtime.Events;late.graph.Central.Parts.Runtime.Events={}
local trace=#late.central.runtime.trace;fn('global','PVPEnabled',true);assert(#late.central.runtime.trace==trace,'replaced descriptor owner invalidates wrapper')
late.graph.Central.Parts.Runtime.Events=events
local timeout=T.new();timeout.prepare();timeout.api.Install()
local ok2,err=pcall(timeout.emit,'initVehicle','entity:999',true)
assert(not ok2 and tostring(err):find('statebag timed out while awaiting entity creation!',1,true),'real helper/waitFor timeout contract preserved')
print('PASS lot54 bags: canonical client50 PVP/Discord/initVehicle, nil/empty filters, actual Lib resolver/PR waitFor, ownership/timeout/post-await revocation; no real natives or service initialization')
