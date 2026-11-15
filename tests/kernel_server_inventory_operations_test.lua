local O=dofile('tests/kernel_inventory_operations_harness.lua');local r=O.context();local f=r.fixture;local before=f.snapshot();r.prepareOperations()
O.H.same(f.snapshot(),before,'context63 construction inert');assert(#r.inventory.calls==0 and #r.sqlTrace==0)
assert(r.operationsInstall());assert(#r.inventory.calls==0 and #r.sqlTrace==0,'Install does not mutate inventory or schema')
r.emit('onResourceStart','forge-core');r.begin();assert(#r.sqlTrace==2);r.resume();assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]))
assert(r.api.Progress().phase=='running'and r.graph.PlayerCore==f.base.PlayerCore)
local pc=r.graph.PlayerCore;pc.Players.CheckPlayerData(1,{citizenid='OPS',license='license:test',userId=101,money={cash=10,bank=0}})
local player=assert(pc.Lookup.GetPlayer(1));local metadata={key='value'}
assert(player.Functions.AddItem('burger',2,3,metadata));local call=r.inventory.calls[#r.inventory.calls]
assert(call.name=='AddItem'and call.args[1]==1 and call.args[4]==metadata and call.args[5]==3,'Player legacy inventory uses PR raw before closure capture')
assert(player.Functions.GetItemBySlot(3).name=='burger');assert(player.Functions.ClearInventory()~=false)
local deps=f.base.JobCatalog.Dependencies;assert(deps.VipService.grant(2,1,'gold',1))
r.clock.advance(5000);assert(r.inventory.capacity.rows[1].slots>4,'real VIP worker reaches installed custom OX capacity through PR')
local service=deps.InventoryService
assert(service.upsertItem(2,{name='burger',label='Burger',active=true,interaction={enabled=true,duration=1,remove=1,hunger=10}}))
-- PR's actual local fallback registry is retained; no framework adapter returns to this core.
assert(pc.Lifecycle.Functions.CanUseItem('burger'),'usable registry remains local')
r.api.Stop();r.clock.advance(120000);r.api.Poll();assert(r.api.Progress().complete,'context63 drain includes operations and62')
local n=#r.inventory.calls;assert(player.Functions.AddItem('burger',1)==nil and #r.inventory.calls==n,'legacy closure revoked after Stop')
assert(r.api.Progress().operations.complete and r.api.Progress().inventoryContext.inventory.complete and #r.errors==0)
local fail=O.context();fail.prepareOperations();fail.dbReady=false;assert(not fail.operationsInstall());assert(fail.api.Progress().operations.complete and #fail.inventory.calls==0,'preflight failure closes operations before effect')
local stop=O.context();stop.prepareOperations();assert(stop.operationsInstall());stop.begin();stop.emit('onResourceStop','forge-core');stop.resume();stop.clock.advance(120000);stop.api.Poll()
assert(stop.api.Progress().phase=='closed'and stop.api.Progress().operations.complete,'native stop closes raw operations during startup')
local stale=O.context();stale.prepareOperations();assert(stale.operationsInstall());stale.api.InventoryContext.Startup.Stop()
assert(stale.api.Operations.Raw.SetItem(1,'money',10)==nil and #stale.inventory.calls==0,'closed inner61 refuses inventory operations');stale.api.Stop()
local replaced=O.context();replaced.prepareOperations();assert(replaced.operationsInstall());replaced.fixture.base.Callbacks={}
assert(replaced.api.Operations.Raw.SetItem(1,'money',10)==nil and #replaced.inventory.calls==0,'replaced Security refuses stale raw mutation');replaced.api.Stop()
print('PASS lot63 actual62/61/60/48:Player raw closures, VIP worker/custom capacity, local usable registry, schema/start order, closure/native stop/preflight failure and same authority;SQL/JSON/platform virtual')
