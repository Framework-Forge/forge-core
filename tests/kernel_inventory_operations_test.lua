local O=dofile('tests/kernel_inventory_operations_harness.lua');local H=O.H;local r=O.new();r.mountOperations()
assert(#r.calls==0,'operations constructor inert');assert(r.ops.Raw.AddItem(1,'burger',1)==nil and #r.calls==0)
assert(r.ops.Open());local metadata={serial='same-reference'};local count=0
for _,name in ipairs({'AddItem','RemoveItem','Search','SetDurability','CanCarryItem','SetItem','GetSlot','GetSlotWithItem','GetSlotsWithItem','GetInventory'})do
    r.results[name]=table.pack(true,nil,'reason',nil)
    local before=#r.calls;local result=table.pack(r.ops.Raw[name](1,'burger',2,metadata,nil,8))
    H.same(result,table.pack(r.proxy[name](r.proxy,1,'burger',2,metadata,nil,8)),'raw exact tuple '..name)
    assert(r.calls[before+1].args.n==6 and r.calls[before+1].args[4]==metadata,'raw argument identity '..name)
    count=count+1
end
for name,fn in pairs(r.ops.Public)do
    local args=name=='RegisterShop'and table.pack('shop',{name='Store',items={{name='burger',price=2}}},{x=1})or table.pack(1,'burger',2,metadata)
    if name~='ClearInventory'then r.results[name]=table.pack(false,'failure',nil,9)end
    local expected=table.pack(r.library[name](table.unpack(args,1,args.n)))
    H.same(table.pack(fn(table.unpack(args,1,args.n))),expected,'installed PR public contract '..name)
    count=count+1
end
r.results.RemoveItem=table.pack(false,'missing',nil,3)
local raw=table.pack(r.ops.Raw.RemoveItem(1,'burger',1));local public=table.pack(r.ops.Public.RemoveItem(1,'burger',1))
assert(raw.n==4 and raw[2]=='missing'and public.n==1 and public[1]==false,'raw and public RemoveItem are intentionally distinct')
assert(select('#',r.ops.Raw.ClearInventory(999))==0,'installed Clear has no invalid-inventory acknowledgement')
r.clearFalse=true
assert(r.ops.Raw.ClearInventory(999)==false and select('#',r.ops.Public.ClearInventory(999))==0,'raw clear failure is not lost')
r.clearFalse=false
r.results.Search=nil;r.ops.Raw.searchCountRaw(1,'burger');assert(r.calls[#r.calls].args[2]=='count')
r.ops.Raw.searchSlotsRaw(1,'hammer');assert(r.calls[#r.calls].args[2]=='slots')
r.files['data/shops.lua']='return {}';assert(r.ops.ReadShopFile('data/shops.lua')=='return {}')
r.operationState='starting';assert(r.ops.ResourceState()=='starting'and not r.ops.IsReady())
r.results.AddItem=nil
assert(r.ops.Raw.AddItem(1,'burger',1),'consumer starting policy not silently replaced')
r.results.AddItem='throw';assert(not pcall(r.ops.Raw.AddItem,1,'burger',1));assert(r.ops.Progress().pending==0)
r.results.AddItem=nil;r.onCall=function(name)if name=='AddItem'then coroutine.yield()end end
local co=coroutine.create(function()r.ops.Raw.AddItem(1,'burger',1)end);assert(coroutine.resume(co));r.ops.Close()
assert(not r.ops.Progress().complete and r.ops.Progress().pending==1,'Close waits for entered raw await');assert(coroutine.resume(co));assert(r.ops.Progress().complete)
local before=#r.calls;assert(r.ops.Raw.SetItem(1,'money',5)==nil and #r.calls==before,'closed scope cannot write inventory')
for _,mode in ipairs({'starting','wrong_owner','stale'})do local bad=O.new();bad.mountOperations()
    if mode=='starting'then bad.operationState='starting'elseif mode=='wrong_owner'then bad.executing='pr_bridge'else bad.current=false end
    assert(not bad.ops.Open()and #bad.calls==0,'readiness refusal '..mode)
end
assert(count==26)
print('PASS lot63 operations:26 raw/public contract cases, nil tuples/metadata identity/receiver, actual PR return differences, three refusals, state policy, raw await and inert closure;providers virtual')
