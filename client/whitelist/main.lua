ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Whitelist = {
    active = false,
    config = {},
    examRunning = false,
    checking = false,
    targetZone = nil,
    blip = nil,
    lastReturnAt = 0,
}

local function t(key, params)
    return ForgeCore.t(key, params)
end

local function notify(data)
    if pr_lib and pr_lib.Notify then
        pr_lib.Notify({
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

local function fetchWhitelistConfig()
    local ok, config = awaitServer(PR.Whitelist.Callbacks.getConfig)
    if ok and type(config) == 'table' then return config end
end

local beginExam

local function isPlayerLoggedIn()
    return LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn == true
end

local function isCharacterCreationActive()
    if GetResourceState('spacebox_multichar') ~= 'started' then return false end

    local ok, active = pcall(function()
        return exports['spacebox_multichar']:isInCharacterCreation()
    end)

    return ok and active == true
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

local function heading(coords)
    coords = coords or {}
    return tonumber(coords.w or coords.heading) or 0.0
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

local function clearExamTarget()
    if Whitelist.targetZone and pr_lib and pr_lib.target and pr_lib.target.removeZone then
        pr_lib.target.removeZone(Whitelist.targetZone)
    end

    Whitelist.targetZone = nil
end

local function clearExamBlip()
    if Whitelist.blip and DoesBlipExist(Whitelist.blip) then
        RemoveBlip(Whitelist.blip)
    end

    Whitelist.blip = nil
end

local function interactionMode(config)
    local mode = tostring(config.interactionMode or '')
    if mode == '' then
        if config.targetEnabled == true then return 'target' end
        return 'drawtext'
    end

    return mode
end

local function setupExamBlip(config)
    clearExamBlip()
    local blipConfig = type(config.blip) == 'table' and config.blip or {}
    if blipConfig.enabled ~= true then return end

    local coords = coords3(config.examCoords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, tonumber(blipConfig.sprite) or 525)
    SetBlipColour(blip, tonumber(blipConfig.color) or 3)
    SetBlipScale(blip, tonumber(blipConfig.scale) or 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipConfig.label or config.startExamLabel or t('whitelist.pre_exam'))
    EndTextCommandSetBlipName(blip)
    Whitelist.blip = blip
end

local function setupExamTarget(config)
    clearExamTarget()
    local mode = interactionMode(config)
    if mode ~= 'target' and mode ~= 'both' then return end
    if not pr_lib or not pr_lib.target or not pr_lib.target.addBoxZone then return end

    local coords = coords3(config.examCoords)
    Whitelist.targetZone = pr_lib.target.addBoxZone({
        coords = coords,
        size = vec3(1.4, 1.4, 2.0),
        rotation = heading(config.examCoords),
        debug = PR.Debug == true,
        options = {
            {
                name = 'forge_core_whitelist_exam',
                label = config.startExamLabel or t('whitelist.start'),
                icon = 'clipboard2-check-fill',
                distance = 2.0,
                canInteract = function()
                    return Whitelist.active and not Whitelist.examRunning
                end,
                onSelect = function()
                    beginExam()
                end,
            },
        },
    })
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
    local choices = shuffle(question.options or {})
    local options = {}
    for index, option in ipairs(choices) do options[#options + 1] = { value = tostring(index), label = option.label } end
    local result = inputDialog(question.question, {{ type = 'select', label = t('inputs.whitelist_answer'), options = options, required = true }})
    if not result then return false, { value = 'Sem resposta', correct = false } end
    local selected = choices[tonumber(result[1])] or {}
    return selected.value == true, { value = selected.label or 'Sem resposta', correct = selected.value == true }
end

local function finishWhitelist()
    Whitelist.active = false
    teleport(Whitelist.config.completionCoords)
end

local function stopWhitelist()
    Whitelist.active = false
    Whitelist.examRunning = false
    clearExamTarget()
    clearExamBlip()
end

beginExam = function()
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
    local examAnswers = {}
    for index, question in ipairs(questions) do
        local isCorrect, answer = askQuestion(question)
        if isCorrect then correct = correct + 1 end
        examAnswers[question.question or tostring(index)] = answer
    end
    local percent = #questions > 0 and ((100 * correct) / #questions) or 0
    examAnswers.Resultado = { value = ('%.1f%% (%s/%s)'):format(percent, correct, #questions), correct = percent >= (tonumber(config.percent) or 70) }
    awaitServer(PR.Whitelist.Callbacks.submitPreExam, examAnswers)

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

local function startWhitelist(config, forceTeleport)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if type(config) ~= 'table' then return false end

    if Whitelist.active then
        Whitelist.config = config
        setupExamBlip(Whitelist.config)
        setupExamTarget(Whitelist.config)
        if forceTeleport == true then teleport(Whitelist.config.spawnCoords) end
        return true
    end

    Whitelist.active = true
    Whitelist.config = config
    Whitelist.lastReturnAt = 0

    teleport(Whitelist.config.spawnCoords)
    notify({ description = Whitelist.config.loadNotify, type = 'info' })
    setupExamBlip(Whitelist.config)
    setupExamTarget(Whitelist.config)

    CreateThread(function()
        while Whitelist.active do
            Wait(0)

            if not isInsideZone(Whitelist.config) and GetGameTimer() - Whitelist.lastReturnAt >= 3500 then
                Whitelist.lastReturnAt = GetGameTimer()
                teleport(Whitelist.config.spawnCoords)
                notify({ description = Whitelist.config.escapeNotify, type = 'error' })
            end

            local examCoords = coords3(Whitelist.config.examCoords)
            local distance = #(GetEntityCoords(PlayerPedId()) - examCoords)
            local mode = interactionMode(Whitelist.config)

            if Whitelist.config.markerEnabled ~= false and distance <= 20.0 then
                DrawMarker(27, examCoords.x, examCoords.y, examCoords.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 0.3, 26, 115, 179, 160, false, false, 2, false, nil, nil, false)
            end

            if (mode == 'drawtext' or mode == 'both') and distance <= 2.0 then
                drawText3d(vector3(examCoords.x, examCoords.y, examCoords.z + 0.4), ('[E] %s'):format(Whitelist.config.startExamLabel))

                if IsControlJustPressed(0, 38) then
                    beginExam()
                end
            end
        end
    end)

    return true
end

local function checkWhitelist()
    if Whitelist.checking then return end
    if isCharacterCreationActive() then
        SetTimeout(3000, checkWhitelist)
        return
    end

    if not isPlayerLoggedIn() then
        stopWhitelist()
        return
    end

    Whitelist.checking = true

    Wait(2500)

    if isCharacterCreationActive() then
        Whitelist.checking = false
        SetTimeout(3000, checkWhitelist)
        return
    end

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

    local config = type(configOrError) == 'table' and configOrError or fetchWhitelistConfig()
    if type(config) ~= 'table' then
        SetTimeout(3000, checkWhitelist)
        return
    end

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

pr_lib.callback.register(PR.Whitelist.Callbacks.clientRemoved, function(config)
    startWhitelist(type(config) == 'table' and config or fetchWhitelistConfig(), true)
    return true
end)

pr_lib.callback.register(PR.Whitelist.Callbacks.clientConfigUpdated, function(config)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if type(config) ~= 'table' then return true end

    if Whitelist.active then
        if config.enabled then
            startWhitelist(config, false)
        else
            stopWhitelist()
        end
    elseif config.enabled then
        SetTimeout(500, checkWhitelist)
    end

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
