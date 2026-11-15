-- Port of installed QBX bridge/qb/server/functions.lua; see NOTICE-88.md and LICENSE-QBX.
-- Internal services are direct ports; inventory/command/UI integration belongs to PR.
return function(ports)
for _,name in ipairs({'core','state','object','lib','native','helpers','inventory'}) do assert(type(ports[name])=='table','QB functions port required: '..name) end
assert(type(ports.decorate)=='function' and type(ports.createExport)=='function' and type(ports.createResourceExport)=='function','QB decorator/descriptors required')
-- Internal core functions are supplied explicitly.
-- Player decorator is supplied by the same compatibility instance.
local functions = {}

local allowMethodOverrides = ports.native.GetConvar('qbx:allowmethodoverrides', 'true') == 'true'
local disableMethodOverrideWarning = ports.native.GetConvar('qbx:disableoverridewarning', 'false') == 'true'

local createQbExport = ports.createExport

---@deprecated use the ports.native.GetEntityCoords and ports.native.GetEntityHeading natives directly
functions.GetCoords = function(entity)
    local coords = ports.native.GetEntityCoords(entity)
    return ports.native.vec4(coords.x, coords.y, coords.z, ports.native.GetEntityHeading(entity))
end

---@deprecated use the native ports.native.GetPlayerIdentifierByType?
functions.GetIdentifier = ports.native.GetPlayerIdentifierByType

---@return Source[]
function functions.GetPlayers()
    local sources = {}
    local players = ports.core.GetQBPlayers()
    for k in pairs(players) do
        sources[#sources+1] = k
    end

    return sources
end

---@deprecated use ports.helpers.spawnVehicle from modules/ports.lib.lua
---@return number?
function functions.SpawnVehicle(source, model, coords, warp)
    local ped = ports.native.GetPlayerPed(source)
    model = type(model) == 'string' and ports.native.joaat(model) or model
    if not coords then coords = ports.native.GetEntityCoords(ped) end
    local heading = coords.w and coords.w or 0.0
    local veh = ports.native.CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, true)
    while not ports.native.DoesEntityExist(veh) do ports.native.Wait(0) end
    if warp then
        while ports.native.GetVehiclePedIsIn(ped, false) ~= veh do
            ports.native.Wait(0)
            ports.native.TaskWarpPedIntoVehicle(ped, veh, -1)
        end
    end
    while ports.native.NetworkGetEntityOwner(veh) ~= source do ports.native.Wait(0) end
    return veh
end

---@deprecated use ports.helpers.spawnVehicle from modules/ports.lib.lua
function functions.CreateVehicle(source, model, _, coords, warp)
    model = type(model) == 'string' and ports.native.joaat(model) or (model --[[@as integer]])
    local ped = ports.native.GetPlayerPed(source)

    local netId = ports.helpers.spawnVehicle({
        model = model,
        spawnSource = coords or ped,
        warp = warp and ped or nil,
    })

    return ports.native.NetworkGetEntityFromNetworkId(netId)
end

---@deprecated No replacement. See https://coxdocs.dev/ox_inventory/Functions/Client#useitem
---@param source Source
---@param item string name
function functions.UseItem(source, item) -- luacheck: ignore
    assert(ports.native.GetResourceState('qb-inventory') ~= 'started', 'qb-inventory is not compatible with qbx_core. use ox_inventory instead')
end

local discordLink = ports.native.GetConvar('qbx:discordlink', 'discord.gg/qbox')
---@deprecated use setKickReason or deferrals for connecting players, and the ports.native.DropPlayer native directly otherwise
functions.Kick = function(source, reason, setKickReason, deferrals)
    reason = ('\n %s \n 🔸 Check our Discord for further information: %s'):format(reason, discordLink)
    if setKickReason then
        setKickReason(reason)
    end
    ports.native.CreateThread(function()
        if deferrals then
            deferrals.update(reason)
            ports.native.Wait(2500)
        end
        if source then
            ports.native.DropPlayer(source --[[@as string]], reason)
        end
        for _ = 0, 4 do
            while true do
                if source then
                    if ports.native.GetPlayerPing(source --[[@as string]]) >= 0 then
                        break
                    end
                    ports.native.Wait(100)
                    ports.native.CreateThread(function()
                        ports.native.DropPlayer(source --[[@as string]], reason)
                    end)
                end
            end
            ports.native.Wait(5000)
        end
    end)
