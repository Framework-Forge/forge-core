local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local function scenario(ported, sameCharacter)
    local r = P.new(ported)
    r.api.CheckPlayerData(1, {citizenid = 'A', license = 'license:test', position = P.vector(1, 2, 3, 4)})
    r.trace = {}
    local active, maximum = 0, 0
    r.upsertHook = function(request)
        active = active + 1; maximum = math.max(maximum, active)
        r.record('inside-db', request.playerEntity.citizenid, active)
        r.platform.wait(5)
        active = active - 1
        return true
    end
    r.yielding = true
    local offline = H.copy(r.core.Players[1].PlayerData)
    if not sameCharacter then offline.citizenid = 'B' end
    local one = coroutine.create(function() return r.api.Save(1) end)
    local two = coroutine.create(function() return r.api.SaveOffline(offline) end)
    local ok, delay = coroutine.resume(one); assert(ok and delay == 5)
    ok, delay = coroutine.resume(two); assert(ok and delay == (sameCharacter and 0 or 5))
    if sameCharacter then
        assert(maximum == 1, 'Online/offline saves for one citizenid must share a lock')
        ok, delay = coroutine.resume(one); assert(ok and delay == true)
        ok, delay = coroutine.resume(two); assert(ok and delay == 5)
        ok, delay = coroutine.resume(two); assert(ok and delay == true)
    else
        assert(maximum == 2, 'Different characters must not share a global save lock')
        ok, delay = coroutine.resume(one); assert(ok and delay == true)
        ok, delay = coroutine.resume(two); assert(ok and delay == true)
    end
    assert(coroutine.status(one) == 'dead' and coroutine.status(two) == 'dead')
    r.yielding, r.upsertHook = false, nil
    assert(r.api.Save(1), 'Save lock must be released after coroutine completion')
    return r
end
for _, same in ipairs({true, false}) do
    local a, b = scenario(false, same), scenario(true, same)
    P.compare(a, b)
end
print('PASS kernel save locks: same citizenid serialized across online/offline; independent citizenids proceed; locks released')
