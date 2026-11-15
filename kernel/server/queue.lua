-- Inactive port of installed QBX; see NOTICE-04.md and LICENSE-QBX.
return function(ports)
    assert(type(ports) == 'table', 'lifecycle ports required')
    if ports.enabled == false then return false end
    local api = {Events = {}, Exports = {}}
    local function listen(name, handler, network)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = network == true}
    end
    local function network(name, handler) listen(name, handler, true) end
    local function describeExport(name, handler) api.Exports[name] = handler; api[name] = handler end
    local native = assert(ports.native, 'explicit platform ports required')
    local cancelEvent = assert(native.cancelEvent, 'cancelEvent port required')
    local doesPlayerExist = assert(native.doesPlayerExist, 'doesPlayerExist port required')
    local wait = assert(native.wait, 'wait port required')
    local getNumPlayerIndices = assert(native.getNumPlayerIndices, 'getNumPlayerIndices port required')
    local locale = assert(native.locale, 'locale port required')
    local library = assert(ports.library, 'queue library ports required')
    local getResourceState = assert(native.getResourceState, 'resource-state port required')
    local stopResource = assert(native.stopResource, 'resource stop port required')
    local time = assert(ports.time, 'clock port required')

-- Disable hardcap because it kicks the player when the server is full

---@param resource string
listen('onResourceStarting', function(_, resource)
    if resource == 'hardcap' then
        library.print.info('Preventing hardcap from starting...')
        cancelEvent()
    end
end)

local bootstrapped = false
function api.Bootstrap()
    if bootstrapped then return false end
    bootstrapped = true
    if getResourceState('hardcap'):find('start') then
        library.print.info('Stopping hardcap...')
        stopResource('hardcap')
    end
    return true
end

-- Queue code

local config = assert(ports.config, 'local queue configuration required')
local maxPlayers = ports.maxPlayers or 48

-- destructure frequently used config options
local waitingEmojis = config.waitingEmojis
local waitingEmojiCount = #waitingEmojis
local useAdaptiveCard = config.useAdaptiveCard
local generateCard = config.generateCard

---@type SubQueue[]
local subQueues = {}
for i = 1, #config.subQueues do
    subQueues[i] = {
        name = config.subQueues[i].name,
        predicate = config.subQueues[i].predicate,
        cardOptions = config.subQueues[i].cardOptions,
        positions = {},
        size = 0,
    }
end

---Player license to queue data map.
---@type table<string, PlayerQueueData>
local playerDatas = {}
local totalQueueSize = 0

---@param license string
---@param subQueueIndex number
local function enqueue(license, subQueueIndex)
    local subQueue = subQueues[subQueueIndex]

    subQueue.size = subQueue.size + 1
    subQueue.positions[license] = subQueue.size

    local globalPos = subQueue.size
    -- increase set the global position of the current player by the sizes of sub-queues the player comes after
    for i = 1, subQueueIndex - 1 do
        globalPos = globalPos + subQueues[i].size
    end

    totalQueueSize = totalQueueSize + 1
    playerDatas[license] = {
        waitingSeconds = 0,
        subQueueIndex = subQueueIndex,
        globalPos = globalPos,
    }

    -- inrease the global positions of players who are in sub-queues that come after the current player
    for i = subQueueIndex + 1, #subQueues do
        for k in pairs(subQueues[i].positions) do
            playerDatas[k].globalPos = playerDatas[k].globalPos + 1
        end
    end
end

---@param license string
local function dequeue(license)
    local subQueueIndex = playerDatas[license].subQueueIndex
    local subQueue = subQueues[subQueueIndex]
    local subQueuePos = subQueue.positions[license]

    subQueue.size = subQueue.size - 1
    subQueue.positions[license] = nil

    totalQueueSize = totalQueueSize - 1
    playerDatas[license] = nil

    -- decrease the positions of players who are after the current player in the same sub-queue
    for k, v in pairs(subQueue.positions) do
        if v > subQueuePos then
            subQueue.positions[k] = subQueue.positions[k] - 1
            playerDatas[k].globalPos = playerDatas[k].globalPos - 1
        end
    end

    -- decrease the global positions of players who are in sub-queues that come after the current player
    for i = subQueueIndex + 1, #subQueues do
        for k in pairs(subQueues[i].positions) do
            playerDatas[k].globalPos = playerDatas[k].globalPos - 1
        end
    end
end

---Map of player licenses that passed the queue and are downloading server content.
---Needs to be saved because these players won't be part of regular player counts such as `getNumPlayerIndices`.
---@type table<string, { source: Source, timestamp: integer }>
local joiningPlayers = {}
local joiningPlayerCount = 0

