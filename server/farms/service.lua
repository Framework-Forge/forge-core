ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    state = {},
    activeRoutes = {},
}

local function debug(level, message)
    local api = pr_lib and pr_lib.debug
    local fn = api and api[level]
    if type(fn) == 'function' then
        fn(message)
    elseif PR.Debug == true or level == 'warn' or level == 'error' then
        print(('[forge-core:farms][%s] %s'):format(level, tostring(message)))
    end
end

local function notify(source, data)
    if not source or source <= 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('farms.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function trim(value)
    if value == nil then return '' end
    if pr_lib and pr_lib.utils and pr_lib.utils.trim then return pr_lib.utils.trim(value) end
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function clone(value)
    return pr_lib and pr_lib.table and pr_lib.table.clone and pr_lib.table.clone(value) or value
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function numberValue(value, fallback)
    return tonumber(value) or fallback or 0
end

local function normalizeId(value, fallback)
    value = trim(value)
    if value == '' then value = fallback or '' end
    value = value:lower():gsub('%s+', '_'):gsub('[^%w_%-]', ''):gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return value
end

local function vectorValue(value)
    value = type(value) == 'table' and value or {}
    return {
        x = numberValue(value.x or value[1]),
        y = numberValue(value.y or value[2]),
        z = numberValue(value.z or value[3]),
    }
end

local function canManage(source)
    if source == 0 then return true end
    if ForgeCore.JobService and ForgeCore.JobService.canManage then return ForgeCore.JobService.canManage(source) end
    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function gradeLevel(group)
    local grade = group and group.grade
    if type(grade) == 'table' then return tonumber(grade.level or grade.grade or grade.value) or 0 end
    return tonumber(grade) or 0
end

local function canUseFarm(source, farm)
    if farm.public == true then return true end
    if not pr_lib or not pr_lib.framework or not pr_lib.framework.GetPlayerData then return false end

    local playerData = pr_lib.framework.GetPlayerData(source)
    if type(playerData) ~= 'table' then return false end

    local group = farm.groupType == 'gang' and playerData.gang or playerData.job
    local activeName = tostring(group and group.name or ''):lower()
    local requiredName = tostring(farm.groupName or ''):lower()

    return requiredName ~= '' and activeName == requiredName and gradeLevel(group) >= (tonumber(farm.minGrade) or 0)
end

local function itemExists(name)
    name = trim(name)
    if name == '' then return false end
    if pr_lib and pr_lib.inventory and pr_lib.inventory.Items then
        return pr_lib.inventory.Items(name) ~= nil
    end
    return true
end

local function itemLabel(name)
    if pr_lib and pr_lib.inventory and pr_lib.inventory.GetItemLabel then
        local label = pr_lib.inventory.GetItemLabel(name)
        if label and label ~= '' then return label end
    end
    return name
end

local function addItem(source, name, count, metadata)
    count = math.floor(numberValue(count, 0))
    if count <= 0 then return true end
    if pr_lib and pr_lib.inventory and pr_lib.inventory.AddItem then
        return pr_lib.inventory.AddItem(source, name, count, metadata)
    end
    if GetResourceState('ox_inventory'):find('start') then
        return exports.ox_inventory:AddItem(source, name, count, metadata)
    end
    return false
end

local function hasTool(source, required)
    required = type(required) == 'table' and required or {}
    local item = trim(required.item)
    if item == '' then return true end

    local results
    if pr_lib and pr_lib.inventory and pr_lib.inventory.Search then
        results = pr_lib.inventory.Search(source, 'slots', item)
    elseif GetResourceState('ox_inventory'):find('start') then
        results = exports.ox_inventory:Search(source, 'slots', item)
    end

    if type(results) ~= 'table' then return false end
    local durability = numberValue(required.durability, 0)
    if durability <= 0 then return true end

    for _, slot in pairs(results) do
        local metadata = type(slot) == 'table' and type(slot.metadata) == 'table' and slot.metadata or {}
        if numberValue(metadata.durability, 100) >= durability then return true, slot end
    end

    return false
end

local function consumeTool(source, required)
    required = type(required) == 'table' and required or {}
    local durability = numberValue(required.durability, 0)
    if durability <= 0 then return true end

    local ok, slot = hasTool(source, required)
    if not ok or type(slot) ~= 'table' then return false end
    local current = type(slot.metadata) == 'table' and numberValue(slot.metadata.durability, 100) or 100
    local nextDurability = math.max(0, current - durability)

    if pr_lib and pr_lib.inventory and pr_lib.inventory.SetDurability then
        pr_lib.inventory.SetDurability(source, slot.slot, nextDurability)
        return true
    end
    if GetResourceState('ox_inventory'):find('start') then
        exports.ox_inventory:SetDurability(source, slot.slot, nextDurability)
        return true
    end

    return true
end

local function normalizeAnimation(animation)
    animation = type(animation) == 'table' and animation or {}
    local mode = trim(animation.mode)
    if mode == '' then mode = 'preset' end

    return {
        mode = mode,
        preset = normalizeId(animation.preset, 'pickup'),
        scenario = trim(animation.scenario),
        dict = trim(animation.dict or animation.animDict),
        anim = trim(animation.anim or animation.animName),
    }
end

local function normalizeExtra(extra, index)
    extra = type(extra) == 'table' and extra or {}
    local item = normalizeId(extra.item or extra.name, ('extra_%s'):format(index or 1))
    return {
        item = item,
        min = math.max(0, math.floor(numberValue(extra.min, 0))),
        max = math.max(0, math.floor(numberValue(extra.max, 1))),
    }
end

local function normalizeFarmItem(item, index)
    item = type(item) == 'table' and item or {}
    local reward = normalizeId(item.reward or item.item or item.name, ('item_%s'):format(index or 1))
    local extras = {}
    for i, extra in ipairs(type(item.extraItems) == 'table' and item.extraItems or {}) do
        local normalized = normalizeExtra(extra, i)
        if normalized.item ~= '' then extras[#extras + 1] = normalized end
    end

    local points = {}
    for _, point in ipairs(type(item.points) == 'table' and item.points or {}) do
        points[#points + 1] = vectorValue(point)
    end

    local required = type(item.required) == 'table' and item.required or type(item.collectItem) == 'table' and item.collectItem or {}
    local limits = type(item.limits) == 'table' and item.limits or {}

    return {
        id = normalizeId(item.id, reward),
        label = trim(item.label or item.customName) ~= '' and trim(item.label or item.customName) or itemLabel(reward),
        enabled = boolValue(item.enabled, true),
        reward = reward,
        min = math.max(0, math.floor(numberValue(item.min, 1))),
        max = math.max(0, math.floor(numberValue(item.max, 1))),
        collectTime = math.max(1000, math.floor(numberValue(item.collectTime, PR.Farms.Defaults.collectTime))),
        randomRoute = boolValue(item.randomRoute, false),
        unlimited = boolValue(item.unlimited, false),
        required = {
            item = normalizeId(required.item or required.name, ''),
            durability = math.max(0, numberValue(required.durability, 0)),
            vehicle = trim(required.vehicle or item.requiredVehicle or item.collectVehicle),
        },
        limits = {
            enabled = boolValue(limits.enabled, false),
            scope = trim(limits.scope) == 'farm' and 'farm' or 'item',
            maxPerRoute = math.max(0, math.floor(numberValue(limits.maxPerRoute, 0))),
            cooldownMinutes = math.max(0, math.floor(numberValue(limits.cooldownMinutes, 0))),
            onceDaily = boolValue(limits.onceDaily, false),
        },
        animation = normalizeAnimation(item.animation),
        points = points,
        extraItems = extras,
    }
end

local function normalizeFarm(farm)
    farm = type(farm) == 'table' and farm or {}
    local items = {}
    for i, item in ipairs(type(farm.items) == 'table' and farm.items or {}) do
        local normalized = normalizeFarmItem(item, i)
        if normalized.reward ~= '' then items[#items + 1] = normalized end
    end

    return {
        id = math.floor(numberValue(farm.id or farm.farmId)),
        name = trim(farm.name) ~= '' and trim(farm.name) or ForgeCore.t('farms.default_name'),
        enabled = boolValue(farm.enabled, true),
        public = boolValue(farm.public, true),
        groupType = trim(farm.groupType) ~= '' and trim(farm.groupType) or 'job',
        groupName = normalizeId(farm.groupName or farm.group and farm.group.name, ''),
        minGrade = math.max(0, math.floor(numberValue(farm.minGrade or farm.group and farm.group.grade, 0))),
        start = {
            coords = vectorValue(farm.start and farm.start.coords or farm.start and farm.start.location),
            rotation = numberValue(farm.start and farm.start.rotation, 0.0),
            label = trim(farm.start and farm.start.label) ~= '' and trim(farm.start and farm.start.label) or ForgeCore.t('menu.farms.open_target'),
        },
        items = items,
    }
end

local function normalizeState(state)
    state = type(state) == 'table' and state or {}
    local settings = type(state.settings) == 'table' and state.settings or {}
    local normalized = {
        settings = {
            enabled = boolValue(settings.enabled, PR.Farms.Defaults.enabled),
        },
        nextFarmId = math.max(1, math.floor(numberValue(state.nextFarmId, 1))),
        farms = {},
        usage = type(state.usage) == 'table' and state.usage or {},
        revision = GetGameTimer(),
    }

    local seen = {}
    for _, farm in ipairs(type(state.farms) == 'table' and state.farms or {}) do
        farm = normalizeFarm(farm)
        if farm.id > 0 and not seen[farm.id] then
            seen[farm.id] = true
            normalized.farms[#normalized.farms + 1] = farm
            if farm.id >= normalized.nextFarmId then normalized.nextFarmId = farm.id + 1 end
        end
    end

    table.sort(normalized.farms, function(left, right) return left.id < right.id end)
    return normalized
end

local function playerCitizenId(source)
    if pr_lib and pr_lib.framework and pr_lib.framework.GetPlayerData then
        local data = pr_lib.framework.GetPlayerData(source)
        if type(data) == 'table' then
            return trim(data.citizenid or data.citizenId or data.identifier or data.license)
        end
    end

    return trim(GetPlayerIdentifierByType(source, 'license') or GetPlayerIdentifier(source, 0) or source)
end

local function usageKey(source, farmId, item)
    local limits = type(item.limits) == 'table' and item.limits or {}
    local segment = limits.scope == 'farm' and 'farm' or tostring(item.id)
    return ('%s:%s:%s'):format(playerCitizenId(source), tostring(farmId), segment)
end

local function activeRouteKey(source, farmId, itemId)
    return ('%s:%s:%s'):format(tostring(source), tostring(farmId), tostring(itemId))
end

local function currentDay()
    return os.date('%Y-%m-%d')
end

local function checkUsageLimit(source, farmId, item)
    local limits = type(item.limits) == 'table' and item.limits or {}
    if limits.enabled ~= true then return true end

    local key = usageKey(source, farmId, item)
    local usage = type(Service.state.usage) == 'table' and Service.state.usage[key] or nil
    if type(usage) ~= 'table' then return true end

    local now = os.time()
    local cooldownMinutes = tonumber(limits.cooldownMinutes) or 0
    if cooldownMinutes > 0 and tonumber(usage.lastAt) and now - tonumber(usage.lastAt) < cooldownMinutes * 60 then
        return false, 'cooldown_active'
    end

    if limits.onceDaily == true and usage.day == currentDay() then
        return false, 'daily_limit'
    end

    return true
end

local function registerUsage(source, farmId, item)
    local limits = type(item.limits) == 'table' and item.limits or {}
    if limits.enabled ~= true then return end

    Service.state.usage = type(Service.state.usage) == 'table' and Service.state.usage or {}
    Service.state.usage[usageKey(source, farmId, item)] = {
        lastAt = os.time(),
        day = currentDay(),
    }
end

local function readState()
    local loaded = pr_lib.loadJson(PR.Farms.Storage.file, true)
    if type(loaded) ~= 'table' then
        return { settings = { enabled = true }, nextFarmId = 1, farms = {} }
    end
    return loaded
end

local function writeState(state)
    local saved = pr_lib.saveJson(PR.Farms.Storage.file, state, { indent = true })
    return saved == true or type(saved) == 'table'
end

local function findFarm(farmId)
    farmId = tonumber(farmId)
    for index, farm in ipairs(Service.state.farms or {}) do
        if tonumber(farm.id) == farmId then return farm, index end
    end
end

local function findItem(farm, itemId)
    itemId = normalizeId(itemId, '')
    for _, item in ipairs(type(farm.items) == 'table' and farm.items or {}) do
        if item.id == itemId then return item end
    end
end

local function publish()
    GlobalState.forgeFarms = Service.getAll()
end

function Service.getAll()
    return {
        settings = clone(Service.state.settings or {}),
        farms = clone(Service.state.farms or {}),
        revision = Service.state.revision,
    }
end

function Service.getGroups(source, groupType)
    if not canManage(source) then return false, 'no_permission' end
    groupType = groupType == 'gang' and 'gang' or 'job'

    if ForgeCore.JobRegistry and ForgeCore.JobRegistry.list then
        return true, ForgeCore.JobRegistry.list(groupType)
    end

    return true, {}
end

function Service.getItems(source)
    if not canManage(source) then return false, 'no_permission' end

    local items = {}
    local rawItems

    if pr_lib and pr_lib.inventory and pr_lib.inventory.Items then
        local ok, result = pcall(pr_lib.inventory.Items)
        if ok then rawItems = result end
    end

    if type(rawItems) ~= 'table' and GetResourceState('ox_inventory'):find('start') then
        local ok, result = pcall(function()
            return exports.ox_inventory:Items()
        end)
        if ok then rawItems = result end
    end

    for name, data in pairs(type(rawItems) == 'table' and rawItems or {}) do
        local itemName = type(name) == 'string' and name or type(data) == 'table' and data.name
        if itemName and itemName ~= '' then
            items[#items + 1] = {
                name = itemName,
                label = type(data) == 'table' and (data.label or data.name) or itemName,
            }
        end
    end

    table.sort(items, function(left, right)
        return tostring(left.label or left.name) < tostring(right.label or right.name)
    end)

    return true, items
end

function Service.getVehicles(source)
    if not canManage(source) then return false, 'no_permission' end

    local vehicles = {}
    local rawVehicles

    if GetResourceState('qbx_core'):find('start') then
        local ok, result = pcall(function()
            return exports.qbx_core:GetVehiclesByName()
        end)
        if ok then rawVehicles = result end
    end

    for key, data in pairs(type(rawVehicles) == 'table' and rawVehicles or {}) do
        local model = type(data) == 'table' and (data.model or key) or key
        if model and model ~= '' then
            local name = type(data) == 'table' and (data.name or data.label or model) or model
            local brand = type(data) == 'table' and data.brand or ''
            vehicles[#vehicles + 1] = {
                model = model,
                label = trim(brand) ~= '' and (brand .. ' ' .. name) or name,
                category = type(data) == 'table' and data.category or '',
            }
        end
    end

    table.sort(vehicles, function(left, right)
        return tostring(left.label or left.model) < tostring(right.label or right.model)
    end)

    return true, vehicles
end

function Service.load()
    Service.state = normalizeState(readState())
    publish()
    return Service.getAll()
end

function Service.save()
    Service.state.revision = GetGameTimer()
    if not writeState(Service.state) then return false, 'save_failed' end
    publish()
    return true, Service.getAll()
end

function Service.saveSettings(source, settings)
    if not canManage(source) then return false, 'no_permission' end
    settings = type(settings) == 'table' and settings or {}
    Service.state.settings.enabled = boolValue(settings.enabled, true)
    return Service.save()
end

function Service.createFarm(source, farm)
    if not canManage(source) then return false, 'no_permission' end
    farm = normalizeFarm(farm)
    farm.id = Service.state.nextFarmId
    Service.state.nextFarmId = Service.state.nextFarmId + 1
    Service.state.farms[#Service.state.farms + 1] = farm
    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.farms.farm_created'), type = 'success' }) end
    return ok, payload
end

function Service.updateFarm(source, farmId, farm)
    if not canManage(source) then return false, 'no_permission' end
    local _, index = findFarm(farmId)
    if not index then return false, 'farm_not_found' end
    farm = normalizeFarm(farm)
    farm.id = tonumber(farmId)
    Service.state.farms[index] = farm
    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.farms.farm_updated'), type = 'success' }) end
    return ok, payload
end

function Service.deleteFarm(source, farmId)
    if not canManage(source) then return false, 'no_permission' end
    local _, index = findFarm(farmId)
    if not index then return false, 'farm_not_found' end
    table.remove(Service.state.farms, index)
    local ok, payload = Service.save()
    if ok then notify(source, { description = ForgeCore.t('notify.farms.farm_deleted'), type = 'success' }) end
    return ok, payload
end

function Service.startRoute(source, farmId, itemId)
    if (Service.state.settings or {}).enabled == false then return false, 'disabled' end
    local farm = findFarm(farmId)
    if not farm or farm.enabled == false then return false, 'farm_not_found' end
    if not canUseFarm(source, farm) then return false, 'no_permission' end

    local item = findItem(farm, itemId)
    if not item or item.enabled == false then return false, 'item_not_found' end

    local key = activeRouteKey(source, farmId, item.id)
    if Service.activeRoutes[key] then return true, { active = true } end

    local limitOk, limitErr = checkUsageLimit(source, farmId, item)
    if not limitOk then return false, limitErr end

    Service.activeRoutes[key] = true
    registerUsage(source, farmId, item)
    if not writeState(Service.state) then
        Service.activeRoutes[key] = nil
        return false, 'save_failed'
    end

    return true, { active = true }
end

function Service.finishRoute(source, farmId, itemId)
    Service.activeRoutes[activeRouteKey(source, farmId, itemId)] = nil
    return true
end

function Service.collect(source, farmId, itemId)
    if (Service.state.settings or {}).enabled == false then return false, 'disabled' end
    local farm = findFarm(farmId)
    if not farm or farm.enabled == false then return false, 'farm_not_found' end
    if not canUseFarm(source, farm) then return false, 'no_permission' end

    local item = findItem(farm, itemId)
    if not item or item.enabled == false then return false, 'item_not_found' end
    if not itemExists(item.reward) then return false, 'reward_item_not_found' end
    if not Service.activeRoutes[activeRouteKey(source, farmId, item.id)] then return false, 'route_not_started' end

    local hasRequired = hasTool(source, item.required)
    if not hasRequired then return false, 'required_item_missing' end
    consumeTool(source, item.required)

    local amount = math.random(math.min(item.min, item.max), math.max(item.min, item.max))
    if not addItem(source, item.reward, amount) then return false, 'add_item_failed' end

    for _, extra in ipairs(item.extraItems or {}) do
        if itemExists(extra.item) then
            addItem(source, extra.item, math.random(math.min(extra.min, extra.max), math.max(extra.min, extra.max)))
        end
    end

    return true, { item = item.reward, count = amount, label = itemLabel(item.reward) }
end

function Service.start()
    if Service.started then return true end
    Service.started = true
    Service.load()
    debug('success', ForgeCore.t('debug.farms.started'))
    return true
end

ForgeCore.FarmsService = Service

AddEventHandler('playerDropped', function()
    local prefix = tostring(source) .. ':'
    for key in pairs(Service.activeRoutes) do
        if key:sub(1, #prefix) == prefix then
            Service.activeRoutes[key] = nil
        end
    end
end)
