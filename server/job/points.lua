ForgeCore = ForgeCore or {}

local Points = {
    registered = {},
    webhookData = {},
    hookId = nil,
}

local trim = pr_lib.utils.trim

local function normalizeId(value)
    value = (trim(value) or ''):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    value = value:gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return value
end

local function coordsVector(coords)
    if type(coords) ~= 'table' then return nil end

    local ok, vector = pcall(pr_lib.math.toVector, coords)
    if ok and type(vector) == 'vector3' then return vector end
end

local function stashId(groupType, groupName, pointId)
    return ('%s:%s:%s:%s'):format(
        PR.Job.Points.stashPrefix or 'forge_core_stash',
        groupType == 'gang' and 'gang' or 'job',
        normalizeId(groupName),
        normalizeId(pointId)
    )
end

local function getGroups()
    local list = {}
    local jobs = ForgeCore.JobRegistry.getJobs()
    local gangs = ForgeCore.JobRegistry.getGangs()

    for _, group in pairs(jobs or {}) do
        group.type = 'job'
        list[#list + 1] = group
    end

    for _, group in pairs(gangs or {}) do
        group.type = 'gang'
        list[#list + 1] = group
    end

    return list
end

local function getPoint(groupType, groupName, pointId)
    local group = ForgeCore.JobRegistry.get(groupType, groupName)
    if not group or type(group.stashes) ~= 'table' then return nil, nil end

    pointId = normalizeId(pointId)

    for i = 1, #group.stashes do
        local point = group.stashes[i]
        if normalizeId(point and point.id) == pointId then
            return group, point
        end
    end

    return nil, nil
end

local function pointEnabled(point)
    return type(point) == 'table' and point.enabled ~= false
end

local function stashEnabled(point)
    return pointEnabled(point) and type(point.stash) == 'table' and point.stash.enabled ~= false
end

local function dutyEnabled(point)
    return pointEnabled(point) and type(point.duty) == 'table' and point.duty.enabled == true
end

local function playerGroup(playerData, groupType)
    if not playerData then return nil end
    return groupType == 'gang' and playerData.gang or playerData.job
end

local function gradeLevel(groupData)
    local grade = groupData and groupData.grade
    if type(grade) == 'table' then
        return tonumber(grade.level or grade.grade or grade.value) or 0
    end

    return tonumber(grade) or 0
end

local function hasGroupAccess(source, groupType, groupName, minGrade)
    local playerData = pr_lib.framework.GetPlayerData(source)
    if not playerData then return false, 'invalid_player' end

    local group = playerGroup(playerData, groupType)
    if not group or group.name ~= groupName then return false, 'wrong_group' end

    if gradeLevel(group) < (tonumber(minGrade) or 0) then
        return false, 'low_grade'
    end

    return true, playerData
end

local function hasRequiredItem(source, item, amount)
    item = trim(item) or ''
    if item == '' then return true end

    if pr_lib.inventory and pr_lib.inventory.HasItem then
        return pr_lib.inventory.HasItem(source, item, tonumber(amount) or 1) == true, 'missing_item'
    end

    return false, 'item_check_failed'
end

local function sendWebhook(webhook, embed)
    webhook = trim(webhook) or ''
    if webhook == '' then return end

    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        embeds = { embed },
    }), {
        ['Content-Type'] = 'application/json',
    })
end

local function itemInfo(slot)
    if type(slot) ~= 'table' then
        return 'unknown', 0, '{}'
    end

    return tostring(slot.name or 'unknown'), tonumber(slot.count) or 0, json.encode(slot.metadata or {})
end

