local T=dofile('tests/kernel_forge_server_adapter_harness.lua');local r=T.new(true)
assert(#r.trace==0,'81 allocation inert');r.hook=function(name)if name=='GetPlayer'then coroutine.yield()end end
local co=coroutine.create(function()assert(not pcall(r.framework.getItemByName,1,'item'))end)
assert(coroutine.resume(co));assert(r.api.Progress().pending>0);r.api.Close();assert(not r.api.Progress().complete)
assert(coroutine.resume(co));assert(r.api.Progress().complete and #r.trace==1,'no new Player.Functions action after closed lookup')
local money=T.new(true);money.hook=function(name)if name=='GetMoney'then coroutine.yield()end end
local cm=coroutine.create(function()assert(not pcall(money.framework.takeMoney,1,20))end)
assert(coroutine.resume(cm));money.api.Close();assert(coroutine.resume(cm));assert(#money.trace==1 and money.api.Progress().complete,'no debit after Close during balance query')
local stale=T.new(true);stale.current=false;assert(stale.framework.GetPlayer(1)==nil and #stale.trace==0);stale.api.Close()
local accepted=T.new(true);accepted.hook=function(name)if name=='AddMoney'then coroutine.yield()end end
local ca=coroutine.create(function()assert(accepted.framework.addPlayerMoney(1,'cash',3))end)
assert(coroutine.resume(ca));accepted.api.Close();assert(coroutine.resume(ca));assert(accepted.api.Progress().complete)
print('PASS lot81 scope:inert factory,owned method/port pending,closed lookup cannot start Player action/debit,stale refusal,accepted mutation may return late;no real money/DB')
