local T=dofile('tests/kernel_import_registry_harness.lua');local H,P=T.H,T.P;local count=0
for _,side in ipairs({'client','server'})do
    local old=T.V.new(false,side);local r=T.new(side);r.mount();r.api.Require('modules.utils')
    for _,entry in ipairs({{'GetPlate',20},{'GetPlate',0},{'CommaValue',123456},{'RandomLetter',2},{'RandomNumber',2},
        {'MapTableBySubfield','name',{a={name='A'},b={name='B'}}},{'GetVehicleDisplayName',1},{'GetVehicleMakeName',1}})do
        local name=entry[1]
        if rawget(old.api,name)and r.target[name]then
            local a=table.pack(pcall(old.api[name],table.unpack(entry,2))),b
            b=table.pack(pcall(r.target[name],table.unpack(entry,2)));H.same(P.snapshot(b),P.snapshot(a),side..':'..name);count=count+1
        end
    end
    for _,value in ipairs({' a ','A-B-C','hello'})do
        H.same(P.snapshot(table.pack(r.target.string.trim(value))),P.snapshot(table.pack(old.api.String.trim(value))),'string trim');count=count+1
    end
end
assert(count>=18,'both installed side branches compared')
print('PASS lot76 parity:'..count..' original utils calls/returns compared after real imports;unchanged kernel helper/Locale/Utils suites also required;virtual only')
