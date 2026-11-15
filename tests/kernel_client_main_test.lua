local R = dofile('tests/kernel_client_runtime_harness.lua')
local H, count = R.H, 0
local function test(name, action, options) R.compare('main',name,action,options); count = count+1 end
for _,mapText in ipairs({'Map','',false,15}) do test('map '..tostring(mapText),function() end,{mapText=mapText}) end
test('nil map fallback',function() end)
for _,method in ipairs({'GetVehiclesByName','GetVehiclesByHash','GetWeapons'}) do
    for _,key in ipairs({'missing','car',3}) do test(method..tostring(key),function(r) return r.api[method](key) end) end
    test(method..' whole reference',function(r)
        local expected = method == 'GetVehiclesByName' and r.core.Shared.Vehicles or method == 'GetVehiclesByHash' and r.core.Shared.VehicleHashes or r.core.Shared.Weapons
        assert(r.api[method]() == expected); return r.api[method]()
    end)
end
test('categories',function(r) return r.api.GetVehiclesByCategory() end)
test('locations reference',function(r) assert(r.api.GetLocations()==r.core.Shared.Locations); return r.api.GetLocations() end)
test('catalog request thread',function(r) r.threads[1]() end)
test('catalog request player loaded',function(r) r.events['QBCore:Client:OnPlayerLoaded']() end)
test('label thread',function(r) r.threads[2]() end)
test('label missing model/name',function(r)
    r.core.Shared.Vehicles.invalid = {name='No Model'}; r.core.Shared.Vehicles.nameless = {model='b'}
    r.threads[2]()
end)
test('CARNOTFOUND suppressed',function(r) r.displayName='CARNOTFOUND'; r.threads[2]() end)
test('catalog labels index refs',function(r)
    local vehicles, hashes = r.core.Shared.Vehicles, r.core.Shared.VehicleHashes
    local value = {truck={model=12,hash=12,name='Truck',category='trucks'}}
    local result = r.events['qbx_core:client:setVehicleCatalog'](value)
    assert(r.core.Shared.Vehicles==vehicles and r.core.Shared.VehicleHashes==hashes)
    return result, r.api.GetVehiclesByName('truck'), r.api.GetVehiclesByCategory()
end)
test('empty catalog',function(r) return r.events['qbx_core:client:setVehicleCatalog']({}) end)
test('health refresh before native',function(r) r.callbacks['qbx_core:client:setHealth'](123); assert(r.health==123) end)
test('vehicle classes',function(r) return r.callbacks['qbx_core:client:getVehicleClasses']() end)
local r = R.new(true,'main')
local player = {citizenid='existing'}; r.core.PlayerData = player; r.core.IsLoggedIn = true
assert(r.api.Initialize() and not r.api.Initialize())
assert(r.core.PlayerData==player and r.core.IsLoggedIn, 'Never reset preexisting canonical state')
local exports=0; for _ in pairs(r.api.Exports) do exports=exports+1 end
assert(exports==5 and #r.api.Threads==2 and #r.api.Events==2)
print('PASS client main: '..count..' differential cases; five exports, stable catalog refs/labels, explicit map initialization and no canonical reset')
