-- Port of installed qbx_core/server/player.lua. See ../NOTICE-02.md and ../LICENSE-QBX.
-- Private dependencies only. No runtime is registered by constructing this factory.
return function(ports)
assert(type(ports) == 'table', 'player ports required')
local core, config, storage = ports.core, ports.config, ports.storage
local platform, inventory = ports.platform, ports.inventory
local lib, qbx = ports.library, ports.utils
local logger, triggerEventHooks = ports.logger, ports.triggerHook
local characterSlots, counters = ports.characterSlots, ports.counters
local defaultSpawn, settings = ports.defaultSpawn, ports.settings
assert(type(core) == 'table' and type(core.Players) == 'table' and type(core.Shared) == 'table', 'private player state required')
assert(type(core.Status) == 'table' and type(core.BridgeCache) == 'table', 'status/cache bindings required')
assert(type(config) == 'table' and type(config.money) == 'table' and type(config.player) == 'table', 'player configuration required')
assert(type(settings) == 'table' and type(settings.accounts) == 'table', 'player settings/accounts required')
assert(type(settings.maxJobs) == 'number' and type(settings.maxGangs) == 'number', 'membership limits required')
assert(type(settings.setJobReplaces) == 'boolean' and type(settings.setGangReplaces) == 'boolean', 'membership replacement policy required')
assert(type(storage) == 'table' and type(characterSlots) == 'table', 'storage/slot services required')
assert(type(logger) == 'table' and type(logger.log) == 'function' and type(triggerEventHooks) == 'function', 'logging/hook ports required')
assert(type(lib) == 'table' and type(lib.print) == 'table' and type(lib.callback) == 'table', 'library ports required')
assert(type(lib.callback.await) == 'function' and type(qbx) == 'table', 'callback/utility ports required')
assert(type(counters) == 'table' and type(counters.PlayerCount) == 'number', 'player counter required')
assert(type(platform) == 'table' and type(inventory) == 'table', 'platform/inventory ports required')
assert(type(ports.lookup) == 'table' and type(ports.groups) == 'table', 'internal lookup/group services required')
assert(type(qbx.math) == 'table' and type(qbx.math.round) == 'function' and type(qbx.table) == 'table' and type(qbx.table.size) == 'function', 'round/size utilities required')
assert(type(core.BridgeCache.player) == 'function', 'explicit cache publisher required')
for _, name in ipairs({'fetchUserByIdentifier', 'fetchPlayerEntity', 'fetchPlayerGroups', 'fetchIsUnique', 'deletePlayer', 'upsertPlayerEntity', 'addPlayerToJob', 'removePlayerFromJob', 'addPlayerToGang', 'removePlayerFromGang'}) do
    assert(type(storage[name]) == 'function', 'player storage port required: ' .. name)
end
for _, name in ipairs({'Initialize', 'Remove', 'RequestClientSnapshot', 'PrepareSave', 'MarkSaved', 'IsStatusKey', 'Set', 'Add', 'Get'}) do
    assert(type(core.Status[name]) == 'function', 'player status port required: ' .. name)
end
assert(type(characterSlots.canLoad) == 'function' and type(characterSlots.handleCharacterDeleted) == 'function', 'slot policy ports required')
for _, name in ipairs({'error', 'warn', 'verbose', 'info'}) do
    assert(type(lib.print[name]) == 'function', 'player log port required: ' .. name)
end
for _, name in ipairs({'getInvokingResource', 'getPlayerName', 'getIdentifier', 'dropPlayer', 'locale', 'wait', 'emitClient', 'emitServer', 'on', 'thread', 'getPed', 'setArmour', 'player', 'entityExists', 'getCoords', 'getHeading', 'vec4', 'time'}) do
    assert(type(platform[name]) == 'function', 'player platform port required: ' .. name)
end
for _, name in ipairs({'AddItem', 'RemoveItem', 'GetSlot', 'GetSlotWithItem', 'GetSlotsWithItem', 'ClearInventory', 'SetItem'}) do
    assert(type(inventory[name]) == 'function', 'player inventory port required: ' .. name)
end
local GetPlayer, GetPlayerByCitizenId = assert(ports.lookup.GetPlayer), assert(ports.lookup.GetPlayerByCitizenId)
local GetJob, GetGang = assert(ports.groups.GetJob), assert(ports.groups.GetGang)
local maxJobsPerPlayer, maxGangsPerPlayer = settings.maxJobs, settings.maxGangs
local setJobReplaces, setGangReplaces = settings.setJobReplaces, settings.setGangReplaces
local accounts = settings.accounts
local cache = {resource = assert(ports.resource, 'resource identity required')}
local api = {Callbacks = {}}
local Login, GetOfflinePlayer, SetJob, SetJobDuty, SetPlayerPrimaryJob, AddPlayerToJob, RemovePlayerFromJob, SetGang, SetPlayerPrimaryGang, AddPlayerToGang, RemovePlayerFromGang, CheckPlayerData, Logout, CreatePlayer, Save, SaveOffline, SaveAllPlayers, SetPlayerData, UpdatePlayerData, SetMetadata, GetMetadata, SetCharInfo, AddMoney, RemoveMoney, SetMoney, GetMoney, DeleteCharacter, ForceDeleteCharacter, GenerateUniqueIdentifier

local accountsAsItems = {}
local playerSaveLocks = {}
local saveRetryCount = 3
local saveRetryDelayMs = 250

for i = 1, #accounts do
    accountsAsItems[accounts[i]] = 0
end

---@param source Source
---@param citizenid? string
---@param newData? PlayerEntity
---@return boolean success
function Login(source, citizenid, newData)
    if not source or source == '' then
        lib.print.error('No source given at login stage')
        return false
    end

    if core.Players[source] then
        platform.dropPlayer(tostring(source), platform.locale('info.exploit_dropped'))
        logger.log({
            source = platform.getInvokingResource() or cache.resource,
            webhook = config.logging.webhook.anticheat,
            event = 'Anti-Cheat',
            color = 'white',
            tags = config.logging.role,
            message = ('%s [%s] Dropped for attempting to login twice'):format(platform.getPlayerName(tostring(source)), tostring(source))
        })
        return false
    end

    local license, license2 = platform.getIdentifier(source --[[@as string]], 'license'), platform.getIdentifier(source --[[@as string]], 'license2')
    local userId = license2 and storage.fetchUserByIdentifier(license2) or storage.fetchUserByIdentifier(license)
    if not userId then
        lib.print.error('User does not exist. Licenses checked:', license2, license)
        return false
    end
    if citizenid then
        local playerData = storage.fetchPlayerEntity(citizenid)
        if playerData and (playerData.license == license2 or playerData.license == license) then
            local allowed, reason = characterSlots.canLoad(source, playerData)
            if not allowed then return false, reason end
            playerData.userId = userId
            return CheckPlayerData(source, playerData) ~= nil
        else
            platform.dropPlayer(tostring(source), platform.locale('info.exploit_dropped'))
            logger.log({
                source = platform.getInvokingResource() or cache.resource,
                webhook = config.logging.webhook.anticheat,
                event = 'Anti-Cheat',
                color = 'white',
                tags = config.logging.role,
                message = ('%s has been dropped for character joining exploit'):format(platform.getPlayerName(source))
            })
        end
    else
        newData.userId = userId

        local player = CheckPlayerData(source, newData)
        Save(player.PlayerData.source)
        return true
    end

    return false
