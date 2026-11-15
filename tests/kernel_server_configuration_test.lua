local C=dofile('tests/kernel_configuration_harness.lua');local r=C.context();local f=r.fixture
local before=f.snapshot();local old=f.ports.central.session.player.config
old.giveVehicleKeys=function()error('foreign config closure must not run')end
r.prepareConfiguration();C.H.same(f.snapshot(),before,'config66 construction inert');assert(#r.configuration.trace==0 and #r.keys.calls==0)
assert(r.configCounts.shared==1 and r.configCounts.server==1 and r.vectors==1,'one local Shared/Server construction')
local cfg=r.api.Config;local server,shared=cfg.Server,cfg.Shared;local p=r.captures
assert(server~=old and p.Player.config==server and p.Commands.config==server and p.Slots.config==server and p.Character.config==server)
assert(p.Functions.config==server.server and p.Events.config==server.server and p.Functions.logging==server.logging and p.Events.logging==server.logging)
assert(p.Status.config==server.player.status and p.Storage.characterDataTables==server.characterDataTables,'captured status/storage branches share local config')
assert(p.Player.defaultSpawn==shared.defaultSpawn and p.Storage.defaultSpawn==shared.defaultSpawn and p.Character.starterItems==shared.starterItems)
assert(p.Functions.notifyPosition==shared.notifyPosition,'local notification default shared')
assert(f.ports.central.session.player.config==old and old.giveVehicleKeys~=server.giveVehicleKeys,'input config preserved not mutated')
assert(r.configurationInstall());r.emit('onResourceStart','forge-core');r.begin();r.resume()
assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]));local pc=r.graph.PlayerCore
local player=pc.Players.CheckPlayerData(2,{citizenid='CONFIG',license='license:test',userId=101})
assert(player.PlayerData.position==shared.defaultSpawn,'Player defaultSpawn is same local value')
assert(player.PlayerData.money.cash==server.money.moneyTypes.cash and pc==f.base.PlayerCore)
local id=pc.Players.GenerateUniqueIdentifier('AccountNumber');assert(id:match('^US0%dQBX'),'canonical Player uses local identifier closure')
local pvp=server.server.pvp;r.surface.run('togglepvp',2,{})
assert(server.server.pvp==not pvp and f.central.n.globalState.PVPEnabled==server.server.pvp,'real command mutates shared local PVP config')
f.central.n.aces[2]={admin=true};r.surface.run('closeserver',2,{'Local close'})
assert(server.server.closed and server.server.closedReason=='Local close','real close command updates canonical lifecycle branch')
r.surface.run('openserver',2,{});assert(server.server.closed==false)
local spawned=f.helperFixture.spawnCount;r.surface.run('car',2,{'sultan','true'})
assert(f.helperFixture.spawnCount==spawned+1 and r.keys.calls[#r.keys.calls].name=='CreateTempKeyItem','real car command uses local Helpers07 then PR65 key')
assert(#r.configuration.trace>0 and r.api.IsCurrent())
local helperBefore=#f.helperFixture.trace;pc.Lifecycle.Functions.DeleteVehicle(101)
local disabled=false;for i=helperBefore+1,#f.helperFixture.trace do local e=f.helperFixture.trace[i]
    if e.kind=='state'and e.args[2]=='persisted'and e.args[3]==nil then disabled=true end end
assert(disabled,'DeleteVehicle disables same local Helpers persistence')
r.surface.run('dv',2,{})
assert(r.keys.calls[#r.keys.calls].name=='RemoveTempKeyItem','real dv command removes key via installed PR65 delegate')
r.api.Stop();r.clock.advance(120000);r.api.Poll();assert(r.api.Progress().complete,'configuration66 drain includes65')
local calls=#r.keys.calls;server.giveVehicleKeys(2,'LATE',101);server.setVehicleLock(101,'lock');assert(#r.keys.calls==calls)
local fail=C.context();fail.prepareConfiguration();fail.dbReady=false;assert(not fail.configurationInstall()and fail.api.Progress().configuration.complete)
local replaced=C.context();replaced.prepareConfiguration();replaced.api.Config.Server.server={}
assert(not replaced.configurationInstall()and #replaced.keys.calls==0,'replaced config branch refuses installation');replaced.api.Stop()
local stale=C.context();stale.prepareConfiguration();assert(stale.configurationInstall());stale.fixture.base.Helpers={}
assert(stale.api.Config.Server.giveVehicleKeys(2,'STALE',101)==nil and #stale.keys.calls==0,'replaced Helpers revokes config and PR65');stale.api.Stop()
local ingress=C.context();ingress.prepareConfiguration();assert(ingress.configurationInstall());ingress.begin();ingress.resume();assert(ingress.outcome[1]and ingress.outcome[2])
local prior=ingress.api.Config.Server.server;ingress.api.Config.Server.server={pvp=false}
local original=prior.pvp;ingress.surface.run('togglepvp',2,{})
assert(prior.pvp==original and ingress.api.Config.Server.server.pvp==false and ingress.surface.exports.GetJobs()==nil,'replaced config revokes new command/export ingress')
ingress.api.Stop()
local stop=C.context();stop.prepareConfiguration();assert(stop.configurationInstall());stop.begin();stop.emit('onResourceStop','forge-core');stop.resume()
stop.clock.advance(120000);stop.api.Poll();assert(stop.api.Progress().phase=='closed'and stop.api.Progress().configuration.complete)
print('PASS lot66 actual65/64/61/48:single local config branches/defaults/identifier,real PVP/open-close/car/dv commands,same Helpers persistence,preflight/identity/native Stop;all SQL/entities virtual')
