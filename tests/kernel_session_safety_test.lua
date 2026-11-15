local T = dofile('tests/kernel_session_harness.lua')
local H = T.H
local count = 0
local function check(fn) fn(); count = count + 1 end
local function statusRuntime(ported)
    local r = T.new(ported, 'server'); r.load('status'); r.core.Status.Initialize(1)
    return r
end
local function identity(r, src, values)
    local packet = H.copy(values or {})
    if r.ported then
        local lease = r.core.Status.ProtocolSnapshot(src)
        packet._session, packet._character = lease._session, lease._character
    end
    return packet
end
for _, change in ipairs({'other-character', 'same-character', 'same-object-data', 'reinitialize', 'logout'}) do
    check(function()
        for _, ported in ipairs({false, true}) do
            local r = statusRuntime(ported)
            local before = r.core.Players[1]
            local response = identity(r, 1, {hunger = 13})
            r.awaitHook = function() coroutine.yield('awaiting'); return response end
            local co = coroutine.create(function() return r.core.Status.RequestClientSnapshot(1) end)
            local ok, result = coroutine.resume(co); assert(ok and result == 'awaiting')
            if change == 'other-character' or change == 'same-character' then
                r.core.Players[1] = {PlayerData = {source = 1, citizenid = change == 'same-character' and 'A' or 'B', metadata = {health = 200, hunger = 81}}}
                r.core.Status.Remove(1); r.core.Status.Initialize(1)
            elseif change == 'same-object-data' then
                before.PlayerData = {source = 1, citizenid = 'A', metadata = {health = 200, hunger = 81}}
                r.core.Status.Initialize(1)
            elseif change == 'reinitialize' then
                before.PlayerData.metadata.hunger = 81; r.core.Status.Initialize(1)
            else
                r.core.Status.Remove(1); r.core.Players[1] = nil
            end
            local traceBefore = #r.trace
            ok, result = coroutine.resume(co); assert(ok and coroutine.status(co) == 'dead')
            if ported or change == 'logout' then
                assert(result == false, 'Old response must be rejected')
                if r.core.Players[1] then assert(r.core.Players[1].PlayerData.metadata.hunger == 81) end
                assert(#r.trace == traceBefore, 'Rejected response must not emit extensions, save or publish')
            else
                assert(result == true and r.core.Players[1].PlayerData.metadata.hunger == 13, 'Installed origin must still demonstrate R08')
            end
        end
    end)
end
check(function()
    local r = statusRuntime(true)
    assert(r.core.Status.RequestClientSnapshot(1), 'Current callback response remains accepted')
    assert(r.core.Status.Get(1, 'hunger') == 65)
    r.awaitError = true
    assert(not r.core.Status.RequestClientSnapshot(1), 'Callback error must not mutate status')
end)
check(function()
    local r = statusRuntime(true)
    local valid = identity(r, 1, {hunger = 23})
    local bad = {{hunger = 13}, {_session = valid._session, _character = 'other', hunger = 13},
        {_session = valid._session + 1, _character = 'A', hunger = 13},
        {_session = tostring(valid._session), _character = 'A', hunger = 13}}
    for _, packet in ipairs(bad) do
        local before = #r.trace
        r.dispatch('qbx_core:server:receiveStatusSnapshot', 1, packet, 'death')
        assert(r.core.Status.Get(1, 'hunger') == 80 and #r.trace == before, 'Bad identity must not save or change status')
    end
    r.dispatch('qbx_core:server:receiveStatusSnapshot', 1, valid, 'death')
    assert(r.core.Status.Get(1, 'hunger') == 23 and r.trace[#r.trace].kind == 'save')
    r.core.Status.Remove(1); r.core.Status.Initialize(1)
    local before = #r.trace
    r.dispatch('qbx_core:server:receiveStatusSnapshot', 1, valid, 'death')
    assert(#r.trace == before, 'Previous generation of the same character must be refused')
end)
check(function()
    for _, ported in ipairs({false, true}) do
        local r = T.new(ported, 'server')
        local saved = {}
        r.save = function(src) saved[#saved + 1] = r.core.Players[src].PlayerData.citizenid; return true end
        r.env.Save = r.save; r.load('status'); r.core.Status.Initialize(1)
        local packet = identity(r, 1, {hunger = 13})
        r.awaitHook = function() coroutine.yield('waiting'); return packet end
        assert(r.step(1) == 'waiting')
        r.core.Players[1] = {PlayerData = {source = 1, citizenid = 'B', metadata = {health = 200}}}
        r.core.Status.Remove(1); r.core.Status.Initialize(1)
        assert(r.step(1) == 60000)
        if ported then assert(#saved == 0, 'Old periodic checkpoint must not save new character')
        else assert(saved[1] == 'B', 'Origin demonstrates stale checkpoint saving B') end
    end
end)
check(function()
    local s, c = statusRuntime(true), T.new(true, 'client')
    c.load('status')
    local function deliver()
        s.core.Status.Sync(1)
        local payload = s.trace[#s.trace].args[3]
        assert(payload._session and payload._character)
        c.dispatch('qbx_core:client:statusUpdated', 0, payload)
        return H.copy(payload)
    end
    c.dispatch('QBCore:Client:OnPlayerLoaded', 0)
    local first = deliver()
    assert(c.exported.SetStatus('hunger', 31))
    local current = c.callbacks['qbx_core:client:getStatusSnapshot']()
    assert(current._session == first._session and current._character == 'A')
    s.dispatch('qbx_core:server:receiveStatusSnapshot', 1, current, 'manual')
    assert(s.core.Status.Get(1, 'hunger') == 31)
    c.dispatch('QBCore:Client:OnPlayerUnload', 0)
    s.core.Players[1] = {PlayerData = {source = 1, citizenid = 'B', metadata = {health = 200, hunger = 87}}}
    s.core.Status.Remove(1); s.core.Status.Initialize(1)
    c.core.PlayerData = {citizenid = 'B', metadata = {health = 200}}
    c.dispatch('QBCore:Client:OnPlayerLoaded', 0)
    c.dispatch('qbx_core:client:statusUpdated', 0, first)
    assert(c.exported.GetStatus('hunger') == 100, 'Old character status must not initialize new UI')
    local second = deliver()
    assert(c.exported.GetStatus('hunger') == 87)
    local before = #s.trace
    s.dispatch('qbx_core:server:receiveStatusSnapshot', 1, current, 'death')
    assert(#s.trace == before and s.core.Status.Get(1, 'hunger') == 87)
    c.dispatch('QBCore:Client:OnPlayerUnload', 0)
    c.dispatch('QBCore:Client:OnPlayerLoaded', 0)
    c.dispatch('qbx_core:client:statusUpdated', 0, second)
    assert(c.exported.GetStatus('hunger') == 100, 'Previous generation of same character must not initialize UI')
    s.core.Status.Remove(1); s.core.Status.Initialize(1); deliver()
    c.dispatch('qbx_core:client:statusUpdated', 0, {hunger = 2})
    assert(c.exported.GetStatus('hunger') == 87, 'Legacy payload must not be relabeled with current identity')
    assert(c.exported.GetStatusSnapshot()._session == nil and s.core.Status.Snapshot(1)._session == nil)
    assert(c.core.PlayerData.metadata._session == nil and s.core.Players[1].PlayerData.metadata._session == nil)
end)
check(function()
    local s, c = statusRuntime(true), T.new(true, 'client')
    c.load('status'); c.dispatch('QBCore:Client:OnPlayerLoaded', 0)
    local function deliver()
        s.core.Status.Sync(1)
        c.dispatch('qbx_core:client:statusUpdated', 0, s.trace[#s.trace].args[3])
    end
    deliver(); c.exported.SetStatus('hunger', 31)
    local oldIdentity = s.core.Status.ProtocolSnapshot(1)
    c.listen('qbx_core:client:collectStatusExtensions', function()
        c.dispatch('QBCore:Client:OnPlayerUnload', 0)
        s.core.Players[1] = {PlayerData = {source = 1, citizenid = 'B', metadata = {health = 200, hunger = 87}}}
        s.core.Status.Remove(1); s.core.Status.Initialize(1)
        c.core.PlayerData = {citizenid = 'B', metadata = {health = 200}}
        c.dispatch('QBCore:Client:OnPlayerLoaded', 0); deliver()
    end)
    local oldPacket = c.callbacks['qbx_core:client:getStatusSnapshot']()
    assert(oldPacket._character == 'A' and oldPacket._session == oldIdentity._session,
        'Extension reentry must not relabel old values with the new identity')
    s.dispatch('qbx_core:server:receiveStatusSnapshot', 1, oldPacket, 'death')
    assert(s.core.Status.Get(1, 'hunger') == 87)
end)
print('PASS session safety: ' .. count .. ' scenarios; origin defects reproduced, identity/generation/callback/network/checkpoint/client protections, no persisted protocol data')
