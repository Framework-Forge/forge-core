local L = dofile('tests/kernel_lifecycle_harness.lua')
local count = 0
local function check(fn) fn(); count = count + 1 end
local function runtime(ported, configure)
    local r = L.new(ported); r.loadFunctions()
    if configure then configure(r) end
    r.loadEvents(); return r
end
for _, saved in ipairs({false, true}) do
    check(function()
        for _, ported in ipairs({false, true}) do
            local r = runtime(ported)
            r.saveResult = saved
            r.functions.SetPlayerBucket(1, 10); r.core.Player_Buckets[2] = 20
            r.dispatch('playerDropped', 1, 'gone')
            assert(r.core.Players[1] == nil and r.core.Player_Buckets[2] == 20)
            if ported then assert(r.core.Player_Buckets[1] == nil, 'R09 must remove the source key')
            else assert(r.core.Player_Buckets[1] == 10, 'Origin must reproduce bucket residue') end
        end
    end)
end
for _, mode in ipairs({'other-character', 'same-character', 'new-data', 'during-publish', 'during-log'}) do
    check(function()
        for _, ported in ipairs({false, true}) do
            local r = runtime(ported)
            r.functions.SetPlayerBucket(1, 10)
            local old = r.core.Players[1]
            if mode == 'during-publish' then
                r.core.BridgeCache.logout = function() r.core.Players[1] = r.makePlayer(1, 'NEW'); r.core.Player_Buckets[1] = 99 end
            elseif mode == 'during-log' then
                r.logger.log = function() r.core.Players[1] = r.makePlayer(1, 'NEW'); r.core.Player_Buckets[1] = 99 end
            else
                r.saveHook = function() coroutine.yield('saving') end
            end
            local task = r.fork(function() r.dispatch('playerDropped', 1, 'gone') end, 1)
            local ok, result = r.step(task); assert(ok, result)
            if mode ~= 'during-publish' and mode ~= 'during-log' then
                assert(result == 'saving')
                if mode == 'new-data' then old.PlayerData = r.makePlayer(1, 'A').PlayerData
                else r.core.Players[1] = r.makePlayer(1, mode == 'same-character' and 'A' or 'NEW') end
                r.core.Player_Buckets[1] = 99
                local traceBefore = #r.trace
                ok, result = r.step(task); assert(ok, result)
                if ported then assert(#r.trace == traceBefore, 'Old drop must not publish unload/remove status after Save') end
            end
            if ported then assert(r.core.Players[1] ~= nil and r.core.Player_Buckets[1] == 99)
            else assert(r.core.Players[1] == nil, 'Origin must reproduce R11') end
            if mode == 'during-log' and ported then
                for _, e in ipairs(r.trace) do assert(e.kind ~= 'save-player', 'Old drop must not save new player after yielding logger') end
            end
        end
    end)
end
for _, refusal in ipairs({'banned', 'whitelist'}) do
    for _, withQueue in ipairs({false, true}) do
        check(function()
            for _, ported in ipairs({false, true}) do
                local queueCalls, whitelistCalls = 0, 0
                local r = runtime(ported, function(r)
                    r.serverConfig.whitelist = true
                    if refusal == 'banned' then r.bans['license2:L1'] = {expire = 2000, reason = 'Denied'} end
                    local white = function() whitelistCalls = whitelistCalls + 1; return false end
                    r.functions.IsWhitelisted = white
                    if not ported then r.env.IsWhitelisted = white end
                    if withQueue then r.queue = {awaitPlayerQueue = function(_, _, d) queueCalls = queueCalls + 1; d.done() end} end
                end)
                r.connect('refused', 1); r.pump(10)
                local done, message = 0
                for _, e in ipairs(r.trace) do if e.kind == 'done' then done = done + 1; message = message or e.args[2] end end
                assert(message ~= nil, 'Refusal text must remain explicit')
                if ported then
                    assert(done == 1 and queueCalls == 0, 'R10 refusal must be terminal with/without queue')
                    assert(whitelistCalls == (refusal == 'banned' and 0 or 1), 'No whitelist check after terminal ban')
                else assert(done >= 2, 'Origin must demonstrate duplicate finalization') end
            end
        end)
    end
end
check(function()
    local r = runtime(true)
    r.connect('late-query', 1)
    local ok, err = r.step(r.connection); assert(ok, err)
    r.now = r.now + 31
    ok, err = r.step(r.connection); assert(not ok and tostring(err):find('database_timeout', 1, true))
    r.pump(0); for _ = 1, 8 do r.runTasks() end
    local done = 0; for _, e in ipairs(r.trace) do if e.kind == 'done' then done = done + 1 end end
    assert(done == 1, 'Late successful DB completion must not finalize/admit a timed-out connection')
end)
print('PASS lifecycle safety: ' .. count .. ' scenarios; correct bucket key, source/session ownership and terminal refusal with/without queue')
