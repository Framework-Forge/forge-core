local M=dofile('tests/kernel_client_media_harness.lua');local r=M.context();local before=r.fixture.snapshot()
r.prepareMedia();M.H.same(r.fixture.snapshot(),before,'client69 construction inert')
assert(#r.media.trace==0 and r.captures['kernel.helpers'].audio==r.api.Media.Audio)
assert(r.captures['kernel.client.character_renderer'].streaming==r.api.Media.Streaming,'renderer captures same PR streaming before construction')
assert(r.installMedia());assert(r.api.Poll()==false and r.api.Progress().phase=='installed','Poll does not start shutdown')
local h=r.graph.Central.Parts.Helpers.Lib;assert(h.playAudio({audioName='local'})==true)
local objects=r.graph.Parts.Objects.Objects
r.graph.Parts.Objects.Subscriptions[1].handler({objects={{id=69,sceneId=1,model='X',coords={x=1,y=2,z=3}}}})
assert(objects.edit(69),'actual object spawn and editor through installed PR')
local n=0;for _ in pairs(r.media.exists)do n=n+1 end;assert(n>0)
r.media.exists[9999]=true
assert(r.api.Stop());local p=r.api.Progress();assert(p.complete and #p.sequence.ledger==16,'real58 cleans all domain handlers with permitted PR deletes')
assert(r.media.exists[9999]==true);local remaining=0;for _ in pairs(r.media.exists)do remaining=remaining+1 end;assert(remaining==1,'owned object removed and foreign entity retained')
local count=#r.media.trace;assert(not pcall(h.playAudio,{audioName='late'})and #r.media.trace==count,'captured Helpers cannot fall back to native sound after Stop')
assert(r.surface.exports.GetPlayerData()==nil and r.active()==0)
local native=M.context();native.prepareMedia();assert(native.installMedia());native.emit('onResourceStop','forge-core')
assert(native.api.Progress().complete and native.api.Progress().sequence.nativeBestEffort,'native stop uses same cleanup window')
local pending=M.context();pending.prepareMedia();assert(pending.installMedia());pending.media.loaded=false
pending.media.waitHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(pending.api.Media.Streaming.requestModel('pending',100))end)
assert(coroutine.resume(co));assert(not pending.api.Stop())
assert(pending.api.Progress().sequence.phase=='draining'and #pending.api.Progress().sequence.ledger==0,'external PR request postpones manual domain cleanup')
pending.media.loaded=true;assert(coroutine.resume(co));assert(pending.api.Poll()and pending.api.Progress().complete)
local started=M.context();started.prepareMedia();assert(started.installMedia());assert(started.api.Start(),'actual57 initialization and worker launch')
started.api.Stop();started.clock.advance(120000);started.api.Poll();assert(started.api.Progress().complete,'owned57 worker queue drains with media')
local fail=M.context();fail.prepareMedia();fail.surface.failAt=1;assert(not fail.installMedia()and fail.api.Progress().media.complete,'failed registration closes private media')
local stale=M.context();stale.prepareMedia();assert(stale.installMedia());stale.fixture.state.ClientMediaContext={}
assert(stale.surface.exports.GetPlayerData()==nil and not pcall(stale.api.Media.Native.GetSoundId),'replaced69 owner refuses public and fallback ingress')
assert(not stale.api.Stop()and not stale.api.Progress().complete,'stale owner does not claim full teardown')
local interrupted=M.context();interrupted.prepareMedia();assert(interrupted.installMedia())
interrupted.readyHook=function()interrupted.emit('onResourceStop','forge-core')end
local ok,value=pcall(interrupted.api.Start)
assert(ok and value==false and interrupted.api.Progress().media.complete,'native Stop during Start does not reopen cleanup or media')
print('PASS lot69 actual57/58:one client/Helpers/Renderer,captured PR streaming/audio,real object teardown+foreign preservation,closed fallback,one native stop;virtual only')
