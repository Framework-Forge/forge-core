local I=dofile('tests/kernel_inventory_harness.lua')
local n=0
local function callbacks(r)
    local result
    if r.ported then result=I.H.load('kernel/server/inventory/callbacks.lua',I.H.environment())({config=r.config,services={InventoryService=r.api}})
    else
        result={};r.services.Callbacks={register=function(name,handler)result[#result+1]={name=name,handler=handler}end}
        I.H.load('server/inventory/callbacks.lua',r.env)
    end
    return result
end
local arguments={getAll={},saveItem={{name='water'}},deleteItem={'burger'},setItemActive={'burger',false},saveAmmo={{name='ammo'}},deleteAmmo={'ammo'},setAmmoActive={'ammo',false},
    saveComponent={{name='comp'}},deleteComponent={'comp'},setComponentActive={'comp',false},parseDefinition={'item',"name='parsed'"},getGiveCatalog={},give={1,'item','burger',1}}
local names={};for name in pairs(arguments)do names[#names+1]=name end;table.sort(names)
for _,name in ipairs(names)do
    for _,allowed in ipairs({true,false})do
        n=n+1;I.case('callback '..name..tostring(allowed),function(r)
            assert(r.api.upsertAmmo(1,{name='ammo'}));assert(r.api.upsertComponent(1,{name='comp'}));if not allowed then r.aces[1]={}end
            local list=callbacks(r);assert(#list==13)
            for _,entry in ipairs(list)do if entry.name==r.config.Callbacks[name]then local out=table.pack(entry.handler(1,table.unpack(arguments[name])));assert(out[1]==allowed);return table.unpack(out,1,out.n)end end
            error('missing callback')
        end)
    end
end
n=n+1;I.case('policy export follows same service',function(r)assert(r.exported.CanUseInventoryItem(1,'burger'));r.api.items.burger.active=false;local ok,err=r.exported.CanUseInventoryItem(1,'burger');assert(not ok and err=='disabled')end)
local r=I.new(true,function(v)v.noInit=true end)
assert(#r.trace==0 and #r.memory.trace==0);assert(r.api.Initialize());local count=#r.trace;assert(not r.api.Initialize()and #r.trace==count,'explicit Initialize is idempotent')
r=I.new(true,function(v)v.noInit=true end)
local originalLoad=r.library.loadJsonRecovery
r.library.loadJsonRecovery=function(...)local nested=r.api.Initialize();assert(nested==false);return originalLoad(...)end
assert(r.api.Initialize(),'reentrant initialize refused')
local retry=I.new(true,function(v)v.noInit=true end);local loader=retry.library.loadJsonRecovery
retry.library.loadJsonRecovery=function()error('fixture-load',0)end;assert(not pcall(retry.api.Initialize));retry.library.loadJsonRecovery=loader;assert(retry.api.Initialize())
print('PASS '..n..' inventory callback/export differential cases plus explicit idempotent/reentrant/retry initialization; thirteen descriptors, no callback installation')
