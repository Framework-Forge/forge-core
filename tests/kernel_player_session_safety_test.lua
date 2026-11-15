local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local count = 0
local function check(fn) fn(); count = count + 1 end
local function runtime(ported)
    local r = P.new(ported)
    r.api.CheckPlayerData(1, {citizenid = 'A', license = 'license:test', position = P.vector(1, 2, 3, 4)})
    r.trace = {}; r.yielding = true
    return r
end
local function replace(r, same)
    r.api.CheckPlayerData(1, {citizenid = same and 'A' or 'B', license = 'license:test', position = P.vector(5, 6, 7, 8)})
    return r.core.Players[1]
end
local function finish(co)
    local result
    for _ = 1, 20 do
        local ok, value = coroutine.resume(co); assert(ok, value); result = value
        if coroutine.status(co) == 'dead' then return result end
    end
    error('Unbounded coroutine in session safety test')
end
for _, same in ipairs({false, true}) do
    check(function()
        for _, ported in ipairs({false, true}) do
            local r = runtime(ported)
            r.upsertHook = function() r.platform.wait(7); return true end
            local co = coroutine.create(function() return r.api.Save(1) end)
            local ok, delay = coroutine.resume(co); assert(ok and delay == 7)
            local new = replace(r, same)
            r.trace = {}
            assert(finish(co), 'Old data can complete persistence without marking the new session')
            local marked = 0; for _, e in ipairs(r.trace) do if e.kind == 'status-saved' then marked = marked + 1 end end
            assert(r.core.Players[1] == new)
            assert(marked == (ported and 0 or 1), 'Save acknowledgement must remain owned by original session')
        end
    end)
end
for _, stage in ipairs({'snapshot', 'database', 'delay'}) do
    check(function()
        for _, ported in ipairs({false, true}) do
            local r = runtime(ported)
            if stage == 'snapshot' then r.core.Status.RequestClientSnapshot = function() r.platform.wait(7); return true end
            elseif stage == 'database' then r.upsertHook = function() r.platform.wait(7); return true end end
            local co = coroutine.create(function() return r.api.Logout(1) end)
            local ok, delay = coroutine.resume(co); assert(ok and delay == (stage == 'delay' and 200 or 7))
            local new = replace(r, false)
            r.trace = {}
            local result = finish(co)
            if ported then
                assert(result == false and r.core.Players[1] == new)
                for _, e in ipairs(r.trace) do assert(e.kind ~= 'status-remove', 'Logout must not remove new status') end
            else assert(result == true and r.core.Players[1] == nil, 'Origin must reproduce stale Logout cleanup') end
        end
    end)
end
check(function()
    local r = runtime(true)
    r.upsertHook = function() r.platform.wait(7); return true end
    local one = coroutine.create(function() return r.api.Save(1) end)
    local two = coroutine.create(function() return r.api.Save(1) end)
    local ok, delay = coroutine.resume(one); assert(ok and delay == 7)
    ok, delay = coroutine.resume(two); assert(ok and delay == 0)
    local new = replace(r, false)
    assert(finish(one) == true)
    assert(finish(two) == false, 'Waiting save must not read ped/status/data from replacement session')
    assert(r.saveAttempts == 1 and r.core.Players[1] == new)
end)
check(function()
    for _, ported in ipairs({false, true}) do
        local r = runtime(ported)
        r.core.Status.RequestClientSnapshot = function() r.platform.wait(7); return false end
        local co = coroutine.create(function() return r.api.SaveAllPlayers('test') end)
        local ok, delay = coroutine.resume(co); assert(ok and delay == 7)
        local new = replace(r, false)
        local results = table.pack(coroutine.resume(co)); assert(results[1], results[2])
        if ported then assert(results[2] == false and results[3] == 0 and results[4] == 1 and r.saveAttempts == 0)
        else assert(results[2] == true and results[3] == 1 and r.saveAttempts == 1, 'Origin saves replacement player after stale request') end
        assert(r.core.Players[1] == new)
    end
end)
print('PASS player session safety: ' .. count .. ' scenarios; save acknowledgement/lock wait/Logout/SaveAll owned across awaits, old persistence preserved')
