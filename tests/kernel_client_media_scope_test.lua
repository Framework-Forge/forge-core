local M=dofile('tests/kernel_client_media_harness.lua');local r=M.provider();r.mount();assert(r.api.Open());r.loaded=false
r.waitHook=function()coroutine.yield()end
local result;local co=coroutine.create(function()result=table.pack(r.api.Streaming.requestModel('late',100))end)
assert(coroutine.resume(co));r.api.CloseIngress();assert(r.api.Progress().pending==1)
assert(not pcall(r.api.Streaming.createObject,'new',M.V.vector(0,0,0),{}),'new create denied during drain')
r.loaded=true;assert(coroutine.resume(co));assert(result[1]==true and r.api.Progress().pending==0,'accepted request can complete after ingress closure')
r.exists[7]=true
assert(not pcall(r.api.Streaming.deleteEntity,7),'cleanup cannot be called outside permit')
local cleanup=coroutine.create(function()r.api.DuringCleanup(function()coroutine.yield();assert(r.api.Streaming.deleteEntity(7))end)end)
assert(coroutine.resume(cleanup));assert(r.api.Progress().cleanupWindows==1)
assert(not pcall(r.api.Streaming.deleteEntity,7),'cleanup permit is coroutine-local')
assert(coroutine.resume(cleanup));assert(r.exists[7]==nil and r.api.Progress().cleanupWindows==0)
assert(not pcall(function()r.api.DuringCleanup(function()r.api.Streaming.createPed('new',M.V.vector(0,0,0),0,{})end)end),'cleanup cannot create entities')
r.api.Close();assert(r.api.Progress().complete and not r.api.Open())
local helper=M.helper(true,r);local before=#helper.trace
-- The actual bound native fallback is tested on graph69; raw export refusal alone is caught by lib.
assert(not pcall(r.api.Native.GetSoundId)and #helper.trace==before,'closed native audio refuses fallback effects')
print('PASS lot69 client scope:late request accounting,no new creates,coroutine-local delete/release permit,zero create privilege during cleanup,closed native fallback')
