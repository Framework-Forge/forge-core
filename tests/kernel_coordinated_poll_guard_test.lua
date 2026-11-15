local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H
local create=req('kernel.entry.coordinated_boot_preparation_v2')
for _,side in ipairs({'server','client'})do
 local c=create({side=side,providers={},inspectFunction=function(fn)return debug.getinfo(fn,'S')end,createRaw=function()error('unexpected raw')end})
 assert(c.Progress().phase=='allocated');assert(not c.Poll()and c.Progress().phase=='allocated')
 assert(c.Stop()and c.Poll()and c.Poll())
end
-- Isolate coordinator lifecycle with a virtual core delegate;barrier/action implementations are real.
local facts={};local probes={};for _,name in ipairs({'allocations','rawProviders','bootstrap','nativeAPI','compatIdentity','consumerBindings','oxHooks','catalogs','banking','keys','decisions','environment'})do
 facts[name]=true;probes[name]=function()return facts[name]end
end
local barrier=req('kernel.entry.activation_barrier')({generation='p232',consumers={'consumer'},probes=probes,isCurrent=function()return true end})
assert(barrier.ConsumerState('p232','consumer','prepared'))
local phase='allocated';local rawPhase='allocated';local stops,polls=0,0;local baseReady=false;local cleanupReady=false
local seed={};local entry={Foundation={Seed=seed},Profile={Seed=seed},Bootstrap={Progress=function()return{phase=phase=='installed'and'installed'or'prepared'}end}}
local raw={Services={Progress=function()return{phase=rawPhase}end}}
local base={Progress=function()return{phase=phase}end,Inspect=function()return{accepted=true}end,
 Prepare=function()phase='prepared';return true end,Install=function()phase='installed';rawPhase='open';return true end,
 GetPreparedEntry=function()return entry end,GetPreparedRaw=function()return raw end,GetPreparedBarrier=function()return barrier end,
 Start=function()phase='running';return true end,Stop=function()stops=stops+1;phase='closing';return false end,
 Poll=function()polls=polls+1;if baseReady then phase='closed';return true end;return false end}
local steps={};for i=1,6 do steps[i]={name=tostring(i),close=function()return i~=6 or cleanupReady end,
 run=function(b,g,c)
  if i==1 then return c.Prepare()elseif i==2 then return c.Install()
  elseif i==5 then assert(b.ConsumerState(g,'consumer','attaching'));assert(b.ConsumerState(g,'consumer','committed'))end
  return true
 end}end
local factory=H.load('kernel/entry/coordinated_boot_preparation_v2.lua',H.environment({require=function(name)
 if name=='kernel.entry.owned_boot_preparation'then return function()return base end end;return req(name)
end}))
local c=factory({providers={constructionApproved=true,installApproved=true,startApproved=true,activation={generation='p232',barrier=barrier,steps=steps}},
 inspectFunction=function()return{source='@native/controlled-virtual.lua'}end})
assert(c.Activate()and phase=='running');assert(not c.Poll()and phase=='running'and barrier.IsIngressOpen())
assert(stops==0 and polls==0);assert(not c.Stop()and not barrier.IsIngressOpen()and stops==0)
assert(not c.Poll()and stops==0);cleanupReady=true;assert(not c.Poll()and stops==1 and phase=='closing')
assert(not c.Poll()and polls==1);baseReady=true;assert(c.Poll()and phase=='closed');local old=polls;assert(c.Poll()and polls==old)
print('PASS232 R230-02 fixed;allocated/running Poll has no effects;pending action cleanup retained;explicit Stop/delayed core Poll/closed idempotence')
