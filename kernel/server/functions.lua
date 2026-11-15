-- Inactive port of installed QBX; see NOTICE-04.md and LICENSE-QBX.
return function(ports)
    assert(type(ports) == 'table', 'lifecycle ports required')
    local api = {Events = {}, Exports = {}}
    local function listen(name, handler, network)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = network == true}
    end
    local function network(name, handler) listen(name, handler, true) end
    local function describeExport(name, handler) api.Exports[name] = handler; api[name] = handler end
    local native = assert(ports.native, 'explicit platform ports required')
    local setPlayerBucket = assert(native.setPlayerBucket, 'setPlayerBucket port required')
    local setEntityBucket = assert(native.setEntityBucket, 'setEntityBucket port required')
    local emit = assert(native.emit, 'emit port required')
    local emitClient = assert(native.emitClient, 'emitClient port required')
    local isAceAllowed = assert(native.isAceAllowed, 'isAceAllowed port required')
    local getIdentifier = assert(native.getIdentifier, 'getIdentifier port required')
    local getResourceMetadata = assert(native.getResourceMetadata, 'getResourceMetadata port required')
    local getPlayerName = assert(native.getPlayerName, 'getPlayerName port required')
    local dropPlayer = assert(native.dropPlayer, 'dropPlayer port required')
    local entityExists = assert(native.entityExists, 'entityExists port required')
    local deleteEntity = assert(native.deleteEntity, 'deleteEntity port required')
    local spawn = assert(native.spawn, 'spawn port required')
    local locale = assert(native.locale, 'locale port required')
    local core = assert(ports.core, 'authoritative core state required')
    local serverConfig = assert(ports.config, 'server configuration required')
    local positionConfig = ports.notifyPosition
    local storage = assert(ports.storage, 'internal storage required')
    local lookup = assert(ports.lookup, 'internal lookup required')
    local GetPlayer, GetPlayerByCitizenId = lookup.GetPlayer, lookup.GetPlayerByCitizenId
    local GetOfflinePlayer = assert(ports.players, 'internal player service required').GetOfflinePlayer
    local GetJob, GetGang = ports.groups.GetJob, ports.groups.GetGang
    local HasPlayerGotGroup, GetPlayerGroups = ports.membership.HasPlayerGotGroup, ports.membership.GetPlayerGroups
    local DisablePersistence = assert(ports.disablePersistence, 'internal persistence service required')
    local library = assert(ports.library, 'library ports required')
    local logger = assert(ports.logger, 'logger port required')
    local loggingConfig = assert(ports.logging, 'logging configuration required')
    local deliverNotification = assert(ports.notify, 'PR notification delivery port required')
    local time, date = assert(ports.time), assert(ports.date)
    assert(type(ports.resource) == 'string', 'resource name required')
    assert(type(core.Player_Buckets) == 'table' and type(core.Entity_Buckets) == 'table' and type(core.UsableItems) == 'table', 'core buckets/items required')
-- Routing buckets (Only touch if you know what you are doing)

-- Returns the objects related to buckets, first returned value is the player buckets, second one is entity buckets
---@return table
---@return table
local function GetBucketObjects()
    return core.Player_Buckets, core.Entity_Buckets
end

describeExport('GetBucketObjects', GetBucketObjects)

-- Will set the provided player id / source into the provided bucket id
---@param source Source
---@param bucket integer
---@return boolean
local function SetPlayerBucket(source, bucket)
    if not (source or bucket) then return false end

    setPlayerBucket(source --[[@as string]], bucket)
    core.Player_Buckets[source] = bucket
    emit('qbx_core:server:bucketChanged', source, bucket)
    return true
end

describeExport('SetPlayerBucket', SetPlayerBucket)

-- Will set any entity into the provided bucket, for example peds / vehicles / props / etc.
---@param entity integer
---@param bucket integer
---@return boolean
local function SetEntityBucket(entity, bucket)
    if not (entity or bucket) then return false end

    setEntityBucket(entity, bucket)
    core.Entity_Buckets[entity] = bucket
    return true
end

describeExport('SetEntityBucket', SetEntityBucket)

