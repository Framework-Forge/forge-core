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
        title = data.title or ForgeCore.t('npcs.title'),
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

local function trim(value)
    if pr_lib and pr_lib.utils and pr_lib.utils.trim then
        return pr_lib.utils.trim(value)
    end

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
    return tonumber(value) or fallback or 0.0
end

local function normalizeVector(value)
    value = type(value) == 'table' and value or {}
    return {
        x = numberValue(value.x or value[1]),
        y = numberValue(value.y or value[2]),
        z = numberValue(value.z or value[3]),
    }
end

local function mergeTable(base, changes)
    base = type(base) == 'table' and clone(base) or {}
    changes = type(changes) == 'table' and changes or {}

    for key, value in pairs(changes) do
        if type(value) == 'table' and type(base[key]) == 'table' then
            base[key] = mergeTable(base[key], value)
        else
            base[key] = value
        end
    end

    return base
end

local function normalizeGroup(group)
    group = type(group) == 'table' and group or {}
    return {
        id = math.floor(numberValue(group.id)),
        name = trim(group.name) ~= '' and trim(group.name) or ForgeCore.t('npcs.default_group'),
        description = trim(group.description),
    }
end

local function normalizeAccess(access)
    access = type(access) == 'table' and access or {}
    return {
        job = trim(access.job),
        grade = math.max(0, math.floor(numberValue(access.grade or access.jobGrade))),
        gang = trim(access.gang),
        gangGrade = math.max(0, math.floor(numberValue(access.gangGrade))),
    }
end

local function normalizeInteraction(interaction)
    interaction = type(interaction) == 'table' and interaction or {}
    local mode = trim(interaction.mode)
    if mode ~= 'target' and mode ~= 'drawtext' and mode ~= 'both' then mode = 'none' end

    return {
        mode = mode,
        label = trim(interaction.label),
        event = trim(interaction.event),
        distance = math.max(1.0, numberValue(interaction.distance, PR.Npcs.Defaults.interactionDistance)),
        access = normalizeAccess(interaction.access),
    }
end

local function normalizeAnimation(animation)
    animation = type(animation) == 'table' and animation or {}
    return {
        scenario = trim(animation.scenario),
        animDict = trim(animation.animDict),
        animName = trim(animation.animName),
    }
end

local function normalizeNpc(npc)
    npc = type(npc) == 'table' and npc or {}
    local rotation = normalizeVector(npc.rotation)
    local heading = numberValue(npc.heading, rotation.z)

    return {
        id = math.floor(numberValue(npc.id)),
        groupId = math.floor(numberValue(npc.groupId or npc.groupid)),
        model = trim(npc.model),
        name = trim(npc.name) ~= '' and trim(npc.name) or ForgeCore.t('npcs.default_name'),
        description = trim(npc.description),
        enabled = boolValue(npc.enabled, true),
        coords = normalizeVector(npc.coords),
        rotation = rotation,
        heading = heading % 360.0,
        interaction = normalizeInteraction(npc.interaction),
        animation = normalizeAnimation(npc.animation),
    }
end

local function readState()
    local loaded = pr_lib.loadJsonRecovery(PR.Npcs.Storage.file, true)
    if type(loaded) ~= 'table' then
        local defaults = clone(PR.Npcs.Defaults)
        defaults.nextGroupId = 1
        defaults.nextNpcId = 1
        defaults.groups = {}
        defaults.npcs = {}
        return defaults
    end

    return loaded
end

local function writeState(state)
    local saved = pr_lib.saveJsonRecovery(PR.Npcs.Storage.file, state, { indent = true })
    return saved == true or type(saved) == 'table'
end

local function findById(list, id)
    id = tonumber(id)
    for index, item in ipairs(list or {}) do
        if tonumber(item.id) == id then return item, index end
    end
end

local function countNpcs(groupId)
    local total = 0
    groupId = tonumber(groupId)

    for _, npc in ipairs(Service.state.npcs or {}) do
        if tonumber(npc.groupId) == groupId then total = total + 1 end
    end

    return total
end