end

---@deprecated check for license usage directly yourself
functions.IsLicenseInUse = function(license)
    local players = ports.native.GetPlayers()

    for _, player in pairs(players) do
        local plyLicense2 = ports.native.GetPlayerIdentifierByType(player --[[@as string]], 'license2')
        local plyLicense = ports.native.GetPlayerIdentifierByType(player --[[@as string]], 'license')
        if plyLicense2 == license or plyLicense == license then
            return true
        end
    end

    return false
end

-- Utility functions

---@deprecated use https://coxdocs.dev/ox_inventory/Functions/Server#search
functions.HasItem = function(source, items, amount) -- luacheck: ignore
    amount = amount or 1
    local count = ports.inventory.search(source, 'count', items)
    if type(items) == 'table' and type(count) == 'table' then
        for _, v in pairs(count) do
            if v < amount then
                return false
            end
        end
        return true
    end
    return count >= amount
end

---@deprecated use ports.helpers.getVehiclePlate from modules/ports.lib.lua
functions.GetPlate = ports.helpers.getVehiclePlate

-- Single add item
---@deprecated incompatible with ox_inventory. Update ox_inventory item config instead.
local function AddItem(itemName, item)
    ports.lib.print.warn(('%s invoked deprecated function AddItem. This is incompatible with ox_inventory'):format(ports.native.GetInvokingResource() or 'unknown resource'))
    if type(itemName) ~= 'string' then
        return false, 'invalid_item_name'
    end

    if ports.object.Shared.Items[itemName] then
        return false, 'item_exists'
    end

    ports.lib.print.warn(('New item %s added but not found in ox_inventory. Printing item data'):format(itemName))
    ports.lib.print.warn(item)
    ports.object.Shared.Items[itemName] = item

    ports.native.TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', itemName, item)
    ports.native.TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

functions.AddItem = AddItem
createQbExport('AddItem', AddItem)

-- Single update item
---@deprecated incompatible with ox_inventory. Update ox_inventory item config instead.
local function UpdateItem(itemName, item)
    ports.lib.print.warn(('%s invoked deprecated function UpdateItem. This is incompatible with ox_inventory'):format(ports.native.GetInvokingResource() or 'unknown resource'))
    if type(itemName) ~= 'string' then
        return false, 'invalid_item_name'
    end
    if not ports.object.Shared.Items[itemName] then
        return false, 'item_not_exists'
    end
    ports.object.Shared.Items[itemName] = item
    ports.native.TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', itemName, item)
    ports.native.TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

functions.UpdateItem = UpdateItem
createQbExport('UpdateItem', UpdateItem)

-- Multiple Add Items
---@deprecated incompatible with ox_inventory. Update ox_inventory item config instead.
local function AddItems(items)
    ports.lib.print.warn(('%s invoked deprecated function AddItems. This is incompatible with ox_inventory'):format(ports.native.GetInvokingResource() or 'unknown resource'))
    local shouldContinue = true
    local message = 'success'
    local errorItem = nil

    for key, value in pairs(items) do
        if type(key) ~= 'string' then
            message = 'invalid_item_name'
            shouldContinue = false
            errorItem = items[key]
            break
        end

        if ports.object.Shared.Items[key] then
            message = 'item_exists'
            shouldContinue = false
            errorItem = items[key]
            break
        end
        ports.lib.print.warn(('New item %s added but not found in ox_inventory. Printing item data'):format(key))
        ports.lib.print.warn(value)

        ports.object.Shared.Items[key] = value
    end

    if not shouldContinue then return false, message, errorItem end
    ports.native.TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', -1, 'Items', items)
    ports.native.TriggerEvent('QBCore:Server:UpdateObject')
    return true, message, nil
end

functions.AddItems = AddItems
createQbExport('AddItems', AddItems)

-- Single Remove Item
---@deprecated incompatible with ox_inventory. Update ox_inventory item config instead.
local function RemoveItem(itemName)
    ports.lib.print.warn(('%s invoked deprecated function RemoveItem. This is incompatible with ox_inventory'):format(ports.native.GetInvokingResource() or 'unknown resource'))
    if type(itemName) ~= 'string' then
        return false, 'invalid_item_name'
    end

    if not ports.object.Shared.Items[itemName] then
        return false, 'item_not_exists'
    end

    ports.object.Shared.Items[itemName] = nil

    ports.native.TriggerClientEvent('QBCore:Client:OnSharedUpdate', -1, 'Items', itemName, nil)
    ports.native.TriggerEvent('QBCore:Server:UpdateObject')
    return true, 'success'
