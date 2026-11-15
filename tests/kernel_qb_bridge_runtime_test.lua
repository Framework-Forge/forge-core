local T=dofile('tests/kernel_qb_bridge_harness.lua');local H=T.H
local r=T.runtime();local graph=r.graph;local pc=graph.PlayerCore
pc.Players.CheckPlayerData(2,{citizenid='BRIDGE89',license='license:test',userId=101,money={cash=5,bank=0}})
local object=r.qb.GetCoreObject();local player=pc.Lookup.GetPlayer(2)
assert(object.Players==pc.State.Players and object.Functions.GetPlayer(2)==player)
assert(r.framework.GetPlayer(2)==player,'PR81 and native QB must resolve the same canonical player')
assert(object.Player_Buckets==pc.State.Player_Buckets and object.Entity_Buckets==pc.State.Entity_Buckets and object.UsableItems==pc.State.UsableItems)
assert(object.Shared.Jobs==pc.Groups.GetJobs()and object.Shared.Gangs==pc.Groups.GetGangs())
assert(object.Shared.Vehicles==pc.Shared.Vehicles and object.Shared.Weapons==pc.Shared.Weapons and pc.Shared.Items==nil)
assert(object.Functions.GetPlayerByCitizenId('BRIDGE89')==player)
local players=object.Functions.GetQBPlayers();assert(players~=pc.State.Players and players[2]==player)
assert(object.Player.GetOfflinePlayer==object.Player.GetOfflinePlayer and object.Functions.GetPlayer(2).Functions.AddMoney('cash',3,'qb-test'))
assert(player.PlayerData.money.cash==8)
assert(object.Functions.AddJob('qb89job',{label='QB89',grades={[0]={name='Entry',payment=0}}}))
assert(pc.Groups.GetJob('qb89job')==object.Shared.Jobs.qb89job)
assert(object.Config.defaultSpawn==r.qbBackend.Config.Shared.defaultSpawn or type(object.Config.defaultSpawn)=='table')
-- Every backend method has a path to this graph; no QBX resource receiver is available in this harness.
local paths=r.qbBackend.Describe();local count=0
for name,path in pairs(paths)do local v=pc;for key in path:gmatch('[^.]+')do v=assert(v[key])end;assert(type(v)=='function'and type(r.qbBackend.Core[name])=='function');count=count+1 end
assert(count==39,'backend service coverage')
local routing=H.load('../pr_bridge/bridge/frameworks/forge/routing_factory.lua',H.environment())({active={frameworks='forge'},config={},contracts={qb=true},
    isCurrent=function()return r.current end,readDeclarations=function()return{'forge'}end})
local host=H.load('../pr_bridge/bridge/frameworks/forge/native_host_factory.lua',H.environment())({resourceName='forge-core',
    isCurrent=function()return r.qb.IsCurrent()end,isReady=function()return true end,getNativeOwner=function()return'forge-core'end,
    getBridgeSetting=function()return'true'end,contracts={qb=true},routing=routing,getCoreObject=r.qb.GetCoreObject})
assert(host.GetCoreObject()==object and host.GetCoreObject({'Functions'})==object)
assert(host.Exports.getQBCoreObject().Functions.GetPlayer(2)==player)
-- Replacing a canonical service invalidates the prepared backend, not the actual player graph.
local old=pc.Lookup.GetPlayer;pc.Lookup.GetPlayer=function()error('foreign')end
assert(not r.qbBackend.IsCurrent()and not pcall(host.GetCoreObject))
pc.Lookup.GetPlayer=old
host.Close();routing.Close();r.qb.Close()
assert(pc.Lookup.GetPlayer(2)==player and r.qb.Progress().complete and r.qbBackend.Progress().complete)
r.close();assert(r.api.Progress().complete)
-- Await/canonical replacement in backend readiness must prevent service invocation.
local x=T.runtime();x.qbReadyHook=function()coroutine.yield('backend-ready')end
local co=coroutine.create(function()return x.qbBackend.Core.GetPlayer(2)end);assert(coroutine.resume(co))
assert(x.qbBackend.Progress().pending==1);x.qbBackend.Close();assert(not x.qbBackend.Progress().complete)
x.qbReadyHook=nil;local ok=coroutine.resume(co);assert(not ok and x.qbBackend.Progress().complete)
x.qb.Close();x.close()
print('PASS lot89 actual74/87/88/86:39 canonical backend services,same Player/Shared/config/groups/money,getter+native host,owned Close/stale service/readiness await;no QBX receiver/second authority/real IO')
