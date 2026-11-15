local R=dofile('tests/kernel_support_context_harness.lua');local r=R.context();local f=r.fixture;local before=f.snapshot()
r.prepareSupport();R.H.same(f.snapshot(),before,'support67 construction inert')
assert(#r.log.requests==0 and #r.log.libraryCalls==0 and #r.clock.queue==0)
for _,key in ipairs({'Player','Functions','Events','Commands','Character'})do assert(r.supportCaptures[key].logger==r.api.Logger,'one logger captured across consumers')end
assert(r.supportCaptures.Player.triggerHook==r.api.Hooks.Hooks.trigger)
r.startSupport();assert(r.api.Public.Counts.exports==2 and r.api.Public.PhysicalUnregistration==false)
local pc=r.graph.PlayerCore;local player=pc.Players.CheckPlayerData(2,{citizenid='SUPPORT',license='license:test',userId=101,money={cash=0,bank=0}})
local veto=true;local cb=setmetatable({},{__call=function(_,p)assert(p.source==2 and p.moneyType=='cash');return not veto end})
r.internal.caller='owner-A';local id=r.surface.exports.registerHook('addMoney',cb)
assert(id==1 and not pc.Players.AddMoney(2,'cash',25,'virtual')and player.PlayerData.money.cash==0,'canonical Player obeys internal hook veto')
veto=false;local n=#r.log.libraryCalls;assert(pc.Players.AddMoney(2,'cash',25,'virtual')and player.PlayerData.money.cash==25)
assert(#r.log.libraryCalls==n+1,'canonical Player logs once through installed PR')
r.internal.caller='owner-B';r.surface.exports.removeHooks(id);veto=true
assert(not pc.Players.AddMoney(2,'cash',25,'virtual'))
r.emit('onResourceStop','owner-A');assert(pc.Players.AddMoney(2,'cash',1,'virtual'),'existing resource-stop listener cleans internal hooks')
r.api.Context.Config.Server.logging.webhook.playermoney='virtual://discord'
for i=1,6 do assert(pc.Players.AddMoney(2,'cash',1,'queue'))end
r.clock.advance(0);assert(#r.log.requests==5,'installed Discord queue pauses after five messages')
r.clock.advance(60000);assert(#r.log.requests==6,'sixth queued message follows original wait')
assert(r.active('onResourceStop')==1,'no duplicate resource stop listener')
local balance=player.PlayerData.money.cash;r.log.libraryError=true
assert(not pcall(pc.Players.AddMoney,2,'cash',10,'partial')and player.PlayerData.money.cash==balance+10,'logger failure occurs after money mutation without rollback')
r.log.libraryError=false;r.api.Stop();r.clock.advance(1200000);r.api.Poll();local progress=r.api.Progress()
assert(progress.complete,'support67 private drain complete: inner='..tostring(progress.context.complete)..' hooks='..tostring(progress.hooks.complete)..' tasks='..tostring(progress.tasks.quiescent)..' http='..progress.delivery.pendingHTTP..' unknown='..progress.delivery.unknownHTTP)
assert(r.surface.exports.registerHook('late',cb)==nil and r.surface.exports.AddMoney(2,'cash',1)==nil)
local collision=R.context();collision.prepareSupport();collision.surface.exports.registerHook=function()end
assert(not collision.supportInstall()and collision.surface.exports.GetJobs==nil,'foreign hook namespace refused before core publication')
local fail=R.context();fail.prepareSupport();fail.dbReady=false;assert(not fail.supportInstall()and fail.api.Progress().delivery.complete)
local pending=R.context();pending.prepareSupport();pending.startSupport();pending.log.defer=true
pending.api.Logger.log({source=2,event='late',message='virtual',webhook='virtual://discord'});pending.clock.advance(0)
pending.api.Stop();pending.clock.advance(120000);pending.api.Poll();assert(not pending.api.Progress().complete and pending.api.Progress().delivery.pendingHTTP==1)
pending.log.callbacks[1](204,'',{});assert(pending.api.Progress().complete,'pending Discord request drained by late callback')
local native=R.context();native.prepareSupport();native.startSupport();native.emit('onResourceStop','forge-core');native.clock.advance(1200000);native.api.Poll()
assert(native.api.Progress().phase=='closed'and native.api.Progress().complete,'native stop closes hooks/log tasks/delivery on same listener')
local stale=R.context();stale.prepareSupport();stale.startSupport();stale.fixture.base.ServerSupportContext={}
assert(stale.surface.exports.registerHook('stale',cb)==nil and stale.surface.exports.GetJobs()==nil,'replaced support owner revokes supplemental and previous public surfaces')
stale.api.Stop()
local queued=R.context();queued.prepareSupport();queued.startSupport()
for i=1,6 do queued.api.Logger.log({source=2,event='queue',message='virtual',webhook='virtual://discord'})end
queued.clock.advance(0);assert(#queued.log.requests==5);queued.api.Stop();queued.clock.advance(1200000);queued.api.Poll()
assert(#queued.log.requests==5 and queued.api.Progress().complete,'Close cancels private queue continuation without flushing sixth message')
local rate=R.context();rate.prepareSupport();rate.startSupport();rate.log.headers={['X-RateLimit-Remaining']='0',['X-RateLimit-Reset']='1010'}
for i=1,2 do rate.api.Logger.log({source=2,event='rate',message='virtual',webhook='virtual://discord'})end
rate.clock.advance(0);assert(#rate.log.requests==1);rate.clock.advance(999);assert(#rate.log.requests==1)
rate.clock.advance(1);assert(#rate.log.requests==2,'installed rate-limit delay is preserved');rate.api.Stop();rate.clock.advance(1200000);rate.api.Poll()
assert(rate.api.Progress().complete)
print('PASS lot67 actual66/61/48:single Player/internal veto+cleanup,one PR log,six-message queue timing,partial money on log error,two supplemental exports,collision/preflight/pending Stop;virtual only')
