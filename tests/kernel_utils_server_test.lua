local V=dofile('tests/kernel_legacy_harness.lua')
local count=0
local function test(name,action) V.compare('server',name,action);count=count+1 end
for _,model in ipairs({'car',103}) do
    for _,warp in ipairs({true,false}) do test('spawn '..model..tostring(warp),function(r)
        return r.api.SpawnVehicle(1,model,nil,warp,{plate='ABC'})
    end) end
end
test('spawn coords',function(r) return r.api.SpawnVehicle(1,'car',V.vector(4,5,6,70),true) end)
for _,license in ipairs({'license:A','license2:A','license:B','missing'}) do test('license '..license,function(r) return r.api.IsLicenseInUse(license) end) end
for _,item in ipairs({'one','many'}) do
    for _,amount in ipairs({false,1,5,6}) do test('item '..item..tostring(amount),function(r)
        r.searchResult=item=='one' and 5 or {a=5,b=5}
        return r.api.HasItem(1,item=='one' and 'a' or {'a','b'},amount or nil)
    end) end
end
test('list partial',function(r) r.searchResult={a=5,b=0};return r.api.HasItem(1,{'a','b'},1) end)
test('list empty retains true',function(r) r.searchResult={};return r.api.HasItem(1,{},1) end)
test('nil count retains error',function(r) r.searchResult=nil;return pcall(r.api.HasItem,1,'a') and true or false end)
for _,deferrals in ipairs({true,false}) do test('kick '..tostring(deferrals),function(r)
    local d=deferrals and {update=function(...) r.record('deferral',...) end} or nil
    r.api.KickWithReason(1,'reason',function(...) r.record('reason',...) end,d)
    for _=1,8 do if coroutine.status(r.tasks[1])=='dead' then break end;r.step() end
    assert(coroutine.status(r.tasks[1])=='dead')
end) end
test('negative ping bounded steps',function(r)
    r.ping=-1;r.api.KickWithReason(1,'reason')
    r.step();r.step();r.ping=1
    for _=1,8 do if coroutine.status(r.tasks[1])=='dead' then break end;r.step() end
    assert(coroutine.status(r.tasks[1])=='dead')
end)
-- Observe invalid nil-source legacy loop with host-only instruction budget.
test('nil-source loop retained and bounded',function(r)
    r.api.KickWithReason(nil,'reason')
    local co=r.tasks[1]
    debug.sethook(co,function() error('test instruction budget',0) end,'',10000)
    local ok,why=coroutine.resume(co)
    debug.sethook(co)
    assert(not ok and tostring(why):find('test instruction budget',1,true))
    return false
end)
assert(count==24)
print('PASS legacy utils server: '..count..' differential cases; spawn/search/license/kick coroutine effects; invalid loop observed only under test instruction budget')
