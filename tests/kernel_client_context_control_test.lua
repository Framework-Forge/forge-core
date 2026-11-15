local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local current,ready,phase,rpcReady=true,false,'allocated',true
local function fn()end
local reg={available=fn,prCommand=fn,oxCommand=fn,native={publishExport=fn,RegisterCommand=fn}}
local f={Side='client',IsCurrent=function()return current end,RegistrationInput=reg}
local s={IsCurrent=function()return current end};local rpc={Side='client',Owners={}}
for _,name in ipairs({'native','ox'})do rpc.Owners[name]={IsReady=function()return rpcReady end}end
local p={rpc=rpc,services={Progress=function()return{phase=phase}end},isReady=function()return ready end,isCurrent=function()return current end,running=coroutine.running,onError=error}
local out=req('kernel.entry.client_context_control')(f,s,p)
assert(not out.isReady());ready=true;assert(not out.isReady());phase='open';assert(out.isReady())
rpcReady=false;assert(not out.isReady());rpcReady=true;current=false;assert(not out.isReady())
assert(out.public.rpc==rpc.Owners.ox and out.callbacks.native==rpc.Owners.native and out.public.publishExport==fn)
p.isReady=nil;current=true;assert(not pcall(req('kernel.entry.client_context_control'),f,s,p))
print('PASS216 readiness requires coordinator, raw open and both RPC owners; registration identities borrowed')