---@param license string
local function removePlayerJoining(license)
    if joiningPlayers[license] then
        joiningPlayerCount = joiningPlayerCount - 1
    end
    joiningPlayers[license] = nil
end

---@param license string
local function awaitPlayerJoinsOrDisconnects(license)
    local joiningData
    while true do
        joiningData = joiningPlayers[license]
        if not joiningData then return end

        -- wait until the player finally joins or disconnects while installing server content
        -- this may result in waiting ~2 additional minutes if the player disconnects as FXServer will think that the player exists
        while doesPlayerExist(joiningData.source --[[@as string]]) do
            wait(1000)
        end

        -- wait until either the player reconnects or was disconnected for too long
        while joiningPlayers[license] and joiningPlayers[license].source == joiningData.source and (time() - joiningData.timestamp) < config.joiningTimeoutSeconds do
            wait(1000)
        end

        -- if the player disconnected for too long stop waiting for them
        if joiningPlayers[license] and joiningPlayers[license].source == joiningData.source then
            removePlayerJoining(license)
            break
        end
    end
end

---@param source Source
---@param license string
local function updatePlayerJoining(source, license)
    if not joiningPlayers[license] then
        joiningPlayerCount = joiningPlayerCount + 1
    end
    joiningPlayers[license] = { source = source, timestamp = time() }
end

---@type table<string, true>
local timingOut = {}

---@param license string
---@return boolean shouldDequeue
local function awaitPlayerTimeout(license)
    timingOut[license] = true

    wait(config.timeoutSeconds * 1000)

    -- if timeout data wasn't consumed then the player hasn't reconnected
    if timingOut[license] then
        timingOut[license] = nil
        return true
    end

    return false
end

---@param license string
---@return boolean playerTimingOut
local function isPlayerTimingOut(license)
    local playerTimingOut = timingOut[license] or false
    timingOut[license] = nil
    return playerTimingOut
end

---@param waitingSeconds number
---@param waitingEmojiIndex number
local function createDisplayTime(waitingSeconds, waitingEmojiIndex)
    local minutes = math.floor(waitingSeconds / 60)
    local seconds = waitingSeconds % 60
    return ('%02d:%02d %s'):format(minutes, seconds, waitingEmojis[waitingEmojiIndex])
end

---@param source Source
---@param license string
---@param deferrals Deferrals
local function awaitPlayerQueue(source, license, deferrals)
    if joiningPlayers[license] then
        -- the player was in the middle of joining, so let them in
        updatePlayerJoining(source, license)
        deferrals.done()
        return
    end

    local playerTimingOut = isPlayerTimingOut(license)
    local data = playerDatas[license]

    if data and not playerTimingOut then
        deferrals.done(locale('error.already_in_queue'))
        return
    end

    if not playerTimingOut then
        local subQueueIndex
        for i = 1, #subQueues do
            local predicate = subQueues[i].predicate
            if not predicate or predicate(source) then
                subQueueIndex = i
                break
            end
        end

        if not subQueueIndex then
            deferrals.done(locale('error.no_subqueue'))
            return
        end

        enqueue(license, subQueueIndex)
        data = playerDatas[license]
    end

    local waitingEmojiIndex = 1 -- for updating the waiting emoji
    local subQueue = subQueues[data.subQueueIndex]

    -- wait until the player disconnected or until there are available slots and the player is first in queue
    while doesPlayerExist(source --[[@as string]]) and ((getNumPlayerIndices() + joiningPlayerCount) >= maxPlayers or data.globalPos > 1) do
        local displayTime = createDisplayTime(data.waitingSeconds, waitingEmojiIndex)

        if useAdaptiveCard then
            deferrals.presentCard(generateCard({
                subQueue = subQueue,
                globalPos = data.globalPos,
                totalQueueSize = totalQueueSize,
                displayTime = displayTime,
            }))
        end

        data.waitingSeconds = data.waitingSeconds + 1
        waitingEmojiIndex = waitingEmojiIndex + 1

        if waitingEmojiIndex > waitingEmojiCount then
            waitingEmojiIndex = 1
        end

        wait(1000)
    end

    -- if the player disconnected while waiting in queue
    if not doesPlayerExist(source --[[@as string]]) then
        if awaitPlayerTimeout(license) then
            dequeue(license)
        end
        return
    end

    updatePlayerJoining(source, license)
    dequeue(license)
    deferrals.done()

    awaitPlayerJoinsOrDisconnects(license)
end

api.awaitPlayerQueue = awaitPlayerQueue
api.removePlayerJoining = removePlayerJoining
    return api
end
