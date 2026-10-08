ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Billboards = {
    enabled = false,
    renderDistance = PR.Billboards.Defaults.renderDistance,
    entries = {},
    duis = {},
    captureActive = false,
}

ForgeCore.Client.Billboards = Billboards

local function t(key, params)
    return ForgeCore.t(key, params)
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

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function textureNames(id)
    return 'forge_billboard_txd_' .. tostring(id), 'forge_billboard_tex_' .. tostring(id)
end

local function normalFromVertices(topLeft, topRight, bottomLeft)
    local horizontal = topRight - topLeft
    local vertical = bottomLeft - topLeft
    local normal = vector3(
        horizontal.y * vertical.z - horizontal.z * vertical.y,
        horizontal.z * vertical.x - horizontal.x * vertical.z,
        horizontal.x * vertical.y - horizontal.y * vertical.x
    )

    local length = #(normal)
    if length <= 0.001 then return vector3(0.0, 0.0, 0.0) end

    return normal / length
end

local function offsetVertices(vertices, offset)
    local topLeft = vec3(vertices[1])
    local topRight = vec3(vertices[2])
    local bottomLeft = vec3(vertices[3])
    local bottomRight = vec3(vertices[4])
    local normal = normalFromVertices(topLeft, topRight, bottomLeft) * (tonumber(offset) or 0.03)

    return topLeft + normal, topRight + normal, bottomLeft + normal, bottomRight + normal
end

local function destroyDui(id)
    local item = Billboards.duis[id]
    if not item then return end

    if item.dui then DestroyDui(item.dui) end
    Billboards.duis[id] = nil
end

local function ensureDui(billboard)
    local id = tonumber(billboard.id)
    if not id then return false end

    local url = tostring(billboard.url or '')
    local width = math.max(1, math.floor(tonumber(billboard.width) or PR.Billboards.Defaults.width))
    local height = math.max(1, math.floor(tonumber(billboard.height) or PR.Billboards.Defaults.height))
    local current = Billboards.duis[id]

    if current and current.url == url and current.width == width and current.height == height then
        return true
    end

    destroyDui(id)

    if url == '' then return false end

    local txdName, textureName = textureNames(id)
    local txd = CreateRuntimeTxd(txdName)
    local dui = CreateDui(url, width, height)
    local handle = GetDuiHandle(dui)
    CreateRuntimeTextureFromDuiHandle(txd, textureName, handle)

    Billboards.duis[id] = {
        dui = dui,
        url = url,
        width = width,
        height = height,
    }

    return true
end

local function drawBillboard(billboard)
    if not boolValue(billboard.enabled, true) then return end
    if not ensureDui(billboard) then return end

    local vertices = type(billboard.vertices) == 'table' and billboard.vertices or {}
    local topLeft, topRight, bottomLeft, bottomRight = offsetVertices(vertices, billboard.offset)
    local txdName, textureName = textureNames(billboard.id)

    DrawSpritePoly(
        bottomRight.x, bottomRight.y, bottomRight.z,
        topRight.x, topRight.y, topRight.z,
        topLeft.x, topLeft.y, topLeft.z,
        255, 255, 255, 255,
        txdName, textureName,
        1.0, 1.0, 1.0,
        1.0, 0.0, 1.0,
        0.0, 0.0, 1.0
    )

    DrawSpritePoly(
        topLeft.x, topLeft.y, topLeft.z,
        bottomLeft.x, bottomLeft.y, bottomLeft.z,
        bottomRight.x, bottomRight.y, bottomRight.z,
        255, 255, 255, 255,
        txdName, textureName,
        0.0, 0.0, 1.0,
        0.0, 1.0, 1.0,
        1.0, 1.0, 1.0
    )
end

