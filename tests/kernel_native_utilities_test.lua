local T=dofile('tests/kernel_native_utilities_harness.lua');local r=T.new();r.allocate();local lib=r.api138.Library;local original=r.original()
for _,radius in ipairs({0.5,1,2,3})do for _,ignore in ipairs({false,2,3})do
    T.H.same(table.pack(lib.getClosestPlayer(nil,radius,ignore)),table.pack(original.getClosestPlayer(nil,radius,ignore)),'public closest')
    T.H.same(lib.getNearbyPlayers(nil,radius,ignore),original.getNearbyPlayers(nil,radius,ignore),'public nearby')
end end
r.exists[4]=true;r.positions[4]=T.M.V.vector(2,0,0);r.pools.CVehicle={4}
assert(lib.getClosestVehicle(nil,2)==4);assert(lib.math.round(1.25,1)==1.3 and lib.string.random('A'):match('%u'))
local frozen=lib.table.freeze({a=1});assert(frozen.a==1 and not pcall(function()frozen.a=2 end))
local ok,hash=lib.requestModel(123);assert(ok and hash==123)
assert(r.api138.Close());print('PASS lot138 24 installed public query comparisons,boundary radius/exclusion,actual objects/math/table/string/model utilities;no loader/listener/collector bootstrap')
