local R = dofile('tests/kernel_client_runtime_harness.lua')
local H, count = R.H, 0
local function test(name,action,options) R.compare('events',name,action,options); count=count+1 end
for _,pvp in ipairs({false,true}) do test('load '..tostring(pvp),function(r)
    r.tutorial=2; r.motd='test'; r.events['QBCore:Client:OnPlayerLoaded']()
    assert(r.trace[1].kind=='ShutdownLoadingScreenNui')
end,{pvp=pvp}) end
for _,caller in ipairs({false,'forge-core','foreign','qbx_core'}) do test('guard '..tostring(caller),function(r)
    r.caller=caller or nil; local old=r.core.PlayerData; local value={citizenid='B'}
    r.events['QBCore:Player:SetPlayerData'](value)
    assert(r.core.PlayerData==(caller and caller~='forge-core' and old or value)); return r.core.PlayerData
end) end
test('nil PlayerData accepted by old handler',function(r) r.events['QBCore:Player:SetPlayerData'](nil) end)
for _,bag in ipairs({'global','player:1'}) do
    for _,value in ipairs({false,true,0}) do test('pvp bag '..bag..tostring(value),function(r) r.bags.PVPEnabled(bag,nil,value) end) end
end
for _,caller in ipairs({false,'forge-core'}) do
    test('teleport player '..tostring(caller),function(r) r.caller=caller or nil; r.events['QBCore:Command:TeleportToPlayer'](R.V.vector(5,6,7)) end)
    for _,heading in ipairs({false,0,42}) do test('teleport coords '..tostring(caller)..tostring(heading),function(r)
        r.caller=caller or nil; r.events['QBCore:Command:TeleportToCoords'](5,6,7,heading or nil)
    end) end
end
test('marker guarded',function(r) r.caller='foreign'; return r.events['QBCore:Command:GoToMarker']() end)
test('marker missing',function(r) r.marker=false; return r.events['QBCore:Command:GoToMarker']() end)
for _,vehicle in ipairs({0,20}) do
    for _,found in ipairs({false,true}) do test('marker ground '..vehicle..tostring(found),function(r)
        r.vehicle=vehicle; r.foundGround=found; r.groundAfter=2; r.fadeWaits=1
        r.events['QBCore:Command:GoToMarker']()
        if not found then
            local messages={}; for _,entry in ipairs(r.trace) do if entry.kind=='notify' then messages[#messages+1]=entry.args[2] end end
            H.same(messages,{'error','success'},'inherited failure still followed by success')
            assert(r.coords[10].x==12 and r.coords[10].z==r.groundZ, 'Inherited final move not silently fixed')
        end
    end) end
end
test('marker loading/collision timeout',function(r) r.loading=true; r.collision=false; r.events['QBCore:Command:GoToMarker']() end)
for _,radius in ipairs({false,0,12}) do test('nearby radius '..tostring(radius),function(r) return r.callbacks['qbx_core:client:getVehiclesInRadius'](radius or nil) end) end
test('nearby empty',function(r) r.nearby={}; return r.callbacks['qbx_core:client:getVehiclesInRadius']() end)
test('Notify full arguments',function(r) r.events['QBCore:Notify']('Text','inform',200,'sub','center',{color='red'},'gear','#fff') end)
test('Notify table',function(r) r.events['QBCore:Notify']({text='Title',caption='Body'},'error') end)
test('me nil',function(r) r.bags.me('player:1',nil,nil) end)
test('me invalid player',function(r) r.playerId=nil; r.bags.me('player:1',nil,'hi') end)
test('me inactive',function(r) r.active=false; r.bags.me('player:1',nil,'hi') end)
test('me no ped',function(r) r.exists=false; r.bags.me('player:1',nil,'hi') end)
test('me remote distant',function(r) r.playerId=2; r.coords[11]=R.V.vector(100,0,0); r.bags.me('player:2',nil,'hi') end)
for _,id in ipairs({1,2}) do test('me drawing '..id,function(r)
    r.playerId=id; r.bags.me('player:'..id,nil,'hello'); assert(#r.threads==1); r.threads[1]()
end) end
test('shared update',function(r) r.events['QBCore:Client:OnSharedUpdate']('Weapons',3,{label='New'}) end)
test('shared remove',function(r) r.events['QBCore:Client:OnSharedRemove']('Weapons',3) end)
test('shared multiple',function(r) r.events['QBCore:Client:OnSharedUpdateMultiple']('Weapons',{[3]={label='New'},[4]={label='Four'}}) end)
test('props nil',function(r) r.events['qbx_core:client:setVehicleProperties'](120,nil) end)
test('props accepted',function(r) r.events['qbx_core:client:setVehicleProperties'](120,{plate='A'}) end)
test('props retry',function(r) r.propertyAfter=3; r.events['qbx_core:client:setVehicleProperties'](120,{plate='A'}) end)
test('props no ownership',function(r) r.owners[20]=2; r.events['qbx_core:client:setVehicleProperties'](120,{plate='A'}); assert(r.propertyCalls==0) end)
test('props rejected timeout',function(r) r.propertySuccess=false; r.events['qbx_core:client:setVehicleProperties'](120,{plate='A'}) end)
test('props acquire ownership',function(r)
    local calls=0; r.ownerHook=function() calls=calls+1; return calls>1 and 1 or 2 end
    r.events['qbx_core:client:setVehicleProperties'](120,{plate='A'})
end)
test('init false',function(r) r.entities.initVehicle(20,nil,false) end)
test('init clear own NPC only',function(r) r.entities.initVehicle(20,nil,true); assert(#r.timers==1); r.timers[1]() end)
test('init other owner',function(r) r.owners[20]=2; r.entities.initVehicle(20,nil,true); assert(#r.timers==0) end)
test('init collision timeout error preserved',function(r) r.worldCollision=true; return pcall(r.entities.initVehicle,20,nil,true) end)
print('PASS client events: '..count..' differential cases; caller/identity/order, tutorial/loading port, PVP, teleports, notifications, shared, me, ownership/retries/statebags; inherited waypoint defect retained')
