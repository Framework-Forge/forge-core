local R=dofile('tests/kernel_access_client_harness.lua')
local count=0
local function case(n,fn)R.case(n,fn);count=count+1 end
case('descriptors',function(r)
    assert(#r.descriptors==4 and #r.initial==1)
    local n=0;for _ in pairs(r.callbacks)do n=n+1 end;assert(n==3)
    assert(not r.state.active and not r.state.checking)
end)
for _,loaded in ipairs({false,true})do
    case('initial loaded '..tostring(loaded),function(r)r.loaded=loaded;r.run(r.initial[1]);r.advance(9000);r.stop()end)
end
for _,key in ipairs({'QBCore:Client:OnPlayerUnload','qbx_core:client:playerLoggedOut'})do
    case('unload '..key,function(r)r.start();r.advance(600);r.fire(key,nil);r.advance(20);assert(not r.state.active and not r.zones[44])end)
end
case('loaded event allowed',function(r)r.allowed=true;r.fire('QBCore:Client:OnPlayerLoaded',nil);r.advance(5000);assert(not r.state.active)end)
case('session old check',function(r)
    r.awaitHook=function(name)assert(name==r.config.Whitelist.Callbacks.check);r.native.Wait(2000);return false,r.cfg end
    r.fire('QBCore:Client:OnPlayerLoaded',nil);r.advance(4500);assert(r.state.checking)
    r.fire('forge-core:session:changed',nil,'B');r.advance(1500);assert(r.state.checking and not r.state.active)
    r.advance(2500);r.loaded=false;r.fire('forge-core:session:changed',nil,nil);r.advance(2500)
    assert(not r.state.active and not r.state.checking)
end)
case('creation started',function(r)r.resource='started';r.creation=true;r.fire('QBCore:Client:OnPlayerLoaded',nil);r.advance(5000);assert(not r.state.checking)end)
case('creation error pcall',function(r)r.resource='started';r.creationError=true;r.allowed=true;r.run(r.fn('checkWhitelist'));r.advance(2600)end)
case('creation nonboolean',function(r)r.resource='started';r.creation=1;r.allowed=true;r.run(r.fn('checkWhitelist'));r.advance(2600)end)
case('creation after wait',function(r)r.resource='started';r.run(r.fn('checkWhitelist'));r.advance(1000);r.creation=true;r.advance(1600);assert(not r.state.checking)end)
case('logout during wait',function(r)r.run(r.fn('checkWhitelist'));r.advance(1000);r.loaded=false;r.advance(1600);assert(not r.state.active)end)
for _,payload in ipairs({{pending=true,enabled=true},{enabled=false}})do
    case('check cfg '..tostring(payload.pending),function(r)r.awaitHook=function()return false,payload end;r.run(r.fn('checkWhitelist'));r.advance(2600);assert(not r.state.active)end)
end
case('fallback config',function(r)
    local n=0;r.awaitHook=function(name)n=n+1;if name==r.config.Whitelist.Callbacks.check then return false,'not-ready'end;return true,r.cfg end
    r.run(r.fn('checkWhitelist'));r.advance(3200);assert(n==2 and r.state.active);r.stop()
end)
case('missing config retry',function(r)r.awaitHook=function()return false end;r.run(r.fn('checkWhitelist'));r.advance(2600);assert(not r.state.active)end)
for _,mode in ipairs({'target','drawtext','both','unknown',''})do
    case('interaction '..mode,function(r)r.cfg.interactionMode=mode;r.cfg.targetEnabled=true;r.start();r.advance(650);r.stop();r.advance(20)end)
end
case('target selected',function(r)r.start();r.advance(600);assert(r.target.options[1].canInteract());r.alerts={'cancel'};r.run(r.target.options[1].onSelect);r.advance(20);r.stop()end)
case('escape return',function(r)r.start();r.advance(600);r.pos=R.vector(500,500,500);r.advance(650);assert(r.pos.x==1);r.stop()end)
case('active reload no teleport',function(r)r.start();r.advance(600);r.cfg.spawnCoords.x=5;r.start(r.cfg,false);r.advance(20);assert(r.pos.x==1);r.stop()end)
case('active reload forced teleport',function(r)r.start();r.advance(600);r.cfg.spawnCoords.x=5;r.start(r.cfg,true);r.advance(600);assert(r.pos.x==5);r.stop()end)
case('removed callback',function(r)r.cb('clientRemoved',r.cfg);r.advance(650);assert(r.state.active);r.stop()end)
for _,enabled in ipairs({false,true})do
    case('updated active '..tostring(enabled),function(r)r.start();r.advance(600);r.cfg.enabled=enabled;r.cb('clientConfigUpdated',r.cfg);r.advance(20);assert(r.state.active==enabled);r.stop()end)
end
case('added inactive',function(r)r.cb('clientAdded');r.advance(10);assert(not r.state.active)end)
case('added active',function(r)r.start();r.advance(600);r.cb('clientAdded');r.advance(600);assert(not r.state.active and r.pos.x==9);r.stop()end)
case('updated idle schedules',function(r)r.cb('clientConfigUpdated',r.cfg);r.advance(3200);assert(r.state.active);r.stop()end)
print('PASS access client runtime differentials '..count)
