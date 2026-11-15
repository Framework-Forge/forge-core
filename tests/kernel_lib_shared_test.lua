local T = dofile('tests/kernel_helpers_harness.lua')
local count = 0
local function test(name, action) T.compare('server', name, action); count = count + 1 end
for _, value in ipairs({'  a  ', '', ' ABC ', 'a\nb', '123', 'área'}) do
    test('trim ' .. value, function(r) return r.api.string.trim(value) end)
    test('capitalize ' .. value, function(r) return r.api.string.capitalize(value) end)
end
for _, value in ipairs({-1.6, -1.5, -0.5, 0, 1.49, 1.5, 1.234}) do
    for _, decimal in ipairs({false, 0, 2, -1}) do
        test('round ' .. value .. '/' .. tostring(decimal), function(r) return r.api.math.round(value, decimal or nil) end)
    end
end
test('size mixed', function(r) return r.api.table.size({1, 2, x = false, z = 'value'}) end)
test('size empty', function(r) return r.api.table.size({}) end)
test('map references and false/nil fields', function(r)
    local data = {{category = 'car'}, {category = false}, {other = 1}, {category = 'car'}, {category = 0}}
    local mapped = r.api.table.mapBySubfield(data, 'category')
    assert(mapped.car[1] == data[1] and mapped.car[2] == data[4] and mapped[0][1] == data[5])
    return mapped
end)
for _, value in ipairs({1, 3, '1', false}) do
    test('contains ' .. tostring(value), function(r) return r.api.array.contains({1, 2, false}, value) end)
end
for _, plate in ipairs({' ABC ', '', false}) do
    test('plate ' .. tostring(plate), function(r) r.plate = plate or nil; return r.api.getVehiclePlate(5) end)
end
for _, pattern in ipairs({'default', 'aa11', ''}) do
    test('random plate ' .. pattern, function(r) return r.api.generateRandomPlate(pattern ~= 'default' and pattern or nil) end)
end
for _, heading in ipairs({-1, 0, 44.9, 45, 134.9, 135, 224.9, 225, 314.9, 315, 359, 360, 720}) do
    test('heading ' .. heading, function(r) r.heading = heading; return r.api.getCardinalDirection(5) end)
end
local a, b = T.new(true), T.new(true)
a.api.armsWithoutGloves.male[999] = true
assert(b.api.armsWithoutGloves.male[999] == nil, 'Independent constant fixtures')
for _, name in ipairs({'qbx','QBX','Locale','exports'}) do assert(rawget(a.env, name) == nil, 'No global ' .. name) end
assert(count == 66)
print('PASS kernel lib shared: ' .. count .. ' differential cases; all nine shared methods, table/reference/data semantics and independent namespaces')
