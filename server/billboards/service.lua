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
        title = data.title or ForgeCore.t('billboards.title'),
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

local function normalizeGroup(group)
    group = type(group) == 'table' and group or {}
    return {
        id = math.floor(numberValue(group.id)),
        name = trim(group.name) ~= '' and trim(group.name) or ForgeCore.t('billboards.default_group'),
    }
end

local function normalizeBillboard(billboard)
    billboard = type(billboard) == 'table' and billboard or {}
    local vertices = type(billboard.vertices) == 'table' and billboard.vertices or type(billboard.Vertices) == 'table' and billboard.Vertices or {}

    return {
        id = math.floor(numberValue(billboard.id or billboard.Uid)),
        groupId = math.floor(numberValue(billboard.groupId or billboard.groupid)),
        name = trim(billboard.name) ~= '' and trim(billboard.name) or ForgeCore.t('billboards.default_billboard'),
        enabled = boolValue(billboard.enabled, true),
        url = trim(billboard.url or billboard.Url or billboard.Data and billboard.Data.Url),
        width = math.max(1, math.floor(numberValue(billboard.width or billboard.Width or billboard.Data and billboard.Data.Width, PR.Billboards.Defaults.width))),
        height = math.max(1, math.floor(numberValue(billboard.height or billboard.Height or billboard.Data and billboard.Data.Height, PR.Billboards.Defaults.height))),
        offset = math.max(-2.0, math.min(2.0, numberValue(billboard.offset, 0.03))),
        vertices = {
            vectorValue(vertices[1]),
            vectorValue(vertices[2]),
            vectorValue(vertices[3]),
            vectorValue(vertices[4]),
        },
    }
end

local function normalizeState(state)
    state = type(state) == 'table' and state or {}

    local normalized = {
        enabled = boolValue(state.enabled, PR.Billboards.Defaults.enabled),
        renderDistance = math.max(25.0, numberValue(state.renderDistance, PR.Billboards.Defaults.renderDistance)),
        editDistance = math.max(2.0, numberValue(state.editDistance, PR.Billboards.Defaults.editDistance)),
        nextGroupId = math.max(1, math.floor(numberValue(state.nextGroupId, 1))),
        nextBillboardId = math.max(1, math.floor(numberValue(state.nextBillboardId, 1))),
        groups = {},
        billboards = {},
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

    local billboards = {}
    for _, billboard in ipairs(type(state.billboards) == 'table' and state.billboards or {}) do
        billboard = normalizeBillboard(billboard)
        if billboard.id > 0 and billboard.groupId > 0 and billboard.url ~= '' and groups[billboard.groupId] and not billboards[billboard.id] then
            billboards[billboard.id] = true
            normalized.billboards[#normalized.billboards + 1] = billboard
            if billboard.id >= normalized.nextBillboardId then normalized.nextBillboardId = billboard.id + 1 end
        end
    end

    table.sort(normalized.groups, function(left, right) return left.id < right.id end)
    table.sort(normalized.billboards, function(left, right) return left.id < right.id end)

    return normalized
end

local function readState()
    local loaded = pr_lib.loadJson(PR.Billboards.Storage.file, true)
    if type(loaded) ~= 'table' then
        local defaults = clone(PR.Billboards.Defaults)
        defaults.nextGroupId = 1
        defaults.nextBillboardId = 1
        defaults.groups = {}
        defaults.billboards = {}
        return defaults
    end

    return loaded
end

local function writeState(state)
    local saved = pr_lib.saveJson(PR.Billboards.Storage.file, state, { indent = true })
    return saved == true or type(saved) == 'table'
end

local function findById(list, id)
    id = tonumber(id)
    for index, item in ipairs(list or {}) do
        if tonumber(item.id) == id then return item, index end
    end
end

local function countBillboards(groupId)
    local total = 0
    groupId = tonumber(groupId)

    for _, billboard in ipairs(Service.state.billboards or {}) do
        if tonumber(billboard.groupId) == groupId then total = total + 1 end
    end

    return total
end

local function publish()
    GlobalState.forgeBillboards = {
        enabled = Service.state.enabled == true,
        renderDistance = Service.state.renderDistance,
        billboards = Service.state.billboards or {},
        revision = Service.state.revision or GetGameTimer(),
    }
end

function Service.getAll()
    local groups = {}
    for _, group in ipairs(Service.state.groups or {}) do
        groups[#groups + 1] = {
            id = group.id,
            name = group.name,
            count = countBillboards(group.id),
        }
    end

    return {
        enabled = Service.state.enabled == true,
        renderDistance = Service.state.renderDistance,
        editDistance = Service.state.editDistance,
        groups = groups,
        billboards = clone(Service.state.billboards or {}),
        revision = Service.state.revision,
    }
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

    notify(source, { description = ForgeCore.t('notify.billboards.group_created'), type = 'success' })
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

    notify(source, { description = ForgeCore.t('notify.billboards.group_renamed'), type = 'success' })
    return true, payload
end

function Service.deleteGroup(source, groupId)
    if not canManage(source) then return false, 'no_permission' end
    if countBillboards(groupId) > 0 then return false, 'group_not_empty' end

    local _, index = findById(Service.state.groups, groupId)
    if not index then return false, 'group_not_found' end

    table.remove(Service.state.groups, index)
    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.billboards.group_deleted'), type = 'success' })
    return true, payload
end

function Service.createBillboard(source, billboard)
    if not canManage(source) then return false, 'no_permission' end

    billboard = normalizeBillboard(billboard)
    if not findById(Service.state.groups, billboard.groupId) then return false, 'group_not_found' end
    if billboard.url == '' then return false, 'invalid_url' end

    billboard.id = Service.state.nextBillboardId
    Service.state.nextBillboardId = Service.state.nextBillboardId + 1
    Service.state.billboards[#Service.state.billboards + 1] = billboard

    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.billboards.billboard_created'), type = 'success' })
    return true, billboard.id, payload
end

function Service.updateBillboard(source, billboardId, changes)
    if not canManage(source) then return false, 'no_permission' end

    local billboard = findById(Service.state.billboards, billboardId)
    if not billboard then return false, 'billboard_not_found' end

    changes = normalizeBillboard(changes)
    if changes.groupId > 0 and findById(Service.state.groups, changes.groupId) then
        billboard.groupId = changes.groupId
    end

    billboard.name = changes.name
    billboard.enabled = changes.enabled
    billboard.url = changes.url
    billboard.width = changes.width
    billboard.height = changes.height
    billboard.offset = changes.offset
    billboard.vertices = changes.vertices

    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.billboards.billboard_updated'), type = 'success' })
    return true, payload
end

function Service.deleteBillboard(source, billboardId)
    if not canManage(source) then return false, 'no_permission' end

    local _, index = findById(Service.state.billboards, billboardId)
    if not index then return false, 'billboard_not_found' end

    table.remove(Service.state.billboards, index)
    local ok, payload = Service.save()
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.billboards.billboard_deleted'), type = 'success' })
    return true, payload
end

function Service.start()
    if Service.started then return true end
    Service.started = true

    Service.load()
    debug('success', ForgeCore.t('debug.billboards.started'))

    return true
end

ForgeCore.BillboardsService = Service
