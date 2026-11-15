local J = dofile('tests/kernel_job_catalog_harness.lua')
local P, H = J.P, J.H
local player = P.new(true)
local nativeGroups = H.load('kernel/server/groups.lua', H.environment())({
    jobs = player.groupData.jobs, gangs = player.groupData.gangs,
    emitServer = player.platform.emitServer, emitClient = player.platform.emitClient,
    saveGroups = function() error('No legacy Lua file commit allowed during catalog projection') end,
    logError = function() error('Unexpected Groups error') end,
})
local base = {Groups = nativeGroups, Players = player.core.Players, Lookup = player.lookup}
local config = J.config(true).config
local memory = J.persistence()
local ports = {config = config, library = memory.api, translate = function(key) return key end}
local catalog = J.composition(base, ports)
assert(base.JobCatalog == catalog and catalog.Groups == base.Groups)
assert(base.Players == player.core.Players and base.Lookup == player.lookup)
assert(#memory.trace == 0, 'assembly must not read/write files')
assert(not pcall(J.composition, base, ports), 'duplicate catalog attachment refused')
assert(not pcall(J.composition, {}, ports), 'no substitute Groups created')
assert(next(catalog.Registry.jobs) == nil and not next(catalog.Registry.gangs))

player.api.CheckPlayerData(1, {citizenid = 'CATALOG', license = 'license:test', userId = 101})
assert(player.api.SetJob(1, 'taxi', 1)); assert(player.api.SetGang(1, 'ballas', 1))
local online = player.core.Players[1]
local offline = player.api.CheckPlayerData(nil, {citizenid = 'OFFLINE', job = {name = 'taxi', grade = {level = 1}},
    gang = {name = 'ballas', grade = {level = 1}}})
assert(offline and offline.Offline)
local jobsIdentity, gangsIdentity = nativeGroups.GetJobs(), nativeGroups.GetGangs()
catalog.Registry.setAll({taxi = {label = 'Taxi Updated', jobtype = 'civ', grades = {
    ['0'] = {name = 'Driver', payment = 40}, ['1'] = {name = 'Supervisor', payment = 150}}, stashes = {{id = 'duty'}}}},
    {ballas = {label = 'Ballas Updated', grades = {['0'] = {name = 'Member'}, ['1'] = {name = 'Leader'}}}})
local sourceCopy = catalog.Registry.getJobs()
assert(catalog.Projection.syncAll())
assert(nativeGroups.GetJobs() == jobsIdentity and nativeGroups.GetGangs() == gangsIdentity)
assert(online.PlayerData.job.label == 'Taxi Updated' and online.PlayerData.job.payment == 150)
assert(online.PlayerData.gang.label == 'Ballas Updated' and online.PlayerData.gang.grade.name == 'Leader')
assert(offline.PlayerData.job.label == 'Taxi Updated' and offline.PlayerData.gang.label == 'Ballas Updated')
assert(nativeGroups.GetJobs().taxi.stashes == nil and catalog.Registry.get('job', 'taxi').stashes[1].id == 'duty')
H.same(catalog.Registry.getJobs(), sourceCopy, 'projection does not mutate admin schema')
assert(nativeGroups.GetJobs().mechanic, 'installed first-sync policy does not delete untracked native seeds')
assert(#memory.trace == 0, 'projection alone must not commit JSON or old Lua data')

catalog.Registry.setAll({}, {}); assert(catalog.Projection.syncAll())
assert(online.PlayerData.job.name == 'unemployed' and online.PlayerData.gang.name == 'none')
assert(offline.PlayerData.job.name == 'unemployed' and offline.PlayerData.gang.name == 'none')
assert(nativeGroups.GetJobs().unemployed and nativeGroups.GetGangs().none)
assert(nativeGroups.GetJobs().taxi == nil and nativeGroups.GetGangs().ballas == nil)

-- Identity guard is local. Legacy success/tracking bug remains visible, not an activation approval.
base.Groups = {}
catalog.Registry.setAll({police = {label = 'New'}}, {})
assert(catalog.Projection.syncAll() == true)
assert(not nativeGroups.GetJobs().police and catalog.Projection.registeredJobs.police)
assert(#memory.trace == 0)
base.Groups = nativeGroups
assert(catalog.Projection.syncAll()); assert(nativeGroups.GetJobs().police)
assert(base.Players[1] == online and player.lookup.GetPlayer(1) == online)
assert(#memory.trace == 0)
print('PASS job catalog composition: actual private Registry/Groups/Player/Lookup online/offline update/removal, no QBX or self-framework route; seeds/failure policy retained, no Service activation')
