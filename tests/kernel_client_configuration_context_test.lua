local T=dofile('tests/kernel_client_configuration_harness.lua');local r=T.context();local before=r.fixture.snapshot()
r.prepareConfiguration();T.H.same(r.fixture.snapshot(),before,'client70 construction inert')
assert(r.configConstructions==1 and #r.configuration.trace==0,'construct exactly one local Client06')
local config=r.api.Config.Client;local captures=r.captures
assert(r.graph.Central.Config.Client==config)
assert(captures['kernel.client.session_core'].statusConfig==config.playerStatus,'status captures local branch')
assert(captures['kernel.client.runtime_core'].config==config and captures['kernel.client.character_core'].config==config,'runtime and character capture same Client')
assert(captures['kernel.helpers'].library.waitFor==r.api.Boundary.WaitFor,'Helpers captures PR wait before construction')
assert(captures['kernel.client.runtime_core'].library.waitFor==r.api.Boundary.WaitFor)
assert(r.installConfiguration());assert(r.api.Poll()==false,'Poll does not initiate Stop')
r.configuration.states.pr_carkeys='starting';r.configuration.keyState:AddTempKey('ABC');assert(config.hasKeys(' ab c ',42))
config.statusIntervalSeconds=7;assert(r.api.IsCurrent(),'value edits do not replace branches')
assert(r.api.Stop());assert(r.api.Progress().complete and #r.api.Progress().context.sequence.ledger==16,'same58 cleanup with70')
local n=#r.configuration.trace;assert(not pcall(config.hasKeys,'ABC',42)and #r.configuration.trace==n,'captured config closes external calls')
assert(not pcall(r.api.Library.waitFor,function()return true end))
assert(r.surface.exports.GetPlayerData()==nil and r.active()==0)
local entity=T.context();local exists=false
entity.mediaPorts.worker.central.native.NetworkDoesEntityExistWithNetworkId=function(id)assert(id==1501);return exists end
entity.mediaPorts.worker.central.native.NetworkGetEntityFromNetworkId=function(id)assert(id==1501);return 501 end
entity.prepareConfiguration();assert(entity.installConfiguration());entity.configuration.waitHook=function()exists=true end
local handle,netId=entity.graph.Central.Parts.Helpers.Lib.getEntityAndNetIdFromBagName('entity:1501')
assert(handle==501 and netId==1501 and entity.configuration.now==1,'actual Helpers bag resolution uses installed PR waitFor');assert(entity.api.Stop())
local pending=T.context();local queries=0
pending.mediaPorts.worker.central.native.NetworkDoesEntityExistWithNetworkId=function()queries=queries+1;return false end
pending.prepareConfiguration();assert(pending.installConfiguration());pending.configuration.waitHook=function()coroutine.yield()end
local co=coroutine.create(function()local ok,err=pcall(pending.graph.Central.Parts.Helpers.Lib.getEntityAndNetIdFromBagName,'entity:1501')
    assert(not ok and err=='client_configuration_closed')end)
assert(coroutine.resume(co));assert(not pending.api.Stop())
assert(pending.api.Progress().context.sequence.phase=='draining'and #pending.api.Progress().context.sequence.ledger==0,'PR wait postpones manual cleanup')
assert(coroutine.resume(co));assert(queries==1,'closed PR wait refuses another Helpers native query');assert(pending.api.Poll()and pending.api.Progress().complete)
local key=T.context();key.prepareConfiguration();assert(key.installConfiguration());key.configuration.states.pr_carkeys='started'
key.configuration.keyState:AddTempKey('ABC');key.configuration.keyHook=function()coroutine.yield()end
local query=coroutine.create(function()assert(key.api.Config.Client.hasKeys('ABC',42))end)
assert(coroutine.resume(query));assert(not key.api.Stop());assert(coroutine.resume(query));assert(key.api.Poll()and key.api.Progress().complete)
for _,change in ipairs({'owner','config','characters','status','closure','library','libraryRef','graphConfig'})do
    local stale=T.context();stale.prepareConfiguration();assert(stale.installConfiguration());local old=stale.api.Config.Client.hasKeys
    if change=='owner'then stale.fixture.state.ClientConfigurationContext={}
    elseif change=='config'then stale.api.Config.Client={}
    elseif change=='characters'then stale.api.Config.Client.characters={}
    elseif change=='status'then stale.api.Config.Client.playerStatus={}
    elseif change=='closure'then stale.api.Config.Client.hasKeys=function()return true end
    elseif change=='library'then stale.api.Library.waitFor=function()return true end
    elseif change=='libraryRef'then stale.api.Library={}
    else stale.graph.Central.Config.Client={}end
    assert(not stale.api.IsCurrent()and stale.surface.exports.GetPlayerData()==nil,'replaced config/owner closes public ingress')
    assert(not pcall(old,'ABC',42)and not pcall(stale.api.Context.Media.Native.GetSoundId),'old config and media closures honor70 ownership')
    assert(not stale.api.Stop()and not stale.api.Progress().complete,'stale context never claims complete cleanup')
end
local staleStop=T.context();staleStop.prepareConfiguration();assert(staleStop.installConfiguration())
staleStop.fixture.state.ClientConfigurationContext={}
assert(pcall(staleStop.emit,'onResourceStop','forge-core')and not staleStop.api.Progress().complete,'native Stop on stale owner is fail-closed,not a cleanup success')
local native=T.context();native.prepareConfiguration();assert(native.installConfiguration());assert(native.active('onResourceStop')==1,'only existing58 stop listener')
native.emit('onResourceStop','forge-core');assert(native.api.Progress().complete)
local fail=T.context();fail.prepareConfiguration();fail.surface.failAt=1
assert(not fail.installConfiguration()and fail.api.Progress().boundary.complete,'failed Install closes70')
local started=T.context();started.prepareConfiguration();assert(started.installConfiguration());assert(started.api.Start(),'actual57 startup with local config')
started.api.Stop();started.clock.advance(120000);started.api.Poll();assert(started.api.Progress().complete)
local interrupt=T.context();interrupt.prepareConfiguration();assert(interrupt.installConfiguration())
interrupt.readyHook=function()interrupt.emit('onResourceStop','forge-core')end
local ok,value=pcall(interrupt.api.Start);assert(ok and value==false and interrupt.api.Progress().complete,'Stop during Start does not reopen70')
local duplicate=T.context();duplicate.configurationPorts.mediaContext.worker.central.config.Client={}
assert(not pcall(duplicate.prepareConfiguration),'reject preconstructed Client config')
assert(duplicate.fixture.state.ClientConfigurationContext==nil,'reject foreign Client before publishing private scope')
local construction=T.context();construction.configuration.ports.vec4=function()error('virtual vector failure',0)end
assert(not pcall(construction.prepareConfiguration))
assert(construction.fixture.state.ClientConfigurationContext.Boundary.Progress().complete,'failed Client construction closes70 before any registry')
local registration=T.context();registration.prepareConfiguration()
registration.onListen=function()registration.api.Stop()end
assert(not registration.installConfiguration()and registration.api.Progress().boundary.complete,'Stop during registration does not reopen70')
print('PASS lot70 actual69/57/58/49:one Client06/status/Runtime/Character/Helpers;pending key/wait drain,16 cleanups,one listener,ownership/closure/error/start-stop guards;virtual only')
