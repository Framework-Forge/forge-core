-- Player lookup subset of installed server/functions.lua; see ../NOTICE-02.md.
return function(ports)
assert(type(ports) == 'table' and type(ports.core) == 'table' and type(ports.core.Players) == 'table', 'player state required')
assert(type(ports.getIdentifiers) == 'function', 'identifier port required')
local playerRecords, getIdentifiers = ports.core.Players, ports.getIdentifiers
local api = {}
-- Getters
-- Get your player first and then trigger a function on them
-- ex: local player = GetPlayer(source)
-- ex: local example = player.functionname(parameter)

---@alias Identifier 'steam'|'license'|'license2'|'xbl'|'ip'|'discord'|'live'

---@param identifier Identifier
---@return integer source of the player with the matching identifier or 0 if no player found
local function GetSource(identifier)
    for src in pairs(playerRecords) do
        local idens = getIdentifiers(src)
        for _, id in pairs(idens) do
            if identifier == id then
                return src
            end
        end
    end
    return 0
end

api.GetSource = GetSource

---@param identifier Identifier
---@return integer source of the player with the matching identifier or 0 if no player found
local function GetUserId(identifier)
    for src in pairs(playerRecords) do
        local idens = getIdentifiers(src)
        for _, id in pairs(idens) do
            if identifier == id then
                return playerRecords[src].PlayerData.userId
            end
        end
    end
    return 0
end

api.GetUserId = GetUserId

---@param source Source|string source or identifier of the player
---@return Player
local function GetPlayer(source)
    if tonumber(source) ~= nil then
        return playerRecords[tonumber(source)]
    else
        return playerRecords[GetSource(source --[[@as string]])]
    end
end

api.GetPlayer = GetPlayer

---@param citizenid string
---@return Player?
local function GetPlayerByCitizenId(citizenid)
    for src in pairs(playerRecords) do
        if playerRecords[src].PlayerData.citizenid == citizenid then
            return playerRecords[src]
        end
    end
end

api.GetPlayerByCitizenId = GetPlayerByCitizenId

---@param userId string
---@return Player?
local function GetPlayerByUserId(userId)
    for src in pairs(playerRecords) do
        if playerRecords[src].PlayerData.userId == userId then
            return playerRecords[src]
        end
    end
end

api.GetPlayerByUserId = GetPlayerByUserId

---@param number string
---@return Player?
local function GetPlayerByPhone(number)
    for src in pairs(playerRecords) do
        if playerRecords[src].PlayerData.charinfo.phone == number then
            return playerRecords[src]
        end
    end
end

api.GetPlayerByPhone = GetPlayerByPhone

---Will return an array of QB Player class instances
---unlike the GetPlayers() wrapper which only returns IDs
---@return table<Source, Player>
local function GetQBPlayers()
    return playerRecords
end

api.GetQBPlayers = GetQBPlayers

---Gets a list of all on duty players of a specified job and the number
---@param job string name
---@return integer
---@return Source[]
local function GetDutyCountJob(job)
    local players = {}
    local count = 0
    for src, player in pairs(playerRecords) do
        if player.PlayerData.job.name == job then
            if player.PlayerData.job.onduty then
                players[#players + 1] = src
                count = count + 1
            end
        end
    end
    return count, players
end

api.GetDutyCountJob = GetDutyCountJob

---Gets a list of all on duty players of a specified job type and the number
---@param type string
---@return integer
---@return Source[]
local function GetDutyCountType(type)
    local players = {}
    local count = 0
    for src, player in pairs(playerRecords) do
        if player.PlayerData.job.type == type then
            if player.PlayerData.job.onduty then
                players[#players + 1] = src
                count = count + 1
            end
        end
    end
    return count, players
end

api.GetDutyCountType = GetDutyCountType


return api
end
