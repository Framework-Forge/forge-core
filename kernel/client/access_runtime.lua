-- Whole installed whitelist client port; inactive descriptors, see NOTICE-33.md.
return function(ports)
    local PR,library,native=assert(ports.config),assert(ports.library),assert(ports.native)
    local session,translate,integration=assert(ports.session),assert(ports.translate),assert(ports.characterIntegration)
    assert(type(integration.resourceState)=='function' and type(integration.isInCharacterCreation)=='function','PR character integration required')
    local api={Events={},Callbacks={},Threads={}}
    local function listen(name,handler,network)api.Events[#api.Events+1]={name=name,handler=handler,network=network==true}end
    local function network(name,handler)listen(name,handler,true)end
    local function describeCallback(name,handler)api.Callbacks[name]=handler end
    local function describeThread(handler)api.Threads[#api.Threads+1]=handler end
    local vector3,vec3=assert(native.vector3),assert(native.vec3)
    local AddBlipForCoord=assert(native.AddBlipForCoord,'AddBlipForCoord port required')
    local AddTextComponentString=assert(native.AddTextComponentString,'AddTextComponentString port required')
    local BeginTextCommandSetBlipName=assert(native.BeginTextCommandSetBlipName,'BeginTextCommandSetBlipName port required')
    local ClearDrawOrigin=assert(native.ClearDrawOrigin,'ClearDrawOrigin port required')
    local CreateThread=assert(native.CreateThread,'CreateThread port required')
    local DoScreenFadeIn=assert(native.DoScreenFadeIn,'DoScreenFadeIn port required')
    local DoScreenFadeOut=assert(native.DoScreenFadeOut,'DoScreenFadeOut port required')
    local DoesBlipExist=assert(native.DoesBlipExist,'DoesBlipExist port required')
    local DrawMarker=assert(native.DrawMarker,'DrawMarker port required')
    local DrawText=assert(native.DrawText,'DrawText port required')
    local EndTextCommandSetBlipName=assert(native.EndTextCommandSetBlipName,'EndTextCommandSetBlipName port required')
    local GetEntityCoords=assert(native.GetEntityCoords,'GetEntityCoords port required')
    local GetGameTimer=assert(native.GetGameTimer,'GetGameTimer port required')
    local IsControlJustPressed=assert(native.IsControlJustPressed,'IsControlJustPressed port required')
    local PlayerPedId=assert(native.PlayerPedId,'PlayerPedId port required')
    local RemoveBlip=assert(native.RemoveBlip,'RemoveBlip port required')
    local SetBlipAsShortRange=assert(native.SetBlipAsShortRange,'SetBlipAsShortRange port required')
    local SetBlipColour=assert(native.SetBlipColour,'SetBlipColour port required')
    local SetBlipScale=assert(native.SetBlipScale,'SetBlipScale port required')
    local SetBlipSprite=assert(native.SetBlipSprite,'SetBlipSprite port required')
    local SetDrawOrigin=assert(native.SetDrawOrigin,'SetDrawOrigin port required')
    local SetEntityCoords=assert(native.SetEntityCoords,'SetEntityCoords port required')
    local SetEntityHeading=assert(native.SetEntityHeading,'SetEntityHeading port required')
    local SetTextCentre=assert(native.SetTextCentre,'SetTextCentre port required')
    local SetTextEntry=assert(native.SetTextEntry,'SetTextEntry port required')
    local SetTextFont=assert(native.SetTextFont,'SetTextFont port required')
    local SetTextScale=assert(native.SetTextScale,'SetTextScale port required')
    local SetTimeout=assert(native.SetTimeout,'SetTimeout port required')
    local Wait=assert(native.Wait,'Wait port required')
local Whitelist = {
    active = false,
    config = {},
    examRunning = false,
    checking = false,
    session = 0,
    targetZone = nil,
    blip = nil,
    lastReturnAt = 0,
}

local function t(key, params)
    return translate(key, params)
end

local function notify(data)
    if library and library.Notify then
        library.Notify({
            title = data.title or t('whitelist.title'),
            description = data.description,
            type = data.type,
            position = PR.NotifyPos,
        })
    end
end

local function awaitServer(callbackName, ...)
    if not library or not library.callback or not library.callback.await then
        return false, 'callback_unavailable'
    end

    return library.callback.await(callbackName, 10000, ...)
end

local function fetchWhitelistConfig()
    local ok, config = awaitServer(PR.Whitelist.Callbacks.getConfig)
    if ok and type(config) == 'table' then return config end
end

local beginExam

local function isPlayerLoggedIn()
    return session.isLoaded()
end

local function isCharacterCreationActive()
    if integration.resourceState('spacebox_multichar') ~= 'started' then return false end

    local ok, active = pcall(function()
        return integration.isInCharacterCreation('spacebox_multichar')
    end)

    return ok and active == true
end

local function alertDialog(data)
    if library and library.menus and library.menus.AlertDialog then
        return library.menus.AlertDialog(data)
    end
end

local function inputDialog(title, rows)
    if library and library.menus and library.menus.InputDialog then
        return library.menus.InputDialog(title, rows)
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
    if Whitelist.targetZone and library and library.target and library.target.removeZone then
        library.target.removeZone(Whitelist.targetZone)
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
    if not library or not library.target or not library.target.addBoxZone then return end

    local coords = coords3(config.examCoords)
    Whitelist.targetZone = library.target.addBoxZone({
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
    local session = Whitelist.session

    Wait(2500)
    if session ~= Whitelist.session then return end

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
    if session ~= Whitelist.session then return end
    Whitelist.checking = false

    if allowed == true then
        stopWhitelist()
        return
    end

    local config = type(configOrError) == 'table' and configOrError or fetchWhitelistConfig()
    if session ~= Whitelist.session then return end
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

describeCallback(PR.Whitelist.Callbacks.clientAdded, function()
    if Whitelist.active then
        finishWhitelist()
    else
        stopWhitelist()
    end

    return true
end)

describeCallback(PR.Whitelist.Callbacks.clientRemoved, function(config)
    startWhitelist(type(config) == 'table' and config or fetchWhitelistConfig(), true)
    return true
end)

describeCallback(PR.Whitelist.Callbacks.clientConfigUpdated, function(config)
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

describeThread(function()
    Wait(5000)

    if isPlayerLoggedIn() then
        checkWhitelist()
    end
end)

network('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(1500, checkWhitelist)
end)

network('QBCore:Client:OnPlayerUnload', function()
    stopWhitelist()
end)

network('qbx_core:client:playerLoggedOut', function()
    stopWhitelist()
end)

listen('forge-core:session:changed', function(character)
    Whitelist.session = Whitelist.session + 1
    Whitelist.checking = false
    if character then
        SetTimeout(1500, checkWhitelist)
    else
        stopWhitelist()
    end
end)

    api.State=Whitelist
    return api
end
