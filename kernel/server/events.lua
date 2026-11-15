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
    local cancelEvent = assert(native.cancelEvent, 'cancelEvent port required')
    local getIdentifier = assert(native.getIdentifier, 'getIdentifier port required')
    local wait = assert(native.wait, 'wait port required')
    local dropPlayer = assert(native.dropPlayer, 'dropPlayer port required')
    local getNumPlayerIndices = assert(native.getNumPlayerIndices, 'getNumPlayerIndices port required')
    local getPlayerName = assert(native.getPlayerName, 'getPlayerName port required')
    local emit = assert(native.emit, 'emit port required')
    local getNumIdentifiers = assert(native.getNumIdentifiers, 'getNumIdentifiers port required')
    local getIdentifierAt = assert(native.getIdentifierAt, 'getIdentifierAt port required')
    local isAceAllowed = assert(native.isAceAllowed, 'isAceAllowed port required')
    local spawn = assert(native.spawn, 'spawn port required')
    local locale = assert(native.locale, 'locale port required')
    local core = assert(ports.core, 'authoritative core state required')
    local serverConfig = assert(ports.config, 'server config required')
    local loggingConfig = assert(ports.logging, 'logging config required')
    local library, logger = assert(ports.library), assert(ports.logger)
    local storage = assert(ports.storage, 'internal storage required')
    local queue = ports.queue
    local globalState = assert(ports.globalState, 'replicated counters port required')
    local functions, lookup = assert(ports.functions), assert(ports.lookup)
    local GetPlayer, Notify = lookup.GetPlayer, functions.Notify
    local IsPlayerBanned, IsWhitelisted = functions.IsPlayerBanned, functions.IsWhitelisted
    local SaveAllPlayers = assert(ports.players).SaveAllPlayers
    local newPromise, time, clock = assert(ports.newPromise), assert(ports.time), assert(ports.clock)
    local querySchema = assert(ports.querySchema, 'explicit schema executor port required')
    assert(type(ports.resource) == 'string', 'resource name required')







-- Event Handler

local usedLicenses = {}

---@param message string
listen('chatMessage', function(eventSource, _, _, message)
    if string.sub(message, 1, 1) == '/' then
        cancelEvent()
        return
    end
end)

listen('playerJoining', function(eventSource)
    local src = eventSource --[[@as string]]
    local license = getIdentifier(src, 'license2') or getIdentifier(src, 'license')
    if not license then return end
    if queue then
        queue.removePlayerJoining(license)
    end
    if not serverConfig.checkDuplicateLicense then return end
    if usedLicenses[license] then
        wait(0) -- mandatory wait for the drop reason to show up
        dropPlayer(src, locale('error.duplicate_license'))
    else
        usedLicenses[license] = true
    end
end)

-- A newly loaded client requests the current values once, with a retry cooldown.
local lastGlobalStateRequest = {}
local globalStateKeys = {'MaxPlayers', 'PVPEnabled', 'PlayerCount'}
network('qbx_core:server:requestGlobalState', function(eventSource)
    local src = tonumber(eventSource)
    if not src or src < 1 or not GetPlayer(src) then return end

    local now = native.GetGameTimer()
    local last = lastGlobalStateRequest[src]
    if last and now >= last and now - last < 1000 then return end
    lastGlobalStateRequest[src] = now

    for _, key in ipairs(globalStateKeys) do
        local value = globalState[key]
        if value ~= nil then
            native.TriggerClientEvent('qbx_core:client:globalState:' .. key, src, value)
        end
    end
end)

---@param reason string
listen('playerDropped', function(eventSource, reason)
    local src = tonumber(eventSource)
    if not src then return end
    lastGlobalStateRequest[src] = nil
    local license = getIdentifier(src, 'license2') or getIdentifier(src, 'license')
    if license then usedLicenses[license] = nil end
    if not core.Players[src] then
        if core.Session then core.Session.clear(src) end
        return
    end
    globalState.PlayerCount = getNumPlayerIndices()
    local player = core.Players[src]
    local data, character = player.PlayerData, player.PlayerData.citizenid
    local function ownsSession()
        return core.Players[src] == player and player.PlayerData == data and data.citizenid == character
    end
    player.PlayerData.lastLoggedOut = time()
    logger.log({
        source = 'qbx_core',
        webhook = loggingConfig.webhook['joinleave'],
        event = 'Dropped',
        color = 'red',
        message = ('**%s** (%s) left...\n **Reason:** %s'):format(getPlayerName(src), player.PlayerData.license, reason),
    })
    if not ownsSession() then return end
    local saved = player.Functions.Save()
    if not saved then
        library.print.error(('Player disconnected before data could be persisted (source=%s citizenid=%s)'):format(src, player.PlayerData.citizenid))
    end

    if not ownsSession() then return end
    core.BridgeCache.logout(src, 'disconnect')
    if not ownsSession() then return end
    emit('pr_bridge:server:OnPlayerUnloaded', src)
    if not ownsSession() then return end
    core.Status.Remove(src)
    if not ownsSession() then return end
    core.Player_Buckets[src] = nil
    core.Players[src] = nil
    if core.Session then core.Session.clear(src) end
end)

listen('txAdmin:events:scheduledRestart', function(_, eventData)
    if eventData.secondsRemaining ~= 60 then return end
    SaveAllPlayers('scheduled_restart')
end)

