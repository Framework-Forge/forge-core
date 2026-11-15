return function(ports)
    local Menu,Shared,PR,Objects=assert(ports.menu),assert(ports.shared),assert(ports.config),assert(ports.objects)
    local library,native=ports.library,assert(ports.native)
    local SetTimeout,joaat,IsModelInCdimage=assert(native.SetTimeout),assert(native.joaat),assert(native.IsModelInCdimage)
    local api={Menu=Menu,Commands={}}
    local function describeCommand(transport,name,a,b)
        local entry={transport=transport,name=name,properties=transport=='pr' and a or nil,handler=transport=='pr' and b or a}
        if transport=='native' then entry.restricted=b end
        api.Commands[#api.Commands+1]=entry
    end
local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local alertDialog = Shared.alertDialog

local function notify(description, notifyType)
    if library and library.Notify then
        library.Notify({
            title = t('objects.title'),
            description = description,
            type = notifyType or 'inform',
            position = PR.NotifyPos,
        })
    end
end

local function fetchPayload()
    local ok, payload = awaitServer(PR.Objects.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.objects.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.scenes = type(payload.scenes) == 'table' and payload.scenes or {}
    payload.objects = type(payload.objects) == 'table' and payload.objects or {}
    payload.imageServer = tostring(payload.imageServer or PR.Objects.Defaults.imageServer or '')

    return payload
end

local function getObjectImage(object, payload)
    local model = object and object.model

    if library and library.fivem and library.fivem.blips and library.fivem.blips.getPropImageUrl then
        local url = library.fivem.blips.getPropImageUrl(model)
        if url then return url end
    end

    local imageServer = payload and payload.imageServer
    if type(imageServer) == 'string' and imageServer ~= '' and model then
        return imageServer:gsub('/+$', '') .. '/' .. tostring(model) .. '.jpg'
    end
end

local function objectDescription(object)
    local coords = object.coords or {}
    return t('menu.objects.object_description', {
        x = ('%.2f'):format(tonumber(coords.x) or 0.0),
        y = ('%.2f'):format(tonumber(coords.y) or 0.0),
        z = ('%.2f'):format(tonumber(coords.z) or 0.0),
    })
end

local function createScene()
    local result = inputDialog(t('menu.objects.create_scene'), {
        {
            type = 'input',
            label = t('inputs.object_scene_name'),
            required = true,
        },
    })

    if not result then
        Menu.openObjectsMenu()
        return
    end

    local ok, response = awaitServer(PR.Objects.Callbacks.createScene, tostring(result[1] or ''))
    if not ok then
        notifyFailure('notify.objects.scene_create_failed', response)
    end

    SetTimeout(400, function()
        Menu.openObjectsMenu()
    end)
end

local function renameScene(scene)
    local result = inputDialog(t('menu.objects.rename_scene'), {
        {
            type = 'input',
            label = t('inputs.object_scene_name'),
            default = scene.name,
            required = true,
        },
    })

    if not result then
        Menu.openObjectsScene(scene.id, scene.name)
        return
    end

    local ok, response = awaitServer(PR.Objects.Callbacks.renameScene, scene.id, tostring(result[1] or ''))
    if not ok then
        notifyFailure('notify.objects.scene_rename_failed', response)
    end

    SetTimeout(400, function()
        Menu.openObjectsMenu()
    end)
end

local function deleteScene(scene)
    local confirmed = true
    if alertDialog then
        local result = alertDialog({
            header = t('dialogs.remove_object_scene_header'),
            content = t('dialogs.remove_object_scene_content', { scene = scene.name }),
            centered = true,
            cancel = true,
        })
        confirmed = result == 'confirm'
    end

    if not confirmed then
        Menu.openObjectsScene(scene.id, scene.name)
        return
    end

    local ok, response = awaitServer(PR.Objects.Callbacks.deleteScene, scene.id)
    if not ok then
        notifyFailure('notify.objects.scene_delete_failed', response)
    end

    SetTimeout(400, function()
        Menu.openObjectsMenu()
    end)
end

local function createObject(scene)
    local result = inputDialog(t('menu.objects.create_object'), {
        {
            type = 'input',
            label = t('inputs.object_model'),
            required = true,
        },
    })

    if not result then
        Menu.openObjectsScene(scene.id, scene.name)
        return
    end

    local model = tostring(result[1] or '')
    if not IsModelInCdimage(joaat(model)) then
        notify(t('notify.objects.invalid_model', { model = model }), 'error')
        Menu.openObjectsScene(scene.id, scene.name)
        return
    end

    local created, error = Objects.createPreview(model, scene.id, function()
        SetTimeout(600, function()
            Menu.openObjectsScene(scene.id, scene.name)
        end)
    end)

    if not created then
        notifyFailure('notify.objects.create_failed', error)
        Menu.openObjectsScene(scene.id, scene.name)
    end
end

local function duplicateObject(object)
    local scene = { id = object.sceneId, name = t('menu.objects.scene_title', { id = tostring(object.sceneId) }) }
    local created, error = Objects.createPreview(object.model, object.sceneId, function()
        SetTimeout(600, function()
            Menu.openObjectsScene(object.sceneId, scene.name)
        end)
    end)

    if not created then
        notifyFailure('notify.objects.create_failed', error)
    end
end

local function deleteObject(object)
    local confirmed = true
    if alertDialog then
        local result = alertDialog({
            header = t('dialogs.remove_object_header'),
            content = t('dialogs.remove_object_content', { object = tostring(object.id) }),
            centered = true,
            cancel = true,
        })
        confirmed = result == 'confirm'
    end

    if not confirmed then
        Menu.openObjectActions(object.id)
        return
    end

    local ok, response = awaitServer(PR.Objects.Callbacks.deleteObject, object.id)
    if not ok then
        notifyFailure('notify.objects.delete_failed', response)
    end

    SetTimeout(400, function()
        Menu.openObjectsScene(object.sceneId, t('menu.objects.scene_title', { id = tostring(object.sceneId) }))
    end)
end

function Menu.openObjectsMenu()
    local payload = fetchPayload()
    if not payload then return end

    local options = {
        {
            title = t('menu.objects.create_scene'),
            description = t('menu.objects.create_scene_description'),
            icon = 'folder-plus',
            onSelect = createScene,
        },
        {
            title = Objects.debugIds and t('menu.objects.disable_debug') or t('menu.objects.enable_debug'),
            description = t('menu.objects.debug_description'),
            icon = Objects.debugIds and 'toggle-on' or 'toggle-off',
            iconColor = Objects.debugIds and 'green' or 'red',
            onSelect = function()
                Objects.toggleDebug()
                Menu.openObjectsMenu()
            end,
        },
        {
            title = t('menu.objects.total_scenes', { count = tostring(#payload.scenes) }),
            icon = 'boxes',
            disabled = true,
        },
    }

    for _, scene in ipairs(payload.scenes) do
        options[#options + 1] = {
            title = scene.name,
            description = t('menu.objects.scene_description', {
                count = tostring(scene.count or 0),
            }),
            icon = 'folder',
            onSelect = function()
                Menu.openObjectsScene(scene.id, scene.name)
            end,
        }
    end

    showContext({
        id = 'forge_core_objects',
        title = t('menu.objects.title'),
        menu = 'forge_core_server_settings',
        options = options,
    })
end

function Menu.openObjectsScene(sceneId, sceneName)
    local payload = fetchPayload()
    if not payload then return end

    local scene = { id = sceneId, name = sceneName }
    for _, item in ipairs(payload.scenes) do
        if tonumber(item.id) == tonumber(sceneId) then scene = item break end
    end

    local sceneObjects = {}
    for _, object in ipairs(payload.objects) do
        if tonumber(object.sceneId or object.sceneid) == tonumber(sceneId) then
            sceneObjects[#sceneObjects + 1] = object
        end
    end

    table.sort(sceneObjects, function(left, right) return tonumber(left.id) < tonumber(right.id) end)

    local options = {
        {
            title = t('menu.objects.create_object'),
            description = t('menu.objects.create_object_description'),
            icon = 'plus',
            onSelect = function()
                createObject(scene)
            end,
        },
        {
            title = t('menu.objects.rename_scene'),
            description = t('menu.objects.rename_scene_description'),
            icon = 'pencil-square',
            onSelect = function()
                renameScene(scene)
            end,
        },
        {
            title = t('menu.objects.delete_scene'),
            description = #sceneObjects > 0 and t('menu.objects.delete_scene_blocked') or t('menu.objects.delete_scene_description'),
            icon = 'trash',
            iconColor = 'red',
            disabled = #sceneObjects > 0,
            onSelect = function()
                deleteScene(scene)
            end,
        },
        {
            title = t('menu.objects.total_objects', { count = tostring(#sceneObjects) }),
            icon = 'box',
            disabled = true,
        },
    }

    for _, object in ipairs(sceneObjects) do
        local image = getObjectImage(object, payload)

        options[#options + 1] = {
            title = ('[%s] %s'):format(object.id, object.model),
            description = objectDescription(object),
            icon = 'box',
            image = image,
            onSelect = function()
                Menu.openObjectActions(object.id)
            end,
        }
    end

    showContext({
        id = 'forge_core_objects_scene',
        title = scene.name,
        menu = 'forge_core_objects',
        onBack = function()
            for _, object in ipairs(sceneObjects) do
                Objects.setOutline(object.id, false)
            end
        end,
        onExit = function()
            for _, object in ipairs(sceneObjects) do
                Objects.setOutline(object.id, false)
            end
        end,
        options = options,
    })
end

function Menu.openObjectActions(objectId)
    local object = Objects.get(objectId)
    if not object then
        notify(t('notify.objects.object_missing'), 'error')
        Menu.openObjectsMenu()
        return
    end

    Objects.setOutline(objectId, true, 255, 0, 0)

    showContext({
        id = 'forge_core_object_actions',
        title = ('[%s] %s'):format(object.id, object.model),
        menu = 'forge_core_objects_scene',
        onBack = function()
            Objects.setOutline(objectId, false)
        end,
        onExit = function()
            Objects.setOutline(objectId, false)
        end,
        options = {
            {
                title = t('menu.objects.edit_object'),
                icon = 'arrows-move',
                onSelect = function()
                    Objects.setOutline(objectId, false)
                    Objects.edit(objectId)
                end,
            },
            {
                title = t('menu.objects.duplicate_object'),
                icon = 'copy',
                onSelect = function()
                    Objects.setOutline(objectId, false)
                    duplicateObject(object)
                end,
            },
            {
                title = t('menu.objects.teleport_object'),
                icon = 'bounding-box-circles',
                onSelect = function()
                    Objects.setOutline(objectId, false)
                    Objects.teleportTo(objectId)
                    Menu.openObjectActions(objectId)
                end,
            },
            {
                title = t('menu.objects.delete_object'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    Objects.setOutline(objectId, false)
                    deleteObject(object)
                end,
            },
        },
    })
end

if library and library.command then
    describeCommand('pr', PR.Objects.Command or 'objectspawner', {
        help = t('commands.objects_help'),
    }, function()
        Menu.openObjectsMenu()
    end)
else
    describeCommand('native', PR.Objects.Command or 'objectspawner', function()
        Menu.openObjectsMenu()
    end, false)
end
    return api
end
