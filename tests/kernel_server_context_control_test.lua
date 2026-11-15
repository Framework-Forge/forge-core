local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader();local ready=false;local phase='prepared';local count=0
local fn=function()count=count+1 end
local f={Side='server',IsCurrent=function()return true end,RegistrationInput={available=fn,prCommand=fn,oxCommand=fn,native={publishExport=fn,RegisterCommand=fn}},
 EngineInputs={Select=function()return{wait=fn,setTimeout=fn}end},Seed={Execution={Bind=function()return{GetResourceState=fn}end}}}
local s={IsCurrent=function()return true end};local v={Database={IsReady=function()return true end}};local rpc={Side='server',Owners={native={},ox={}}}
local a=req('kernel.entry.server_context_control')(f,s,v,{}, {rpc=rpc,config={},services={Progress=function()return{phase=phase}end},
 isReady=function()return ready end,isCurrent=function()return true end,running=coroutine.running,onError=error})
assert(count==0 and not a.isReady());ready=true;assert(not a.isReady());phase='open';assert(a.isReady())
ready=false;assert(not a.isReady());assert(a.callbacks.native==rpc.Owners.native and a.public.rpc==rpc.Owners.ox)
print('PASS206 explicit coordinator/raw/database readiness;owned registration/RPC projected without opening ingress or duplicate owners')