local function normalizeState(state)
    state = type(state) == 'table' and state or {}

    local normalized = {
        enabled = boolValue(state.enabled, PR.Npcs.Defaults.enabled),
        spawnDistance = math.max(25.0, numberValue(state.spawnDistance, PR.Npcs.Defaults.spawnDistance)),
        nextGroupId = math.max(1, math.floor(numberValue(state.nextGroupId, 1))),
        nextNpcId = math.max(1, math.floor(numberValue(state.nextNpcId, 1))),
        groups = {},
        npcs = {},
        revision = GetGameTimer(),
    }

    local seenGroups = {}
    for _, group in ipairs(type(state.groups) == 'table' and state.groups or {}) do
        group = normalizeGroup(group)
        if group.id > 0 and not seenGroups[group.id] then
            seenGroups[group.id] = true
            normalized.groups[#normalized.groups + 1] = group
            if group.id >= normalized.nextGroupId then normalized.nextGroupId = group.id + 1 end
        end
    end

    local seenNpcs = {}
    for _, npc in ipairs(type(state.npcs) == 'table' and state.npcs or {}) do
        npc = normalizeNpc(npc)
        if npc.id > 0 and npc.groupId > 0 and npc.model ~= '' and seenGroups[npc.groupId] and not seenNpcs[npc.id] then
            seenNpcs[npc.id] = true
            normalized.npcs[#normalized.npcs + 1] = npc
            if npc.id >= normalized.nextNpcId then normalized.nextNpcId = npc.id + 1 end
        end
    end

    table.sort(normalized.groups, function(left, right) return left.id < right.id end)
    table.sort(normalized.npcs, function(left, right) return left.id < right.id end)

    return normalized
end

local function publish()
    ForgeCore.State.publish('npcs',{
        enabled = Service.state.enabled == true,
        spawnDistance = Service.state.spawnDistance,
        npcs = Service.state.npcs or {},
        revision = Service.state.revision or GetGameTimer(),
    })
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
            description = group.description,
            count = countNpcs(group.id),
        }
    end

    return {
        enabled = Service.state.enabled == true,
        spawnDistance = Service.state.spawnDistance,
        groups = groups,
        npcs = clone(Service.state.npcs or {}),
        revision = Service.state.revision,
    }
end

function Service.load()
    Service.state = normalizeState(readState())
    publish()
    return Service.getAll()
end

function Service.save(draft)
    draft = draft or pr_lib.jsonDraft(Service.state, {})
    draft.revision = GetGameTimer()
    if not writeState(draft) then return false, 'save_failed' end
    Service.state = draft
    publish()
    return true, Service.getAll()
end

function Service.createGroup(source, data)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    data = type(data) == 'table' and data or { name = data }
    local name = trim(data.name)
    if name == '' then return false, 'invalid_name' end

    local group = {
        id = draft.nextGroupId,
        name = name,
        description = trim(data.description),
    }

    draft.nextGroupId = draft.nextGroupId + 1
    draft.groups[#draft.groups + 1] = group

    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.npcs.group_created'), type = 'success' })
    return true, payload
end

function Service.renameGroup(source, groupId, data)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    local group = findById(draft.groups, groupId)
    if not group then return false, 'group_not_found' end

    data = type(data) == 'table' and data or { name = data }
    local name = trim(data.name)
    if name == '' then return false, 'invalid_name' end

    group.name = name
    group.description = trim(data.description)

    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.npcs.group_renamed'), type = 'success' })
    return true, payload
end

function Service.deleteGroup(source, groupId)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)
    if countNpcs(groupId) > 0 then return false, 'group_not_empty' end

    local _, index = findById(draft.groups, groupId)
    if not index then return false, 'group_not_found' end

    table.remove(draft.groups, index)
    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.npcs.group_deleted'), type = 'success' })
    return true, payload
end

function Service.createNpc(source, data)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    data = normalizeNpc(data)
    if not findById(draft.groups, data.groupId) then return false, 'group_not_found' end
    if data.model == '' then return false, 'invalid_model' end

    data.id = draft.nextNpcId
    draft.nextNpcId = draft.nextNpcId + 1
    draft.npcs[#draft.npcs + 1] = data

    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.npcs.npc_created'), type = 'success' })
    return true, data.id, payload
end

function Service.updateNpc(source, npcId, changes)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    local npc = findById(draft.npcs, npcId)
    if not npc then return false, 'npc_not_found' end

    changes = normalizeNpc(mergeTable(npc, changes))
    changes.id = npc.id
    changes.groupId = npc.groupId

    for key, value in pairs(changes) do
        npc[key] = value
    end

    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.npcs.npc_updated'), type = 'success' })
    return true, payload
end

function Service.deleteNpc(source, npcId)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    local _, index = findById(draft.npcs, npcId)
    if not index then return false, 'npc_not_found' end

    table.remove(draft.npcs, index)
    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.npcs.npc_deleted'), type = 'success' })
    return true, payload
end

function Service.start()
    if Service.started then return true end
    Service.started = true

    Service.load()
    debug('success', ForgeCore.t('debug.npcs.started'))

    return true
end

pr_lib.wrapJsonMutations(PR.Npcs.Storage.file, Service, {
    'createGroup', 'renameGroup', 'deleteGroup', 'createNpc', 'updateNpc', 'deleteNpc',
})

ForgeCore.NpcsService = Service
