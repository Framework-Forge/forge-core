local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local ready={};local probes={}
for _,name in ipairs({'allocations','rawProviders','bootstrap','nativeAPI','compatIdentity','consumerBindings','oxHooks','catalogs','banking','keys','decisions','environment'})do
 ready[name]=true;probes[name]=function()return ready[name]end
end
local barrier=req('kernel.entry.activation_barrier')({generation='g',isCurrent=function()return true end,probes=probes,consumers={'consumer'}})
assert(barrier.ConsumerState('g','consumer','prepared'))
local runs,closed={},{};local steps={}
for i=1,6 do steps[i]={name=tostring(i),run=function(b,g)runs[i]=(runs[i]or 0)+1
 if i==5 then assert(b.ConsumerState(g,'consumer','attaching'));assert(b.ConsumerState(g,'consumer','committed'))end;return true end,
 close=function()closed[#closed+1]=i;return true end}end
local create=req('kernel.entry.activation_actions')
assert(not pcall(create,{barrier=barrier,generation='g',steps=steps,inspectFunction=function(fn)return debug.getinfo(fn,'S')end}))
local a=create({barrier=barrier,generation='g',steps=steps,inspectFunction=function()return{source='@native/virtual.lua'}end})
assert(a.Advance(1));ready.rawProviders=false;assert(not a.Advance(2)and runs[2]==1)
ready.rawProviders=true;assert(a.Advance(2)and runs[2]==1)
ready.oxHooks=false;assert(not a.Run()and not barrier.IsIngressOpen());assert(runs[6]==1)
ready.oxHooks=true;assert(a.Run()and barrier.IsIngressOpen()and runs[6]==1)
assert(a.Close()and not barrier.IsIngressOpen()and a.Progress().complete)
assert(closed[1]==6 and closed[6]==1 and not a.Advance(1))
print('PASS227 real118 A-F barrier;accepted actions once;pending probes retry;F remains closed on missing OX;reverse cleanup/origin refusal')
