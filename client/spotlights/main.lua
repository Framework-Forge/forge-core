ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Spotlights = {
    lights = {},
    editorActive = false,
}

ForgeCore.Client.Spotlights = Spotlights

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function notify(description, notifyType)
    if pr_lib and pr_lib.notify and pr_lib.notify.Notify then
        pr_lib.notify.Notify({
            title = t('spotlights.title'),
            description = description,
            type = notifyType or 'inform',
            position = PR.NotifyPos,
        })
    end
end

local function vec3(value)
    if type(value) == 'vector3' then return value end
    value = type(value) == 'table' and value or {}
    return vector3(tonumber(value.x or value[1]) or 0.0, tonumber(value.y or value[2]) or 0.0, tonumber(value.z or value[3]) or 0.0)
end

local function serialVector(value)
    value = vec3(value)
    return {
        x = tonumber(('%0.3f'):format(value.x)),
        y = tonumber(('%0.3f'):format(value.y)),
        z = tonumber(('%0.3f'):format(value.z)),
    }
end

local function colorFromRgb(value)
    value = tostring(value or '')
    local r, g, b = value:match('rgb%((%d+),%s*(%d+),%s*(%d+)%)')

    return {
        r = tonumber(r) or 255,
        g = tonumber(g) or 255,
        b = tonumber(b) or 255,
    }
end

local function rgbString(color)
    color = type(color) == 'table' and color or {}
    return ('rgb(%d, %d, %d)'):format(
        tonumber(color.r or color.x or color[1]) or 255,
        tonumber(color.g or color.y or color[2]) or 255,
        tonumber(color.b or color.z or color[3]) or 255
    )
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function direction(origin, target)
    origin = vec3(origin)
    target = vec3(target)
    local dir = target - origin

    if #(dir) <= 0.001 then
        return vector3(0.0, 0.0, -1.0)
    end

    return dir
end

local function drawLight(light)
    if not boolValue(light.enabled, true) then return end

    local origin = vec3(light.origin)
    local dir = direction(light.origin, light.target)
    local color = type(light.color) == 'table' and light.color or {}

    DrawSpotLight(
        origin.x,
        origin.y,
        origin.z,
        dir.x,
        dir.y,
        dir.z,
        math.floor(tonumber(color.r or color.x) or 255),
        math.floor(tonumber(color.g or color.y) or 255),
        math.floor(tonumber(color.b or color.z) or 255),
        tonumber(light.distance) or 50.0,
        tonumber(light.brightness) or 1.0,
        tonumber(light.hardness) or 0.0,
        tonumber(light.radius) or 20.0,
        1.0
    )
end

local function applyPayload(payload)
    payload = type(payload) == 'table' and payload or {}
    Spotlights.lights = type(payload.lights) == 'table' and payload.lights or {}
    Spotlights.enabled = boolValue(payload.enabled, false)
    Spotlights.drawDistance = tonumber(payload.drawDistance) or PR.Spotlights.Defaults.drawDistance
end

function Spotlights.applyPayload(payload)
    applyPayload(payload)
end

local function currentPayload()
    local payload = GlobalState.forgeSpotlights
    return type(payload) == 'table' and payload or { enabled = false, lights = {}, drawDistance = PR.Spotlights.Defaults.drawDistance }
end

local function setText(text)
    if lib and lib.showTextUI then
        lib.showTextUI(text, { position = 'right-center' })
    elseif pr_lib and pr_lib.framework and pr_lib.framework.ShowTextUI then
        pr_lib.framework.ShowTextUI(text)
    end
end

local function hideText()
    if lib and lib.hideTextUI then
        lib.hideTextUI()
    elseif pr_lib and pr_lib.framework and pr_lib.framework.HideTextUI then
        pr_lib.framework.HideTextUI()
    end
end

