local C=dofile('tests/kernel_configuration_harness.lua')
local r=C.new();r.keys.states.pr_carkeys='stopped';r.keys.states.qbx_vehiclekeys='started'
r.qbxHook=function()coroutine.yield()end
local out;local co=coroutine.create(function()out=table.pack(r.config.giveVehicleKeys(2,'TEST',101))end)
assert(coroutine.resume(co));r.api.Close();assert(r.api.Progress().pending==1 and not r.api.Progress().complete)
local n=#r.trace;r.config.setVehicleLock(101,'lock');assert(#r.trace==n,'closed config cannot use native fallback')
assert(coroutine.resume(co));assert(out[1]=='ALT'and out[3]==7 and r.api.Progress().complete,'accepted alternate call completes after close without rollback')
local old=C.new();old.current=false;local count=#old.keys.calls
assert(old.config.giveVehicleKeys(2,'STALE',101)==nil and #old.keys.calls==count,'stale config owner cannot grant keys')
assert(old.api.Ports.randomString('A.......')==nil,'stale identifier RNG refused');old.api.Close();assert(not old.api.Open())
local lock=C.new();lock.keys.states.pr_carkeys='stopped';lock.lockHook=function()coroutine.yield()end
local pending=coroutine.create(function()lock.config.setVehicleLock(101,'lock')end)
assert(coroutine.resume(pending));lock.api.Close();assert(lock.api.Progress().pending==1)
assert(coroutine.resume(pending));assert(lock.api.Progress().complete,'accepted native port is tracked not undone')
print('PASS lot66 owned config:pending alternate/native calls,closed native fallback,RNG/stale owner,zero reopen,no rollback of accepted effects')