local function applyPayload(payload)
    payload = type(payload) == 'table' and payload or {}
    local nextEntries = {}
    local seen = {}

    Billboards.enabled = boolValue(payload.enabled, false)
    Billboards.renderDistance = tonumber(payload.renderDistance) or PR.Billboards.Defaults.renderDistance

    for _, billboard in ipairs(type(payload.billboards) == 'table' and payload.billboards or {}) do
        local id = tonumber(billboard.id)
        if id then
            seen[id] = true
            if boolValue(billboard.enabled, true) and Billboards.enabled then
                nextEntries[#nextEntries + 1] = billboard
            else
                destroyDui(id)
            end
        end
    end

    for id in pairs(Billboards.duis) do
        if not seen[id] then destroyDui(id) end
    end

    Billboards.entries = nextEntries
end

function Billboards.applyPayload(payload)
    applyPayload(payload)
end

function Billboards.setBillboardEnabled(id, enabled)
    id = tonumber(id)
    if not id then return end

    for _, billboard in ipairs(Billboards.entries) do
        if tonumber(billboard.id) == id then
            billboard.enabled = enabled == true
            break
        end
    end

    if enabled ~= true then destroyDui(id) end
end

local function setText(text)
    if pr_lib and pr_lib.ShowTextUI then
        pr_lib.ShowTextUI(text, { position = 'right-center' })
    end
end

local function hideText()
    if pr_lib and pr_lib.HideTextUI then pr_lib.HideTextUI() end
end

local function raycastPoint(label, previous)
    if not pr_lib or not pr_lib.raycast or not pr_lib.raycast.FromCamera then
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
        DisableControlAction(0, 177, true)
        DisableControlAction(0, 202, true)
        DisablePlayerFiring(PlayerId(), true)

        local hit, _, coords = pr_lib.raycast.FromCamera(1000.0, 1, 4)
        if hit and coords then
            local point = vec3(coords)
            DrawSphere(point.x, point.y, point.z, 0.06, 0, 220, 255, 0.75)

            if previous then
                for _, previousPoint in ipairs(previous) do
                    previousPoint = vec3(previousPoint)
                    DrawSphere(previousPoint.x, previousPoint.y, previousPoint.z, 0.05, 0, 255, 120, 0.65)
                    DrawLine(previousPoint.x, previousPoint.y, previousPoint.z, point.x, point.y, point.z, 0, 220, 255, 190)
                end
            end

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

function Billboards.captureVertices()
    if Billboards.captureActive then return false, 'capture_active' end
    Billboards.captureActive = true

    local captured = {}
    local labels = {
        t('menu.billboards.capture_top_left'),
        t('menu.billboards.capture_top_right'),
        t('menu.billboards.capture_bottom_left'),
        t('menu.billboards.capture_bottom_right'),
    }

    for index, label in ipairs(labels) do
        local point, error = raycastPoint(label, captured)
        if not point then
            Billboards.captureActive = false
            return false, error
        end

        captured[index] = point
        Wait(250)
    end

    Billboards.captureActive = false

    return true, {
        serialVector(captured[1]),
        serialVector(captured[2]),
        serialVector(captured[3]),
        serialVector(captured[4]),
    }
end

local function tuneText(offset)
    return t('menu.billboards.offset_controls', {
        offset = ('%.3f'):format(tonumber(offset) or 0.0),
    })
end

function Billboards.fineTuneOffset(billboard)
    if Billboards.captureActive then return false, 'capture_active' end
    if type(billboard) ~= 'table' then return false, 'invalid_billboard' end

    Billboards.captureActive = true

    local data = {
        id = billboard.id,
        enabled = true,
        url = billboard.url,
        width = billboard.width,
        height = billboard.height,
        vertices = billboard.vertices,
        offset = tonumber(billboard.offset) or 0.03,
    }

    while Billboards.captureActive do
        Wait(0)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 38, true)
        DisableControlAction(0, 172, true)
        DisableControlAction(0, 173, true)
        DisableControlAction(0, 177, true)
        DisableControlAction(0, 201, true)
        DisableControlAction(0, 202, true)
        DisablePlayerFiring(PlayerId(), true)

        setText(tuneText(data.offset))
        drawBillboard(data)

        local vertices = type(data.vertices) == 'table' and data.vertices or {}
        local topLeft, topRight, bottomLeft, bottomRight = offsetVertices(vertices, data.offset)
        DrawLine(topLeft.x, topLeft.y, topLeft.z, topRight.x, topRight.y, topRight.z, 0, 255, 120, 220)
        DrawLine(topRight.x, topRight.y, topRight.z, bottomRight.x, bottomRight.y, bottomRight.z, 0, 255, 120, 220)
        DrawLine(bottomRight.x, bottomRight.y, bottomRight.z, bottomLeft.x, bottomLeft.y, bottomLeft.z, 0, 255, 120, 220)
        DrawLine(bottomLeft.x, bottomLeft.y, bottomLeft.z, topLeft.x, topLeft.y, topLeft.z, 0, 255, 120, 220)

        if IsControlPressed(0, 172) or IsDisabledControlPressed(0, 172) then
            data.offset = math.min(2.0, data.offset + 0.0025)
        elseif IsControlPressed(0, 173) or IsDisabledControlPressed(0, 173) then
            data.offset = math.max(-2.0, data.offset - 0.0025)
        elseif IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
            Billboards.captureActive = false
            hideText()
            return true, data.offset
        elseif IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 202) then
            Billboards.captureActive = false
            hideText()
            return false, 'cancelled'
        end
    end

    hideText()
    return false, 'cancelled'
end

ForgeCore.State.onChange('billboards', function(value)
    applyPayload(value)
end)

CreateThread(function()
    local current = ForgeCore.State.peek('billboards')
    applyPayload(type(current) == 'table' and current or {})

    while true do
        local wait = 1000

        if Billboards.enabled and #Billboards.entries > 0 then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local renderDistance = tonumber(Billboards.renderDistance) or PR.Billboards.Defaults.renderDistance

            for _, billboard in ipairs(Billboards.entries) do
                local vertices = type(billboard.vertices) == 'table' and billboard.vertices or {}
                local origin = vec3(vertices[1])
                if #(playerCoords - origin) <= renderDistance then
                    wait = 0
                    drawBillboard(billboard)
                end
            end
        end

        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for id in pairs(Billboards.duis) do
        destroyDui(id)
    end
end)
