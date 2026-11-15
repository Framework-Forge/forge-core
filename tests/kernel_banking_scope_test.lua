local B=dofile('tests/kernel_banking_harness.lua')
local r=B.new();r.mount();assert(r.api.Open())
r.exportHook=function(name)if name=='GetJobAccount'then coroutine.yield()end end
local out;local co=coroutine.create(function()out=table.pack(r.api.EnsureJobAccount('late','Late',0))end)
assert(coroutine.resume(co));r.api.Close();assert(r.api.Progress().pending==1 and not r.api.Progress().complete)
assert(coroutine.resume(co));assert(out[1]==nil and r.count('insert')==0 and r.api.Progress().complete,'closed pending lookup cannot create account')
local accepted=B.new();accepted.mount();assert(accepted.api.Open());accepted.dbHook=function(kind)if kind=='insert'then coroutine.yield()end end
local create=coroutine.create(function()assert(accepted.api.EnsureJobAccount('accepted','Accepted',0))end)
assert(coroutine.resume(create));accepted.api.Close();assert(accepted.api.Progress().pending==1)
assert(coroutine.resume(create));assert(accepted.accounts.accepted and accepted.api.Progress().complete,'accepted creation may finish after Close; no rollback')
local stale=B.new();stale.mount();assert(stale.api.Open());stale.current=false
assert(stale.api.EnsureJobAccount('new','New',0)==nil and stale.count('insert')==0,'stale owner cannot write');stale.api.Close()
-- Installed cache-before-insert behavior is not a durability/locking guarantee.
local race=B.new();race.mount();assert(race.api.Open());race.dbFalse='insert'
race.dbHook=function(kind)if kind=='insert'then coroutine.yield()end end
local outcome;local first=coroutine.create(function()outcome=table.pack(pcall(race.api.EnsureJobAccount,'race','Race',0))end)
assert(coroutine.resume(first));local ok,why=race.api.EnsureJobAccount('race','Race',0)
assert(ok and why=='exists','installed transient cache can appear as existing account')
assert(coroutine.resume(first));assert(outcome[1]==false and race.accounts.race==nil,'later failed insert invalidates earlier cache-only existence')
race.api.Close();assert(race.api.Progress().complete)
print('PASS lot64 banking scope:lookup cancellation prevents new CREATE, in-flight create drain without rollback, stale owner, installed transient cache/concurrent false existence characterized')
