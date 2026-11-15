local S = dofile('tests/kernel_support_harness.lua')
local H, P, count = S.H, S.P, 0
local function compare(side, name, action)
    local a, b = S.config(false, side), S.config(true, side)
    local left, right = table.pack(action(a)), table.pack(action(b))
    H.same(P.snapshot(right), P.snapshot(left), name .. ': returns')
    H.same(b.trace, a.trace, name .. ': trace')
    H.same(P.snapshot(b.api), P.snapshot(a.api), name .. ': all config data')
    count = count + 1
end
for _, side in ipairs({'shared', 'server', 'client'}) do compare(side, side .. ' complete table', function() end) end
for _, name in ipairs({'citizenid', 'AccountNumber', 'PhoneNumber', 'FingerId', 'WalletId', 'SerialNumber'}) do
    compare('server', name, function(r) return r.api.player.identifierTypes[name].valueFunction() end)
end
for _, state in ipairs({'started', 'starting', 'stopped', 'missing'}) do
    for _, keyType in ipairs({'permanent', 'timed', 'temporary'}) do
        compare('server', state .. keyType, function(r)
            r.states = {pr_carkeys = state, qbx_vehiclekeys = 'started'}
            return r.api.giveVehicleKeys(17, '  ABC  ', 501, keyType, 600)
        end)
    end
end
for _, case in ipairs({'nativePlate', 'nilPlate', 'falseOriginal', 'errorOriginal', 'tempFalse', 'tempError', 'fallbackError', 'bothStopped', 'qbxStarting'}) do
    compare('server', case, function(r)
        r.states.pr_carkeys = 'started'
        if case == 'nativePlate' then return r.api.giveVehicleKeys(17, nil, 501, 'permanent') end
        if case == 'nilPlate' then return r.api.giveVehicleKeys(17, nil, nil, 'temporary') end
        if case == 'falseOriginal' then r.keyResult = false end
        if case == 'errorOriginal' then r.fail = 'pr.buyOriginalKey' end
        if case == 'tempFalse' then r.tempResult = false end
        if case == 'tempError' then r.fail = 'pr.createTempKeyItem' end
        if case == 'fallbackError' then r.tempResult = false; r.fail = 'pr.giveTempKey' end
        if case == 'bothStopped' then r.states = {} end
        if case == 'qbxStarting' then r.states = {qbx_vehiclekeys = 'starting'} end
        local keyType = (case == 'falseOriginal' or case == 'errorOriginal') and 'permanent' or 'temporary'
        return r.api.giveVehicleKeys(17, '  ABC  ', 501, keyType)
    end)
end
for _, backend in ipairs({'pr', 'qbx', 'native'}) do
    for _, state in ipairs({'lock', 'unlock', 1, 2}) do
        compare('server', backend .. tostring(state), function(r)
            if backend == 'pr' then r.states = {pr_carkeys = 'starting', qbx_vehiclekeys = 'started'} end
            if backend == 'qbx' then r.states.qbx_vehiclekeys = 'started' end
            return r.api.setVehicleLock(501, state)
        end)
    end
end
for _, pr in ipairs({'started', 'starting', 'stopped'}) do
    for _, qb in ipairs({'started', 'starting', 'stopped'}) do
        compare('client', pr .. '/' .. qb, function(r)
            r.states = {pr_carkeys = pr, qbx_vehiclekeys = qb}
            return r.api.hasKeys('  ABC  ', 501)
        end)
    end
end
for _, case in ipairs({'nativePlate', 'nilPlate', 'false', 'error'}) do
    compare('client', case, function(r)
        r.states.pr_carkeys = 'started'
        if case == 'nativePlate' then return r.api.hasKeys(nil, 501) end
        if case == 'nilPlate' then return r.api.hasKeys(nil, nil) end
        if case == 'false' then r.keyResult = false; return r.api.hasKeys('ABC', 501) end
        r.fail = 'pr.haveKey'; return pcall(r.api.hasKeys, 'ABC', 501) and true or false
    end)
end
local a, b = S.config(true, 'server'), S.config(true, 'server')
a.api.money.moneyTypes.cash = 999
assert(b.api.money.moneyTypes.cash == 0, 'No shared mutable config between factories')
a = nil; b = nil
assert(count == 55)
print('PASS kernel configs: ' .. count .. ' differential cases; complete tables, six generators, key provider priority/fallback/pcall/plate/lock semantics; local closures')
