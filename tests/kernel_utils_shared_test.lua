local V = dofile('tests/kernel_legacy_harness.lua')
local H,count = V.H,0
local function test(name,action) V.compare('server',name,action); count=count+1 end
test('coords',function(r) return r.api.GetCoordsFromEntity(20) end)
for _,vehicle in ipairs({false,0,20}) do test('plate '..tostring(vehicle),function(r) return r.api.GetPlate(vehicle or nil) end) end
test('comma',function(r) return r.api.CommaValue(12345) end)
for _,value in ipairs({' a ','','ABC','área'}) do
    test('trim '..value,function(r) return r.api.String.trim(value) end)
    test('uppercase '..value,function(r) return r.api.String.firstToUpper(value) end)
end
test('nil trim',function(r) return r.api.String.trim(nil) end)
test('nil uppercase',function(r) return r.api.String.firstToUpper(nil) end)
for _,value in ipairs({'a,b,c','a,,b',',a,','a'}) do test('split '..value,function(r) return r.api.String.split(value,',') end) end
for _,value in ipairs({-1.5,0,1.234}) do test('round '..value,function(r) return r.api.Math.round(value,2) end) end
for _,name in ipairs({'RandomLetter','RandomNumber','RandomNumberOrLetter'}) do
    for _,length in ipairs({-1,0,1,4}) do test(name..length,function(r) return r.api[name](length) end) end
end
test('random plate',function(r) return r.api.GenerateRandomPlate('aa11') end)
test('nil pattern remains invalid',function(r) return pcall(r.api.GenerateRandomPlate) and true or false end)
test('map order',function(r) return r.api.MapTableBySubfield('a',{{a='x'},{a='x'},{a=false}}) end)
local beforeRound,beforeTrim,beforeSplit = math.round,string.trim,string.split
local a,b=V.new(true,'client'),V.new(true,'client')
a.api.Math.changed=true; a.api.String.changed=true; a.api.MaleNoGloves[999]=true
assert(b.api.Math.changed==nil and b.api.String.changed==nil and b.api.MaleNoGloves[999]==nil)
assert(math.round==beforeRound and string.trim==beforeTrim and string.split==beforeSplit,'No host standard-library changes')
assert(rawget(a.env,'GetPlate')==nil and rawget(a.env,'qbx')==nil and rawget(a.env,'MaleNoGloves')==nil)
assert(count==37)
print('PASS legacy utils shared: '..count..' differential cases; all shared wrappers, private math/string, RNG and multiple returns; no global pollution')