local function registerWebhookHook()
    if GetResourceState('ox_inventory') ~= 'started' then return end

    if Points.hookId then
        pcall(function()
            exports.ox_inventory:removeHooks(Points.hookId)
        end)
        Points.hookId = nil
    end

    Points.hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
        local stashIdForLog
        local action

        if Points.webhookData[tostring(payload.fromInventory)] and payload.toType == 'player' then
            stashIdForLog = tostring(payload.fromInventory)
            action = 'remove'
        elseif Points.webhookData[tostring(payload.toInventory)] and payload.fromType == 'player' then
            stashIdForLog = tostring(payload.toInventory)
            action = 'add'
        end

        if not stashIdForLog then return end

        local data = Points.webhookData[stashIdForLog]
        if not data or (trim(data.webhook) or '') == '' then return end

        local itemName, amount, metadata = itemInfo(payload.fromSlot or payload.toSlot)
        local playerName = GetPlayerName(payload.source) or tostring(payload.source)
        local discord = GetPlayerIdentifierByType(payload.source, 'discord') or ''
        discord = discord:match('%d+') or discord
        local coords = GetEntityCoords(GetPlayerPed(payload.source))

        sendWebhook(data.webhook, {
            title = data.label or 'Forge Stash',
            description = ForgeCore.t(action == 'add' and 'webhooks.stashes.add' or 'webhooks.stashes.remove', {
                player = playerName,
                discord = discord ~= '' and ('<@%s>'):format(discord) or 'N/A',
                source = tostring(payload.source),
                item = itemName,
                amount = tostring(amount),
                metadata = metadata,
                stash = data.label or stashIdForLog,
                coords = ('%.2f, %.2f, %.2f'):format(coords.x, coords.y, coords.z),
            }),
            color = PR.Job.Points.webhookColor or 65280,
        })
    end)
end

function Points.registerAll()
    if not pr_lib.inventory or not pr_lib.inventory.RegisterStash then return false, 'inventory_unavailable' end

    local groups = getGroups()
    local registered = {}
    local webhookData = {}

    for i = 1, #groups do
        local group = groups[i]
        local stashes = type(group.stashes) == 'table' and group.stashes or {}

        for j = 1, #stashes do
            local point = stashes[j]

            if stashEnabled(point) then
                local stash = point.stash or {}
                local coords = coordsVector(stash.coords or point.coords)
                local id = stashId(group.type, group.name, point.id)
                local slots = tonumber(stash.slots) or PR.Job.Points.defaultSlots
                local weight = tonumber(stash.weight) or PR.Job.Points.defaultWeight
                local minGrade = tonumber(stash.minGrade) or PR.Job.Points.defaultMinGrade
                local stashLabel = trim(stash.label) or ''
                local pointTitle = trim(point.title) or ''
                local label = stashLabel ~= '' and stashLabel or pointTitle ~= '' and pointTitle or group.label
                local accessGroups = {
                    [group.name] = minGrade,
                }

                pr_lib.inventory.RegisterStash(id, label, slots, weight, nil, accessGroups, coords)
                registered[id] = true
                webhookData[id] = {
                    webhook = stash.webhook,
                    label = label,
                }
            end
        end
    end

    Points.registered = registered
    Points.webhookData = webhookData
    registerWebhookHook()
    return true
end

function Points.openStash(source, groupType, groupName, pointId, password)
    groupType = groupType == 'gang' and 'gang' or 'job'

    local group, point = getPoint(groupType, groupName, pointId)
    if not group or not stashEnabled(point) then return false, 'stash_not_found' end

    local stash = point.stash or {}
    local minGrade = tonumber(stash.minGrade) or 0
    local ok, accessErr = hasGroupAccess(source, groupType, group.name, minGrade)
    if not ok then return false, accessErr end

    if (trim(stash.password) or '') ~= '' and tostring(password or '') ~= tostring(stash.password) then
        return false, 'wrong_password'
    end

    local hasItem, itemErr = hasRequiredItem(source, stash.item, stash.itemAmount)
    if not hasItem then return false, itemErr end

    local id = stashId(groupType, group.name, point.id)
    pr_lib.inventory.forceOpenInventory(source, 'stash', id)

    return true
end

function Points.toggleDuty(source, groupName, pointId)
    local group, point = getPoint('job', groupName, pointId)
    if not group or not dutyEnabled(point) then return false, 'duty_not_found' end

    local duty = point.duty or {}
    local ok, playerData = hasGroupAccess(source, 'job', group.name, tonumber(duty.minGrade) or 0)
    if not ok then return false, playerData end

    local current = playerData and playerData.job and playerData.job.onduty == true
    if not pr_lib.framework.SetPlayerDuty then return false, 'duty_unavailable' end

    local changed, err = pr_lib.framework.SetPlayerDuty(source, not current)
    if not changed then return false, err or 'duty_failed' end

    return true, not current
end

ForgeCore.JobPoints = Points