local function raycastPoint(label, fromPoint)
    if not lib or not lib.raycast or not lib.raycast.cam then
        return nil, 'raycast_unavailable'
    end

    local captured
    local cancelled = false

    setText(label)

    while not captured and not cancelled do
        Wait(0)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 38, true)
        DisableControlAction(0, 44, true)
        DisableControlAction(0, 202, true)
        DisablePlayerFiring(PlayerId(), true)

        local hit, _, coords = lib.raycast.cam(1, 4, 1000.0)
        if hit and coords then
            local point = vec3(coords)
            local head = GetPedBoneCoords(PlayerPedId(), 31086, 0.0, 0.0, 0.0)

            if fromPoint then
                local origin = vec3(fromPoint)
                DrawLine(origin.x, origin.y, origin.z, point.x, point.y, point.z, 255, 255, 60, 220)
            else
                DrawLine(head.x, head.y, head.z, point.x, point.y, point.z, 255, 255, 60, 220)
            end

            DrawSphere(point.x, point.y, point.z, 0.06, 255, 255, 60, 0.7)

            if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
                captured = point
            end
        end

        if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 202) then
            cancelled = true
        end
    end

    hideText()

    if cancelled then return nil, 'cancelled' end
    return captured
end

local function editorText(data)
    return t('menu.spotlights.editor_controls', {
        distance = ('%.2f'):format(tonumber(data.distance) or 0.0),
        brightness = ('%.2f'):format(tonumber(data.brightness) or 0.0),
        hardness = ('%.2f'):format(tonumber(data.hardness) or 0.0),
        radius = ('%.2f'):format(tonumber(data.radius) or 0.0),
    })
end

local function fineTune(data)
    Spotlights.editorActive = true
    local repeatState = {}

    local function held(control, delay, interval)
        local now = GetGameTimer()
        local pressed = IsDisabledControlPressed(0, control) or IsControlPressed(0, control)
        local justPressed = IsDisabledControlJustPressed(0, control) or IsControlJustPressed(0, control)

        if not pressed then
            repeatState[control] = nil
            return false
        end

        if justPressed or not repeatState[control] then
            repeatState[control] = now + (delay or 280)
            return true
        end

        if now >= repeatState[control] then
            repeatState[control] = now + (interval or 75)
            return true
        end

        return false
    end

    while Spotlights.editorActive do
        Wait(0)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 38, true)
        DisableControlAction(0, 44, true)
        DisableControlAction(0, 172, true)
        DisableControlAction(0, 173, true)
        DisableControlAction(0, 174, true)
        DisableControlAction(0, 175, true)
        DisableControlAction(0, 177, true)
        DisableControlAction(0, 201, true)
        DisableControlAction(0, 202, true)
        DisableControlAction(0, 241, true)
        DisableControlAction(0, 242, true)
        DisablePlayerFiring(PlayerId(), true)
        setText(editorText(data))

        drawLight(data)
        local origin = vec3(data.origin)
        local target = vec3(data.target)
        DrawSphere(origin.x, origin.y, origin.z, 0.08, 255, 255, 60, 0.85)
        DrawSphere(target.x, target.y, target.z, 0.06, 60, 170, 255, 0.75)
        DrawLine(origin.x, origin.y, origin.z, target.x, target.y, target.z, 255, 255, 60, 220)

        if held(241, 220, 70) then
            data.distance = math.min(1000.0, (tonumber(data.distance) or 50.0) + 1.0)
        elseif held(242, 220, 70) then
            data.distance = math.max(0.1, (tonumber(data.distance) or 50.0) - 1.0)
        elseif held(172, 280, 65) then
            data.brightness = math.min(50.0, (tonumber(data.brightness) or 1.0) + 0.1)
        elseif held(173, 280, 65) then
            data.brightness = math.max(0.0, (tonumber(data.brightness) or 1.0) - 0.1)
        elseif held(174, 280, 65) then
            data.hardness = math.max(0.0, (tonumber(data.hardness) or 0.0) - 0.05)
        elseif held(175, 280, 65) then
            data.hardness = math.min(100.0, (tonumber(data.hardness) or 0.0) + 0.05)
        elseif held(44, 280, 75) then
            data.radius = math.max(0.0, (tonumber(data.radius) or 20.0) - 0.5)
        elseif held(38, 280, 75) then
            data.radius = math.min(500.0, (tonumber(data.radius) or 20.0) + 0.5)
        elseif IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
            Spotlights.editorActive = false
            hideText()
            return true, data
        elseif IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 202) then
            Spotlights.editorActive = false
            hideText()
            return false, 'cancelled'
        end
    end

    hideText()
    return false, 'cancelled'
