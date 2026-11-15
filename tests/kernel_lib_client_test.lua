local T = dofile('tests/kernel_helpers_harness.lua')
local count = 0
local function test(name, action) T.compare('client', name, action); count = count + 1 end
for _, dimension in ipairs({2, 3}) do
    for _, options in ipairs({'defaults','decorated','numericScale','noRect'}) do
        test('draw ' .. dimension .. '/' .. options, function(r)
            local value = {text = 'hello', coords = T.vector('vector3', 1, 2, 3)}
            if options == 'decorated' then
                value.scale = dimension == 3 and T.vector('vector2', .2, .4) or .2
                value.enableDropShadow, value.enableOutline = true, true
                value.font, value.color = 1, T.vector('vector4', 1.2, 2.5, 3.9, 150.4)
                value.width, value.height = .4, .3
            end
            if options == 'numericScale' then value.scale = .8 end
            if options == 'noRect' then value.disableDrawRect = true end
            if dimension == 2 then return r.api.drawText2d(value) end
            return r.api.drawText3d(value)
        end)
    end
end
test('entity resolves', function(r) return r.api.getEntityAndNetIdFromBagName('entity:12') end)
test('entity invalid return retained', function(r)
    r.waitReturnsNil = true; r.networkExists = false; return r.api.getEntityAndNetIdFromBagName('entity:12')
end)
test('entity timeout', function(r)
    r.networkExists = false
    local ok, why = pcall(r.api.getEntityAndNetIdFromBagName, 'entity:12')
    assert(not ok and tostring(why):find('statebag timed out while awaiting entity creation!', 1, true)); return false
end)
for _, valid in ipairs({true, false}) do
    test('state handler ' .. tostring(valid), function(r)
        local token = r.api.entityStateHandler('example', function(...) r.record('callback', ...) end)
        if not valid then r.networkExists = false; r.waitReturnsNil = true end
        r.callbacks.example('entity:12', nil, {hello = true})
        return token
    end)
end
for _, failed in ipairs({false, true}) do
    test('delete ' .. tostring(failed), function(r) r.deleteFails = failed; return r.api.deleteVehicle(5) end)
end
for _, name in ipairs({'getVehicleDisplayName','getVehicleMakeName','getVehicleModName','getVehicleLiveryName'}) do
    test(name, function(r) return r.api[name](5, 1, 2) end)
end
test('street', function(r) return r.api.getStreetName(T.vector('vector3', 1, 2, 3)) end)
test('zone', function(r) return r.api.getZoneName(T.vector('vector3', 1, 2, 3)) end)
for _, extra in ipairs({1, 3}) do
    for _, enabled in ipairs({false, true}) do test('extra ' .. extra .. '/' .. tostring(enabled), function(r) return r.api.setVehicleExtra(5, extra, enabled) end) end
end
test('reset extras', function(r) return r.api.resetVehicleExtras(5) end)
test('set extras', function(r) return r.api.setVehicleExtras(5, {[1] = false, [3] = true, [20] = false}) end)
for _, model in ipairs({1, 2}) do
    for _, index in ipairs({0, 16, 40, 153, 999}) do
        test('clothing ' .. model .. '/' .. index, function(r)
            r.model, r.variation = model, index
            return r.api.isWearingGloves(), r.api.isWearingDuffelbag()
        end)
    end
end
for _, loaded in ipairs({true, false}) do
    test('bank ' .. tostring(loaded), function(r)
        r.bankLoaded = loaded; r.waitReturnsNil = not loaded
        return r.api.loadAudioBank('BANK'), r.api.lastAudioBank
    end)
end
test('bank custom timeout and remembered success', function(r)
    assert(r.api.loadAudioBank('FIRST', 900))
    r.bankLoaded, r.waitReturnsNil = false, true
    return r.api.loadAudioBank('SECOND', 10), r.api.lastAudioBank
end)
test('bank thrown timeout', function(r)
    r.bankLoaded = false
    local ok, why = pcall(r.api.loadAudioBank, 'BANK')
    assert(not ok and tostring(why):find('timed out while requesting audio bank!', 1, true)); return false
end)
for _, state in ipairs({'stopped','starting','started'}) do
    for _, source in ipairs({'vec3','coordsTable','entity','frontend'}) do
        for _, shared in ipairs({true, false}) do
            test('audio ' .. state .. '/' .. source .. '/' .. tostring(shared), function(r)
                r.states.pr_3dsound = state
                local value = source == 'vec3' and T.vector('vector3', 1, 2, 3)
                    or source == 'coordsTable' and {x = 1, y = 2, z = 3} or source == 'entity' and 5 or nil
                return r.api.playAudio({audioName = 'A', soundSet = 'REF', source = value, radius = 6,
                    shared = shared, occlusion = true, skipOnOcclusion = true, occlusionMode = 'hard',
                    occludedAudioName = 'O', occludedAudioRef = 'OR', delayBetweenSounds = 15})
            end)
        end
    end
end
for _, result in ipairs({false, true, 42}) do
    test('client audio return ' .. tostring(result), function(r)
        r.states.pr_3dsound = 'started'; r.audioResult = result
        return r.api.playAudio({audioName = 'A', entity = 5})
    end)
end
test('client audio exception fallback', function(r)
    r.states.pr_3dsound = 'started'; r.audioFails = true
    return r.api.playAudio({audioName = 'A', coords = {x = 1, y = 2, z = 3}})
end)
test('client return sound id bypasses integration', function(r)
    r.states.pr_3dsound = 'started'
    return r.api.playAudio({audioName = 'A', returnSoundId = true})
end)
test('client bank remembered in payload', function(r)
    r.states.pr_3dsound = 'started'; r.api.loadAudioBank('BANK')
    return r.api.playAudio({audioName = 'A', coords = {x = 1, y = 2, z = 3}})
end)
test('client bad payload', function(r) return r.api.playAudio(false) end)
assert(count == 72)
print('PASS kernel lib client: ' .. count .. ' differential cases; all client helpers, draw/statebag/delete/labels/extras/clothing/audio bank and custom local/shared/fallback audio')