end

functions.RemoveItem = RemoveItem
createQbExport('RemoveItem', RemoveItem)

-- Single add job function which should only be used if you planning on adding a single job
---@deprecated use export CreateJobs
---@param jobName string
---@param job Job
---@return boolean success
---@return string message
local function addJob(jobName, job)
    if type(jobName) ~= 'string' then
        return false, 'invalid_job_name'
    end

    if ports.core.GetJob(jobName) then
        return false, 'job_exists'
    end

    ports.core.CreateJobs({[jobName] = job})
    return true, 'success'
end

functions.AddJob = function(jobName, job)
    return addJob(jobName, job)
end
createQbExport('AddJob', addJob)

-- Multiple Add Jobs
---@deprecated call export CreateJobs
---@param jobs table<string, Job>
---@return boolean success
---@return string message
---@return Job? errorJob job causing the error message. Only present if success is false.
local function addJobs(jobs)
    for key in pairs(jobs) do
        if type(key) ~= 'string' then
            return false, 'invalid_job_name', jobs[key]
        end

        if ports.core.GetJob(key) then
            return false, 'job_exists', jobs[key]
        end
    end

    ports.core.CreateJobs(jobs)
    return true, 'success'
end

functions.AddJobs = function(jobs)
    return addJobs(jobs)
end
createQbExport('AddJobs', addJobs)

-- Single Update Job
---@deprecated call CreateJobs
---@param jobName string
---@param job Job
---@return boolean success
---@return string message
local function updateJob(jobName, job)
    if type(jobName) ~= 'string' then
        return false, 'invalid_job_name'
    end

    if not ports.core.GetJob(jobName) then
        return false, 'job_not_exists'
    end

    ports.core.CreateJobs({[jobName] = job})
    return true, 'success'
end

functions.UpdateJob = function(jobName, job)
    return updateJob(jobName, job)
end
createQbExport('UpdateJob', updateJob)

-- Single Add Gang
---@deprecated call export CreateGangs
---@param gangName string
---@param gang Gang
---@return boolean success
---@return string message
local function addGang(gangName, gang)
    if type(gangName) ~= 'string' then
        return false, 'invalid_gang_name'
    end

    if ports.core.GetGang(gangName) then
        return false, 'gang_exists'
    end

    ports.core.CreateGangs({[gangName] = gang})
    return true, 'success'
end

functions.AddGang = function(gangName, gang)
    return addGang(gangName, gang)
end
createQbExport('AddGang', addGang)

-- Single Update Gang
---@deprecated call export CreateGangs
---@param gangName string
---@param gang Gang
---@return boolean success
---@return string message
local function updateGang(gangName, gang)
    if type(gangName) ~= 'string' then
        return false, 'invalid_gang_name'
    end

    if not ports.core.GetGang(gangName) then
        return false, 'gang_not_exists'
    end

    ports.core.CreateGangs({[gangName] = gang})
    return true, 'success'
end

functions.UpdateGang = function(gangName, gang)
    return updateGang(gangName, gang)
end
createQbExport('UpdateGang', updateGang)

-- Multiple Add Gangs
---@deprecated call export CreateGangs
---@param gangs table<string, Gang>
---@return boolean success
---@return string message
---@return Gang? errorGang present if success is false. Gang that caused the error message.
local function addGangs(gangs)
    for key in pairs(gangs) do
        if type(key) ~= 'string' then
            return false, 'invalid_gang_name', gangs[key]
        end

        if ports.core.GetGang(key) then
            return false, 'gang_exists', gangs[key]
        end
    end

    ports.core.CreateGangs(gangs)
    return true, 'success'
end

functions.AddGangs = function(gangs)
    return addGangs(gangs)
end
createQbExport('AddGangs', addGangs)

functions.RemoveJob = function(jobName)
    return ports.core.RemoveJob(jobName)
end
createQbExport('RemoveJob', ports.core.RemoveJob)