listen('txAdmin:events:serverShuttingDown', function()
    SaveAllPlayers('server_shutdown')
end)

listen('onResourceStop', function(_, resourceName)
    if resourceName ~= ports.resource then return end
    SaveAllPlayers('resource_stop')
end)

---@param source Source|string
---@return table<string, string>
local function getIdentifiers(source)
    local identifiers = {}

    for i = 0, getNumIdentifiers(source --[[@as string]]) - 1 do
        local identifier = getIdentifierAt(source --[[@as string]], i)
        local prefix = identifier:match('([^:]+)')

        if prefix ~= 'ip' then
            identifiers[prefix] = identifier
        end
    end

    return identifiers
end

-- Player Connecting
---@param name string
---@param _ any
---@param deferrals Deferrals
local function onPlayerConnecting(eventSource, name, _, deferrals)
    local src = eventSource --[[@as string]]
    local license = getIdentifier(src, 'license2') or getIdentifier(src, 'license')
    local finished = false
    local function finish(...)
        if finished then return false end
        finished = true
        -- Preserve arity: approval has no arguments; even a malformed denial stays a denial.
        deferrals.done(...)
        return true
    end
    deferrals.defer()

    -- Mandatory wait
    wait(0)

    if serverConfig.closed then
        if not isAceAllowed(src, 'qbadmin.join') then
            finish(serverConfig.closedReason)
            return
        end
    end

    if not license then
        finish(locale('error.no_valid_license'))
        return
    elseif serverConfig.checkDuplicateLicense and usedLicenses[license] then
        finish(locale('error.duplicate_license'))
        return
    end

    local databaseTime = clock()
    local databasePromise = newPromise()

    -- conduct database-dependant checks
    spawn(function()
        local userId = storage.fetchUserByIdentifier(license)
        if not userId then
            local identifiers = getIdentifiers(src)
            identifiers.username = name

            storage.createUser(identifiers)
        end

        local success, err = pcall(function()
            local isBanned, Reason = IsPlayerBanned(src --[[@as Source]])
            if isBanned then
                wait(0) -- Mandatory wait
                finish(Reason)
            end
        end)

        if not finished and serverConfig.whitelist and success then
            success, err = pcall(function()
                if not IsWhitelisted(src --[[@as Source]]) then
                    wait(0) -- Mandatory wait
                    finish(locale('error.not_whitelisted'))
                end
            end)
        end

        if not success then
            databasePromise:reject(err)
            return
        end
        databasePromise:resolve()
    end)

    local onError = function(err)
        finish(locale('error.connecting_error'))
        library.print.error(err)
    end

    -- wait for database to finish
    databasePromise:next(function()
        if finished then return end
        -- Mandatory wait
        wait(0)
        if finished then return end

        if queue then
            -- Queue owns its waiting/card logic; finalization still goes through the terminal guard.
            local queueDeferrals = {defer = deferrals.defer, presentCard = deferrals.presentCard, done = finish}
            queue.awaitPlayerQueue(src --[[@as Source]], license, queueDeferrals)
        else
            finish()
        end
    end, onError):next(function() end, onError)

    -- if conducting db checks for too long then raise error
    while databasePromise.state == 0 do
        if clock() - databaseTime > 30 then
            finish(locale('error.connecting_database_timeout'))
            error(locale('error.connecting_database_timeout'))
            break
        end
        wait(1000)
    end

    -- Add any additional defferals you may need!
end

listen('playerConnecting', onPlayerConnecting)

listen('onResourceStart', function(_, resource)
    if resource ~= ports.resource then return end

    storage.createUsersTable()

    querySchema([[
        ALTER TABLE `players`
        ADD COLUMN IF NOT EXISTS `userId` INT UNSIGNED DEFAULT NULL AFTER `id`;
    ]])
end)

-- Session load/unload is cached by server/session.lua. Inventory creation
-- still uses QBCore:Server:PlayerLoaded (before the actual spawn completes).

-- Open & Close Server (prevents players from joining)

---@param reason string
network('QBCore:Server:CloseServer', function(eventSource, reason)
    local src = eventSource --[[@as Source]]
    if isAceAllowed(src --[[@as string]], 'admin') then
        reason = reason or 'No reason specified'
        serverConfig.closed = true
        serverConfig.closedReason = reason
        for k in pairs(core.Players) do
            if not isAceAllowed(k --[[@as string]], serverConfig.whitelistPermission) then
                dropPlayer(k --[[@as string]], reason)
            end
        end
    else
        dropPlayer(src --[[@as string]], locale('error.no_permission'))
    end
end)

network('QBCore:Server:OpenServer', function(eventSource)
    local src = eventSource --[[@as Source]]
    if isAceAllowed(src --[[@as string]], 'admin') then
        serverConfig.closed = false
    else
        dropPlayer(src --[[@as string]], locale('error.no_permission'))
    end
end)

-- Player

network('QBCore:ToggleDuty', function(eventSource)
    local src = eventSource --[[@as Source]]
    local player = GetPlayer(src)
    if not player then return end
    if player.PlayerData.job.onduty then
        player.Functions.SetJobDuty(false)
        Notify(src, locale('info.off_duty'))
    else
        player.Functions.SetJobDuty(true)
        Notify(src, locale('info.on_duty'))
    end
end)
    return api
end
