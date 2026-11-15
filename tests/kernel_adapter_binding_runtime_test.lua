local T=dofile('tests/kernel_adapter_binding_harness.lua');local B=dofile('tests/kernel_framework_backend_harness.lua')
local core=B.new();core.start();local pc=core.graph.PlayerCore
pc.Players.CheckPlayerData(2,{citizenid='BIND83',license='license:test',userId=101,money={cash=5,bank=0}})
local r=T.new('server');r.ports.adapter.core=core.backend.Core;r.ports.backend=core.backend
r.mount();r.api.Install();local framework=r.target.framework
assert(framework.GetPlayer(2)==pc.Lookup.GetPlayer(2));assert(framework.addPlayerMoney(2,'cash',3,'binding83'))
assert(framework.getPlayerMoney(2,'cash')==8)
framework.RegisterCallback('forge83:actual',function(source)return framework.GetIdentifier(source)end)
assert(r.wire.server.find('forge83:actual'))
assert(r.wire.client.api.native.await('forge83:actual',5000)=='BIND83','installed PR wire reaches canonical Player through adapter81/backend82')
assert(r.api.Close()and r.api.Progress().complete and core.backend.Progress().complete)
assert(framework.GetPlayer(2)==nil and pc.Lookup.GetPlayer(2).PlayerData.money.cash==8,'consumer Close leaves canonical player intact')
core.close();assert(core.api.Progress().complete)
print('PASS lot83 actual74/81/82:installed opt-in PR surface reaches same canonical Player/money,owned native callback,consumer Close retires backend only,core player retained;SQL/events/providers virtual')
