local R=dofile('tests/kernel_vehicles_harness.lua')
local n=0
local function case(name,fn)R.case(name,fn);n=n+1 end
local inputs={'','  ','model = "new", name = "New", hash = `new`, price = 12, class = "A"',
 'return {model="new",brand="Maker"}',
 '["new"] = {name="Name", hash="new"}',
 'return {{model="new"},{model="other",active=false}}',
 'return {a={model="same",name="One"},b={model="same",name="Two"}}',
 'return {bogus=4}', 'return {}','return {name="X"}','return {{model="a"},{model="b",class="BAD"}}',
 'return true','return nil','return','return {','error("not available")','return os.time()',
 'return {a={model="new",extra={x=1}}}'}
for i,snippet in ipairs(inputs)do
    case('parse '..i,function(r)local ok,v=r.d.importDefinition(snippet);return ok,v end)
end
case('atomic invalid batch before IO',function(r)local rev=r.d.revision;local ok=r.d.importDefinition('return {{model="a"},{class="BAD"}}');assert(not ok and r.d.revision==rev)end)
case('commit persisted before sync failure',function(r)r.coreState='stopped';local ok=r.d.importDefinition('model="new"');assert(not ok and r.d.getEntry('new'))end)
case('failed writer leaves catalog',function(r)r.saved=false;local ok=r.d.importDefinition('model="new"');assert(not ok and not r.d.getEntry('new'))end)
case('loop budget only in harness',function(r)
    debug.sethook(function()error('fixture-budget',0)end,'',10000)
    local out=table.pack(pcall(r.d.importDefinition,'return (function()while true do end end)()'))
    debug.sethook();assert(out[1]and not out[2]and tostring(out[3]):find('fixture-budget',1,true))
end)
print('PASS vehicle import differentials '..n)
