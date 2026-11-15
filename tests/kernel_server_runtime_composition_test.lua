local R=dofile('tests/kernel_server_runtime_harness.lua')
local L=dofile('tests/kernel_lifecycle_harness.lua')
local H,P=R.H,R.P
local r,p,l=R.new(true,'commands'),P.new(true),L.new(true)
p.core.Shared=r.core.Shared
p.core.Player_Buckets,p.core.Entity_Buckets,p.core.UsableItems={},{},{}
local fb={};for key,value in pairs(l.bindings) do fb[key]=value end
fb.core,fb.lookup,fb.players=p.core,p.lookup,p.api
local functions=H.load('kernel/server/functions.lua',H.environment())(fb)
local playerCore={State=p.core,Players=p.api,Lookup=p.lookup,Storage=p.bindings.storage,Lifecycle={Functions=functions}}
local base={PlayerCore=playerCore}
local env,loaded=H.environment(),{}
local paths={['kernel.server.main']='kernel/server/main.lua',['kernel.server.weapons']='kernel/server/weapons.lua',
    ['kernel.server.commands']='kernel/server/commands.lua'}
env.require=function(name)
    local path=assert(paths[name],'External import forbidden: '..tostring(name))
    if not loaded[name] then loaded[name]=H.load(path,env) end;return loaded[name]
end
local helperFixture=R.V.T.new(true,'server')
local bindings={};for key,value in pairs(r.bindings) do bindings[key]=value end
bindings.helpers=helperFixture.api
p.config.server=l.serverConfig;p.config.giveVehicleKeys=r.config.giveVehicleKeys
bindings.config,bindings.globalState,bindings.logger=p.config,p.counters,p.bindings.logger
local compose=H.load('kernel/server/runtime_core.lua',env)
local api=compose(base,playerCore,bindings)
assert(api.State==p.core and playerCore.Runtime==api)
assert(#r.trace==0 and #p.trace==0 and #l.trace==0 and #helperFixture.trace==0,'No constructor effects')
assert(not pcall(compose,base,playerCore,bindings))
assert(not pcall(compose,{},playerCore,bindings))
local players,buckets,items,weapons=p.core.Players,p.core.Player_Buckets,p.core.UsableItems,p.core.Shared.Weapons
assert(api.Initialize() and not api.Initialize())
assert(p.core.Players==players and p.core.Player_Buckets==buckets and p.core.UsableItems==items)
assert(api.Commands.Commands[22].name=='logout' and api.Commands.Commands[22].handler==p.api.Logout)
local handlers={};for _,command in ipairs(api.Commands.Commands) do handlers[command.name]=command.handler end
local player=p.api.CheckPlayerData(1,{citizenid='A',license='license:test',userId=101,money={cash=10,bank=0}})
assert(p.lookup.GetPlayer(1)==player and players[1]==player)
handlers.givemoney(1,R.args('givemoney',{id=1,moneytype='cash',amount=25}))
assert(player.PlayerData.money.cash==35,'Use actual local Player AddMoney, not PR framework forwarding')
handlers.setmoney(1,R.args('setmoney',{id=1,moneytype='bank',amount=60}))
assert(player.PlayerData.money.bank==60)
handlers.setjob(1,R.args('setjob',{id=1,job='taxi',grade=1}))
assert(player.PlayerData.job.name=='taxi' and player.PlayerData.jobs.taxi==1)
api.Weapons.CreateWeapons({{name='weapon_test',hash=444,label='Test'}})
assert(p.core.Shared.Weapons==weapons and api.Main.GetWeapons(444)==weapons[444])
assert(api.Weapons.HasWeapon(444))
assert(api.Weapons.RemoveWeapon(444) and api.Main.GetWeapons(444)==weapons)
assert(api.Main.SetVehicleCatalog({car={hash=101,model='car',name='Car',category='cars'}}))
local categories=api.Main.GetVehiclesByCategory();assert(categories.cars[1]==p.core.Shared.Vehicles.car)
-- Explicit force-delete mapping must be the installed DeleteCharacter export.
p.offline.A={citizenid='A',license='license:test',userId=101}
local before=#p.trace
handlers.deletechar(1,{id=1})
local dropped=false
for i=before+1,#p.trace do if p.trace[i].kind=='dropPlayer' or p.trace[i].kind=='drop' then dropped=true end end
assert(dropped,'Actual force-delete path must request the active character drop in the simulated platform')
assert(#p.tasks>0,'Delete persistence must remain deferred to the explicit platform thread')
-- No actual thread body/SQL is executed here; storage/slots have separate tests.
local freshCore={State=p.core,Players=p.api,Lookup=p.lookup,Storage=p.bindings.storage,Lifecycle={Functions=functions}}
local waiting={};for key,value in pairs(bindings) do waiting[key]=value end
waiting.library={};for key,value in pairs(bindings.library) do waiting.library[key]=value end
local checks=0
waiting.library.versionCheck=function() checks=checks+1;coroutine.yield('dependency pending') end
local pending=compose({PlayerCore=freshCore},freshCore,waiting)
local co=coroutine.create(pending.Initialize)
assert(coroutine.resume(co) and not pending.Initialize() and checks==1)
assert(coroutine.resume(co) and coroutine.status(co)=='dead' and not pending.Initialize())
assert(not pcall(env.require,'pr_lib.framework'))
for _,name in ipairs({'QBX','qbx','exports','RegisterNetEvent','RegisterCommand','CreateThread','GlobalState','MySQL'}) do
    assert(rawget(env,name)==nil,'No ambient runtime '..name)
end
print('PASS server runtime composition: same actual Player/lookup/functions/Shared/Lib, internal money/jobs/force-delete mapping and catalogs; no duplicate authority/registrations/constructor effects; one-shot init across yield')
