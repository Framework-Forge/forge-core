local T=dofile('tests/kernel_forge_adapter_harness.lua');local L=dofile('tests/kernel_client_locale_harness.lua')
local client=L.new();client.prepareLocale();local core=client.fixture.state
local r=T.new(true);core.PlayerData=T.data();core.IsLoggedIn=false
r.ports.readSessionReady=core.Session.isLoaded
-- Recreate with the same actual canonical readiness port, never a QBX export or another authority.
r.api=T.H.load(T.path,T.H.environment())(r.ports);r.framework=r.api.Framework
r.events={};for _,d in ipairs(r.api.Events)do r.events[d.name]=d end
r.cached=core.PlayerData;r.emit('QBCore:Player:SetPlayerData',core.PlayerData)
assert(r.framework.IsPlayerLoaded()and not r.framework.IsSessionReady(),'authenticated character precedes world-ready')
core.IsLoggedIn=true;assert(r.framework.IsSessionReady())
assert(r.framework.GetPlayerData()==core.PlayerData and r.framework.GetPlayer().fullName=='Ana Forge')
r.session={authenticated=false};assert(not r.framework.IsPlayerLoaded()and next(r.framework.GetPlayerData())==nil)
assert(core.PlayerData.citizenid=='A80','passive cache refusal does not clear core')
r.api.Close();assert(r.api.Progress().complete and core.PlayerData.citizenid=='A80')
client.api.Stop();client.clock.advance(120000);client.api.Poll();assert(client.api.Progress().complete)
print('PASS lot80 actual75:PR snapshot complete/reduced views,canonical Session.isLoaded/auth-before-world-ready,passive unauthenticated refusal/no core reset,owned Close;all effects virtual')
