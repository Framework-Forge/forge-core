local O=dofile('tests/kernel_inventory_operations_harness.lua');local H=O.H;local count=0
local function state(rows)local out=H.copy(rows);for _,row in pairs(out)do row.syncSlotsWithClients=nil end;return out end
local cases={{1,2,500},{1,0,0},{1,-1,2},{1,2,-1},{1,math.huge,2},{1,2,0/0},{999,1,2},{1,'2.9','12.9'}}
for _,args in ipairs(cases)do
    local r,direct=O.new(),O.limits();r.mountOperations();assert(r.ops.Open())
    direct.seed(1);H.same(table.pack(r.ops.Raw.ApplyPlayerInventoryBonus(table.unpack(args))),
        table.pack(direct.exported.ApplyPlayerInventoryBonus(table.unpack(args))),'installed bonus exact returns')
    H.same(state(r.capacity.rows),state(direct.rows),'installed capacity state');H.same(r.capacity.events,direct.events,'installed capacity events');count=count+1
end
local r=O.new();r.mountOperations();assert(r.ops.Open())
local row=r.capacity.seed(1,{[5]={name='burger',count=1,slot=5}});row.slots=8
assert(r.ops.Raw.ApplyPlayerInventoryBonus(1,0,0));assert(row.items[1].name=='burger'and row.items[1].slot==1 and row.slots==4,'installed overflow relocation preserved')
row.items={};for slot=1,5 do row.items[slot]={name='burger',slot=slot,count=1}end;row.slots=8
local ok,reason,details=r.ops.Raw.ApplyPlayerInventoryBonus(1,0,900)
assert(ok==false and reason=='slot_limit_below_item_count'and details.weightUpdated==true,'installed partial failure details preserved')
assert(row.slots==8 and row.maxWeight==1900 and row.items[5],'failed slot reduction still changes weight; no invented rollback')
assert(select('#',r.ops.Raw.ClearInventory(999))==0,'installed raw clear invalid inventory remains unacknowledged')
assert(r.ops.Raw.ClearInventory(1)~=false and next(r.clear.records[1].items)==nil,'installed raw Clear body executed')
assert(count==8)
print('PASS lot63 installed OX limit block:8 cases, defaults+extras/nonfinite/invalid player, overflow relocation and partial slot-failure weight update;installed Clear body via PR, no real item/SQL effect')