end

api.Login = Login

---@param citizenid string
---@return Player? player if found in storage
function GetOfflinePlayer(citizenid)
    if not citizenid then return end
    local playerData = storage.fetchPlayerEntity(citizenid)
    if not playerData then return end
    return CheckPlayerData(nil, playerData)
end

api.GetOfflinePlayer = GetOfflinePlayer

---Overwrites current primary job with a new job. Removing the player from their current primary job
---@param identifier Source | string
---@param jobName string name
---@param grade? integer defaults to 0
---@return boolean success if job was set
---@return ErrorResult? errorResult
function SetJob(identifier, jobName, grade)
    jobName = jobName:lower()
    grade = tonumber(grade) or 0

    local job = GetJob(jobName)

    if not job then
        lib.print.error(('cannot set job. Job %s does not exist'):format(jobName))

        return false
    end

    if not job.grades[grade] then
        lib.print.error(('cannot set job. Job %s does not have grade %s'):format(jobName, grade))

        return false
    end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if setJobReplaces and player.PlayerData.job.name ~= 'unemployed' then
        local success, errorResult = RemovePlayerFromJob(player.PlayerData.citizenid, player.PlayerData.job.name)

        if not success then
            return false, errorResult
        end
    end

    if jobName ~= 'unemployed' then
        local success, errorResult = AddPlayerToJob(player.PlayerData.citizenid, jobName, grade)

        if not success then
            return false, errorResult
        end
    end

    return SetPlayerPrimaryJob(player.PlayerData.citizenid, jobName)
end

api.SetJob = SetJob

---@param identifier Source | string
---@param onDuty boolean
function SetJobDuty(identifier, onDuty)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return end

    player.PlayerData.job.onduty = not not onDuty

    if player.Offline then return end

    platform.emitServer('QBCore:Server:SetDuty', player.PlayerData.source, player.PlayerData.job.onduty)
    platform.emitClient('QBCore:Client:SetDuty', player.PlayerData.source, player.PlayerData.job.onduty)

    UpdatePlayerData(identifier)
end

api.SetJobDuty = SetJobDuty

---@param jobName string
---@param job Job
---@param grade integer
---@return PlayerJob
local function toPlayerJob(jobName, job, grade)
    return {
        name = jobName,
        label = job.label,
        isboss = job.grades[grade].isboss or false,
        bankAuth = job.grades[grade].bankAuth or false,
        onduty = job.defaultDuty or false,
        payment = job.grades[grade].payment or 0,
        type = job.type,
        grade = {
            name = job.grades[grade].name,
            level = grade
        }
    }
end

---Sets a player's job to be primary only if they already have it.
---@param citizenid string
---@param jobName string
---@return boolean success
---@return ErrorResult? errorResult
function SetPlayerPrimaryJob(citizenid, jobName)
    local player = GetPlayerByCitizenId(citizenid) or GetOfflinePlayer(citizenid)
    if not player then
        return false, {
            code = 'player_not_found',
            message = ('player not found with citizenid %s'):format(citizenid)
        }
    end

    local grade = jobName == 'unemployed' and 0 or player.PlayerData.jobs[jobName]
    if not grade then
        return false, {
            code = 'player_not_in_job',
            message = ('player %s does not have job %s'):format(citizenid, jobName)
        }
    end

    local job = GetJob(jobName)
    if not job then
        return false, {
            code = 'job_not_found',
            message = ('%s does not exist in core memory'):format(jobName)
        }
    end

    assert(job.grades[grade] ~= nil, ('job %s does not have grade %s'):format(jobName, grade))

    player.PlayerData.job = toPlayerJob(jobName, job, grade)

    if player.Offline then
        SaveOffline(player.PlayerData)
    else
        Save(player.PlayerData.source)
        UpdatePlayerData(player.PlayerData.source)
        platform.emitServer('QBCore:Server:OnJobUpdate', player.PlayerData.source, player.PlayerData.job)
        platform.emitClient('QBCore:Client:OnJobUpdate', player.PlayerData.source, player.PlayerData.job)
    end

    return true
end

api.SetPlayerPrimaryJob = SetPlayerPrimaryJob

---Adds a player to the job or overwrites their grade for a job already held
---@param citizenid string
---@param jobName string
---@param grade? integer
---@return boolean success
---@return ErrorResult? errorResult
function AddPlayerToJob(citizenid, jobName, grade)
    jobName = jobName:lower()
    grade = tonumber(grade) or 0

    -- unemployed job is the default, so players cannot be added to it
    if jobName == 'unemployed' then
        return false, {
            code = 'unemployed',
            message = 'players cannot be added to the unemployed job'
        }
    end

    local job = GetJob(jobName)
    if not job then
        return false, {
            code = 'job_not_found',
            message = ('%s does not exist in core memory'):format(jobName)
        }
    end

    if not job.grades[grade] then
        return false, {
            code = 'job_missing_grade',
            message = ('job %s does not have grade %s'):format(jobName, grade),
        }
    end

    local player = GetPlayerByCitizenId(citizenid) or GetOfflinePlayer(citizenid)
    if not player then
        return false, {
            code = 'player_not_found',
            message = ('player not found with citizenid %s'):format(citizenid)
        }
    end

    if player.PlayerData.jobs[jobName] == grade then
        return true
    end

    if qbx.table.size(player.PlayerData.jobs) >= maxJobsPerPlayer and not player.PlayerData.jobs[jobName] then
        return false, {
            code = 'max_jobs',
            message = 'player already has maximum amount of jobs allowed'
        }
    end

    storage.addPlayerToJob(citizenid, jobName, grade)

    if not player.Offline then
        player.PlayerData.jobs[jobName] = grade
        SetPlayerData(player.PlayerData.source, 'jobs', player.PlayerData.jobs)
        platform.emitServer('qbx_core:server:onGroupUpdate', player.PlayerData.source, jobName, grade)
        platform.emitClient('qbx_core:client:onGroupUpdate', player.PlayerData.source, jobName, grade)
    end

    if player.PlayerData.job.name == jobName then
        SetPlayerPrimaryJob(citizenid, jobName)
    end

    return true
end

api.AddPlayerToJob = AddPlayerToJob

---If the job removed from is primary, sets the primary job to unemployed.
---@param citizenid string
---@param jobName string
---@return boolean success
---@return ErrorResult? errorResult
function RemovePlayerFromJob(citizenid, jobName)
    if jobName == 'unemployed' then
        return false, {
            code = 'unemployed',
            message = 'players cannot be removed from the unemployed job'
        }
    end

    local player = GetPlayerByCitizenId(citizenid) or GetOfflinePlayer(citizenid)
    if not player then
        return false, {
            code = 'player_not_found',
            message = ('player not found with citizenid %s'):format(citizenid)
        }
    end

    if not player.PlayerData.jobs[jobName] then
        return true
    end

    storage.removePlayerFromJob(citizenid, jobName)
    player.PlayerData.jobs[jobName] = nil

    if player.PlayerData.job.name == jobName then
        local job = GetJob('unemployed')
        assert(job ~= nil, 'cannot find unemployed job. Does it exist in shared/jobs.lua?')
        player.PlayerData.job = toPlayerJob('unemployed', job, 0)
        if player.Offline then
            SaveOffline(player.PlayerData)
        else
            Save(player.PlayerData.source)
        end
    end

    if not player.Offline then
        SetPlayerData(player.PlayerData.source, 'jobs', player.PlayerData.jobs)
        platform.emitServer('qbx_core:server:onGroupUpdate', player.PlayerData.source, jobName)
        platform.emitClient('qbx_core:client:onGroupUpdate', player.PlayerData.source, jobName)
    end

    return true
