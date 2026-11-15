local T=dofile('tests/kernel_qb_client_functions_harness.lua');local V=T.vector;local n=0;local covered={}
local function test(name,fn)T.compare(name,fn);n=n+1 end
local cases={
    {'GetPlayerData'},{'GetCoords',10},{'HasItem','bread',2},{'DrawText',1,2,3,4,.7,1,2,3,4,'Text'},
    {'DrawText3D',1,2,3,'Text'},{'RequestAnimDict','dict'},{'PlayAnim','dict','clip',true,123},
    {'PlayAnim','dict','clip'},{'LoadModel','prop'},{'LoadAnimSet','set'},{'GetVehicles'},{'GetObjects'},{'GetPlayers'},
    {'GetPeds',{10,30}},{'GetClosestPed',nil,{10}},{'IsWearingGloves'},{'GetClosestVehicle',V(0,0,0)},{'GetClosestObject'},
    {'GetClosestBone',20,{{id=5},{id=1}}},{'GetClosestBone',20,{}},{'GetClosestBone',20,{1,2}},
    {'GetBoneDistance',20,1,5},{'GetBoneDistance',20,2,'bone'},{'AttachProp',10,'prop',1,1,2,3,4,5,6,false},
    {'DeleteVehicle',20},{'GetPlate',20},{'GetPlate',0},{'GetVehicleLabel',20},{'GetVehicleLabel',0},
    {'SpawnClear',nil,2},{'SpawnClear',nil,5},{'LoadParticleDictionary','dict'},
    {'GetStreetNametAtCoords',V(1,2,3)},{'GetZoneAtCoords',V(1,2,3)},{'GetCardinalDirection',20},{'GetCardinalDirection'},
    {'GetGroundZCoord',V(1,2,3)},{'GetGroundZCoord'},{'Notify','Text','error',1200,'Subtitle','top',{},'icon','red'},
}
for _,c in ipairs(cases)do test(c[1],function(r)return r.api[c[1]](table.unpack(c,2,table.maxn and table.maxn(c)or #c))end);covered[c[1]]=true end
for _,mode in ipairs({'one','table','empty','partial','invalid'})do test('items:'..mode,function(r)
    r.searchResult=mode=='one'and 3 or mode=='table'and{a=2,b=3}or mode=='empty'and{}or mode=='partial'and{a=0,b=3}or false
    return r.api.HasItem(mode=='one'and'a'or{'a','b'},2)
end)end
test('closest player',function(r)r.closestPlayer=3;r.closestPed=30;r.closestCoords=V(4,0,0);return r.api.GetClosestPlayer()end);covered.GetClosestPlayer=true
test('closest player absent',function(r)return r.api.GetClosestPlayer()end)
test('nearby',function(r)r.nearby={{id=2,ped=20},{id=3,ped=30}};return r.api.GetPlayersFromCoords(nil,12)end);covered.GetPlayersFromCoords=true
for _,warp in ipairs({false,true})do for _,network in ipairs({false,true})do test('spawn',function(r)
    return r.api.SpawnVehicle('car',function(v)r.record('callback',v)end,{x=1,y=2,z=3},network,warp)
end)end end;covered.SpawnVehicle=true
test('spawn invalid model',function(r)r.cdImage=false;return r.api.SpawnVehicle('car')end)
for _,looped in ipairs({false,true})do for _,decorated in ipairs({false,true})do
    test('particle coords',function(r)return r.api.StartParticleAtCoord('dict','name',looped,nil,V(0,0,0),nil,nil,decorated and{r=1,g=2,b=3}or nil,decorated and 50 or nil)end)
    for _,kind in ipairs({1,2})do for _,bone in ipairs({false,3})do test('particle entity',function(r)
        r.entityType=kind;return r.api.StartParticleOnEntity('dict','name',looped,20,bone or nil,V(0,0,0),V(0,0,0),1,.4,
            decorated and{r=1,g=2,b=3}or nil,decorated and{name='evolution',amount=.2}or nil,decorated and 50 or nil)
    end)end end
end end;covered.StartParticleAtCoord=true;covered.StartParticleOnEntity=true
for _,hour in ipairs({0,12,13,23})do for _,minute in ipairs({0,9,10,59})do test('clock',function(r)r.hour=hour;r.minute=minute;return r.api.GetCurrentTime()end)end end;covered.GetCurrentTime=true
test('ground fallback',function(r)r.groundFound=false;return r.api.GetGroundZCoord(V(1,2,3))end)
-- The other two suites exercise these names and their full property/progress branches.
for _,name in ipairs({'GetVehicleProperties','SetVehicleProperties','Progressbar'})do covered[name]=true end
for name in pairs(T.new(false).api)do assert(covered[name],'uncovered installed QB client function: '..name)end
print('PASS lot90 installed client functions whole-file parity:'..n..' cases;all names covered across3 suites,native/library/inventory boundaries and retained errors')