functions.RemoveGang = function(gangName)
    return ports.core.RemoveGang(gangName)
end
createQbExport('RemoveGang', ports.core.RemoveGang)

local function checkExistingMethod(method, methodName)
    local methodType = type(method)
    if methodType == 'function' then
        local warnMessage = allowMethodOverrides and 'A resource is overriding method %s in player class. This can cause unexpected behavior. Disable this warning by setting convar qbx:disableoverridewarning to true' or 'A resource attempted to override method %s in player object and was blocked. Disable this warning by setting convar qbx:disableoverridewarning to true'
        if not disableMethodOverrideWarning then
            ports.lib.print.warn(warnMessage:format(methodName))
        end
        return allowMethodOverrides
    end
    return true
end

---Add a new function to the Functions table of the player class
---Use-case:
-- [[
--     AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
--         functions.AddPlayerMethod(Player.PlayerData.source, 'functionName', function(oneArg, orMore)
--             -- do something here
--         end)
--     end)
-- ]]
---@deprecated
---@param ids number|number[] which players to add the method to. -1 for all players
---@param methodName string
---@param handler function
function functions.AddPlayerMethod(ids, methodName, handler)
    local idType = type(ids)
    if idType == 'number' then
        if ids == -1 then
            for _, v in pairs(ports.state.Players) do
                if checkExistingMethod(v.Functions[methodName], methodName) then
                    v.Functions[methodName] = handler
                end
            end
        else
            if not ports.state.Players[ids] then return end
            if checkExistingMethod(ports.state.Players[ids].Functions[methodName], methodName) then
                ports.state.Players[ids].Functions[methodName] = handler
            end
        end
    elseif idType == 'table' and table.type(ids) == 'array' then
        for i = 1, #ids do
            ---@diagnostic disable-next-line: deprecated
            functions.AddPlayerMethod(ids[i], methodName, handler)
        end
    end
end

---Add a new field table of the player class
---Use-case:
--[[
    AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
        functions.AddPlayerField(Player.PlayerData.source, 'fieldName', 'fieldData')
    end)
]]
---@deprecated
---@param ids number|number[] which players to add a new field to. -1 for all players
---@param fieldName string
---@param data any
function functions.AddPlayerField(ids, fieldName, data)
    local idType = type(ids)
    if idType == 'number' then
        if ids == -1 then
            for _, v in pairs(ports.state.Players) do
                ---@diagnostic disable-next-line: undefined-field
                v.Functions.AddField(fieldName, data)
            end
        else
            if not ports.state.Players[ids] then return end

            ---@diagnostic disable-next-line: undefined-field
            ports.state.Players[ids].Functions.AddField(fieldName, data)
        end
    elseif idType == 'table' and table.type(ids) == 'array' then
        for i = 1, #ids do
            ---@diagnostic disable-next-line: deprecated
            functions.AddPlayerField(ids[i], fieldName, data)
        end
    end
end

-- Add or change (a) method(s) in the Functions table
---@deprecated
---@param methodName string
---@param handler function
---@return boolean success
---@return string message
local function SetMethod(methodName, handler)
    if type(methodName) ~= 'string' then
        return false, 'invalid_method_name'
    end

    functions[methodName] = handler

    ports.native.TriggerEvent('QBCore:Server:UpdateObject')

    return true, 'success'
end

functions.SetMethod = SetMethod
createQbExport('SetMethod', SetMethod)

-- Add or change (a) field(s) in the QBCore table
---@deprecated
---@param fieldName string
---@param data any
---@return boolean success
---@return string message
local function SetField(fieldName, data)
    if type(fieldName) ~= 'string' then
        return false, 'invalid_field_name'
    end

    ports.state[fieldName] = data

    ports.native.TriggerEvent('QBCore:Server:UpdateObject')

    return true, 'success'
end

functions.SetField = SetField
ports.createResourceExport('SetField', SetField)

---@param identifier Identifier
---@return integer source of the player with the matching identifier or 0 if no player found
function functions.GetSource(identifier)
    return ports.core.GetSource(identifier)
end

---@param source Source|string source or identifier of the player
---@return Player?
function functions.GetPlayer(source)
    return ports.decorate(ports.core.GetPlayer(source))
end

---@param citizenid string
---@return Player?
function functions.GetPlayerByCitizenId(citizenid)
    return ports.decorate(ports.core.GetPlayerByCitizenId(citizenid))
