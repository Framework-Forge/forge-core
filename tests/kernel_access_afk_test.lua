local A=dofile('tests/kernel_access_harness.lua')
local n=0
local function case(name,fn,options)A.case(name,fn,options);n=n+1 end
local function start(r,settings)
    r.online={'1'};r.m.seed(r.config.Afk.Storage.file,settings or {enabled=true,minutes=1})
    assert(r.a.start());local co=r.runWorker();r.tick(co);return co
end
case('normalize-defaults',function(r)return r.a.getSettings(),r.a.load()end)
for _,value in ipairs({-4,0,1,2.8,1440,99999,'3','bad'})do
    case('minutes-'..tostring(value),function(r)local ok,c=r.a.save(1,{minutes=value});assert(ok and c.minutes>=1 and c.minutes<=1440);return c end)
end
for _,value in ipairs({true,false,1,0,'sim','yes','TRUE','no'})do
    case('enabled-'..tostring(value),function(r)local ok,c=r.a.save(1,{enabled=value,minutes=5});assert(ok);return c end)
end
case('save-denied',function(r)r.manage=false;local ok,e=r.a.save(1,{});assert(not ok and e=='no_permission')end)
case('save-failed',function(r)r.m.onWrite=function()return false end;local ok,e=r.a.save(1,{minutes=2});assert(not ok and e=='save_failed')end)
case('save-resets-timers',function(r)local co=start(r);r.tick(co);assert(r.a.remainingSeconds[1]==59);assert(r.a.save(1,{minutes=2}));assert(next(r.a.remainingSeconds)==nil)end)
case('stationary-countdown',function(r)local co=start(r);r.tick(co);assert(r.a.remainingSeconds[1]==59)end)
case('same-threshold',function(r)local co=start(r);r.coords[1]=A.vector(0.05,0,0);r.tick(co);assert(r.a.remainingSeconds[1]==59)end)
case('moved-resets',function(r)local co=start(r);r.tick(co);r.coords[1]=A.vector(0.051,0,0);r.tick(co);assert(r.a.remainingSeconds[1]==60)end)
case('iteration-not-elapsed',function(r)local co=start(r);r.tick(co,30000);assert(r.a.remainingSeconds[1]==59)end)
case('kicks-virtual-only',function(r)local co=start(r);for i=1,61 do r.tick(co)end;assert(#r.drops==1 and not r.a.remainingSeconds[1])end)
case('unloaded-resets',function(r)local co=start(r);r.tick(co);r.event('pr_bridge:server:OnPlayerUnloaded',1);r.tick(co);assert(not r.a.remainingSeconds[1])end)
case('loaded-new-resets',function(r)local co=start(r);r.tick(co);r.players[1].PlayerData.citizenid='NEW';r.event('pr_bridge:server:OnPlayerLoaded',1)
    r.tick(co);assert(r.a.remainingSeconds[1]==60)end)
case('drop-reset',function(r)local co=start(r);r.tick(co);r.event('playerDropped');assert(not r.a.remainingSeconds[1])end)
case('missing-ped',function(r)local co=start(r);r.pedMissing=true;r.tick(co);assert(not r.a.remainingSeconds[1])end)
case('disconnected-passive-block',function(r)r.library.cache.SetResourceState('qbx_core','session:1',{connected=false});start(r);assert(not r.a.remainingSeconds[1])end)
case('stopped-worker',function(r)local co=start(r);r.a.started=false;r.tick(co);assert(coroutine.status(co)=='dead')end)
case('single-worker',function(r)start(r);r.a.start();assert(#r.workers==1)end)
case('disabled-retains-warning-map',function(r)local co=start(r);r.a.warnedSeconds[1]={[30]=true};r.a.settings.enabled=false;r.tick(co)
    assert(r.a.warnedSeconds[1][30]and not r.a.remainingSeconds[1])end)
case('drop-retains-lastNotify',function(r)local co=start(r);r.a.lastNotify['1:old']=100;r.event('playerDropped');assert(r.a.lastNotify['1:old']==100)end)
case('warning-once',function(r)local co=start(r);r.a.remainingSeconds[1]=30;r.tick(co);assert(r.a.warnedSeconds[1][30])
    r.a.remainingSeconds[1]=30;r.tick(co)
end)
case('start-load-error-stuck',function(r)r.library.loadJsonRecovery=function()error('fixture-load',0)end;assert(not pcall(r.a.start));assert(r.a.start()and #r.workers==0)end)
print('PASS AFK service differentials '..n)
