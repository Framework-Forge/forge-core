local V=dofile('tests/kernel_legacy_harness.lua')
local count=0
local function test(name,action) V.compare('client',name,action);count=count+1 end
for _,name in ipairs({'DrawText2D','DrawText3D'}) do test(name,function(r)
    if name=='DrawText2D' then return r.api[name]('A',V.vector(1,2,3),.5,.5,.8,2,1,2,3,100) end
    return r.api[name](V.vector(1,2,3),'A',.8,2,1,2,3,100)
end) end
test('resolve entity',function(r) return r.api.GetEntityAndNetIdFromBagName('entity:12') end)
test('state callback',function(r) return r.api.EntityStateHandler('test',function() end) end)
for _,mode in ipairs({'one','many','empty','partial'}) do test('item '..mode,function(r)
    r.searchResult=mode=='one' and 5 or mode=='empty' and {} or mode=='partial' and {a=0,b=5} or {a=5,b=5}
    return r.api.HasItem(mode=='one' and 'a' or {'a','b'},1)
end) end
for _,upper in ipairs({true,false}) do test('anim '..tostring(upper),function(r) return r.api.PlayAnim('dict','clip',upper,123) end) end
test('anim defaults',function(r) return r.api.PlayAnim('dict','clip') end)
test('entities',function(r) return r.api.GetEntities('CPed',{10,30}) end)
for _,name in ipairs({'GetVehicles','GetObjects','GetPeds','GetPickups','GetPlayersInScope'}) do
    test(name,function(r) return r.api[name]({10,30}) end)
end
test('closest empty',function(r) return r.api.GetClosestEntity({}) end)
test('closest table coords',function(r) return r.api.GetClosestEntity({30,20},{x=0,y=0,z=0}) end)
for _,name in ipairs({'GetClosestPed','GetClosestVehicle','GetClosestObject'}) do test(name,function(r) return r.api[name](nil,{10}) end) end
test('legacy delete inverse',function(r) return r.api.DeleteVehicle(20) end)
test('legacy delete failed',function(r) r.deleteFails=true;return r.api.DeleteVehicle(20) end)
test('closest player found',function(r) r.closestPlayer=3;r.closestPed=30;r.closestCoords=V.vector(5,0,0);return r.api.GetClosestPlayer() end)
test('closest player missing',function(r) return r.api.GetClosestPlayer() end)
test('nearby players map',function(r) r.nearby={{id=1,ped=10},{id=2,ped=20}};return r.api.GetPlayersFromCoords() end)
test('bones table',function(r) return r.api.GetClosestBone(20,{{id=5},{id=1}}) end)
test('bones fallback',function(r) return r.api.GetClosestBone(20,{}) end)
test('numeric bones legacy error',function(r) return pcall(r.api.GetClosestBone,20,{1,2}) and true or false end)
for _,kind in ipairs({1,2}) do test('bone distance '..kind,function(r) return r.api.GetBoneDistance(20,kind,5) end) end
for _,vertex in ipairs({true,false}) do test('attach '..tostring(vertex),function(r) return r.api.AttachProp(10,'prop',1,1,2,3,4,5,6,vertex) end) end
for _,name in ipairs({'GetVehicleDisplayName','GetVehicleMakeName'}) do test(name,function(r) return r.api[name](20) end) end
for _,radius in ipairs({false,2,3,5}) do test('spawn clear '..tostring(radius),function(r) return r.api.IsVehicleSpawnClear(nil,radius or nil) end) end
for _,looped in ipairs({true,false}) do
    for _,decorated in ipairs({true,false}) do test('particle coords '..tostring(looped)..tostring(decorated),function(r)
        return r.api.StartParticleAtCoord('dict','name',looped,nil,V.vector(0,0,0),nil,nil,decorated and {r=1,g=2,b=3} or nil,decorated and 20 or nil)
    end) end
end
for _,looped in ipairs({true,false}) do
    for _,entityType in ipairs({1,2}) do
        for _,bone in ipairs({false,3}) do test('particle entity '..tostring(looped)..entityType..tostring(bone),function(r)
            r.entityType=entityType
            return r.api.StartParticleOnEntity('dict','name',looped,20,bone or nil,V.vector(0,0,0),V.vector(0,0,0),1,.4,{r=1,g=2,b=3},{name='scale',amount=.2},50)
        end) end
    end
end
test('particle entity no bone found',function(r)
    r.boneIndex=0;r.entityType=2
    return r.api.StartParticleOnEntity('dict','name',true,20,3,V.vector(0,0,0),V.vector(0,0,0))
end)
for _,name in ipairs({'GetStreetNameAtCoords','GetZoneAtCoords'}) do test(name,function(r) return r.api[name](V.vector(1,2,3)) end) end
test('cardinal',function(r) return r.api.GetCardinalDirection() end)
test('cardinal missing',function(r) r.exists=false;return r.api.GetCardinalDirection() end)
for _,hour in ipairs({0,12,13,23}) do
    for _,minute in ipairs({0,9,10,59}) do test('time '..hour..':'..minute,function(r) r.hour,r.minute=hour,minute;return r.api.GetCurrentTime() end) end
end
for _,found in ipairs({true,false}) do test('ground '..tostring(found),function(r) r.groundFound=found;return r.api.GetGroundZCoord(V.vector(1,2,3)) end) end
test('ground nil',function(r) return r.api.GetGroundZCoord() end)
test('change extra',function(r) return r.api.ChangeVehicleExtra(20,1,false) end)
test('set extras',function(r) return r.api.SetVehicleExtras(20,{[1]=false}) end)
for _,model in ipairs({1,2}) do
    for _,index in ipairs({0,16,153}) do test('gloves '..model..'/'..index,function(r) r.model,r.variation=model,index;return r.api.IsWearingGloves() end) end
end
test('load bank',function(r) return r.api.LoadAudioBank('BANK',100) end)
test('audio coords preferred',function(r) return r.api.PlayAudio('A','REF',true,20,V.vector(1,2,3),6) end)
test('audio entity',function(r) return r.api.PlayAudio('A','REF',false,20) end)
assert(count==87, 'Unexpected client case count: '..count)
print('PASS legacy utils client: '..count..' differential cases; all client wrappers, pools/proximity/bones/props/particles/time/extras/audio and preserved legacy defaults/errors')
