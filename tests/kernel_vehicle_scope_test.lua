local V=dofile('tests/kernel_vehicle_integration_harness.lua')
local r=V.new();r.mount();assert(r.api.Open());r.sqlHook=function()coroutine.yield()end
local outcome;local co=coroutine.create(function()outcome=r.api.Pr.buyOriginalKey(2,'LATE')end)
assert(coroutine.resume(co));r.api.Close();assert(r.api.Progress().pending==1 and not r.api.Progress().complete)
assert(r.api.Pr.buyOriginalKey(2,'OTHER')==nil and #r.sql==1,'closed scope never starts second purchase')
assert(coroutine.resume(co));assert(outcome.success and #r.items==1 and r.api.Progress().complete,'accepted key purchase finishes after Close without rollback')
local stale=V.new();stale.mount();assert(stale.api.Open());stale.current=false
assert(stale.api.Pr.giveTempKey(2,'STALE')==nil and #stale.calls==0,'old owner cannot give keys')
assert(stale.api.Integration.registerExistingPersistentVehicle(-1,'STALE',1)==nil and #stale.messages==0)
local fail=V.new();fail.mount();assert(fail.api.Open());fail.itemError=true
assert(not pcall(fail.api.Pr.buyOriginalKey,2,'PARTIAL')and fail.cache.KEY1 and #fail.sql==1,'item exception preserves installed partial key record')
fail.api.Close();assert(fail.api.Progress().complete and not fail.api.Open(),'closed scope cannot reopen')
local delivery=V.new();delivery.mount();assert(delivery.api.Open());delivery.sendHook=function()coroutine.yield()end
local send=coroutine.create(function()delivery.api.Integration.registerExistingPersistentVehicle(-1,'TEST',501)end)
assert(coroutine.resume(send));delivery.api.Close();assert(delivery.api.Progress().pending==1)
assert(coroutine.resume(send));assert(delivery.api.Progress().complete and #delivery.messages==1,'drain tracks send not client reception')
print('PASS lot65 owned keys:pending purchase/send,revocation,stale owner,installed partial record on item exception,no replay/rollback/receipt guarantee')
