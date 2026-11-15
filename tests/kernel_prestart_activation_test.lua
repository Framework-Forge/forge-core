local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local H=N.H
local T=dofile('tests/kernel_pr_native_api_harness.lua');local r=T.new('server');r.nativeAPI.Close()
local holdClose=true
local control=H.load('../pr_bridge/bridge/frameworks/forge/activation_consumer_control.lua',H.environment())({
 native=r.bindingPorts.native,generation='assembly238',instance='238',isCurrent=r.api.IsCurrent,
 createProxy=r.makeProxy,createBindings=function(api)r.bindingPorts.api=api;return r.makeBindings()end,
 claim=function(...)return assert(r.surface.exports.ForgePrConsumerState)(...)end})
local close=control.Close;control.Close=function()if holdClose then return false end;return close()end
local cp='prepared';local compat={Graph=r.graph,Origin=r.origin,GetCoreObject=r.boundAPI.getCoreObject,
 IsCurrent=function()return cp~='closed'and r.api.IsCurrent()end,IsReady=function()return cp=='installed'end,
 Install=function()cp='installed';return true end,Close=function()cp='closed';return true end,
 Progress=function()return{phase=cp,complete=cp=='closed'}end}
local candidate,assembly;local facts={};local external={}
for _,name in ipairs({'oxHooks','catalogs','banking','keys','decisions','environment'})do
 facts[name]=true;external[name]=function()return facts[name]end
end
facts.environment=false;facts.oxHooks=false
assembly=req('kernel.entry.activation_assembly_v2')({side='server',generation='assembly238',isCurrent=r.api.IsCurrent,
 getCandidate=function()return candidate end,external=external,consumers={{name=r.boundResource,control=control}},
 createCompatibility=function()return compat end,getInvokingResource=function()return r.nativeCaller end,
 loadPR=function(path)return H.load('../pr_bridge/'..path,H.environment())end})
local seed={};local phase='allocated';local rawPhase='allocated';local starts,stops,prepares,installs=0,0,0,0
local entry={IsCurrent=r.api.IsCurrent,Foundation={Seed=seed},Profile={Seed=seed},Bootstrap={Graph=r.graph,Transport=r.api.Transport,Progress=function()return{phase='installed'}end}}
local raw={Services={Progress=function()return{phase=rawPhase}end}}
local base={Inspect=function()return{accepted=true}end,Progress=function()return{phase=phase,complete=phase=='closed'}end,
 Prepare=function()prepares=prepares+1;phase='prepared';return true end,
 Install=function()installs=installs+1;rawPhase='open';phase='installed';return true end,
 Start=function()starts=starts+1;phase='running';return true end,
 Stop=function()stops=stops+1;phase='closed';rawPhase='closed';return true end,
 Poll=function()return phase=='closed'end,
 GetPreparedEntry=function()return phase~='allocated'and phase~='closed'and entry or nil end,
 GetPreparedRaw=function()return phase~='allocated'and phase~='closed'and raw or nil end,
 GetPreparedBarrier=function()return assembly.Barrier end}
local env=H.environment({require=function(name)if name=='kernel.entry.owned_boot_preparation_v2'then return function()return base end end;return req(name)end})
candidate=H.load('kernel/entry/coordinated_boot_preparation_v5.lua',env)({inspectFunction=function(fn)return debug.getinfo(fn,'S')end,
 providers={constructionApproved=true,installApproved=true,startApproved=true,activation=assembly.Plan}})
assert(not candidate.StartPreparedCore());assert(not candidate.Poll()and phase=='allocated')
assert(not candidate.Activate());assert(assembly.Barrier.Progress().stage==5 and starts==0)
assert(prepares==1 and installs==1 and assembly.Consumers.IsAttached())
facts.environment=true;facts.decisions=false;assert(not candidate.Activate()and starts==0)
facts.decisions=true;assert(not candidate.Activate());assert(starts==1 and not assembly.Barrier.IsIngressOpen())
assert(not candidate.Start()and not candidate.StartPreparedCore());assert(prepares==1 and installs==1)
facts.oxHooks=true;assert(candidate.Activate());assert(starts==1 and prepares==1 and installs==1)
assert(r.pr.forgeNormalizedFacade.GetIdentifier(2)=='LATE114')
assert(not candidate.Poll()and phase=='running'and assembly.Barrier.IsIngressOpen())
assert(not candidate.Stop()and stops==0 and rawPhase=='open')
assert(not candidate.Poll()and stops==0 and rawPhase=='open')
holdClose=false;assert(candidate.Poll()and stops==1);assert(candidate.Poll()and stops==1)
assert(assembly.Publication.Progress().complete and assembly.Consumers.Progress().complete and assembly.Readiness.Progress().complete)
r.nativeAPI={Close=function()return true end};r.finish()
--Before D/E/F have started, action A still owns allocated child closures.
local closed={};local function child(name)
 return{Close=function()closed[name]=true;return true end,Progress=function()return{complete=closed[name]==true}end}
end
local stopped=0;local c={Prepare=function()return false,'partial-prepare'end,ClosePreparedCore=function()stopped=stopped+1;return true end}
local b={Progress=function()return{generation='partial238'}end}
local plan=req('kernel.entry.owned_activation_plan_v2')({barrier=b,generation='partial238',
 publication=child('pub'),consumers=child('consumers'),readiness=child('readiness')})
assert(not plan.steps[1].run(b,'partial238',c));assert(plan.steps[1].close())
assert(closed.pub and closed.consumers and closed.readiness and stopped==1)
print('PASS248 prestart decisions/environment block startup;warm Start once behind closed ingress;poststart OX probe retry;commit no duplicate;pending cleanup preserved')

local seed2={};local e={IsCurrent=function()return true end,Foundation={Seed=seed2},Profile={Seed=seed2}}
local c2={GetPreparedEntry=function()return e end,GetPreparedRaw=function()return{}end}
local ext={};for _,name in ipairs({'oxHooks','catalogs','banking','keys','decisions','environment'})do ext[name]=function()return true end end
ext.environment=function()coroutine.yield('preflight-pending');return true end
local check=req('kernel.entry.activation_readiness_v2')({generation='pending248',getCandidate=function()return c2 end,external=ext,publication={},consumers={}})
local task=coroutine.create(check.PreStart);local ok,value=coroutine.resume(task);assert(ok and value=='preflight-pending')
assert(not check.Close());ok,value=coroutine.resume(task);assert(ok and value==false);assert(check.Close())
