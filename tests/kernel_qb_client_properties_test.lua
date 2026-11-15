local T=dofile('tests/kernel_qb_client_functions_harness.lua');local H=T.H;local n=0
local function test(name,fn,build)T.compare(name,fn,build);n=n+1 end
for _,mode in ipairs({'nil','full','boolean-doors','missing-tyres'})do test('get:'..mode,function(r)
    if mode~='nil'then r.props={tyres=mode~='missing-tyres'and{[0]=1,[1]=2,[2]=0}or nil,modNitrous=2,modSubwoofer=3,modHydraulics=4,modDoorR=5,modLightbar=6,modRoofLivery=7}end
    r.doorBool=mode=='boolean-doors';return r.api.GetVehicleProperties(200)
end)end
local scalarFields={'plate','plateIndex','bodyHealth','engineHealth','tankHealth','fuelLevel','oilLevel','dirtLevel','color1','color2',
    'paintType1','paintType2','pearlescentColor','wheelColor','interiorColor','dashboardColor','wheels','wheelSize','wheelWidth','windowTint',
    'modSpoilers','modFrontBumper','modRearBumper','modSideSkirt','modExhaust','modFrame','modGrille','modHood','modFender','modRightFender',
    'modRoof','modEngine','modBrakes','modTransmission','modHorns','modSuspension','modArmor','modNitrous','modFrontWheels','modBackWheels',
    'modPlateHolder','modVanityPlate','modTrimA','modOrnaments','modDashboard','modDial','modDoorSpeaker','modSeats','modSteeringWheel',
    'modShifterLeavers','modAPlate','modSpeakers','modTrunk','modHydrolic','modEngineBlock','modAirFilter','modStruts','modArchCover',
    'modAerials','modTrimB','modTank','modWindows','modDoorR','modLivery','modRoofLivery','modLightbar','xenonColor',
    'headlightColor','modKit17','modKit19','modKit21','modKit47','modKit49','liveryRoof'}
local structured={extras={['1']=1,['2']=false},tireHealth={[0]=40},tireBurstState={[1]=true},tireBurstCompletely={[2]=true},
    windowStatus={[0]=true,[1]=false},doorStatus={[0]=true,[1]=false},tyres={[0]=1,[1]=2},windows={0,3},doors={0,2},
    neonEnabled={true,false,true,false},neonColor={1,2,3},tyreSmokeColor={4,5,6}}
local booleans={'modSmokeEnabled','modTurbo','modSubwoofer','modHydraulics','modXenon','modCustomTiresF','modCustomTiresR','bulletProofTyres','driftTyres'}
local function check(r,props)
    local result=table.pack(r.api.SetVehicleProperties(200,props));r.record('mutated',props)
    return table.unpack(result,1,result.n)
end
for _,field in ipairs(scalarFields)do for _,value in ipairs({0,2})do test(field,function(r)return check(r,{[field]=field=='plate'and' QB90 'or value})end)end end
for field,value in pairs(structured)do test(field,function(r)return check(r,{[field]=H.copy(value)})end)end
for _,field in ipairs(booleans)do for _,value in ipairs({false,true})do test(field,function(r)return check(r,{[field]=value})end)end end
for _,build in ipairs({2060,2372,3258})do for _,owner in ipairs({17,18})do for _,network in ipairs({false,true})do test('full vehicle state',function(r)
    r.owner=owner;r.networked=network
    local props={color1={1,2,3},color2={4,5,6},paintType1=4,paintType2=5}
    for _,field in ipairs(scalarFields)do if props[field]==nil then props[field]=field=='plate'and'QB90'or 2 end end
    for field,value in pairs(structured)do props[field]=H.copy(value)end
    for _,field in ipairs(booleans)do props[field]=true end
    return check(r,props)
end,build)end end end
test('missing entity',function(r)r.exists=false;return check(r,{plate='X'})end)
test('legacy windows/doors/tyres mutates and drift captured',function(r)
    r.build=0
    return check(r,{windowStatus={[0]=true,[1]=false},doorStatus={[0]=true},tireHealth={[0]=80},tireBurstState={[1]=true},
        tireBurstCompletely={[2]=true},modKit17=4,modKit19=8,driftTyres=true,bulletProofTyres=false})
end,3258)
print('PASS lot90 vehicle property parity:'..n..' cases;complete modified setter/getter,field/default/false/build/ownership/failure and argument mutations preserved')
