local M=dofile('tests/kernel_media_harness.lua');local r=M.context();local f=r.fixture;local before=f.snapshot()
r.prepareMedia();M.H.same(f.snapshot(),before,'media68 construction inert')
assert(#r.media.events==0 and #r.media.calls==0 and r.media.statesRead==nil)
assert(r.mediaCaptures['kernel.helpers'].audio==r.api.Media.Audio and r.mediaCaptures['kernel.server.commands'].chatMessage==r.api.Media.ChatMessage,'media ports captured before Helpers and Commands')
r.startMedia();local pc=r.graph.PlayerCore;local helpers=f.base.Helpers
assert(helpers==r.graph.Parts.Helpers and pc==f.base.PlayerCore,'one local Helpers/Player authority')
assert(helpers.Lib.playAudio(-1,{audioName='near',coords={x=0,y=0,z=0},radius=15})==true and #r.media.events==2,'real local Helpers routes through PR to installed sound radius')
r.media.states.pr_3dsound='starting';assert(helpers.Lib.playAudio(2,{audioName='wait'})==false);r.media.states.pr_3dsound='started'
pc.Players.CheckPlayerData(2,{citizenid='MEDIA2',license='license:test',userId=101})
local admin=pc.Players.CheckPlayerData(3,{citizenid='MEDIA3',license='license:three',userId=102,metadata={optin=true}})
local cfg=r.api.Context.Context.Config.Server.server;cfg.requireOptIn=true
f.central.l.ids[3]={'license:three'};f.central.l.aces[3]={admin=true};f.central.n.aces[3]={admin=true}
local count=#r.media.events;local logs=#r.log.libraryCalls;r.surface.run('ooc',2,{'hello','world'})
assert(#r.media.events==count+3 and #r.log.libraryCalls==logs+1,'real OOC near/self/admin optin with canonical logger')
assert(r.media.events[count+1].name=='chat:addMessage'and r.media.events[count+3].payload.args[1]:find('Proximity OOC',1,true))
assert(r.media.nui[#r.media.nui].message.args[2]=='hello world','OOC reaches installed legacy chat handler')
admin.PlayerData.metadata.optin=false;count=#r.media.events;logs=#r.log.libraryCalls;r.surface.run('ooc',2,{'denied far admin'})
assert(#r.media.events==count+2 and #r.log.libraryCalls==logs,'OOC optout admin gets neither proximity message nor log')
local calls=#r.media.calls;r.api.Stop();r.clock.advance(1200000);r.api.Poll()
assert(r.api.Progress().complete and helpers.Lib.playAudio(2,{audioName='closed'})==false and #r.media.calls==calls)
local fail=M.context();fail.prepareMedia();fail.dbReady=false;assert(not fail.mediaInstall()and fail.api.Progress().media.complete,'preflight failure closes media')
local stale=M.context();stale.prepareMedia();stale.startMedia();stale.fixture.base.ServerMediaContext={}
count=#stale.media.events;stale.surface.run('ooc',2,{'stale'})
assert(#stale.media.events==count and stale.surface.exports.GetJobs()==nil and stale.surface.exports.registerHook('x',{})==nil,'replaced media owner revokes previous and supplemental public ingress')
stale.api.Poll();assert(stale.api.Progress().media.complete)
local config=M.context();config.prepareMedia();config.startMedia();config.api.Context.Context.Config.Server.server={}
assert(config.api.Media.Audio.PlayNativeSound(2,{})==nil and config.surface.exports.GetJobs()==nil,'replaced inner config revokes media ingress too');config.api.Stop()
local native=M.context();native.prepareMedia();native.startMedia();native.emit('onResourceStop','forge-core');native.clock.advance(1200000);native.api.Poll()
assert(native.api.Progress().phase=='closed'and native.api.Progress().complete and native.active('onResourceStop')==0,'one native stop tears down media with67')
print('PASS lot68 actual67:single Helpers/Player,captured PR audio/chat,installed radius/OOC optin/logging,preflight/stale/manual/native Stop;no live effects')
