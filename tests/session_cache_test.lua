local H=dofile('tests/cache_harness.lua')
local c=H.new(false);local e=c.env
e.ForgeCore.State={copy=H.copy}
e.exports.qbx_core={GetPlayerData=function() return {} end}
e.pr_lib.framework=c.load(H.bridge..'bridge/frameworks/qbx/client.lua')
c.load('shared/session.lua');local S=e.ForgeCore.Session
assert(not S.isLoaded())
local changes=0;e.AddEventHandler('forge-core:session:changed',function() changes=changes+1 end)
local function data(citizen,job,gang)
    return {citizenid=citizen,job=job or {name='police',grade={level=2}},gang=gang or {name='lost',grade=1}}
end
c.fire('QBCore:Player:SetPlayerData',65535,data('A'));c.fire('pr_bridge:client:OnPlayerLoaded')
assert(S.isLoaded() and S.character()=='A' and S.group('job').grade.level==2)
c.fire('QBCore:Client:OnJobUpdate',65535,{name='taxi',grade=0,onduty=true});c.advance(0)
assert(S.group('job').name=='taxi' and S.group('job').grade==0)
c.fire('QBCore:Client:OnGangUpdate',65535,{name='ballas',grade={level=3}});c.advance(0);assert(S.group('gang').name=='ballas')
c.fire('QBCore:Client:SetDuty',65535,false);c.advance(0);assert(S.group('job').onduty==false)
assert(changes==1,'Duty and group edits must not reset the character lifecycle')
c.fire('QBCore:Player:SetPlayerData',65535,data('B'));c.fire('pr_bridge:client:OnInventoryChanged');c.advance(0)
assert(S.character()=='B' and changes==2)
c.fire('QBCore:Client:OnPlayerUnload',65535);c.fire('pr_bridge:client:OnPlayerUnloaded')
assert(not S.isLoaded() and not S.group('job') and not S.character())
c.fire('QBCore:Client:OnJobUpdate',65535,{name='police',grade=0});c.advance(0)
assert(not S.isLoaded(),'Partial delayed job data cannot resurrect a logged-out session')
local server=H.new(true);server.env.ForgeCore.State={copy=H.copy};server.players[1]={PlayerData={citizenid='A'}}
server.load('shared/session.lua');local SS=server.env.ForgeCore.Session
assert(SS.isLoaded(1) and SS.character(1)=='A')
server.fire('pr_bridge:server:OnPlayerUnloaded',nil,1);assert(not SS.isLoaded(1))
server.players[1]={PlayerData={citizenid='B'}};server.fire('pr_bridge:server:OnPlayerLoaded',nil,1)
assert(SS.character(1)=='B');server.fire('playerDropped',1);server.players[1]=nil;assert(not SS.isLoaded(1))
print('PASS session: real QBX data, load/unload, character binding, job/gang/duty updates, late partial data, source reuse and invalidation')
