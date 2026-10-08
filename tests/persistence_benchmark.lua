-- CPU microbenchmark, not an FXServer/2,000-connected-player capacity test.
local api = {resource='benchmark'}
dofile('../pr_bridge/bridge/persistence.lua')(api,function(path) return 'benchmark',path end)
local state = {settings={enabled=true},stores={}}
for index=1,100 do
    local store={id=tostring(index),label='Store '..index,stock={},items={},sales={}}
    for item=1,100 do
        store.items[item]={name='item_'..item,price=item,enabled=true,metadata={quality=100}}
        store.stock['item_'..item]=100
    end
    for sale=1,50 do store.sales[sale]={item='water',count=1,total=5,buyer='example'} end
    state.stores[index]=store
end
local claims={claimed={},settings={enabled=true},items={{name='water',count=1}}}
for index=1,2000 do claims.claimed['player_'..index]={at=123,name='Player '..index} end
local function measure(label, iterations, action)
    for _=1,10 do action() end
    collectgarbage('collect')
    local initial=collectgarbage('count');local started=os.clock()
    for _=1,iterations do action() end
    local elapsed=(os.clock()-started)*1000/iterations
    local growth=collectgarbage('count')-initial
    print(('%s: %.4f ms/op; iterations=%d; heap_delta=%.1f KiB (GC enabled)'):format(label,elapsed,iterations,growth))
    return elapsed
end
local full=measure('100 stores x 100 items, full draft',100,function() return api.jsonDraft(state) end)
local selected=measure('100 stores x 100 items, one-store draft',2000,function()
    local draft=api.jsonDraft(state,{stores={[50]=true}});draft.stores[50].stock.water=99;return draft
end)
local claim=measure('2000 private claims, shallow claim-map draft',2000,function()
    local draft=api.jsonDraft(claims,{claimed='shallow'});draft.claimed.new={at=124};return draft
end)
measure('uncontended/reentrant file lock, no I/O',20000,function()
    return api.withJsonLock('data/test.json',function() return true end)
end)
measure('2000 character-id reads, no drafts or writes',100,function()
    local found=0
    for index=1,2000 do if claims.claimed['player_'..index] then found=found+1 end end
    assert(found==2000)
end)
print(('Selective draft is %.1fx faster than full draft in this fixture'):format(full/selected))
assert(selected < full,'selective copying regression')
assert(selected < 5 and claim < 5,'local 5ms guard exceeded; review before rollout')