end

function Spotlights.createLight(groupId, defaults, onFinish)
    if Spotlights.editorActive then return false, 'editor_active' end

    defaults = type(defaults) == 'table' and defaults or {}
    local origin, originError = raycastPoint(t('menu.spotlights.capture_origin'))
    if not origin then return false, originError end

    local target, targetError = raycastPoint(t('menu.spotlights.capture_target'), origin)
    if not target then return false, targetError end

    local result = pr_lib.menus.InputDialog(t('menu.spotlights.new_light'), {
        { type = 'input', label = t('inputs.spotlight_name'), default = defaults.name or t('spotlights.default_light'), required = true },
        { type = 'select', label = t('inputs.spotlight_enabled'), options = {
            { value = 'true', label = t('common.yes') },
            { value = 'false', label = t('common.no') },
        }, default = boolValue(defaults.enabled, true) and 'true' or 'false', required = true },
        { type = 'color', label = t('inputs.spotlight_color'), format = 'rgb', default = rgbString(defaults.color), required = true },
        { type = 'number', label = t('inputs.spotlight_distance'), default = tonumber(defaults.distance) or 50.0, min = 0.1, required = true },
        { type = 'number', label = t('inputs.spotlight_brightness'), default = tonumber(defaults.brightness) or 1.0, min = 0.0, required = true },
        { type = 'number', label = t('inputs.spotlight_hardness'), default = tonumber(defaults.hardness) or 0.0, min = 0.0, required = true },
        { type = 'number', label = t('inputs.spotlight_radius'), default = tonumber(defaults.radius) or 20.0, min = 0.0, required = true },
    })

    if not result then return false, 'cancelled' end

    local data = {
        groupId = tonumber(groupId) or tonumber(defaults.groupId) or 0,
        name = tostring(result[1] or defaults.name or t('spotlights.default_light')),
        enabled = boolValue(result[2], true),
        origin = serialVector(origin),
        target = serialVector(target),
        color = colorFromRgb(result[3]),
        distance = tonumber(result[4]) or 50.0,
        brightness = tonumber(result[5]) or 1.0,
        hardness = tonumber(result[6]) or 0.0,
        radius = tonumber(result[7]) or 20.0,
    }

    local confirmed, tuned = fineTune(data)
    if not confirmed then return false, tuned end

    if onFinish then onFinish(tuned) end
    return true, tuned
end

function Spotlights.editLight(light, onFinish)
    light = type(light) == 'table' and light or {}
    local confirmed, tuned = fineTune({
        id = light.id,
        groupId = light.groupId,
        name = light.name,
        enabled = boolValue(light.enabled, true),
        origin = light.origin,
        target = light.target,
        color = light.color,
        distance = light.distance,
        brightness = light.brightness,
        hardness = light.hardness,
        radius = light.radius,
    })

    if not confirmed then return false, tuned end
    if onFinish then onFinish(tuned) end
    return true, tuned
end

AddStateBagChangeHandler('forgeSpotlights', 'global', function(_, _, value)
    applyPayload(value)
end)

CreateThread(function()
    Wait(1000)
    local ok, payload = pr_lib.callback.await(PR.Spotlights.Callbacks.getAll, 10000)
    if ok and payload then applyPayload(payload) else applyPayload(currentPayload()) end

    while true do
        local wait = 1000
        if Spotlights.enabled and #Spotlights.lights > 0 then
            wait = 0
            local playerCoords = GetEntityCoords(PlayerPedId())
            local drawDistance = tonumber(Spotlights.drawDistance) or PR.Spotlights.Defaults.drawDistance

            for _, light in ipairs(Spotlights.lights) do
                if #(playerCoords - vec3(light.origin)) <= drawDistance then
                    drawLight(light)
                end
            end
        end

        Wait(wait)
    end
end)
