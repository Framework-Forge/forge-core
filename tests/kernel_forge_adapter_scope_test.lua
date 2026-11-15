local T=dofile('tests/kernel_forge_adapter_harness.lua');local r=T.new(true)
assert(r.pulls==0 and #r.trace==0,'factory never pulls startup data')
r.cached=T.data();r.cacheHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(not pcall(r.framework.GetPlayerData))end)
assert(coroutine.resume(co));assert(r.api.Progress().pending==1);r.api.Close();assert(not r.api.Progress().complete)
assert(coroutine.resume(co));assert(r.api.Progress().complete,'accepted cache await unwinds without next read')
local old=r.view.PlayerData;r.emit('QBCore:Player:SetPlayerData',T.data());assert(r.view.PlayerData==old)
assert(r.framework.GetPlayerData()==nil and r.framework.toggleOutfit(false,{})==nil)
local stale=T.new(true);stale.current=false;assert(stale.framework.IsSessionReady()==nil)
stale.emit('QBCore:Client:SetDuty',true);assert(stale.view.PlayerData.job==nil);stale.api.Close()
local ready=T.new(true);ready.readyHook=function()coroutine.yield();return end;ready.ready=true
local cr=coroutine.create(function()assert(ready.framework.IsSessionReady()==true)end)
assert(coroutine.resume(cr));ready.api.Close();assert(not ready.api.Progress().complete);assert(coroutine.resume(cr));assert(ready.api.Progress().complete)
print('PASS lot80 scope:no startup pull,closed/stale event/method refusal,pending cache/readiness drain,accepted result not rolled back,no next read after Close;virtual only')
