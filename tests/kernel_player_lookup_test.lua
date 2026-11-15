local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local a, b = P.new(false), P.new(true)
for _, r in ipairs({a, b}) do
    r.identifiers = {[1] = {'license:one'}, [2] = {'license:two'}}
    r.api.CheckPlayerData(1, {citizenid = 'A', userId = 101, charinfo = {phone = '111'}})
    r.api.CheckPlayerData(2, {citizenid = 'B', userId = 102, charinfo = {phone = '222'}})
end
local checks = 0
local function call(name, ...)
    local ar, br = table.pack(a.lookup[name](...)), table.pack(b.lookup[name](...))
    H.same(P.snapshot(br), P.snapshot(ar), 'lookup ' .. name)
    checks = checks + 1
    return br
end
call('GetSource', 'license:two'); call('GetSource', 'missing')
call('GetUserId', 'license:two'); call('GetUserId', 'missing')
call('GetPlayer', 1); call('GetPlayer', '2'); call('GetPlayer', 'license:one'); call('GetPlayer', 'missing')
call('GetPlayerByCitizenId', 'B'); call('GetPlayerByCitizenId', 'missing')
call('GetPlayerByUserId', 102); call('GetPlayerByUserId', 999)
call('GetPlayerByPhone', '222'); call('GetPlayerByPhone', 'missing')
call('GetQBPlayers')
for _, r in ipairs({a, b}) do
    r.core.Players[1].PlayerData.job = {name = 'taxi', type = 'civ', onduty = true}
    r.core.Players[2].PlayerData.job = {name = 'taxi', type = 'civ', onduty = false}
end
assert(call('GetDutyCountJob', 'taxi')[1] == 1)
assert(call('GetDutyCountType', 'civ')[1] == 1)
assert(call('GetDutyCountJob', 'missing')[1] == 0)
assert(call('GetDutyCountType', 'missing')[1] == 0)
assert(b.lookup.GetQBPlayers() == b.core.Players)
assert(b.lookup.GetPlayer(1) == b.core.Players[1])
print('PASS kernel lookup: ' .. checks .. ' differential cases; source/identifier/citizenid/user/phone, references, duty counts and multiple returns')
