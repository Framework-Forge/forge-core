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
        title = data.title or ForgeCore.t('objects.title'),
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

local function normalizeVector(value)
    value = type(value) == 'table' and value or {}
    return {
        x = numberValue(value.x or value[1]),
        y = numberValue(value.y or value[2]),
        z = numberValue(value.z or value[3]),
    }
end

local function normalizeScene(scene)
    scene = type(scene) == 'table' and scene or {}
    return {
        id = math.floor(numberValue(scene.id)),
        name = trim(scene.name) ~= '' and trim(scene.name) or ForgeCore.t('objects.default_scene'),
    }
end

local function normalizeObject(object)
    object = type(object) == 'table' and object or {}
    local model = trim(object.model)

    return {
        id = math.floor(numberValue(object.id)),
        sceneId = math.floor(numberValue(object.sceneId or object.sceneid)),
        model = model,
        coords = normalizeVector(object.coords),
        rotation = normalizeVector(object.rotation),
        heading = numberValue(object.heading),
    }
end

local function normalizeState(state)
    state = type(state) == 'table' and state or {}

    local normalized = {
        enabled = boolValue(state.enabled, PR.Objects.Defaults.enabled),
        spawnDistance = math.max(25.0, numberValue(state.spawnDistance, PR.Objects.Defaults.spawnDistance)),
        imageServer = trim(state.imageServer) ~= '' and trim(state.imageServer) or PR.Objects.Defaults.imageServer or '',
        nextSceneId = math.max(1, math.floor(numberValue(state.nextSceneId, 1))),
        nextObjectId = math.max(1, math.floor(numberValue(state.nextObjectId, 1))),
        scenes = {},
        objects = {},
        revision = GetGameTimer(),
    }

    local seenScenes = {}
    for _, scene in ipairs(type(state.scenes) == 'table' and state.scenes or {}) do
        scene = normalizeScene(scene)
        if scene.id > 0 and not seenScenes[scene.id] then
            seenScenes[scene.id] = true
            normalized.scenes[#normalized.scenes + 1] = scene
            if scene.id >= normalized.nextSceneId then normalized.nextSceneId = scene.id + 1 end
        end
    end

    local seenObjects = {}
    for _, object in ipairs(type(state.objects) == 'table' and state.objects or {}) do
        object = normalizeObject(object)
        if object.id > 0 and object.sceneId > 0 and object.model ~= '' and seenScenes[object.sceneId] and not seenObjects[object.id] then
            seenObjects[object.id] = true
            normalized.objects[#normalized.objects + 1] = object
            if object.id >= normalized.nextObjectId then normalized.nextObjectId = object.id + 1 end
        end
    end

    table.sort(normalized.scenes, function(left, right) return left.id < right.id end)
    table.sort(normalized.objects, function(left, right) return left.id < right.id end)

    return normalized
end

local function readState()
    local loaded = pr_lib.loadJsonRecovery(PR.Objects.Storage.file, true)
    if type(loaded) ~= 'table' then
        local defaults = clone(PR.Objects.Defaults)
        defaults.nextSceneId = 1
        defaults.nextObjectId = 1
        defaults.scenes = {}
        defaults.objects = {}
        return defaults
    end

    return loaded
end

local function writeState(state)
    local saved = pr_lib.saveJsonRecovery(PR.Objects.Storage.file, state, { indent = true })
    return saved == true or type(saved) == 'table'
end

local function findById(list, id)
    id = tonumber(id)
    for index, item in ipairs(list or {}) do
        if tonumber(item.id) == id then return item, index end
    end
end

local function countObjects(sceneId)
    local total = 0
    sceneId = tonumber(sceneId)

    for _, object in ipairs(Service.state.objects or {}) do
        if tonumber(object.sceneId) == sceneId then total = total + 1 end
    end

    return total
end

local function publish()
    ForgeCore.State.publish('objects',{
        enabled = Service.state.enabled == true,
        spawnDistance = Service.state.spawnDistance,
        objects = Service.state.objects or {},
        revision = Service.state.revision or GetGameTimer(),
    })
end

function Service.canManage(source)
    return canManage(source)
end

function Service.getAll()
    local scenes = {}
    for _, scene in ipairs(Service.state.scenes or {}) do
        scenes[#scenes + 1] = {
            id = scene.id,
            name = scene.name,
            count = countObjects(scene.id),
        }
    end

    return {
        enabled = Service.state.enabled == true,
        spawnDistance = Service.state.spawnDistance,
        imageServer = Service.state.imageServer,
        scenes = scenes,
        objects = clone(Service.state.objects or {}),
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

function Service.createScene(source, name)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    name = trim(name)
    if name == '' then return false, 'invalid_name' end

    local scene = {
        id = draft.nextSceneId,
        name = name,
    }

    draft.nextSceneId = draft.nextSceneId + 1
    draft.scenes[#draft.scenes + 1] = scene

    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.objects.scene_created'), type = 'success' })
    return true, payload
end

function Service.renameScene(source, sceneId, name)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    local scene = findById(draft.scenes, sceneId)
    if not scene then return false, 'scene_not_found' end

    name = trim(name)
    if name == '' then return false, 'invalid_name' end

    scene.name = name
    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.objects.scene_renamed'), type = 'success' })
    return true, payload
end

function Service.deleteScene(source, sceneId)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)
    if countObjects(sceneId) > 0 then return false, 'scene_not_empty' end

    local _, index = findById(draft.scenes, sceneId)
    if not index then return false, 'scene_not_found' end

    table.remove(draft.scenes, index)
    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.objects.scene_deleted'), type = 'success' })
    return true, payload
end

function Service.createObject(source, object)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    object = normalizeObject(object)
    if not findById(draft.scenes, object.sceneId) then return false, 'scene_not_found' end
    if object.model == '' then return false, 'invalid_model' end

    object.id = draft.nextObjectId
    draft.nextObjectId = draft.nextObjectId + 1
    draft.objects[#draft.objects + 1] = object

    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.objects.object_created'), type = 'success' })
    return true, object.id, payload
end

function Service.updateObject(source, objectId, changes)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    local object = findById(draft.objects, objectId)
    if not object then return false, 'object_not_found' end

    changes = normalizeObject(changes)
    object.coords = changes.coords
    object.rotation = changes.rotation
    object.heading = changes.heading

    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.objects.object_updated'), type = 'success' })
    return true, payload
end

function Service.deleteObject(source, objectId)
    if not canManage(source) then return false, 'no_permission' end
    local draft = pr_lib.jsonDraft(Service.state)

    local _, index = findById(draft.objects, objectId)
    if not index then return false, 'object_not_found' end

    table.remove(draft.objects, index)
    local ok, payload = Service.save(draft)
    if not ok then return false, payload end

    notify(source, { description = ForgeCore.t('notify.objects.object_deleted'), type = 'success' })
    return true, payload
end

function Service.start()
    if Service.started then return true end
    Service.started = true

    Service.load()
    debug('success', ForgeCore.t('debug.objects.started'))

    return true
end

pr_lib.wrapJsonMutations(PR.Objects.Storage.file, Service, {
    'createScene', 'renameScene', 'deleteScene', 'createObject', 'updateObject', 'deleteObject',
})

ForgeCore.ObjectsService = Service