end

api.RemovePlayerFromJob = RemovePlayerFromJob

---Removes the player from their current primary gang and adds the player to the new gang
---@param identifier Source | string
---@param gangName string name
---@param grade? integer defaults to 0
---@return boolean success if gang was set
---@return ErrorResult? errorResult
function SetGang(identifier, gangName, grade)
    gangName = gangName:lower()
    grade = tonumber(grade) or 0

    local gang = GetGang(gangName)

    if not gang then
        lib.print.error(('cannot set gang. Gang %s does not exist'):format(gangName))

        return false
    end

    if not gang.grades[grade] then
        lib.print.error(('cannot set gang. Gang %s does not have grade %s'):format(gangName, grade))

        return false
    end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if setGangReplaces and player.PlayerData.gang.name ~= 'none' then
        local success, errorResult = RemovePlayerFromGang(player.PlayerData.citizenid, player.PlayerData.gang.name)

        if not success then
            return false, errorResult
        end
    end

    if gangName ~= 'none' then
        local success, errorResult = AddPlayerToGang(player.PlayerData.citizenid, gangName, grade)

        if not success then
            return false, errorResult
        end
    end

    return SetPlayerPrimaryGang(player.PlayerData.citizenid, gangName)
end

api.SetGang = SetGang

---Sets a player's gang to be primary only if they already have it.
---@param citizenid string
---@param gangName string
---@return boolean success
---@return ErrorResult? errorResult
function SetPlayerPrimaryGang(citizenid, gangName)
    local player = GetPlayerByCitizenId(citizenid) or GetOfflinePlayer(citizenid)
    if not player then
        return false, {
            code = 'player_not_found',
            message = ('player not found with citizenid %s'):format(citizenid)
        }
    end

    local grade = gangName == 'none' and 0 or player.PlayerData.gangs[gangName]
    if not grade then
        return false, {
            code = 'player_not_in_gang',
            message = ('player %s does not have gang %s'):format(citizenid, gangName)
        }
    end

    local gang = GetGang(gangName)
    if not gang then
        return false, {
            code = 'gang_not_found',
            message = ('%s does not exist in core memory'):format(gangName)
        }
    end

    assert(gang.grades[grade] ~= nil, ('gang %s does not have grade %s'):format(gangName, grade))

    player.PlayerData.gang = {
        name = gangName,
        label = gang.label,
        isboss = gang.grades[grade].isboss,
        bankAuth = gang.grades[grade].bankAuth,
        grade = {
            name = gang.grades[grade].name,
            level = grade
        }
    }

    if player.Offline then
        SaveOffline(player.PlayerData)
    else
        Save(player.PlayerData.source)
        UpdatePlayerData(player.PlayerData.source)
        platform.emitServer('QBCore:Server:OnGangUpdate', player.PlayerData.source, player.PlayerData.gang)
        platform.emitClient('QBCore:Client:OnGangUpdate', player.PlayerData.source, player.PlayerData.gang)
    end

    return true
end

api.SetPlayerPrimaryGang = SetPlayerPrimaryGang

---Adds a player to the gang or overwrites their grade if already in the gang
---@param citizenid string
---@param gangName string
---@param grade? integer
---@return boolean success
---@return ErrorResult? errorResult
function AddPlayerToGang(citizenid, gangName, grade)
    gangName = gangName:lower()
    grade = tonumber(grade) or 0

    if gangName == 'none' then
        return false, {
            code = 'none',
            message = 'none is the default gang, so players cannot be added to it',
        }
    end

    local gang = GetGang(gangName)
    if not gang then
        return false, {
            code = 'gang_not_found',
            message = ('%s does not exist in core memory'):format(gangName)
        }
    end

    if not gang.grades[grade] then
        return false, {
            code = 'gang_missing_grade',
            message = ('gang %s does not have grade %s'):format(gangName, grade)
        }
    end

    local player = GetPlayerByCitizenId(citizenid) or GetOfflinePlayer(citizenid)
    if not player then
        return false, {
            code = 'player_not_found',
            message = ('player not found with citizenid %s'):format(citizenid)
        }
    end

    if player.PlayerData.gangs[gangName] == grade then
        return true
    end

    if qbx.table.size(player.PlayerData.gangs) >= maxGangsPerPlayer and not player.PlayerData.gangs[gangName] then
        return false, {
            code = 'max_gangs',
            message = 'player already has maximum amount of gangs allowed'
        }
    end

    storage.addPlayerToGang(citizenid, gangName, grade)

    if not player.Offline then
        player.PlayerData.gangs[gangName] = grade
        SetPlayerData(player.PlayerData.source, 'gangs', player.PlayerData.gangs)
        platform.emitServer('qbx_core:server:onGroupUpdate', player.PlayerData.source, gangName, grade)
        platform.emitClient('qbx_core:client:onGroupUpdate', player.PlayerData.source, gangName, grade)
    end

    if player.PlayerData.gang.name == gangName then
        SetPlayerPrimaryGang(citizenid, gangName)
    end

    return true
end

api.AddPlayerToGang = AddPlayerToGang

---Remove a player from a gang, setting them to the default no gang.
---@param citizenid string
---@param gangName string
---@return boolean success
---@return ErrorResult? errorResult
function RemovePlayerFromGang(citizenid, gangName)
    if gangName == 'none' then
        return false, {
            code = 'none',
            message = 'none is the default gang, so players cannot be removed from it',
        }
    end

    local player = GetPlayerByCitizenId(citizenid) or GetOfflinePlayer(citizenid)
    if not player then
        return false, {
            code = 'player_not_found',
            message = ('player not found with citizenid %s'):format(citizenid)
        }
    end

    if not player.PlayerData.gangs[gangName] then
        return true
    end

    storage.removePlayerFromGang(citizenid, gangName)
    player.PlayerData.gangs[gangName] = nil

    if player.PlayerData.gang.name == gangName then
        local gang = GetGang('none')
        assert(gang ~= nil, 'cannot find none gang. Does it exist in shared/gangs.lua?')
        player.PlayerData.gang = {
            name = 'none',
            label = gang.label,
            isboss = false,
            bankAuth = false,
            grade = {
                name = gang.grades[0].name,
                level = 0
            }
        }
        if player.Offline then
            SaveOffline(player.PlayerData)
        else
            Save(player.PlayerData.source)
        end
    end

    if not player.Offline then
        SetPlayerData(player.PlayerData.source, 'gangs', player.PlayerData.gangs)
        platform.emitServer('qbx_core:server:onGroupUpdate', player.PlayerData.source, gangName)
        platform.emitClient('qbx_core:client:onGroupUpdate', player.PlayerData.source, gangName)
    end

    return true
end

api.RemovePlayerFromGang = RemovePlayerFromGang

