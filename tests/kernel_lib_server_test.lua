local T = dofile('tests/kernel_helpers_harness.lua')
local count = 0
local function test(name, action) T.compare('server', name, action); count = count + 1 end
local function spawn(r, fields)
    local params = {model = 'car', spawnSource = 10}
    for key, value in pairs(fields or {}) do params[key] = value end
    return r.api.spawnVehicle(params)
end
for _, source in ipairs({'ped','vec3','vec4'}) do
    for _, warp in ipairs({false, true, 20}) do
        test('spawn ' .. source .. '/' .. tostring(warp), function(r)
            local value = source == 'vec3' and T.vector('vector3', 4, 5, 6)
                or source == 'vec4' and T.vector('vector4', 4, 5, 6, 70) or 10
            return spawn(r, {spawnSource = value, warp = warp})
        end)
    end
end
for _, bucket in ipairs({0, 7, -1}) do test('bucket ' .. bucket, function(r) return spawn(r, {bucket = bucket}) end) end
test('missing type uses temporary vehicle', function(r) r.catalogResult = {}; return spawn(r) end)
test('entity and plate delayed', function(r)
    local checks, plates = 0, 0
    r.existsHook = function() checks = checks + 1; return checks >= 3 end
    r.plateHook = function() plates = plates + 1; return plates < 3 and '' or 'ABC' end
    return spawn(r)
end)
test('owner delayed', function(r)
    local checks = 0; r.ownerHook = function() checks = checks + 1; return checks < 3 and -1 or 17 end
    return spawn(r)
end)
test('owner timeout deletes and errors', function(r)
    r.owner = -1
    local ok, why = pcall(spawn, r)
    assert(not ok and tostring(why):find('Deleting vehicle which timed out finding an owner', 1, true))
    return ok
end)
test('properties plate must match twice', function(r)
    r.clientHook = function(_, _, _, props) r.plate = props.plate end
    return spawn(r, {props = {plate = ' NEW ', color = 4}, warp = true})
end)
test('properties without plate retains no event', function(r) return spawn(r, {props = {color = 4}}) end)
test('non-table props retained', function(r) return spawn(r, {props = true}) end)
for _, failures in ipairs({1, 2, 3}) do
    test('property failure attempts ' .. failures, function(r)
        local attempts = 0
        r.waitForHook = function(callback, message)
            if message:find('Failed to set vehicle properties', 1, true) then
                attempts = attempts + 1
                if attempts <= failures then error('simulated property timeout', 0) end
                callback(); return callback()
            end
            return callback()
        end
        local ok, a, b = pcall(spawn, r, {props = {plate = 'ABC'}})
        if failures == 3 then
            assert(not ok and tostring(a):find('unable to successfully spawn vehicle after 3 attempts', 1, true))
            return false
        end
        assert(ok); return a, b
    end)
end
test('owner changes during properties refuses all attempts', function(r)
    r.clientHook = function() r.owner = r.owner + 1 end
    local ok, why = pcall(spawn, r, {props = {plate = 'ABC'}})
    assert(not ok and tostring(why):find('unable to successfully spawn vehicle after 3 attempts', 1, true))
    return false
end)
for _, state in ipairs({'stopped','starting','started'}) do
    test('server audio state ' .. state, function(r)
        r.states.pr_3dsound = state
        return r.api.playAudio(1, {audioName = 'BEEP'})
    end)
end
for _, source in ipairs({'coordsTable','vec3','entity','frontend'}) do
    for _, result in ipairs({true, false, 77}) do
        test('server audio ' .. source .. '/' .. tostring(result), function(r)
            r.states.pr_3dsound = 'started'; r.audioResult = result
            local value = source == 'coordsTable' and {x = 1, y = 2, z = 3}
                or source == 'vec3' and T.vector('vector3', 1, 2, 3) or source == 'entity' and 5 or nil
            return r.api.playAudio({1, 2}, {audioName = {'A', 'B'}, soundSet = 'SET', source = value,
                radius = 9, audioBank = 'BANK', timeout = 50, occlusion = true, occlusionMode = 'soft',
                skipOnOcclusion = true, occludedAudioName = 'O', occludedAudioRef = 'R', delayBetweenSounds = 10})
        end)
    end
end
test('server one argument', function(r) r.states.pr_3dsound = 'started'; return r.api.playAudio({audioName = 'A'}) end)
test('server bad argument', function(r) r.states.pr_3dsound = 'started'; return r.api.playAudio(1, false) end)
test('server audio exception', function(r)
    r.states.pr_3dsound = 'started'; r.audioFails = true; return r.api.playAudio(nil, {audioName = 'A'})
end)
assert(count == 41)
print('PASS kernel lib server: ' .. count .. ' differential cases; spawn type/warp/bucket/owner/props/retries/persistence and custom server audio payload/returns/errors')
