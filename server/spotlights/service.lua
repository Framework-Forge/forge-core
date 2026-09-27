ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    state = {},
}

local function debug(level, message)
    local debugApi = pr_lib and pr_lib.debug
    if not debugApi then return end

    local fn = debugApi[level]
    if type(fn) == 'function' then
        fn(message)
    elseif type(debugApi) == 'function' then
        debugApi(level, message)
    end
end

local function notify(source, data)
    if not source or source <= 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('spotlights.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end

    if source == 0 then return true end
    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function clone(value)
    return pr_lib and pr_lib.table and pr_lib.table.clone and pr_lib.table.clone(value) or value
end

local function trim(value)
    if pr_lib and pr_lib.utils and pr_lib.utils.trim then
        return pr_lib.utils.trim(value)
    end

    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function numberValue(value, fallback)
    return tonumber(value) or fallback or 0.0
end

local function vectorValue(value)
    value = type(value) == 'table' and value or {}
    return {
        x = numberValue(value.x or value[1]),
        y = numberValue(value.y or value[2]),
        z = numberValue(value.z or value[3]),
    }
end

local function colorValue(value)
    return PR.Spotlights.NormalizeColor(value)
end

local function normalizeGroup(group)
    group = type(group) == 'table' and group or {}
    return {
        id = math.floor(numberValue(group.id)),
        name = trim(group.name) ~= '' and trim(group.name) or ForgeCore.t('spotlights.default_group'),
    }
end

local function normalizeLight(light)
    light = type(light) == 'table' and light or {}

    return {
        id = math.floor(numberValue(light.id)),
        groupId = math.floor(numberValue(light.groupId or light.groupid)),
        name = trim(light.name) ~= '' and trim(light.name) or ForgeCore.t('spotlights.default_light'),
        enabled = boolValue(light.enabled, true),
        origin = vectorValue(light.origin or light.initalCoords or light.initialCoords),
        target = vectorValue(light.target or light.secondCoords),
        color = colorValue(light.color or (light.data and light.data.rgb)),
        distance = math.max(0.1, numberValue(light.distance or (light.data and light.data.distance), 50.0)),
        brightness = math.max(0.0, numberValue(light.brightness or (light.data and light.data.brightness), 1.0)),
        hardness = math.max(0.0, numberValue(light.hardness or (light.data and light.data.hardness), 0.0)),
        radius = math.max(0.0, numberValue(light.radius or (light.data and light.data.radius), 20.0)),
    }
end

local function normalizeState(state)
    state = type(state) == 'table' and state or {}

    local normalized = {
        enabled = boolValue(state.enabled, PR.Spotlights.Defaults.enabled),
        drawDistance = math.max(25.0, numberValue(state.drawDistance, PR.Spotlights.Defaults.drawDistance)),
        nextGroupId = math.max(1, math.floor(numberValue(state.nextGroupId, 1))),
        nextLightId = math.max(1, math.floor(numberValue(state.nextLightId, 1))),
        groups = {},
        lights = {},
        revision = GetGameTimer(),
    }

    local groups = {}
    for _, group in ipairs(type(state.groups) == 'table' and state.groups or {}) do
        group = normalizeGroup(group)
        if group.id > 0 and not groups[group.id] then
            groups[group.id] = true
            normalized.groups[#normalized.groups + 1] = group
            if group.id >= normalized.nextGroupId then normalized.nextGroupId = group.id + 1 end
        end
    end

    local lights = {}
    for _, light in ipairs(type(state.lights) == 'table' and state.lights or {}) do
        light = normalizeLight(light)
        if light.id > 0 and light.groupId > 0 and groups[light.groupId] and not lights[light.id] then
            lights[light.id] = true
            normalized.lights[#normalized.lights + 1] = light
            if light.id >= normalized.nextLightId then normalized.nextLightId = light.id + 1 end
        end
    end

    table.sort(normalized.groups, function(left, right) return left.id < right.id end)
    table.sort(normalized.lights, function(left, right) return left.id < right.id end)

    return normalized
end

local function readState()
    local loaded = pr_lib.loadJson(PR.Spotlights.Storage.file, true)
    if type(loaded) ~= 'table' then
        local defaults = clone(PR.Spotlights.Defaults)
        defaults.nextGroupId = 1
        defaults.nextLightId = 1
        defaults.groups = {}
        defaults.lights = {}
        return defaults
    end

    return loaded
end

local function writeState(state)
    local saved = pr_lib.saveJson(PR.Spotlights.Storage.file, state, { indent = true })
    return saved == true or type(saved) == 'table'
end

local function findById(list, id)
    id = tonumber(id)
    for index, item in ipairs(list or {}) do
        if tonumber(item.id) == id then return item, index end
    end
end

local function countLights(groupId)
    local total = 0
    groupId = tonumber(groupId)

    for _, light in ipairs(Service.state.lights or {}) do
        if tonumber(light.groupId) == groupId then total = total + 1 end
    end

    return total
end

local function publish()
    GlobalState.forgeSpotlights = {
        enabled = Service.state.enabled == true,
        drawDistance = Service.state.drawDistance,
        lights = Service.state.lights or {},
        revision = Service.state.revision or GetGameTimer(),
    }
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getAll()
    local groups = {}
    for _, group in ipairs(Service.state.groups or {}) do
        groups[#groups + 1] = {
            id = group.id,
            name = group.name,
            count = countLights(group.id),
        }
    end

    return {
        enabled = Service.state.enabled == true,
        drawDistance = Service.state.drawDistance,
        groups = groups,
        lights = clone(Service.state.lights or {}),
        revision = Service.state.revision,
    }
end

function Service.load()
    Service.state = normalizeState(readState())
    publish()
    return Service.getAll()
end

function Service.save()
    Service.state.revision = math.max(
        math.floor(numberValue(Service.state.revision, 0)) + 1,
        GetGameTimer()
    )
    if not writeState(Service.state) then return false, 'save_failed' end
    publish()
    return true, Service.getAll()
end

function Service.createGroup(source, name)
    if not canManage(source) then return false, 'no_permission' end

    name = trim(name)
    if name == '' then return false, 'invalid_name' end

    local group = {
        id = Service.state.nextGroupId,
        name = name,
    }

    Service.state.nextGroupId = Service.state.nextGroupId + 1
    Service.state.groups[#Service.state.groups + 1] = group

    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.spotlights.group_created'), type = 'success' })
    return true, payload
end

function Service.renameGroup(source, groupId, name)
    if not canManage(source) then return false, 'no_permission' end

    local group = findById(Service.state.groups, groupId)
    if not group then return false, 'group_not_found' end

    name = trim(name)
    if name == '' then return false, 'invalid_name' end

    group.name = name
    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.spotlights.group_renamed'), type = 'success' })
    return true, payload
end

function Service.deleteGroup(source, groupId)
    if not canManage(source) then return false, 'no_permission' end
    if countLights(groupId) > 0 then return false, 'group_not_empty' end

    local _, index = findById(Service.state.groups, groupId)
    if not index then return false, 'group_not_found' end

    table.remove(Service.state.groups, index)
    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.spotlights.group_deleted'), type = 'success' })
    return true, payload
end

function Service.createLight(source, light)
    if not canManage(source) then return false, 'no_permission' end

    light = normalizeLight(light)
    if not findById(Service.state.groups, light.groupId) then return false, 'group_not_found' end

    light.id = Service.state.nextLightId
    Service.state.nextLightId = Service.state.nextLightId + 1
    Service.state.lights[#Service.state.lights + 1] = light

    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.spotlights.light_created'), type = 'success' })
    return true, light.id, payload
end

function Service.updateLight(source, lightId, changes)
    if not canManage(source) then return false, 'no_permission' end

    local light = findById(Service.state.lights, lightId)
    if not light then return false, 'light_not_found' end

    changes = type(changes) == 'table' and changes or {}
    local enabled = changes.enabled
    if enabled == nil then enabled = light.enabled end

    local normalized = normalizeLight({
        id = light.id,
        groupId = changes.groupId ~= nil and changes.groupId or light.groupId,
        name = changes.name ~= nil and changes.name or light.name,
        enabled = enabled,
        origin = changes.origin ~= nil and changes.origin or light.origin,
        target = changes.target ~= nil and changes.target or light.target,
        color = changes.color ~= nil and changes.color or light.color,
        distance = changes.distance ~= nil and changes.distance or light.distance,
        brightness = changes.brightness ~= nil and changes.brightness or light.brightness,
        hardness = changes.hardness ~= nil and changes.hardness or light.hardness,
        radius = changes.radius ~= nil and changes.radius or light.radius,
    })

    if not findById(Service.state.groups, normalized.groupId) then
        return false, 'group_not_found'
    end

    light.groupId = normalized.groupId
    light.name = normalized.name
    light.enabled = normalized.enabled
    light.origin = normalized.origin
    light.target = normalized.target
    light.color = normalized.color
    light.distance = normalized.distance
    light.brightness = normalized.brightness
    light.hardness = normalized.hardness
    light.radius = normalized.radius

    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.spotlights.light_updated'), type = 'success' })
    return true, payload
end
function Service.deleteLight(source, lightId)
    if not canManage(source) then return false, 'no_permission' end

    local _, index = findById(Service.state.lights, lightId)
    if not index then return false, 'light_not_found' end

    table.remove(Service.state.lights, index)
    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.spotlights.light_deleted'), type = 'success' })
    return true, payload
end

function Service.start()
    if Service.started then return true end
    Service.started = true

    Service.load()
    debug('success', ForgeCore.t('debug.spotlights.started'))

    return true
end

ForgeCore.SpotlightsService = Service
