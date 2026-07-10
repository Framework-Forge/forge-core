ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Whitelist = {
    active = false,
    config = {},
    examRunning = false,
    checking = false,
}

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function notify(data)
    if pr_lib and pr_lib.notify and pr_lib.notify.Notify then
        pr_lib.notify.Notify({
            title = data.title or t('whitelist.title'),
            description = data.description,
            type = data.type,
            position = PR.NotifyPos,
        })
    end
end

local function awaitServer(callbackName, ...)
    if not pr_lib or not pr_lib.callback or not pr_lib.callback.await then
        return false, 'callback_unavailable'
    end

    return pr_lib.callback.await(callbackName, 10000, ...)
end

local function isPlayerLoggedIn()
    return LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn == true
end

local function alertDialog(data)
    if pr_lib and pr_lib.menus and pr_lib.menus.AlertDialog then
        return pr_lib.menus.AlertDialog(data)
    end
end

local function inputDialog(title, rows)
    if pr_lib and pr_lib.menus and pr_lib.menus.InputDialog then
        return pr_lib.menus.InputDialog(title, rows)
    end
end

local function coords3(coords)
    coords = coords or {}
    return vector3(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
end

local function teleport(coords)
    coords = coords or {}
    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    Wait(550)
    SetEntityCoords(ped, tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0, false, false, false, false)
    SetEntityHeading(ped, tonumber(coords.w) or 0.0)
    DoScreenFadeIn(700)
end

local function shuffle(list)
    local copy = {}

    for index = 1, #(list or {}) do
        copy[index] = list[index]
    end

    for index = #copy, 2, -1 do
        local randomIndex = math.random(index)
        copy[index], copy[randomIndex] = copy[randomIndex], copy[index]
    end

    return copy
end

local function isInsideZone(config)
    local zone = config.citizenZone or {}
    local center = coords3(zone.coords)
    local size = zone.size or {}
    local pedCoords = GetEntityCoords(PlayerPedId())

    return math.abs(pedCoords.x - center.x) <= ((tonumber(size.x) or 0.0) / 2)
        and math.abs(pedCoords.y - center.y) <= ((tonumber(size.y) or 0.0) / 2)
        and math.abs(pedCoords.z - center.z) <= ((tonumber(size.z) or 0.0) / 2)
end

local function drawText3d(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function submitPreExam(config)
    local preExam = config.preExam or {}
    if not preExam.enabled then return true end

    local rows = {}

    for _, question in ipairs(preExam.questions or {}) do
        rows[#rows + 1] = {
            type = question.type or 'input',
            label = question.label,
            placeholder = question.placeholder,
            required = question.required == true,
            min = question.min,
            max = question.max,
        }
    end

    local result = inputDialog(preExam.label or t('whitelist.pre_exam'), rows)
    if not result then return false end

    local payload = {}
    for index, question in ipairs(preExam.questions or {}) do
        payload[question.label or tostring(index)] = {
            kind = question.kind,
            value = result[index],
        }
    end

    awaitServer(PR.Whitelist.Callbacks.submitPreExam, payload)
    return true
end

local function askQuestion(question)
    local options = {}

    for _, option in ipairs(shuffle(question.options or {})) do
        options[#options + 1] = {
            value = option.value == true and 'true' or 'false',
            label = option.label,
        }
    end

    local result = inputDialog(question.question, {
        {
            type = 'select',
            label = t('inputs.whitelist_answer'),
            options = options,
            required = true,
        },
    })

    return result and result[1] == 'true'
end

local function finishWhitelist()
    Whitelist.active = false
    teleport(Whitelist.config.completionCoords)
end

local function stopWhitelist()
    Whitelist.active = false
    Whitelist.examRunning = false
end

local function beginExam()
    if Whitelist.examRunning then return end
    Whitelist.examRunning = true

    local config = Whitelist.config

    if not submitPreExam(config) then
        Whitelist.examRunning = false
        return
    end

    local confirmed = alertDialog({
        header = config.startExamHeader,
        content = config.startExamContent,
        centered = true,
        cancel = true,
        labels = {
            confirm = t('whitelist.start'),
            cancel = t('common.cancel'),
        },
    })

    if confirmed ~= 'confirm' then
        Whitelist.examRunning = false
        return
    end

    local correct = 0
    local questions = shuffle(config.questions or {})

    for _, question in ipairs(questions) do
        if askQuestion(question) then
            correct = correct + 1
        end
    end

    local percent = #questions > 0 and ((100 * correct) / #questions) or 0

    if percent >= (tonumber(config.percent) or 70) then
        alertDialog({
            header = config.successHeader,
            content = config.successContent,
            centered = true,
            labels = { confirm = t('whitelist.play') },
        })

        local ok, response = awaitServer(PR.Whitelist.Callbacks.add)
        if ok then
            finishWhitelist()
        else
            notify({ description = t('notify.whitelist.add_failed', { error = tostring(response) }), type = 'error' })
        end
    else
        alertDialog({
            header = config.failedHeader,
            content = config.failedContent,
            centered = true,
            labels = { confirm = t('common.ok') },
        })
    end

    Whitelist.examRunning = false
end

local function startWhitelist(config)
    if Whitelist.active then
        Whitelist.config = config or Whitelist.config or PR.Whitelist.Defaults
        return
    end

    Whitelist.active = true
    Whitelist.config = config or PR.Whitelist.Defaults

    teleport(Whitelist.config.spawnCoords)
    notify({ description = Whitelist.config.loadNotify, type = 'info' })

    CreateThread(function()
        while Whitelist.active do
            Wait(0)

            if not isInsideZone(Whitelist.config) then
                teleport(Whitelist.config.spawnCoords)
                notify({ description = Whitelist.config.escapeNotify, type = 'error' })
                Wait(1000)
            end

            local examCoords = coords3(Whitelist.config.examCoords)
            local distance = #(GetEntityCoords(PlayerPedId()) - examCoords)

            if distance <= 20.0 then
                DrawMarker(27, examCoords.x, examCoords.y, examCoords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 0.3, 26, 115, 179, 160, false, false, 2, false, nil, nil, false)
            end

            if distance <= 2.0 then
                drawText3d(vector3(examCoords.x, examCoords.y, examCoords.z + 0.4), ('[E] %s'):format(Whitelist.config.startExamLabel))

                if IsControlJustPressed(0, 38) then
                    beginExam()
                end
            end
        end
    end)
end

local function checkWhitelist()
    if Whitelist.checking then return end
    if not isPlayerLoggedIn() then
        stopWhitelist()
        return
    end

    Whitelist.checking = true

    Wait(2500)

    if not isPlayerLoggedIn() then
        Whitelist.checking = false
        stopWhitelist()
        return
    end

    local allowed, configOrError = awaitServer(PR.Whitelist.Callbacks.check)
    Whitelist.checking = false

    if allowed == true then
        stopWhitelist()
        return
    end

    local config = type(configOrError) == 'table' and configOrError or PR.Whitelist.Defaults
    if config.pending then
        SetTimeout(3000, checkWhitelist)
        return
    end

    if config.enabled then
        startWhitelist(config)
    end
end

pr_lib.callback.register(PR.Whitelist.Callbacks.clientAdded, function()
    if Whitelist.active then
        finishWhitelist()
    else
        stopWhitelist()
    end

    return true
end)

pr_lib.callback.register(PR.Whitelist.Callbacks.clientRemoved, function()
    startWhitelist(Whitelist.config or PR.Whitelist.Defaults)
    return true
end)

CreateThread(function()
    Wait(5000)

    if isPlayerLoggedIn() then
        checkWhitelist()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(1500, checkWhitelist)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    stopWhitelist()
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    stopWhitelist()
end)

AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    if value == true then
        SetTimeout(1500, checkWhitelist)
    else
        stopWhitelist()
    end
end)