end

---@param citizenid string
---@return Player?
function functions.GetOfflinePlayerByCitizenId(citizenid)
    return ports.decorate(ports.core.GetOfflinePlayer(citizenid))
end

---@param number string
---@return Player?
function functions.GetPlayerByPhone(number)
    return ports.decorate(ports.core.GetPlayerByPhone(number))
end

---Will return an array of QB Player class instances
---unlike the ports.native.GetPlayers() wrapper which only returns IDs
---@return table<Source, Player>
function functions.GetQBPlayers()
    local players = ports.core.GetQBPlayers()
    local deprecatedPlayers = {}
    for k, player in pairs(players) do
        deprecatedPlayers[k] = ports.decorate(player)
    end
    return deprecatedPlayers
end

---Gets a list of all on duty players of a specified job and the number
---@param job string name
---@return integer
---@return Source[]
function functions.GetDutyCount(job)
    return ports.core.GetDutyCountJob(job)
end

---Gets a list of all on duty players of a specified job and the number
---@param job string name
---@return Source[]
---@return integer
function functions.GetPlayersOnDuty(job)
    local count, sources = ports.core.GetDutyCountJob(job)
    return sources, count
end

-- Returns the objects related to buckets, first returned value is the player buckets, second one is entity buckets
---@return table
---@return table
function functions.GetBucketObjects()
    return ports.core.GetBucketObjects()
end

-- Will set the provided player id / source into the provided bucket id
---@param source Source
---@param bucket integer
---@return boolean
function functions.SetPlayerBucket(source, bucket)
    return ports.core.SetPlayerBucket(source, bucket)
end

-- Will set any entity into the provided bucket, for example peds / vehicles / props / etc.
---@param entity integer
---@param bucket integer
---@return boolean
function functions.SetEntityBucket(entity, bucket)
    return ports.core.SetEntityBucket(entity, bucket)
end

-- Will return an array of all the player ids inside the current bucket
---@param bucket integer
---@return Source[]|boolean
function functions.GetPlayersInBucket(bucket)
    return ports.core.GetPlayersInBucket(bucket)
end

-- Will return an array of all the entities inside the current bucket (not for player entities, use GetPlayersInBucket for that)
---@param bucket integer
---@return boolean | integer[]
function functions.GetEntitiesInBucket(bucket)
    return ports.core.GetEntitiesInBucket(bucket)
end

-- Items
---@param item string name
---@param data fun(source: Source, item: unknown)
function functions.CreateUseableItem(item, data)
    ports.core.CreateUseableItem(item, data)
end

---@param item string name
---@return unknown
function functions.CanUseItem(item)
    return ports.core.CanUseItem(item)
end

-- Check if player is whitelisted, kept like this for backwards compatibility or future plans
---@param source Source
---@return boolean
function functions.IsWhitelisted(source)
    return ports.core.IsWhitelisted(source)
end

---@param source Source
---@param permission string
function functions.AddPermission(source, permission)
    ports.core.AddPermission(source, permission)
end

---@param source Source
---@param permission string
function functions.RemovePermission(source, permission)
    ports.core.RemovePermission(source, permission)
end

-- Checking for Permission Level
---@param source Source
---@param permission string|string[]
---@return boolean
function functions.HasPermission(source, permission)
    return ports.core.HasPermission(source, permission)
end

---@param source Source
---@return table<string, boolean>
function functions.GetPermission(source)
    return ports.core.GetPermission(source)
end

-- Opt in or out of admin reports
---@param source Source
---@return boolean
function functions.IsOptin(source)
    return ports.core.IsOptin(source)
end

---Opt in or out of admin reports
---@param source Source
function functions.ToggleOptin(source)
    ports.core.ToggleOptin(source)
end

-- Check if player is banned
---@param source Source
---@return boolean
---@return string? playerMessage
function functions.IsPlayerBanned(source)
    return ports.core.IsPlayerBanned(source)
end

---@see client/functions.lua:functions.Notify
function functions.Notify(source, text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    ports.core.Notify(source, text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
end

---@param InvokingResource string
---@return string version
function functions.GetCoreVersion(InvokingResource)
    return ports.core.GetCoreVersion(InvokingResource)
end

return functions
end
