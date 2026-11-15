local R=dofile('tests/kernel_starterpack_harness.lua');local n=0
-- Existing full scene test body runs unchanged against BOTH installed source and port.
R.runExistingScene(false);R.runExistingScene(true)
local function case(name,fn,options)R.sceneCase(name,fn,options);n=n+1 end
case('initial timer',function(r,e,s)assert(s.starter.preparationScheduled);r.advance(2499);assert(#s.vehicles==0)end)
case('unconfigured prologue',function(r,e,s)s.payload.prologue.enabled=false;s.start();r.advance(500);assert(not s.starter.vehicle)end)
case('zero start',function(r,e,s)s.payload.prologue.vehicleStart.coords={};s.start();r.advance(500);assert(not s.starter.vehicle)end)
case('no stops',function(r,e,s)s.payload.prologue.stops={};s.start();r.advance(500);s.board();r.advance(100);assert(not s.starter.boarding)end)
case('disabled and zero stops ignored',function(r,e,s)s.payload.prologue.stops={{id='x',enabled=false,coords={x=1}},{id='y',coords={}}};s.start();r.advance(500);s.board();assert(not s.starter.boarding)end)
case('boarding timeout',function(r,e,s)s.start();r.advance(500);e.CreateThread(function()s.starter.preparePrologue()end);r.advance(121000);assert(not s.starter.boarding and s.targets[s.starter.lamar])end)
case('foreign stop ignored',function(r,e,s)s.start();r.advance(500);r.fire('onResourceStop',nil,'other');assert(s.starter.vehicle)end)
case('disabled snapshot removes scene',function(r,e,s)s.start();r.advance(500);s.onChange({prologue={enabled=false}});assert(not s.starter.vehicle and next(s.entities)==nil)end)
case('session change replaces pending generation',function(r,e,s)s.start();r.advance(500);r.fire('forge-core:session:changed',nil,'NEXT');assert(not s.starter.vehicle);r.advance(1501)end)
case('world snapshot during route retained',function(r,e,s)s.start();r.advance(500);s.board();r.advance(350);local old=s.starter.vehicle;s.onChange({prologue={enabled=false}});assert(s.starter.vehicle==old and s.starter.routeActive)end)
case('pending failed reward still completes inherited',function(r,e,s)
 local C=e.PR.Starterpack.Callbacks;s.payload.prologue.stops[1].rewards={{id='r',item='water',enabled=true,progress=0}}
 e.pr_lib.callback.await=function(name)if name==C.grantReward then s.rewardCalls=(s.rewardCalls or 0)+1;return false,'cannot_carry' end;assert(name==C.completePrologue);s.claims=s.claims+1;return false,'save_failed'end
 s.start();r.advance(500);s.board();r.advance(5000);assert(s.rewardCalls==1 and s.claims==1 and not s.starter.routeActive)
end)
local camera={configure=function(r,e,s)
 s.cameras={};s.cameraCalls={};s.keyQueue={}
 e.CreateCam=function(kind)s.cameras[#s.cameras+1]=kind;return #s.cameras end
 e.CreateCamWithParams=e.CreateCam
 for _,key in ipairs({'SetCamCoord','SetCamRot','SetCamFov','SetCamActive','DestroyCam','AddCamSplineNode','SetPauseMenuActive'})do e[key]=function(...)s.cameraCalls[#s.cameraCalls+1]={key,...}end end
 e.GetCamSplinePhase=function()return 1 end;e.GetFrameTime=function()return 1/60 end;e.IsPauseMenuActive=function()return false end
 e.IsDisabledControlPressed=function()return false end
 e.IsDisabledControlJustPressed=function(_,control)if control==s.keyQueue[1]then table.remove(s.keyQueue,1);return true end;return false end
 e.GetEntityHeading=function(id)return id==s.player and 90 or s.entities[id].heading end
 local freeze=e.FreezeEntityPosition;e.FreezeEntityPosition=function(id,value)if id==s.player then s.frozen=value else freeze(id,value)end end
 e.pr_lib.ShowTextUI=function()s.textActive=true end;e.pr_lib.HideTextUI=function()s.textActive=false end
 e.pr_lib.callback.await=function(name,timeout,stop)
  assert(timeout==10000)
  if name==e.PR.Starterpack.Callbacks.setStop then s.savedStop=R.H.copy(stop);return true end
  s.claims=s.claims+1;return true
 end
end}
for _,count in ipairs({1,2})do case('camera frames '..count,function(r,e,s)
 local frames={};for i=1,count do frames[i]={coords={x=i,y=2,z=3},rot={x=0,y=0,z=90},fov=60,duration=300}end
 s.payload.prologue.stops[1].cameraFrames=frames;s.start();r.advance(500);s.board();r.advance(6000)
 assert(s.claims==1 and #s.cameras==1 and not s.starter.playingCam)
end,camera)end
for _,control in ipairs({194,202,322,200})do case('keyframer save or cancel '..control,function(r,e,s)
 s.keyQueue={191,control};s.starter.openStopKeyframer({id='edit',cameraFrames={}});r.advance(3)
 assert(not s.starter.cameraEditor and not s.frozen and not s.textActive)
 if control==194 then assert(not s.savedStop)else assert(s.savedStop and #s.savedStop.cameraFrames==1)end
end,camera)end
case('keyframer clear',function(r,e,s)s.keyQueue={178,202};s.starter.openStopKeyframer({id='edit',cameraFrames={{coords={}}}});r.advance(3);assert(#s.savedStop.cameraFrames==0)end,camera)
case('keyframer stop does not cancel editor inherited',function(r,e,s)
 s.starter.openStopKeyframer({id='edit'});r.fire('onResourceStop',nil,'forge-core');assert(s.starter.cameraEditor)
 s.keyQueue={194};r.advance(2);assert(not s.starter.cameraEditor)
end,camera)
-- Assert inert construction independently of the legacy fixture's explicit initial binding.
local config=R.config(true);local queue,subscriptions,events={},{},{}
local native=setmetatable({},{__index=function()return function()error('unexpected constructor native')end end})
local api=R.H.load('kernel/client/starterpack.lua',R.env())({config={Starterpack=config},library={},native=native,
 world={},session={},translate=function(k)return k end,print=function()end})
assert(#api.Initializers==1 and #api.Subscriptions==1 and #api.Events==4 and #queue==0)
assert(not api.Starterpack.preparationScheduled and api.Starterpack.sceneGeneration==0)
n=n+1
print('PASS starterpack client: '..n..' differential/constructor cases plus the whole installed scene regression body for both implementations; no FiveM rendering/physics/input')
