local V=dofile('tests/kernel_legacy_harness.lua')
local H,P,count=V.H,V.P,0
local function test(name,action)
    local a,b=V.client(false),V.client(true)
    H.same(P.snapshot(table.pack(action(b))),P.snapshot(table.pack(action(a))),name..': returns')
    H.same(b.trace,a.trace,name..': calls');count=count+1
end
for _,text in ipairs({'simple',{text='Title',caption='Body'}, {},{text='Title'}}) do
    test('notify '..tostring(text),function(r) return r.api.Notify(text) end)
end
test('notify all fields',function(r) return r.api.Notify('Title','error',900,'Body','top',{color='red'},'car','#fff') end)
test('notify nil',function(r) return r.api.Notify() end)
test('notify subtitle',function(r) return r.api.Notify('Title',nil,nil,'Body') end)
test('data same reference',function(r) assert(r.api.GetPlayerData()==r.core.PlayerData);return r.api.GetPlayerData() end)
test('data replacement',function(r) local data={citizenid='B'};r.core.PlayerData=data;assert(r.api.GetPlayerData()==data);return r.api.GetPlayerData() end)
test('nil data',function(r) r.core.PlayerData=nil;return r.api.GetPlayerData() end)
for _,filter in ipairs({'taxi','police','none','missing',{'police','missing'},{taxi=1},{taxi=2},{police=2},{},42}) do
    for _,method in ipairs({'HasPrimaryGroup','HasGroup'}) do test(method..'/'..tostring(filter),function(r) return r.api[method](filter) end) end
end
test('nil filter',function(r) return r.api.HasPrimaryGroup(nil),r.api.HasGroup(nil) end)
test('all groups',function(r) return r.api.GetGroups() end)
test('empty player data retains legacy failures',function(r)
    r.core.PlayerData={}
    return pcall(r.api.GetGroups) and true or false,
        pcall(r.api.HasGroup,'taxi') and true or false,
        pcall(r.api.HasPrimaryGroup,'taxi') and true or false
end)
assert(count==33,'Unexpected query count: '..count)
print('PASS client queries: '..count..' differential cases; five APIs, notification payload fields, canonical references and real local membership filters')
