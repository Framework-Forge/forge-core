local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local a, b = P.new(false), P.new(true)
local checks = 0
local function call(name, ...)
    local args = table.pack(...)
    local ar = table.pack(a.api[name](table.unpack(H.copy(args), 1, args.n)))
    local br = table.pack(b.api[name](table.unpack(H.copy(args), 1, args.n)))
    H.same(P.snapshot(br), P.snapshot(ar), name .. ' returns')
    P.compare(a, b); checks = checks + 1
    return br
end
local seed = {citizenid = 'A', license = 'license:test', userId = 101,
    position = P.vector(1, 2, 3, 4), money = {cash = 100, bank = 500, crypto = 20}}
call('CheckPlayerData', 1, seed)
assert(b.core.Players[1] and b.counters.PlayerCount == 1)
for _, name in ipairs({'GetMoney', 'AddMoney', 'RemoveMoney', 'SetMoney'}) do assert(type(b.api[name]) == 'function') end
call('GetMoney', 1, 'cash'); call('GetMoney', 'A', 'bank'); call('GetMoney', 1); call('GetMoney', 999, 'cash')
call('AddMoney', 1, 'cash', '10.6', 'purchase refund')
assert(b.api.GetMoney(1, 'cash') == 111)
-- Account-to-item synchronization must go through the explicit inventory port.
assert(b.trace[#b.trace].kind == 'inventory-SetItem')
call('AddMoney', 1, 'unknown', 10); call('AddMoney', 1, 'cash', -1)
call('RemoveMoney', 1, 'cash', 5000); call('RemoveMoney', 1, 'cash', -5)
call('RemoveMoney', 1, 'bank', 20, 'fee'); call('SetMoney', 1, 'cash', 25)
call('SetMoney', 1, 'cash', -1); call('SetMoney', 1, 'unknown', 1)
a.allowHooks, b.allowHooks = false, false
call('AddMoney', 1, 'cash', 1); call('RemoveMoney', 1, 'cash', 1); call('SetMoney', 1, 'cash', 1)
assert(b.api.GetMoney(1, 'cash') == 25)
a.allowHooks, b.allowHooks = true, true
call('SetPlayerData', 1, 'testFlag', true); call('SetPlayerData', 1, nil, 1)
call('SetCharInfo', 'A', 'firstname', 'Example'); call('SetCharInfo', 1, false, 'ignored')
call('SetMetadata', 1, 'custom', 42); call('GetMetadata', 'A', 'custom')
call('SetMetadata', 1, 'phone.test', 'value'); call('GetMetadata', 1, 'phone.test')
call('SetMetadata', 1, 'hunger', 90); call('GetMetadata', 1, 'hunger')
call('SetMetadata', 1, 'isdead', true)
call('SetJob', 1, 'invalid', 0); call('SetJob', 1, 'taxi', 999)
call('SetJob', 'A', 'TAXI', 0); call('SetJobDuty', 1, true)
call('AddPlayerToJob', 'A', 'mechanic', 0); call('RemovePlayerFromJob', 'A', 'taxi')
call('SetPlayerPrimaryJob', 'A', 'not-held'); call('AddPlayerToJob', 'A', 'unemployed', 0)
call('SetGang', 1, 'BALLAS', 1); call('RemovePlayerFromGang', 'A', 'ballas')
call('AddPlayerToGang', 'A', 'none', 0); call('SetPlayerPrimaryGang', 'absent', 'none')

for name, args in pairs({AddItem = {'cash', 1, 3, {test = true}}, RemoveItem = {'cash', 1, 3},
    GetItemBySlot = {2}, GetItemByName = {'cash'}, GetItemsByName = {'cash'}, ClearInventory = {}}) do
    local ar = table.pack(a.core.Players[1].Functions[name](table.unpack(H.copy(args))))
    local br = table.pack(b.core.Players[1].Functions[name](table.unpack(H.copy(args))))
    H.same(P.snapshot(br), P.snapshot(ar), 'legacy inventory ' .. name)
    P.compare(a, b); checks = checks + 1
end

local stored = H.copy(seed); stored.citizenid = 'B'
a.offline.B, b.offline.B = H.copy(stored), H.copy(stored)
call('GetOfflinePlayer', 'B'); call('GetOfflinePlayer', 'absent')
call('AddMoney', 'B', 'cash', 5, 'offline refund'); call('RemoveMoney', 'B', 'cash', 5)
call('SetMoney', 'B', 'bank', 900); call('SaveOffline', stored); call('SaveOffline', nil)
-- Baseline risk, not a correction: offline money methods ignore a failed save.
a.writeResult, b.writeResult = false, false
local attempts = b.saveAttempts
assert(call('AddMoney', 'B', 'cash', 1)[1] == true and b.saveAttempts == attempts + 3,
    'Installed offline-save failure semantics changed without a decision')
a.writeResult, b.writeResult = true, true

call('Save', 999)
a.upsertResults, b.upsertResults = {'false', 'false'}, {'false', 'false'}
local before = b.saveAttempts; call('Save', 1)
assert(b.saveAttempts == before + 3, 'Failed upserts require the installed three-attempt policy')
a.state.inProperty, b.state.inProperty = true, true
call('Save', 1)
local last
for _, event in ipairs(b.trace) do if event.kind == 'upsert' then last = event.args[1] end end
assert(last.position.x == 1 and last.position.w == 4, 'Interior must preserve saved position')
a.state.inProperty, b.state.inProperty = false, false
a.pedExists, b.pedExists = false, false; call('Save', 1)
a.pedExists, b.pedExists = true, true
a.pedError, b.pedError = true, true; assert(call('Save', 1)[1] == false)
a.pedError, b.pedError = false, false; assert(call('Save', 1)[1] == true, 'Crash must release save lock')
local successFlush = call('SaveAllPlayers', 'test-success'); assert(successFlush[1] and successFlush[2] == 1 and successFlush[3] == 0)
a.writeResult, b.writeResult = false, false
assert(call('Logout', 1)[1] == false and b.core.Players[1], 'Failed save must abort logout')
local flush = call('SaveAllPlayers', 'test-failure'); assert(not flush[1] and flush[2] == 0 and flush[3] == 1)
a.writeResult, b.writeResult = true, true
assert(call('Logout', 1)[1] == true and not b.core.Players[1] and b.counters.PlayerCount == 0)
call('Logout', 999)

-- Login authority and owned-character deletion are distinct from admin deletion.
a.slotAllowed, b.slotAllowed = false, false
assert(call('Login', 1, 'B')[1] == false)
a.slotAllowed, b.slotAllowed = true, true
assert(call('Login', 1, 'B')[1] == true)
assert(call('Login', 1, 'B')[1] == false, 'Double login must be refused')
local callback = 'qbx_core:server:deleteCharacter'
for _, r in ipairs({a, b}) do r.offline.FOREIGN = {citizenid = 'FOREIGN', license = 'license:other'} end
assert(call('Login', 2, 'FOREIGN')[1] == false and not b.core.Players[2], 'Wrong account must not load a character')
call('Login', nil, 'B'); call('Login', '', 'B')
local usersA, usersB = a.users, b.users; a.users, b.users = {}, {}
assert(call('Login', 3, 'B')[1] == false and not b.core.Players[3], 'Missing account must not authenticate')
a.users, b.users = usersA, usersB
assert(call('Login', 3, nil, {citizenid = 'C', license = 'license:test'})[1] == true)
assert(call('Logout', 3)[1] == true)
H.same(table.pack(b.callbacks[callback](1, 'FOREIGN')), table.pack(a.callbacks[callback](1, 'FOREIGN')))
P.compare(a, b); checks = checks + 1
a.slotAllowed, b.slotAllowed = false, false
H.same(table.pack(b.callbacks[callback](1, 'B')), table.pack(a.callbacks[callback](1, 'B')))
P.compare(a, b); checks = checks + 1
a.slotAllowed, b.slotAllowed = true, true
assert(b.callbacks[callback](1, 'B') == true and a.callbacks[callback](1, 'B') == true)
P.compare(a, b); checks = checks + 1
call('DeleteCharacter', 'B') -- legacy export is the administrative force-delete path
assert(#a.tasks == 1 and #b.tasks == 1, 'Admin deletion remains deferred')
a.tasks[1](); b.tasks[1](); P.compare(a, b)
assert(rawget(b.env, 'QBX') == nil and rawget(b.env, 'Login') == nil, 'No framework globals may leak')
print('PASS kernel player: ' .. checks .. ' differential cases; money/hooks/items, metadata/groups, save retries/positions/locks, login/logout/deletion')