---@param source? integer if player is online
---@param playerData? PlayerEntity|PlayerData
---@return Player player
function CheckPlayerData(source, playerData)
    playerData = playerData or {}
    local Offline = true
    if source then
        playerData.source = source
        playerData.license = playerData.license or platform.getIdentifier(source --[[@as string]], 'license2') or platform.getIdentifier(source --[[@as string]], 'license')
        playerData.name = platform.getPlayerName(source)
        Offline = false
    end

    playerData.userId = playerData.userId or nil
    playerData.citizenid = playerData.citizenid or GenerateUniqueIdentifier('citizenid')
    playerData.cid = (playerData.charinfo and playerData.charinfo.cid) or playerData.cid or 1
    playerData.money = playerData.money or {}
    for moneytype, startamount in pairs(config.money.moneyTypes) do
        playerData.money[moneytype] = playerData.money[moneytype] or startamount
    end

    -- Charinfo
    playerData.charinfo = playerData.charinfo or {}
    playerData.charinfo.firstname = playerData.charinfo.firstname or 'Firstname'
    playerData.charinfo.lastname = playerData.charinfo.lastname or 'Lastname'
    playerData.charinfo.birthdate = playerData.charinfo.birthdate or '00-00-0000'
    playerData.charinfo.gender = playerData.charinfo.gender or 0
    playerData.charinfo.backstory = playerData.charinfo.backstory or 'placeholder backstory'
    playerData.charinfo.nationality = playerData.charinfo.nationality or 'USA'
    playerData.charinfo.phone = playerData.charinfo.phone or GenerateUniqueIdentifier('PhoneNumber')
    playerData.charinfo.account = playerData.charinfo.account or GenerateUniqueIdentifier('AccountNumber')
    playerData.charinfo.cid = playerData.charinfo.cid or playerData.cid
    -- Metadata
    playerData.metadata = playerData.metadata or {}
    playerData.metadata.optin = playerData.metadata.optin and true or false
    playerData.metadata.health = playerData.metadata.health or 200
    playerData.metadata.hunger = playerData.metadata.hunger or 100
    playerData.metadata.thirst = playerData.metadata.thirst or 100
    playerData.metadata.stress = playerData.metadata.stress or 0
    playerData.metadata.oxygen = playerData.metadata.oxygen or 100

    playerData.metadata.isdead = playerData.metadata.isdead or false
    playerData.metadata.inlaststand = playerData.metadata.inlaststand or false
    playerData.metadata.armor = playerData.metadata.armor or 0
    playerData.metadata.ishandcuffed = playerData.metadata.ishandcuffed or false
    playerData.metadata.tracker = playerData.metadata.tracker or false
    playerData.metadata.injail = playerData.metadata.injail or 0
    playerData.metadata.jailitems = playerData.metadata.jailitems or {}
    playerData.metadata.status = playerData.metadata.status or {}
    playerData.metadata.phone = playerData.metadata.phone or {}
    playerData.metadata.bloodtype = playerData.metadata.bloodtype or config.player.bloodTypes[math.random(1, #config.player.bloodTypes)]
    playerData.metadata.dealerrep = playerData.metadata.dealerrep or 0
    playerData.metadata.craftingrep = playerData.metadata.craftingrep or 0
    playerData.metadata.attachmentcraftingrep = playerData.metadata.attachmentcraftingrep or 0
    playerData.metadata.currentapartment = playerData.metadata.currentapartment or nil
    playerData.metadata.jobrep = playerData.metadata.jobrep or {}
    playerData.metadata.jobrep.tow = playerData.metadata.jobrep.tow or 0
    playerData.metadata.jobrep.trucker = playerData.metadata.jobrep.trucker or 0
    playerData.metadata.jobrep.taxi = playerData.metadata.jobrep.taxi or 0
    playerData.metadata.jobrep.hotdog = playerData.metadata.jobrep.hotdog or 0
    playerData.metadata.callsign = playerData.metadata.callsign or 'NO CALLSIGN'
    playerData.metadata.fingerprint = playerData.metadata.fingerprint or GenerateUniqueIdentifier('FingerId')
    playerData.metadata.walletid = playerData.metadata.walletid or GenerateUniqueIdentifier('WalletId')
    playerData.metadata.criminalrecord = playerData.metadata.criminalrecord or {
        hasRecord = false,
        date = nil
    }
    playerData.metadata.licences = playerData.metadata.licences or {
        id = true,
        driver = true,
        weapon = false,
    }
    playerData.metadata.inside = playerData.metadata.inside or {
        house = nil,
        apartment = {
            apartmentType = nil,
            apartmentId = nil,
        }
    }
    playerData.metadata.phonedata = playerData.metadata.phonedata or {
        SerialNumber = GenerateUniqueIdentifier('SerialNumber'),
        InstalledApps = {},
    }
    local jobs, gangs = storage.fetchPlayerGroups(playerData.citizenid)

    local job = GetJob((playerData.job and playerData.job.name)) or GetJob('unemployed')
    assert(job ~= nil, 'Unemployed job not found. Does it exist in shared/jobs.lua?')
    local jobGrade = GetJob((playerData.job and playerData.job.name)) and playerData.job.grade.level or 0
    if not job.grades[jobGrade] then
        jobGrade = 0
    end

    playerData.job = {
        name = (playerData.job and playerData.job.name) or 'unemployed',
        label = job.label,
        payment = job.grades[jobGrade].payment or 0,
        type = job.type,
        onduty = (playerData.job and playerData.job.onduty) or false,
        isboss = job.grades[jobGrade].isboss or false,
        bankAuth = job.grades[jobGrade].bankAuth or false,
        grade = {
            name = job.grades[jobGrade].name,
            level = jobGrade,
        }
    }
    if core.Shared.ForceJobDefaultDutyAtLogin and (job.defaultDuty ~= nil) then
        playerData.job.onduty = job.defaultDuty
    end

    playerData.jobs = jobs or {}
    local gang = GetGang((playerData.gang and playerData.gang.name)) or GetGang('none')
    assert(gang ~= nil, 'none gang not found. Does it exist in shared/gangs.lua?')
    local gangGrade = GetGang((playerData.gang and playerData.gang.name)) and playerData.gang.grade.level or 0
    playerData.gang = {
        name = (playerData.gang and playerData.gang.name) or 'none',
        label = gang.label,
        isboss = gang.grades[gangGrade].isboss or false,
        bankAuth = gang.grades[gangGrade].bankAuth or false,
        grade = {
            name = gang.grades[gangGrade].name,
            level = gangGrade
        }
    }
    playerData.gangs = gangs or {}
    playerData.position = playerData.position or defaultSpawn
    playerData.items = {}
    return CreatePlayer(playerData --[[@as PlayerData]], Offline)
end

---On player logout
---@param source Source
local function ownsPlayerSession(source, player, data, character)
    return core.Players[source] == player and player.PlayerData == data and data.citizenid == character
end

function Logout(source)
    local player = GetPlayer(source)
    if not player then return false end
    local data, character = player.PlayerData, player.PlayerData.citizenid

    player.PlayerData.lastLoggedOut = platform.time()
    if core.Status and core.Status.RequestClientSnapshot then
        core.Status.RequestClientSnapshot(source)
    end
    if not ownsPlayerSession(source, player, data, character) then return false end

    if not Save(player.PlayerData.source) then
        lib.print.error(('Player logout aborted because save failed (source=%s citizenid=%s)'):format(source, player.PlayerData.citizenid))
        return false
    end
    if not ownsPlayerSession(source, player, data, character) then return false end

    platform.emitClient('QBCore:Client:OnPlayerUnload', source)
    if not ownsPlayerSession(source, player, data, character) then return false end
    platform.emitServer('QBCore:Server:OnPlayerUnload', source)

    platform.wait(200)
    if not ownsPlayerSession(source, player, data, character) then return false end
    core.Status.Remove(source)
    core.Players[source] = nil
    counters.PlayerCount = counters.PlayerCount - 1
    platform.emitClient('qbx_core:client:playerLoggedOut', source)
    platform.emitServer('qbx_core:server:playerLoggedOut', source)
    return true
end

api.Logout = Logout

---Create a new character
---Don't touch any of this unless you know what you are doing
---Will cause major issues!
---@param playerData PlayerData
---@param Offline boolean
---@return Player player
function CreatePlayer(playerData, Offline)
    local self = {}
    self.Functions = {}
    self.PlayerData = playerData
    self.Offline = Offline

    ---@deprecated use UpdatePlayerData instead
    function self.Functions.UpdatePlayerData()
        if self.Offline then
            lib.print.warn('UpdatePlayerData is unsupported for offline players')
            return
        end

        UpdatePlayerData(self.PlayerData.source)
    end

    ---@deprecated use SetJob instead
    ---Overwrites current primary job with a new job. Removing the player from their current primary job
    ---@param jobName string name
    ---@param grade? integer defaults to 0
    ---@return boolean success if job was set
    ---@return ErrorResult? errorResult
    function self.Functions.SetJob(jobName, grade)
        return SetJob(self.PlayerData.source, jobName, grade)
    end

    ---@deprecated use SetGang instead
    ---Removes the player from their current primary gang and adds the player to the new gang
    ---@param gangName string name
    ---@param grade? integer defaults to 0
    ---@return boolean success if gang was set
    ---@return ErrorResult? errorResult
    function self.Functions.SetGang(gangName, grade)
        return SetGang(self.PlayerData.source, gangName, grade)
    end

    ---@deprecated use SetJobDuty instead
    ---@param onDuty boolean
    function self.Functions.SetJobDuty(onDuty)
        SetJobDuty(self.PlayerData.source, onDuty)
    end

    ---@deprecated use SetPlayerData instead
    ---@param key string
    ---@param val any
    function self.Functions.SetPlayerData(key, val)
        SetPlayerData(self.PlayerData.source, key, val)
    end

    ---@deprecated use SetMetadata instead
    ---@param meta string
    ---@param val any
    function self.Functions.SetMetaData(meta, val)
        SetMetadata(self.PlayerData.source, meta, val)
    end

    ---@deprecated use GetMetadata instead
    ---@param meta string
    ---@return any
    function self.Functions.GetMetaData(meta)
        return GetMetadata(self.PlayerData.source, meta)
    end

    ---@param key 'hunger' | 'thirst' | 'stress'
    ---@param value number
    function self.Functions.SetStatus(key, value)
        assert(not self.Offline, 'status cache is unavailable for offline players')
        return core.Status.Set(self.PlayerData.source, key, value)
    end

    ---@param key 'hunger' | 'thirst' | 'stress'
    ---@param amount number
    function self.Functions.AddStatus(key, amount)
        assert(not self.Offline, 'status cache is unavailable for offline players')
        return core.Status.Add(self.PlayerData.source, key, amount)
    end

    ---@param key 'hunger' | 'thirst' | 'stress'
    ---@return number?
    function self.Functions.GetStatus(key)
        assert(not self.Offline, 'status cache is unavailable for offline players')
        return core.Status.Get(self.PlayerData.source, key)
    end

    ---@deprecated use SetMetadata instead
    ---@param amount number
    function self.Functions.AddJobReputation(amount)
        if not amount then return end

        amount = tonumber(amount) --[[@as number]]

        local existingAmount = self.PlayerData.metadata.jobrep[self.PlayerData.job.name]
        self.PlayerData.metadata.jobrep[self.PlayerData.job.name] = existingAmount + amount

        ---@diagnostic disable-next-line: param-type-mismatch
        UpdatePlayerData(self.Offline and self.PlayerData.citizenid or self.PlayerData.source)
    end

    ---@param moneytype MoneyType
    ---@param amount number
    ---@param reason? string
    ---@return boolean success if money was added
    function self.Functions.AddMoney(moneytype, amount, reason)
        return AddMoney(self.PlayerData.source, moneytype, amount, reason)
    end

    ---@param moneytype MoneyType
    ---@param amount number
    ---@param reason? string
    ---@return boolean success if money was removed
    function self.Functions.RemoveMoney(moneytype, amount, reason)
        return RemoveMoney(self.PlayerData.source, moneytype, amount, reason)
    end

    ---@param moneytype MoneyType
    ---@param amount number
    ---@param reason? string
    ---@return boolean success if money was set
    function self.Functions.SetMoney(moneytype, amount, reason)
        return SetMoney(self.PlayerData.source, moneytype, amount, reason)
    end

    ---@param moneytype MoneyType
    ---@return boolean | number amount or false if moneytype does not exist
    function self.Functions.GetMoney(moneytype)
        return GetMoney(self.PlayerData.source, moneytype)
    end

    local function qbItemCompat(item)
        if not item then return end

        item.info = item.metadata
        item.amount = item.count

        return item
    end

    ---@param item string
    ---@return string
    local function oxItemCompat(item)
        return item == 'cash' and 'money' or item
    end

    ---@deprecated use ox_inventory exports directly
    ---@param item string
    ---@param amount number
    ---@param metadata? table
    ---@param slot? number
    ---@return boolean success
    function self.Functions.AddItem(item, amount, slot, metadata)
        assert(not self.Offline, 'unsupported for offline players')
        return inventory.AddItem(self.PlayerData.source, oxItemCompat(item), amount, metadata, slot)
    end

    ---@deprecated use ox_inventory exports directly
    ---@param item string
    ---@param amount number
    ---@param slot? number
    ---@return boolean success
    function self.Functions.RemoveItem(item, amount, slot)
        assert(not self.Offline, 'unsupported for offline players')
        return inventory.RemoveItem(self.PlayerData.source, oxItemCompat(item), amount, nil, slot)
    end

    ---@deprecated use ox_inventory exports directly
    ---@param slot number
    ---@return any table
    function self.Functions.GetItemBySlot(slot)
        assert(not self.Offline, 'unsupported for offline players')
        return qbItemCompat(inventory.GetSlot(self.PlayerData.source, slot))
    end

    ---@deprecated use ox_inventory exports directly
    ---@param itemName string
    ---@return any table
    function self.Functions.GetItemByName(itemName)
        assert(not self.Offline, 'unsupported for offline players')
        return qbItemCompat(inventory.GetSlotWithItem(self.PlayerData.source, oxItemCompat(itemName)))
    end

    ---@deprecated use ox_inventory exports directly
    ---@param itemName string
    ---@return any table
    function self.Functions.GetItemsByName(itemName)
        assert(not self.Offline, 'unsupported for offline players')
        return qbItemCompat(inventory.GetSlotsWithItem(self.PlayerData.source, oxItemCompat(itemName)))
    end

    ---@deprecated use ox_inventory exports directly
    function self.Functions.ClearInventory()
        assert(not self.Offline, 'unsupported for offline players')
        return inventory.ClearInventory(self.PlayerData.source)
    end

    ---@deprecated use ox_inventory exports directly
    function self.Functions.SetInventory()
        error('Player.Functions.SetInventory is unsupported for ox_inventory. Try ClearInventory, then add the desired items.')
    end

    ---@deprecated use SetCharInfo instead
    ---@param cardNumber number
    function self.Functions.SetCreditCard(cardNumber)
        self.PlayerData.charinfo.card = cardNumber

        ---@diagnostic disable-next-line: param-type-mismatch
        UpdatePlayerData(self.Offline and self.PlayerData.citizenid or self.PlayerData.source)
    end

    ---@deprecated use Save or SaveOffline instead
    function self.Functions.Save()
        if self.Offline then
            return SaveOffline(self.PlayerData)
        end

        return Save(self.PlayerData.source)
    end

    ---@deprecated call exports.qbx_core:Logout(source)
    function self.Functions.Logout()
        assert(not self.Offline, 'unsupported for offline players')
        Logout(self.PlayerData.source)
    end

    platform.on('qbx_core:server:onJobUpdate', function(jobName, job)
        if self.PlayerData.job.name ~= jobName then return end

        if not job then
            self.PlayerData.job = {
                name = 'unemployed',
                label = 'Civilian',
                isboss = false,
                bankAuth = false,
                onduty = true,
                payment = 10,
                grade = {
                    name = 'Freelancer',
                    level = 0,
                }
            }
        else
            self.PlayerData.job.label = job.label
            self.PlayerData.job.type = job.type or 'none'

            local jobGrade = job.grades[self.PlayerData.job.grade.level]

            if jobGrade then
                self.PlayerData.job.grade.name = jobGrade.name
                self.PlayerData.job.payment = jobGrade.payment or 30
                self.PlayerData.job.isboss = jobGrade.isboss or false
                self.PlayerData.job.bankAuth = jobGrade.bankAuth or false
            else
                self.PlayerData.job.grade = {
                    name = 'No Grades',
                    level = 0,
                    payment = 30,
                    isboss = false,
                }
            end
        end

        if not self.Offline then
            UpdatePlayerData(self.PlayerData.source)
            platform.emitServer('QBCore:Server:OnJobUpdate', self.PlayerData.source, self.PlayerData.job)
            platform.emitClient('QBCore:Client:OnJobUpdate', self.PlayerData.source, self.PlayerData.job)
        end
    end)

    platform.on('qbx_core:server:onGangUpdate', function(gangName, gang)
        if self.PlayerData.gang.name ~= gangName then return end

        if not gang then
            self.PlayerData.gang = {
                name = 'none',
                label = 'No Gang Affiliation',
                isboss = false,
                bankAuth = false,
                grade = {
                    name = 'none',
                    level = 0
                }
            }
        else
            self.PlayerData.gang.label = gang.label

            local gangGrade = gang.grades[self.PlayerData.gang.grade.level]

            if gangGrade then
                self.PlayerData.gang.grade.name = gangGrade.name
                self.PlayerData.gang.isboss = gangGrade.isboss or false
                self.PlayerData.gang.bankAuth = gangGrade.bankAuth or false
            else
                self.PlayerData.gang.grade = {
                    name = 'No Grades',
                    level = 0,
                }
                self.PlayerData.gang.isboss = false
                self.PlayerData.gang.bankAuth = false
            end
        end

        if not self.Offline then
            UpdatePlayerData(self.PlayerData.source)
            platform.emitServer('QBCore:Server:OnGangUpdate', self.PlayerData.source, self.PlayerData.gang)
            platform.emitClient('QBCore:Client:OnGangUpdate', self.PlayerData.source, self.PlayerData.gang)
        end
    end)

    if not self.Offline then
        core.Players[self.PlayerData.source] = self
        core.Status.Initialize(self.PlayerData.source, self.PlayerData.metadata)
        local ped = platform.getPed(self.PlayerData.source)
        lib.callback.await('qbx_core:client:setHealth', self.PlayerData.source, self.PlayerData.metadata.health)
        platform.setArmour(ped, self.PlayerData.metadata.armor)
        -- At this point we are safe to emit new instance to third party resource for load handling
        counters.PlayerCount = counters.PlayerCount + 1
        UpdatePlayerData(self.PlayerData.source)
        platform.emitServer('QBCore:Server:PlayerLoaded', self)
    end

    return self
end

api.CreatePlayer = CreatePlayer

local function withPlayerSaveLock(citizenid, callback)
    local key = tostring(citizenid)
    while playerSaveLocks[key] do
        platform.wait(0)
    end

    playerSaveLocks[key] = true
    local ok, result = pcall(callback)
    playerSaveLocks[key] = nil

    if not ok then
        lib.print.error(('Player save crashed (citizenid=%s): %s'):format(key, result))
        return false
    end

    return result == true
end

local function persistPlayerData(playerData, position)
    local lastError

    for attempt = 1, saveRetryCount do
        local ok, result = pcall(storage.upsertPlayerEntity, {
            playerEntity = playerData,
            position = position,
        })

        if ok and result then
            return true
        end

        lastError = ok and 'database did not confirm the upsert' or tostring(result)
        lib.print.error(('Player save attempt %d/%d failed (citizenid=%s): %s'):format(attempt, saveRetryCount, playerData.citizenid, lastError))

        if attempt < saveRetryCount then
            platform.wait(saveRetryDelayMs * attempt)
        end
    end

    return false
end

---Save player info to database (make sure citizenid is the primary key in your database)
---@param source Source
---@return boolean success
function Save(source)
    local player = core.Players[source]
    if not player then
        lib.print.error('QBX.PLAYER.SAVE - PLAYERDATA IS EMPTY!')
        return false
    end
    local playerData, character = player.PlayerData, player.PlayerData.citizenid

    return withPlayerSaveLock(player.PlayerData.citizenid, function()
        if not ownsPlayerSession(source, player, playerData, character) then return false end
        local statusRevision = core.Status.PrepareSave(source)
        if not ownsPlayerSession(source, player, playerData, character) then return false end
        local ped = platform.getPed(source)
        local pcoords = playerData.position
        local pedExists = ped and ped > 0 and platform.entityExists(ped)

        local inside = playerData.metadata and playerData.metadata.inside
        local apartment = type(inside) == 'table' and inside.apartment
        local inProperty = type(inside) == 'table'
            and (inside.property_id or inside.propertyId or inside.house
                or (type(apartment) == 'table' and apartment.apartmentId))
        local canSavePosition = core.Session and core.Session.canSavePosition(source, player)

        if pedExists and canSavePosition and not inProperty then
            local coords = platform.getCoords(ped)
            pcoords = platform.vec4(coords.x, coords.y, coords.z, platform.getHeading(ped))
        end

        local success = persistPlayerData(playerData, pcoords)
        if not success then return false end

        if ownsPlayerSession(source, player, playerData, character) then
            playerData.position = pcoords
            core.Status.MarkSaved(source, statusRevision)
        end
        lib.print.verbose(('%s PLAYER SAVED!'):format(playerData.name))
        return true
    end)
end

api.Save = Save

---@param playerData PlayerEntity
---@return boolean success
function SaveOffline(playerData)
    if not playerData then
        lib.print.error('SaveOffline - PLAYERDATA IS EMPTY!')
        return false
    end

    return withPlayerSaveLock(playerData.citizenid, function()
        local success = persistPlayerData(playerData, playerData.position.xyz)
        if success then
            lib.print.verbose(('%s OFFLINE PLAYER SAVED!'):format(playerData.name))
        end
        return success
    end)
end

api.SaveOffline = SaveOffline

---@param reason? string
---@return boolean success
---@return integer saved
---@return integer failed
function SaveAllPlayers(reason)
    local sources = {}
    for source in pairs(core.Players) do
        sources[#sources + 1] = source
    end

    local saved, failed = 0, 0
    for i = 1, #sources do
        local source = sources[i]
        local player = core.Players[source]
        local data = player and player.PlayerData
        local character = data and data.citizenid
        if core.Players[source] and core.Status.RequestClientSnapshot then
            core.Status.RequestClientSnapshot(source)
        end
        if player and ownsPlayerSession(source, player, data, character) and Save(source) then
            saved = saved + 1
        else
            failed = failed + 1
        end
    end

    local message = ('Player flush completed (reason=%s saved=%d failed=%d)'):format(reason or 'manual', saved, failed)
    if failed > 0 then
        lib.print.error(message)
    else
        lib.print.info(message)
    end

    return failed == 0, saved, failed
end

api.SaveAllPlayers = SaveAllPlayers

---@param identifier Source | string
---@param key string
---@param value any
function SetPlayerData(identifier, key, value)
    if type(key) ~= 'string' then return end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return end

    player.PlayerData[key] = value

    UpdatePlayerData(identifier)
end

api.SetPlayerData = SetPlayerData

---@param identifier Source | string
function UpdatePlayerData(identifier)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player or player.Offline then return end

    core.BridgeCache.player(player, 'playerData')
    platform.emitServer('QBCore:Player:SetPlayerData', player.PlayerData)
    platform.emitClient('QBCore:Player:SetPlayerData', player.PlayerData.source, player.PlayerData)
end

api.UpdatePlayerData = UpdatePlayerData

---@param identifier Source | string
---@param metadata string
---@param value any
function SetMetadata(identifier, metadata, value)
    if type(metadata) ~= 'string' then return end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return end

    if not player.Offline and core.Status.IsStatusKey(metadata) then
        return core.Status.Set(player.PlayerData.source, metadata, value)
    end

    local oldValue

    if metadata:match('%.') then
        local metaTable, metaKey = metadata:match('([^%.]+)%.(.+)')

        if metaKey:match('%.') then
            lib.print.error('cannot get nested metadata more than 1 level deep')
        end

        oldValue = player.PlayerData.metadata[metaTable]

        player.PlayerData.metadata[metaTable][metaKey] = value

        metadata = metaTable
    else
        oldValue = player.PlayerData.metadata[metadata]

        player.PlayerData.metadata[metadata] = value
    end

    UpdatePlayerData(identifier)

    if not player.Offline then
        platform.emitClient('qbx_core:client:onSetMetaData', player.PlayerData.source, metadata, oldValue, value)
        platform.emitServer('qbx_core:server:onSetMetaData', metadata,  oldValue, value, player.PlayerData.source)

    end

    if metadata == 'inlaststand' or metadata == 'isdead' then
        if player.Offline then
            SaveOffline(player.PlayerData)
        else
            Save(player.PlayerData.source)
        end
    end
end

api.SetMetadata = SetMetadata

---@param identifier Source | string
---@param metadata string
---@return any
function GetMetadata(identifier, metadata)
    if type(metadata) ~= 'string' then return end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return end

    if not player.Offline and core.Status.IsStatusKey(metadata) then
        return core.Status.Get(player.PlayerData.source, metadata)
    end

    if metadata:match('%.') then
        local metaTable, metaKey = metadata:match('([^%.]+)%.(.+)')

        if metaKey:match('%.') then
            lib.print.error('cannot get nested metadata more than 1 level deep')
        end

        return player.PlayerData.metadata[metaTable][metaKey]
    else
        return player.PlayerData.metadata[metadata]
    end
end

api.GetMetadata = GetMetadata

---@param identifier Source | string
---@param charInfo string
---@param value any
function SetCharInfo(identifier, charInfo, value)
    if type(charInfo) ~= 'string' then return end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return end

    --local oldCharInfo = player.PlayerData.charinfo[charInfo]

    player.PlayerData.charinfo[charInfo] = value

    UpdatePlayerData(identifier)
end

api.SetCharInfo = SetCharInfo

---@param source Source
---@param playerMoney table
---@param moneyType MoneyType
---@param amount number
---@param actionType 'add' | 'remove' | 'set'
---@param reason? string
---@param difference? number
local function emitMoneyEvents(source, playerMoney, moneyType, amount, actionType, reason, difference)
    local isSet = actionType == 'set'
    local isRemove = actionType == 'remove'

    platform.emitClient('hud:client:OnMoneyChange', source, moneyType, isSet and math.abs(difference) or amount, isSet and difference < 0 or isRemove, reason)
    platform.emitClient('QBCore:Client:OnMoneyChange', source, moneyType, amount, actionType, reason)
    platform.emitServer('QBCore:Server:OnMoneyChange', source, moneyType, amount, actionType, reason)

    if moneyType == 'bank' and isRemove then
        platform.emitClient('qb-phone:client:RemoveBankMoney', source, amount)
    end

    local oxMoneyType = moneyType == 'cash' and 'money' or moneyType

    if accountsAsItems[oxMoneyType] then
        inventory.SetItem(source, oxMoneyType, playerMoney[moneyType])
    end
end

---@param identifier Source | string
---@param moneyType MoneyType
---@param amount number
---@param reason? string
---@return boolean success if money was added
function AddMoney(identifier, moneyType, amount, reason)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    reason = reason or 'unknown'
    amount = qbx.math.round(tonumber(amount) --[[@as number]])

    if amount < 0 or not player.PlayerData.money[moneyType] then return false end

    if not triggerEventHooks('addMoney', {
        source = player.PlayerData.source,
        moneyType = moneyType,
        amount = amount
    }) then return false end

    player.PlayerData.money[moneyType] = player.PlayerData.money[moneyType] + amount

    if player.Offline then
        SaveOffline(player.PlayerData)
    else
        UpdatePlayerData(identifier)

        local tags = amount > 100000 and config.logging.role or nil
        local resource = platform.getInvokingResource() or cache.resource

        logger.log({
            source = resource,
            webhook = config.logging.webhook['playermoney'],
            event = 'AddMoney',
            color = 'lightgreen',
            tags = tags,
            message = ('**%s (citizenid: %s | id: %s)** $%s (%s) added, new %s balance: $%s reason: %s'):format(platform.getPlayerName(player.PlayerData.source), player.PlayerData.citizenid, player.PlayerData.source, amount, moneyType, moneyType, player.PlayerData.money[moneyType], reason),
            --oxLibTags = ('script:%s,playerName:%s,citizenId:%s,playerSource:%s,amount:%s,moneyType:%s,newBalance:%s,reason:%s'):format(resource, platform.getPlayerName(player.PlayerData.source), player.PlayerData.citizenid, player.PlayerData.source, amount, moneyType, player.PlayerData.money[moneyType], reason)
        })

        emitMoneyEvents(player.PlayerData.source, player.PlayerData.money, moneyType, amount, 'add', reason)
    end

    return true
end

api.AddMoney = AddMoney

---@param identifier Source | string
---@param moneyType MoneyType
---@param amount number
---@param reason? string
---@return boolean success if money was removed
function RemoveMoney(identifier, moneyType, amount, reason)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    reason = reason or 'unknown'
    amount = qbx.math.round(tonumber(amount) --[[@as number]])

    if amount < 0 or not player.PlayerData.money[moneyType] then return false end

    if not triggerEventHooks('removeMoney', {
        source = player.PlayerData.source,
        moneyType = moneyType,
        amount = amount
    }) then return false end

    for _, mType in pairs(config.money.dontAllowMinus) do
        if mType == moneyType then
            if (player.PlayerData.money[moneyType] - amount) < 0 then
                return false
            end
        end
    end

    player.PlayerData.money[moneyType] = player.PlayerData.money[moneyType] - amount

    if player.Offline then
        SaveOffline(player.PlayerData)
    else
        UpdatePlayerData(identifier)

        local tags = amount > 100000 and config.logging.role or nil
        local resource = platform.getInvokingResource() or cache.resource

        logger.log({
            source = resource,
            webhook = config.logging.webhook['playermoney'],
            event = 'RemoveMoney',
            color = 'red',
            tags = tags,
            message = ('** %s (citizenid: %s | id: %s)** $%s (%s) removed, new %s balance: $%s reason: %s'):format(platform.getPlayerName(player.PlayerData.source), player.PlayerData.citizenid, player.PlayerData.source, amount, moneyType, moneyType, player.PlayerData.money[moneyType], reason),
            --oxLibTags = ('script:%s,playerName:%s,citizenId:%s,playerSource:%s,amount:%s,moneyType:%s,newBalance:%s,reason:%s'):format(resource, platform.getPlayerName(player.PlayerData.source), player.PlayerData.citizenid, player.PlayerData.source, amount, moneyType, player.PlayerData.money[moneyType], reason)
        })

        emitMoneyEvents(player.PlayerData.source, player.PlayerData.money, moneyType, amount, 'remove', reason)
    end

    return true
end

api.RemoveMoney = RemoveMoney

---@param identifier Source | string
---@param moneyType MoneyType
---@param amount number
---@param reason? string
---@return boolean success if money was set
function SetMoney(identifier, moneyType, amount, reason)
    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    reason = reason or 'unknown'
    amount = qbx.math.round(tonumber(amount) --[[@as number]])
    local oldAmount = player.PlayerData.money[moneyType]

    if amount < 0 or not oldAmount then return false end

    if not triggerEventHooks('setMoney', {
        source = player.PlayerData.source,
        moneyType = moneyType,
        amount = amount
    }) then return false end

    player.PlayerData.money[moneyType] = amount

    if player.Offline then
        SaveOffline(player.PlayerData)
    else
        UpdatePlayerData(identifier)

        local difference = amount - oldAmount
        local dirChange = difference < 0 and 'removed' or 'added'
        local absDifference = math.abs(difference)
        local tags = absDifference > 50000 and config.logging.role or {}
        local resource = platform.getInvokingResource() or cache.resource

        logger.log({
            source = resource,
            webhook = config.logging.webhook['playermoney'],
            event = 'SetMoney',
            color = difference < 0 and 'red' or 'green',
            tags = tags,
            message = ('**%s (citizenid: %s | id: %s)** $%s (%s) %s, new %s balance: $%s reason: %s'):format(platform.getPlayerName(player.PlayerData.source), player.PlayerData.citizenid, player.PlayerData.source, absDifference, moneyType, dirChange, moneyType, player.PlayerData.money[moneyType], reason),
        })

        emitMoneyEvents(player.PlayerData.source, player.PlayerData.money, moneyType, amount, 'set', reason, difference)
    end

    return true
end

api.SetMoney = SetMoney

---@param identifier Source | string
---@param moneyType MoneyType
---@return boolean | number amount or false if moneytype does not exist
function GetMoney(identifier, moneyType)
    if not moneyType then return false end

    local player = type(identifier) == 'string' and (GetPlayerByCitizenId(identifier) or GetOfflinePlayer(identifier)) or GetPlayer(identifier)

    if not player then return false end

    return player.PlayerData.money[moneyType]
end

api.GetMoney = GetMoney

---@param source Source
---@param citizenid string
---@return boolean success
function DeleteCharacter(source, citizenid)
    local license, license2 = platform.getIdentifier(source --[[@as string]], 'license'), platform.getIdentifier(source --[[@as string]], 'license2')
    local playerEntity = storage.fetchPlayerEntity(citizenid)
    local result, success = playerEntity and playerEntity.license, false

    if license == result or license2 == result then
        local allowed, reason = characterSlots.canLoad(source, playerEntity)
        if not allowed then return false, reason end
        success = storage.deletePlayer(citizenid)
        if success then
            if characterSlots then characterSlots.handleCharacterDeleted(playerEntity) end
            logger.log({
                source = 'qbx_core',
                webhook = config.logging.webhook['joinleave'],
                event = 'Character Deleted',
                color = 'red',
                message = ('**%s** deleted **%s**...'):format(platform.getPlayerName(source), citizenid, source),
            })
        end
    else
        platform.dropPlayer(tostring(source), platform.locale('info.exploit_dropped'))
        logger.log({
            source = 'qbx_core',
            webhook = config.logging.webhook['anticheat'],
            event = 'Anti-Cheat',
            color = 'white',
            tags = config.logging.role,
            message = ('%s has been dropped for character deleting exploit'):format(platform.getPlayerName(source)),
        })
    end

    return success
end

api.Callbacks['qbx_core:server:deleteCharacter'] = DeleteCharacter

---@param citizenid string
function ForceDeleteCharacter(citizenid)
    local playerEntity = storage.fetchPlayerEntity(citizenid)
    local result = playerEntity and playerEntity.license
    if result then
        local player = GetPlayerByCitizenId(citizenid)
        if player then
            platform.dropPlayer(player.PlayerData.source --[[@as string]], 'An admin deleted the character which you are currently using')
        end

        platform.thread(function()
            local success = storage.deletePlayer(citizenid)
            if success then
                if characterSlots then characterSlots.handleCharacterDeleted(playerEntity) end
                logger.log({
                    source = 'qbx_core',
                    webhook = config.logging.webhook['joinleave'],
                    event = 'Character Force Deleted',
                    color = 'red',
                    message = ('Character **%s** got deleted'):format(citizenid),
                })
            end
        end)
    end
end

api.DeleteCharacter = ForceDeleteCharacter

---Generate unique values for player identifiers
---@param type UniqueIdType The type of unique value to generate
---@return string | number UniqueVal unique value generated
function GenerateUniqueIdentifier(type)
    local isUnique, uniqueId
    local table = config.player.identifierTypes[type]
    repeat
        uniqueId = table.valueFunction()
        isUnique = storage.fetchIsUnique(type, uniqueId)
    until isUnique
    return uniqueId
end

api.GenerateUniqueIdentifier = GenerateUniqueIdentifier

api.CheckPlayerData = CheckPlayerData
return api
end