-- Will return an array of all the player ids inside the current bucket
---@param bucket integer
---@return Source[]|boolean
local function GetPlayersInBucket(bucket)
    local curr_bucket_pool = {}
    if not (core.Player_Buckets or next(core.Player_Buckets)) then
        return false
    end

    for k, v in pairs(core.Player_Buckets) do
        if v == bucket then
            curr_bucket_pool[#curr_bucket_pool + 1] = k
        end
    end

    return curr_bucket_pool
end

describeExport('GetPlayersInBucket', GetPlayersInBucket)

-- Will return an array of all the entities inside the current bucket (not for player entities, use GetPlayersInBucket for that)
---@param bucket integer
---@return boolean | integer[]
local function GetEntitiesInBucket(bucket)
    local curr_bucket_pool = {}
    if not (core.Entity_Buckets or next(core.Entity_Buckets)) then
        return false
    end

    for k, v in pairs(core.Entity_Buckets) do
        if v == bucket then
            curr_bucket_pool[#curr_bucket_pool + 1] = k
        end
    end

    return curr_bucket_pool
end

describeExport('GetEntitiesInBucket', GetEntitiesInBucket)

-- Items
---@param item string name
---@param data fun(source: Source, item: unknown)
local function CreateUseableItem(item, data)
    core.UsableItems[item] = data
end

describeExport('CreateUseableItem', CreateUseableItem)

---@param item string name
---@return unknown
local function CanUseItem(item)
    return core.UsableItems[item]
end

describeExport('CanUseItem', CanUseItem)

-- Check if player is whitelisted, kept like this for backwards compatibility or future plans
---@param source Source
---@return boolean
local function IsWhitelisted(source)
    if not serverConfig.whitelist then return true end
    if isAceAllowed(source --[[@as string]], serverConfig.whitelistPermission) then return true end
    return false
end

describeExport('IsWhitelisted', IsWhitelisted)

-- Setting & Removing Permissions

---@deprecated use cfg ACEs instead
---@param source Source
---@param permission string
local function AddPermission(source, permission)
    if not isAceAllowed(source --[[@as string]], permission) then
        library.addPrincipal('player.' .. source, 'group.' .. permission)
        library.addAce('player.' .. source, 'group.' .. permission)
        emitClient('QBCore:Client:OnPermissionUpdate', source)
        emit('QBCore:Server:OnPermissionUpdate', source)
    end
end

---@deprecated use cfg ACEs instead
---@diagnostic disable-next-line: deprecated
describeExport('AddPermission', AddPermission)

---@deprecated use cfg ACEs instead
---@param source Source
---@param permission string
local function RemovePermission(source, permission)
    if permission then
        if isAceAllowed(source --[[@as string]], permission) then
            library.removePrincipal('player.' .. source, 'group.' .. permission)
            library.removeAce('player.' .. source, 'group.' .. permission)
            emitClient('QBCore:Client:OnPermissionUpdate', source)
            emit('QBCore:Server:OnPermissionUpdate', source)
        end
    else
        local hasUpdated = false

        ---@diagnostic disable-next-line: deprecated
        for _, v in pairs(serverConfig.permissions) do
            if isAceAllowed(source --[[@as string]], v) then
                library.removePrincipal('player.' .. source, 'group.' .. v)
                library.removeAce('player.' .. source, 'group.' .. v)
                hasUpdated = true
            end
        end
        if hasUpdated then
            emitClient('QBCore:Client:OnPermissionUpdate', source)
            emit('QBCore:Server:OnPermissionUpdate', source)
        end
    end
end

---@deprecated use cfg ACEs instead
---@diagnostic disable-next-line: deprecated
describeExport('RemovePermission', RemovePermission)

-- Checking for Permission Level
---@deprecated use isAceAllowed
---@param source Source
---@param permission string|string[]
---@return boolean
local function HasPermission(source, permission)
    if type(permission) == 'string' then
        if isAceAllowed(source --[[@as string]], permission) then return true end
    elseif type(permission) == 'table' then
        for _, permLevel in pairs(permission) do
            if isAceAllowed(source --[[@as string]], permLevel) then return true end
        end
    end

    return false
end

---@deprecated use isAceAllowed
---@diagnostic disable-next-line: deprecated
describeExport('HasPermission', HasPermission)

---@deprecated use cfg ACEs instead
---@param source Source
---@return table<string, boolean>
local function GetPermission(source)
    local perms = {}

    ---@diagnostic disable-next-line: deprecated
    for _, v in pairs (serverConfig.permissions) do
        if isAceAllowed(source --[[@as string]], v) then
            perms[v] = true
        end
    end
    return perms
end

---@deprecated use cfg ACEs instead
---@diagnostic disable-next-line: deprecated
describeExport('GetPermission', GetPermission)

-- Opt in or out of admin reports
---@param source Source
---@return boolean
local function IsOptin(source)
    if not serverConfig.requireOptIn then return true end
    local license = getIdentifier(source --[[@as string]], 'license2') or getIdentifier(source --[[@as string]], 'license')
    if not license or not isAceAllowed(source --[[@as string]], 'admin') then return false end
    local player = GetPlayer(source)
    return player.PlayerData.metadata.optin
end

describeExport('IsOptin', IsOptin)

---Opt in or out of admin reports
---@param source Source
local function ToggleOptin(source)
    local license = getIdentifier(source --[[@as string]], 'license2') or getIdentifier(source --[[@as string]], 'license')
    if not license or not isAceAllowed(source --[[@as string]], 'admin') then return end
    local player = GetPlayer(source)
    player.PlayerData.metadata.optin = not player.PlayerData.metadata.optin
    player.Functions.SetMetaData('optin', player.PlayerData.metadata.optin)
end

describeExport('ToggleOptin', ToggleOptin)

-- Check if player is banned
---@param source Source
---@return boolean
---@return string? playerMessage
local function IsPlayerBanned(source)
    local license = getIdentifier(source --[[@as string]], 'license')
    local license2 = getIdentifier(source --[[@as string]], 'license2')
    local result = license2 and storage.fetchBan({ license = license2 })

    if not result then
        result = storage.fetchBan({ license = license })
    end

    if not result then return false end

    if time() < result.expire then
        local timeTable = date('*t', tonumber(result.expire))

        return true, ('You have been banned from the server:\n%s\nYour ban expires in %s/%s/%s %s:%s\n'):format(result.reason, timeTable.day, timeTable.month, timeTable.year, timeTable.hour, timeTable.min)
    else
        spawn(function()
            if license2 then
                storage.deleteBan({ license = license2 })
            end

            storage.deleteBan({ license = license })
        end)
    end

    return false
end

describeExport('IsPlayerBanned', IsPlayerBanned)

---@see client/lua:Notify
local function Notify(source, text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    local title, description
    if type(text) == 'table' then
        title = text.text or 'Placeholder'
        description = text.caption or nil
    elseif subTitle then
        title = text
        description = subTitle
    else
        description = text
    end
    local position = notifyPosition or positionConfig

    deliverNotification(source, {
        id = title,
        title = title,
        description = description,
        duration = duration,
        type = notifyType,
        position = position,
        style = notifyStyle,
        icon = notifyIcon,
        iconColor = notifyIconColor
    })
end

describeExport('Notify', Notify)

---@param InvokingResource string
---@return string version
local function GetCoreVersion(InvokingResource)
    ---@diagnostic disable-next-line: missing-parameter
    local resourceVersion = getResourceMetadata(ports.resource, 'version')
    if InvokingResource and InvokingResource ~= '' then
        library.print.debug(('%s called qbcore version check: %s'):format(InvokingResource or 'Unknown Resource', resourceVersion))
    end
    return resourceVersion
end

describeExport('GetCoreVersion', GetCoreVersion)

---@param playerId Source server id
---@param origin string reason
local function ExploitBan(playerId, origin)
    local name = getPlayerName(playerId)
    local success, errorResult = storage.insertBan({
        name = name,
        license = getIdentifier(playerId --[[@as string]], 'license2') or getIdentifier(playerId --[[@as string]], 'license'),
        discordId = getIdentifier(playerId --[[@as string]], 'discord'),
        ip = getIdentifier(playerId --[[@as string]], 'ip'),
        reason = origin,
        expiration = 2147483647,
        bannedBy = 'Anti Cheat'
    })
    if not success then library.print.error(errorResult) end
    dropPlayer(playerId --[[@as string]], locale('info.exploit_banned', serverConfig.discord))
    logger.log({
        source = 'qbx_core',
        webhook = loggingConfig.webhook['anticheat'],
        event = 'Anti-Cheat',
        color = 'red',
        tags = loggingConfig.role,
        message = success and ('%s has been kicked and banned for exploiting %s'):format(name, origin) or ('%s has been kicked for exploiting %s, ban insert failed'):format(name, origin)
    })
end

describeExport('ExploitBan', ExploitBan)

---@param source Source
---@param filter string | string[] | table<string, number>
---@return boolean
local function HasPrimaryGroup(source, filter)
    local playerData = core.Players[source].PlayerData
    return HasPlayerGotGroup(filter, playerData, true)
end

describeExport('HasPrimaryGroup', HasPrimaryGroup)

---@param source Source
---@param filter string | string[] | table<string, number>
---@return boolean
local function HasGroup(source, filter)
    local playerData = core.Players[source].PlayerData
    return HasPlayerGotGroup(filter, playerData)
end

describeExport('HasGroup', HasGroup)

---@param source Source
---@return table<string, integer>
local function GetGroups(source)
    local playerData = core.Players[source].PlayerData
    return GetPlayerGroups(playerData)
end

describeExport('GetGroups', GetGroups)

---@return PlayerData[]
local function getPlayersData()
    local playersData = {}
    for _, player in pairs(core.Players) do
        playersData[#playersData + 1] = player.PlayerData
    end
    return playersData
end

describeExport('GetPlayersData', getPlayersData)

---@param filters table <string, any>
---@return Player[]
local function searchPlayerEntities(filters)
    local result = {}
    local response = storage.searchPlayerEntities(filters)
    for i = 1, #response do
        local citizenid = response[i].citizenid
        local player = GetPlayerByCitizenId(citizenid)
        if player then
            result[#result+1] = player
        else
            local offlinePlayer = GetOfflinePlayer(citizenid)
            if offlinePlayer then
                result[#result+1] = offlinePlayer
            end
        end
    end
    return result
end

describeExport("SearchPlayers", searchPlayerEntities)

local function isGradeBoss(group, grade)
    local groupData = GetJob(group) or GetGang(group)
    if not groupData then return end
    return groupData.grades[grade].isboss
end

describeExport('IsGradeBoss', isGradeBoss)

local function getGroupMembers(group, type)
    return storage.fetchGroupMembers(group, type)
end

describeExport('GetGroupMembers', getGroupMembers)

---Disables persistence before deleting a vehicle, then deletes it.
---@param vehicle number
local function DeleteVehicle(vehicle)
    DisablePersistence(vehicle)
    if entityExists(vehicle) then
        deleteEntity(vehicle)
    end
end

describeExport('DeleteVehicle', DeleteVehicle)
    return api
end
