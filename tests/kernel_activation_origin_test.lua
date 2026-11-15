local req=dofile('tests/kernel_native_foundation_harness.lua').loader()
local caller='qbx_core';local current=true
local native={GetInvokingResource=function()return caller end}
local owner=req('kernel.entry.activation_origin')({running=coroutine.running,getInvokingResource=native.GetInvokingResource,isCurrent=function()return current end})
local p={foundation={native=native},support={native=native},providers={native=native}}
local a=owner.Bind(p);assert(owner.Owns(a));assert(p.foundation.native==native and a.foundation.native~=native)
local invoke=a.providers.native.GetInvokingResource
assert(invoke()=='qbx_core');assert(owner.Origin.Run('shop',invoke)=='shop')
assert(owner.Origin.Run('shop',function()assert(invoke()=='shop');return owner.Origin.Run('admin',invoke)end)=='admin')
assert(invoke()=='qbx_core')
local thread=coroutine.create(function()return owner.Origin.Run('held',function()coroutine.yield('pending');return invoke()end)end)
local ok,value=coroutine.resume(thread);assert(ok and value=='pending'and invoke()=='qbx_core')
assert(not owner.Close()and not owner.Progress().complete)
ok,value=coroutine.resume(thread);assert(ok and value=='held');assert(owner.Close()and owner.Progress().complete)
assert(not owner.Owns(a)and not pcall(owner.Bind,p))
local other=req('kernel.entry.activation_origin')({running=coroutine.running,getInvokingResource=native.GetInvokingResource,isCurrent=function()return true end})
p.support.native={};assert(not pcall(other.Bind,p));assert(other.Close())
print('PASS241 pre-graph origin injection,shared native copy,nested/coroutine isolation,pending drain and mismatched input refusal')
