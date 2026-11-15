local T=dofile('tests/kernel_consumer_context_harness.lua')
local r=T.new();r.mount();r.getHook=function()assert(r.target.QBX==r.api.View);coroutine.yield()end
local co=coroutine.create(function()assert(not pcall(r.api.Require,'modules.playerdata'))end)
assert(coroutine.resume(co));assert(r.api.Progress().pending==1);r.api.Close()
assert(r.target.QBX==r.oldQBX and not r.api.Progress().complete);assert(coroutine.resume(co));assert(r.api.Progress().complete and r.active()==0)
local failure=T.new();failure.mount();failure.getHook=function()error('getter failed',0)end
assert(not pcall(failure.api.Require,'modules.playerdata')and failure.target.QBX==failure.api.View,'published empty view retained on initial getter error')
assert(not pcall(failure.api.Require,'modules.playerdata')and failure.gets==1);failure.api.Close();assert(failure.target.QBX==failure.oldQBX)
local mark=T.new();mark.mount();mark.markHook=function()coroutine.yield()end
local cm=coroutine.create(function()assert(not pcall(mark.api.Require,'modules.playerdata'))end)
assert(coroutine.resume(cm));mark.api.Close();assert(not mark.api.Progress().complete)
assert(coroutine.resume(cm));assert(mark.active()==0,'no new listen after closed network mark');mark.api.Close();assert(mark.api.Progress().complete)
local late=T.new();late.mount();late.listenHook=function()coroutine.yield()end
local cl=coroutine.create(function()assert(not pcall(late.api.Require,'modules.playerdata'))end)
assert(coroutine.resume(cl));late.api.Close();assert(coroutine.resume(cl));late.api.Close()
assert(late.active()==0 and late.api.Progress().complete,'late known token removed and not reopened')
local remove=T.new();remove.mount();remove.api.Require('modules.playerdata');local held=remove.target.QBX
remove.refuseRemove=true;assert(not remove.api.Close()and not remove.api.Progress().complete)
remove.emit('QBCore:Player:SetPlayerData',{citizenid='CLOSED'});assert(held.PlayerData.citizenid=='A','residual callbacks revoked before physical removal')
remove.refuseRemove=false;assert(remove.api.Close()and remove.api.Progress().complete)
local stale=T.new();stale.mount();stale.api.Require('modules.playerdata');stale.current=false
stale.emit('QBCore:Client:OnPlayerUnload');assert(stale.target.QBX.PlayerData.citizenid=='A')
assert(not pcall(stale.api.Require,'modules.utils'));stale.api.Close()
print('PASS lot77 scope:pending getter/mark/listen cancellation,legacy partial error/no replay,late token cleanup,refused removal diagnostic/retry,stale owner,retained aliases;no real events')
