local R=dofile('tests/kernel_server_runtime_harness.lua')
local H,count=R.H,0
local function test(name,fn) R.compare('main',name,fn); count=count+1 end
test('initial startup explicit',function(r) return r.globalState.PlayerCount,r.globalState.MaxPlayers end)
for _,name in ipairs({'GetVehiclesByName','GetVehiclesByHash','GetWeapons'}) do
    for _,key in ipairs({'missing','car',101,123}) do test(name..tostring(key),function(r) return r.api[name](key) end) end
    test(name..' whole ref',function(r)
        local value=r.api[name](); local expected=name=='GetVehiclesByName' and r.core.Shared.Vehicles or name=='GetVehiclesByHash' and r.core.Shared.VehicleHashes or r.core.Shared.Weapons
        assert(value==expected); return value
    end)
end
test('categories',function(r) return r.api.GetVehiclesByCategory() end)
test('locations',function(r) assert(r.api.GetLocations()==r.core.Shared.Locations); return r.api.GetLocations() end)
for _,caller in ipairs({false,'forge-core','qbx_core','foreign'}) do test('catalog caller '..tostring(caller),function(r)
    r.caller=caller or nil
    local vehicles,hashes=r.core.Shared.Vehicles,r.core.Shared.VehicleHashes
    local ok,value=r.api.SetVehicleCatalog({truck={model='truck',hash=102,name='Truck',category='trucks'}})
    assert(vehicles==r.core.Shared.Vehicles and hashes==r.core.Shared.VehicleHashes)
    return ok,value,r.api.GetVehiclesByCategory()
end) end
test('own alternate resource',function(r) r.resource='private-test';r.caller='private-test';return r.api.SetVehicles({}) end)
test('aliases equal',function(r) assert(r.api.SetVehicles==r.api.SetVehicleCatalog) end)
test('catalog request source',function(r) r.events['qbx_core:server:requestVehicleCatalog'](7) end)
test('session ids stable',function(r)
    local first=r.api.CreateSessionId(20); assert(first==1 and r.api.CreateSessionId(20)==first)
    return first,r.api.CreateSessionId(21)
end)
for _,existing in ipairs({0,25,'legacy'}) do test('existing session '..tostring(existing),function(r)
    r.entities[20]={sessionId=existing}; assert(r.api.CreateSessionId(20)==existing); return r.api.CreateSessionId(21)
end) end
test('vehicle class cache',function(r)
    assert(r.api.GetVehicleClass(101)==1); local before=#r.trace
    assert(r.api.GetVehicleClass(102)==2 and r.api.GetVehicleClass(999)==nil and #r.trace==before)
end)
test('empty class table truthy cached',function(r) r.classResponse={};return r.api.GetVehicleClass(101),r.api.GetVehicleClass(102) end)
test('no players then recover',function(r)
    r.players={};local ok,err=pcall(r.api.GetVehicleClass,101);assert(not ok and err:find('no clients online',1,true))
    r.players={'2'};return r.api.GetVehicleClass(101)
end)
test('callback retries error nil response',function(r)
    local calls=0;r.awaitHook=function() calls=calls+1;if calls==1 then error('offline') elseif calls==2 then return nil else return r.classResponse end end
    return r.api.GetVehicleClass(101),calls
end)
test('bounded repeated unanswered callbacks',function(r)
    r.awaitHook=function() coroutine.yield('no response'); return nil end
    local co=coroutine.create(function() r.api.GetVehicleClass(101) end)
    for _=1,3 do local ok,value=coroutine.resume(co);assert(ok and value=='no response') end
    assert(coroutine.status(co)=='suspended', 'Inherited retry must not turn into silent fallback')
end)
for _,reject in ipairs({false,true}) do test('shared promise concurrency '..tostring(reject),function(r)
    r.awaitHook=function() coroutine.yield('client pending'); if reject then r.players={};return nil end; return r.classResponse end
    local first=coroutine.create(function() return r.api.GetVehicleClass(101) end)
    local second=coroutine.create(function() return r.api.GetVehicleClass(102) end)
    assert(coroutine.resume(first));assert(coroutine.resume(second));assert(#r.promises==1)
    local ok,value=coroutine.resume(first)
    if reject then assert(not ok and value:find('no clients online',1,true)) else assert(ok and value==1) end
    ok,value=coroutine.resume(second)
    if reject then assert(not ok and value:find('no clients online',1,true)) else assert(ok and value==2) end
end) end
-- Startup failure is tested as a fake command, never ExecuteCommand in FiveM.
for _,case in ipairs({'ox_lib','ox_inventory','framework','onesync','defaults','custom'}) do
    local a,b=R.new(false,'main'),R.new(true,'main')
    for _,r in ipairs({a,b}) do
        if case=='ox_lib' or case=='ox_inventory' then r.dependencies[case]=false
        elseif case=='framework' then r.convars['inventory:framework']='wrong'
        elseif case=='onesync' then r.convars.onesync_enableInfinity=0
        elseif case=='defaults' then r.convars.sv_maxclients=nil
        elseif case=='custom' then r.convars.sv_maxclients=80;r.convars['qbx:bucketlockdownmode']='strict' end
    end
    local ao,ae=pcall(a.initialize);local bo,be=pcall(b.initialize);assert(ao==bo)
    if not ao then assert(ae:match('([^\n]+)$'):gsub('^.-:%d+: ','')==be:match('([^\n]+)$'):gsub('^.-:%d+: ','')) end
    H.same(b.trace,a.trace,'startup '..case);H.same(b.globalState,a.globalState)
    if not ao then local errors,quits=0,0;for _,e in ipairs(b.trace) do if e.kind=='error' then errors=errors+1 elseif e.kind=='execute-simulated' then quits=quits+1 end end;assert(errors==101 and quits==1) end
    count=count+1
end
local r=R.new(true,'main');r.core.Players[7]={sentinel=true};r.core.Player_Buckets[7]=4
local players,buckets,items=r.core.Players,r.core.Player_Buckets,r.core.UsableItems
assert(r.initialize() and not r.initialize())
assert(r.core.Players==players and players[7].sentinel and r.core.Player_Buckets==buckets and buckets[7]==4 and r.core.UsableItems==items)
local total=0;for _ in pairs(r.api.Exports) do total=total+1 end;assert(total==9 and #r.api.Events==1)
print('PASS server main: '..count..' differential cases; nine exports, startup diagnostics simulated, canonical maps preserved, vehicle catalogs/session ids and class promise concurrency/rejection/retries')
