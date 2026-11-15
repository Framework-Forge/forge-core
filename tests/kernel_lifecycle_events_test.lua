local L = dofile('tests/kernel_lifecycle_harness.lua')
local total = 0
local function scenario(configure, fn)
    local p = L.pair({'Functions'})
    p.run('configure and load events', function(r) if configure then configure(r) end; r.loadEvents() end)
    fn(p); total = total + p.count
end
scenario(nil, function(p)
    p.run('slash chat cancelled', function(r) r.dispatch('chatMessage', 1, 1, 'Name', '/command') end)
    p.run('plain chat', function(r) r.dispatch('chatMessage', 1, 1, 'Name', 'message') end)
    p.run('scheduled not due', function(r) r.dispatch('txAdmin:events:scheduledRestart', 0, {secondsRemaining = 30}) end)
    p.run('scheduled save', function(r) r.dispatch('txAdmin:events:scheduledRestart', 0, {secondsRemaining = 60}) end)
    p.run('shutdown save', function(r) r.dispatch('txAdmin:events:serverShuttingDown', 0) end)
    p.run('other resource stop', function(r) r.dispatch('onResourceStop', 0, 'other') end)
    p.run('self stop', function(r) r.dispatch('onResourceStop', 0, 'forge-core') end)
    p.run('other start', function(r) r.dispatch('onResourceStart', 0, 'other') end)
    p.run('schema descriptor simulated only', function(r) r.dispatch('onResourceStart', 0, 'forge-core') end)
    p.run('duty toggle on', function(r) r.dispatch('QBCore:ToggleDuty', 1) end)
    p.run('duty toggle off', function(r) r.dispatch('QBCore:ToggleDuty', 1) end)
    p.run('no player duty', function(r) r.dispatch('QBCore:ToggleDuty', 999) end)
    p.run('close unauthorized', function(r) r.dispatch('QBCore:Server:CloseServer', 1, 'Reason') end)
    p.run('open unauthorized', function(r) r.dispatch('QBCore:Server:OpenServer', 1) end)
    p.run('close authorized', function(r) r.core.Players[2] = r.makePlayer(2, 'B'); r.aces[1] = {admin = true}; r.dispatch('QBCore:Server:CloseServer', 1); return r.serverConfig end)
    p.run('open authorized', function(r) r.dispatch('QBCore:Server:OpenServer', 1); return r.serverConfig end)
    -- Failed-save drop/bucket cleanup is an approved difference, covered by the safety suite.
end)
scenario(function(r) r.serverConfig.checkDuplicateLicense = true end, function(p)
    p.run('joining first', function(r) r.dispatch('playerJoining', 1) end)
    p.run('joining duplicate waits', function(r) r.joinTask = r.fork(function() r.dispatch('playerJoining', 1) end, 1); return r.step(r.joinTask) end)
    p.run('joining duplicate refused', function(r) return r.step(r.joinTask) end)
    p.run('drop clears license', function(r) r.dispatch('playerDropped', 1, 'left') end)
    p.run('join after drop', function(r) r.dispatch('playerJoining', 1) end)
end)
for _, mode in ipairs({'accepted', 'closed', 'closed-ace', 'no-license', 'duplicate', 'new-user', 'banned', 'whitelist-refused', 'query-error'}) do
    scenario(function(r)
        if mode == 'closed' or mode == 'closed-ace' then r.serverConfig.closed = true end
        if mode == 'closed-ace' then r.aces[1] = {['qbadmin.join'] = true} end
        if mode == 'no-license' then r.ids[1] = {} end
        if mode == 'duplicate' then r.serverConfig.checkDuplicateLicense = true; r.dispatch('playerJoining', 1) end
        if mode == 'new-user' then r.userId = nil end
        if mode == 'banned' then r.bans['license2:L1'] = {expire = 2000, reason = 'Denied'} end
        if mode == 'whitelist-refused' then r.serverConfig.whitelist = true end
        if mode == 'query-error' then r.userError = true end
    end, function(p)
        p.run(mode .. ' entry', function(r) return r.connect(mode, 1) end)
        if mode == 'banned' or mode == 'whitelist-refused' then
            p.a.pump(); p.b.pump()
            local function countDone(r)
                local dones = 0; for _, e in ipairs(r.trace) do if e.kind == 'done' then dones = dones + 1 end end
                return dones
            end
            assert(countDone(p.a) == 2 and countDone(p.b) == 1, 'Approved R10 difference: refusal must be terminal')
        elseif mode ~= 'query-error' then
            p.run(mode .. ' completes', function(r) r.pump() end)
        else
            p.run('query error leaves promise unresolved', function(r)
                local ok, err = r.step(r.connection); assert(ok, err)
                local task = r.tasks[1]; local success, message = r.step(task)
                assert(not success and tostring(message):find('simulated user query error', 1, true))
                r.now = r.now + 31
                local timedOut, reason = r.step(r.connection)
                assert(not timedOut and tostring(reason):find('error.connecting_database_timeout', 1, true))
                return timedOut
            end)
        end
    end)
end
-- R11 bug demonstration moved to explicit origin-vs-fixed safety scenarios, not silently normalized.
scenario(function(r) r.loadQueue() end, function(p)
    p.run('connection delegates to real queue port', function(r) return r.connect('queued-connect', 1) end)
    p.run('connection finishes checks', function(r) r.pump(4) end)
    p.run('joining removes reservation internally', function(r) r.dispatch('playerJoining', 1); r.pump(4) end)
    for _, r in ipairs({p.a, p.b}) do
        local done = 0; for _, e in ipairs(r.trace) do if e.kind == 'done' then done = done + 1 end end
        assert(done == 1, 'Accepted connection must finish once with queue')
    end
end)
scenario(function(r)
    local denied = function() error('simulated ban query refusal') end
    r.functions.IsPlayerBanned = denied
    if not r.ported then r.env.IsPlayerBanned = denied end
end, function(p)
    p.run('ban query throw entry', function(r) return r.connect('ban-query-error', 1) end)
    p.run('ban query throw rejection', function(r) r.pump(8) end)
end)
print('PASS kernel lifecycle events: ' .. total .. ' unchanged differential cases plus explicit R10 refusal difference; R09/R11 safety suite required')
