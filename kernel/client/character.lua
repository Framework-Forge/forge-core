-- Private, inactive installed QBX client character flow. MIT: LICENSE-QBX/NOTICE-13.md.
return function(ports)
    local config = assert(ports.config, 'local client config required')
    local api = {Enabled = false, Events = {}, Threads = {}}
    function api.Initialize() return false end
    if config.characters.useExternalCharacters then return api end
    api.Enabled = true
    local core = assert(ports.core, 'canonical client state required')
    local native = assert(ports.native, 'native ports required')
    local cache = assert(ports.cache, 'canonical native cache required')
    local renderer = assert(ports.renderer, 'local renderer required')
    local defaultSpawn = assert(ports.defaultSpawn, 'local shared default spawn required')
    local ui = assert(ports.ui, 'PR menu/dialog ports required')
    local callbacks = assert(ports.callbacks, 'core callback transport required')
    local integrations = assert(ports.integrations, 'PR external integration ports required')
    local Notify = assert(ports.notify, 'internal Notify required')
    local locale = assert(ports.locale, 'locale port required')
    local groupdigits = assert(ports.groupdigits, 'groupdigits helper required')
    local strsplit = assert(ports.strsplit, 'strsplit helper required')
    local random = assert(ports.random, 'RNG port required')
    local nationalityList = assert(ports.nationalities, 'local nationalities required')
    local randomLocation
    local nationalities = {}
    local function listen(name, handler, networked)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = networked == true}
    end
    local function network(name, handler) listen(name, handler, true) end
    local function thread(handler) api.Threads[#api.Threads + 1] = handler end
    local configuredPreviewLocations = assert(renderer.configuredPreviewLocations, 'renderer method required')
    local previewPed = assert(renderer.previewPed, 'renderer method required')
    local destroyPreviewCam = assert(renderer.destroyPreviewCam, 'renderer method required')
    local buildConfiguredPreviews = assert(renderer.buildConfiguredPreviews, 'renderer method required')
    local configuredOverview = assert(renderer.configuredOverview, 'renderer method required')
    local setupPreviewCam = assert(renderer.setupPreviewCam, 'renderer method required')
    local focusConfiguredPreview = assert(renderer.focusConfiguredPreview, 'renderer method required')
    local showConfiguredOverview = assert(renderer.showConfiguredOverview, 'renderer method required')
    if config.characters.limitNationalities then
        thread(function()
            for i = 1, #nationalityList do
                nationalities[#nationalities + 1] = {value = nationalityList[i]}
            end
        end)
    end

---@param slotSettings table?
---@return CharacterRegistration?
local function characterDialog(slotSettings)
    slotSettings = type(slotSettings) == 'table' and slotSettings or {}
    local nationalityOption = config.characters.limitNationalities and {
        type = 'select',
        required = true,
        icon = 'user-shield',
        label = locale('info.nationality'),
        default = 'American',
        searchable = true,
        options = nationalities
    } or {
        type = 'input',
        required = true,
        icon = 'user-shield',
        label = locale('info.nationality'),
        placeholder = 'Duck'
    }

    local fields = {
        {
            type = 'input',
            required = true,
            icon = 'user-pen',
            label = locale('info.first_name'),
            placeholder = slotSettings.firstNamePlaceholder or 'Hank'
        },
        {
            type = 'input',
            required = true,
            icon = 'user-pen',
            label = locale('info.last_name'),
            placeholder = slotSettings.lastNamePlaceholder or 'Jordan'
        },
        nationalityOption,
        {
            type = 'select',
            required = true,
            icon = 'circle-user',
            label = locale('info.gender'),
            placeholder = locale('info.select_gender'),
            options = {
                { value = locale('info.char_male') },
                { value = locale('info.char_female') }
            }
        },
        {
            type = 'date',
            required = true,
            icon = 'calendar-days',
            label = locale('info.birth_date'),
            format = config.characters.dateFormat,
            returnString = true,
            min = config.characters.dateMin,
            max = slotSettings.birthdateMax or config.characters.dateMax,
            default = slotSettings.birthdateMax or config.characters.dateMax
        }
    }

    if slotSettings.termsEnabled then
        fields[#fields + 1] = {
            type = 'checkbox',
            required = true,
            label = slotSettings.termsTitle or locale('info.character_terms_title'),
            description = slotSettings.termsText or locale('info.character_terms_description'),
        }
    end

    return ui.inputDialog(locale('info.character_registration_title'), fields)
end

---@param dialog string[]
---@param input integer
---@return boolean
local function checkStrings(dialog, input)
    local str = dialog[input]
    if config.characters.profanityWords[str:lower()] then return false end

    local split = {strsplit(' ', str)}
    if #split > 5 then return false end

    for i = 1, #split do
        local word = split[i]
        if config.characters.profanityWords[word:lower()] then return false end
    end

    return true
end

-- @param str string
-- @return string?
local function capString(str)
    return str:gsub("(%w)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

local function openFirstCharacterAppearance()
    for _ = 1, 50 do
        if native.GetResourceState('illenium-appearance') == 'started' then break end
        native.Wait(100)
    end

    integrations.openFirstCharacterAppearance()
end

local function spawnDefault() -- We use a callback to make the server wait on this to be done
    integrations.deferForAppearance()
    native.DoScreenFadeOut(500)

    while not native.IsScreenFadedOut() do
        native.Wait(0)
    end

    destroyPreviewCam()

    pcall(function() integrations.spawnPlayer({
        x = defaultSpawn.x,
        y = defaultSpawn.y,
        z = defaultSpawn.z,
        heading = defaultSpawn.w
    }) end)

    native.TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    native.TriggerEvent('QBCore:Client:OnPlayerLoaded')
    integrations.setHouseInside(0, false)
    integrations.setApartmentInside(0, 0, false)

    while not native.IsScreenFadedIn() do
        native.Wait(0)
    end
    openFirstCharacterAppearance()
end

local function spawnLastLocation()
    native.DoScreenFadeOut(500)

    while not native.IsScreenFadedOut() do
        native.Wait(0)
    end

    destroyPreviewCam()

    pcall(function() integrations.spawnPlayer({
        x = core.PlayerData.position.x,
        y = core.PlayerData.position.y,
        z = core.PlayerData.position.z,
        heading = core.PlayerData.position.w
    }) end)

    --  ps-housing
    local insideMeta = core.PlayerData.metadata and core.PlayerData.metadata.inside
    if insideMeta and insideMeta.property_id then
        integrations.enterProperty(tostring(insideMeta.property_id))
    end

    native.TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    native.TriggerEvent('QBCore:Client:OnPlayerLoaded')
    -- ps-housing

    while not native.IsScreenFadedIn() do
        native.Wait(0)
    end
end

---@param cid integer
---@param slotSettings table?
---@return boolean
local function createCharacter(cid, slotSettings)
    if not renderer.IsConfigured() then previewPed() end

    :: noMatch ::

    local dialog = characterDialog(slotSettings)

    if not dialog then return false end

    for input = 1, 3 do -- Execute as três primeiras entradas, também conhecidas como nome, sobrenome e nacionalidade
        if not checkStrings(dialog, input) then
            Notify(locale('error.no_match_character_registration'), 'error', 10000)
            goto noMatch
            break
        end
    end

    if slotSettings and slotSettings.termsEnabled then
        local acceptance = ui.inputDialog(slotSettings.termsTitle or locale('info.character_terms_title'), {
            { type = 'textarea', label = slotSettings.termsTitle or locale('info.character_terms_title'),
                default = slotSettings.termsText or locale('info.character_terms_description'),
                disabled = true, autosize = true, min = 8, max = 18 },
            { type = 'checkbox', label = locale('info.character_terms_title'), required = true },
        }, { allowCancel = true })
        if not acceptance or acceptance[2] ~= true then return false end
    end

    native.DoScreenFadeOut(150)
    local newData, errorCode = callbacks.await('qbx_core:server:createCharacter', false, {
        firstname = capString(dialog[1]),
        lastname = capString(dialog[2]),
        nationality = capString(dialog[3]),
        gender = dialog[4] == locale('info.char_male') and 0 or 1,
        birthdate = dialog[5],
        cid = cid,
        termsAccepted = not (slotSettings and slotSettings.termsEnabled) or dialog[6] == true,
    })
    if not newData then
        native.DoScreenFadeIn(150)
        local localeKeys = {
            character_slot_unavailable = 'error.character_slot_unavailable',
            character_slot_locked = 'error.character_slot_locked',
            character_slot_occupied = 'error.character_slot_occupied',
            character_terms_required = 'error.character_terms_required',
            minimum_age_required = 'error.minimum_age_required',
            invalid_birthdate = 'error.invalid_birthdate',
        }
        Notify(locale(localeKeys[errorCode] or 'error.character_creation_failed'), 'error', 10000)
        return false
    end

    if native.GetResourceState('qbx_spawn') == 'missing' then
        spawnDefault()
    else
        if config.characters.startingApartment then
            integrations.setupApartmentSpawn(newData)
        else
            native.TriggerEvent('qbx_core:client:spawnNoApartments', true)
        end
    end

    destroyPreviewCam()
    return true
end

local function chooseCharacter()
    core.BridgeCache.refreshContext('character-select')
    ---@type PlayerEntity[], integer, table
    local characters, amount, slotPayload = callbacks.await('qbx_core:server:getCharacters')
    slotPayload = type(slotPayload) == 'table' and slotPayload or {}
    local slotSettings = type(slotPayload.settings) == 'table' and slotPayload.settings or {}
    local unlockedSlots = type(slotPayload.unlocked) == 'table' and slotPayload.unlocked or { [1] = true }
    local charactersBySlot = {}
    for index = 1, #characters do
        local slot = tonumber(characters[index].charinfo and characters[index].charinfo.cid) or index
        charactersBySlot[slot] = characters[index]
    end
    local firstCharacterCitizenId = characters[1] and characters[1].citizenid
    local configuredLocations = configuredPreviewLocations(slotPayload)
    local firstConfiguredLocation = configuredLocations[1]
    local hasConfiguredLocation = type(firstConfiguredLocation) == 'table'
        and tonumber(firstConfiguredLocation.x) and tonumber(firstConfiguredLocation.y)
        and tonumber(firstConfiguredLocation.z) and tonumber(firstConfiguredLocation.heading or firstConfiguredLocation.w)
    if not hasConfiguredLocation then previewPed(firstCharacterCitizenId) end

    randomLocation = config.characters.locations[random(1, #config.characters.locations)]
    native.SetFollowPedCamViewMode(2)
    native.DisplayRadar(false)

    native.DoScreenFadeOut(500)

    while not native.IsScreenFadedOut() and cache.ped ~= native.PlayerPedId()  do
        native.Wait(0)
    end

    native.FreezeEntityPosition(cache.ped, true)
    native.Wait(1000)
    local holdingLocation = hasConfiguredLocation and firstConfiguredLocation or randomLocation.pedCoords
    native.SetEntityCoords(cache.ped, holdingLocation.x, holdingLocation.y, holdingLocation.z, false, false, false, false)
    native.SetEntityHeading(cache.ped, holdingLocation.heading or holdingLocation.w)
    if hasConfiguredLocation then
        native.SetEntityVisible(cache.ped, false, false)
        native.SetEntityCollision(cache.ped, false, false)
    end

    native.NetworkStartSoloTutorialSession()

    while not native.NetworkIsInTutorialSession() do
        native.Wait(0)
    end

    native.Wait(1500)

    local loadingHandled = false
    if native.GetResourceState("forge-loadscreen") == "started" then
        loadingHandled = pcall(function()
            integrations.finishLoadingScreen()
        end)
    end

    if not loadingHandled then
        native.ShutdownLoadingScreen()
        native.ShutdownLoadingScreenNui()
    end

    if hasConfiguredLocation and buildConfiguredPreviews(charactersBySlot, amount, configuredLocations) then
        setupPreviewCam(configuredOverview())
    else
        native.SetEntityVisible(cache.ped, true, false)
        native.SetEntityCollision(cache.ped, true, true)
        native.SetEntityCoords(cache.ped, randomLocation.pedCoords.x, randomLocation.pedCoords.y, randomLocation.pedCoords.z, false, false, false, false)
        native.SetEntityHeading(cache.ped, randomLocation.pedCoords.w)
        previewPed(firstCharacterCitizenId)
        setupPreviewCam()
    end

    local options = {}
    for i = 1, amount do
        local character = charactersBySlot[i]
        local blocked = slotPayload.blocked and (slotPayload.blocked[i] or slotPayload.blocked[tostring(i)])
        local unlocked = not blocked and (character ~= nil or slotSettings.requireItem ~= true
            or unlockedSlots[i] == true or unlockedSlots[tostring(i)] == true)
        local name = character and ('%s %s'):format(character.charinfo.firstname, character.charinfo.lastname)
        options[i] = {
            title = character and ('%s %s - %s'):format(character.charinfo.firstname, character.charinfo.lastname, character.citizenid)
                or unlocked and locale('info.multichar_new_character', i)
                or locale('info.multichar_locked_slot', i),
            description = blocked and 'Slot suspenso pela administração.' or not unlocked and locale('info.multichar_locked_slot_description') or nil,
            disabled = not unlocked,
            metadata = character and {
                Name = name,
                Gender = character.charinfo.gender == 0 and locale('info.char_male') or locale('info.char_female'),
                Birthdate = character.charinfo.birthdate,
                Nationality = character.charinfo.nationality,
                ['Account Number'] = character.charinfo.account,
                Bank = groupdigits(character.money.bank),
                Cash = groupdigits(character.money.cash),
                Job = character.job.label,
                ['Job Grade'] = character.job.grade.name,
                Gang = character.gang.label,
                ['Gang Grade'] = character.gang.grade.name,
                ['Phone Number'] = character.charinfo.phone
            } or nil,
            icon = 'user',
            onSelect = function()
                focusConfiguredPreview(i)
                if character then
                    ui.showContext('qbx_core_multichar_character_'..i)
                    if not renderer.IsConfigured() then previewPed(character.citizenid) end
                else
                    local success = createCharacter(i, slotSettings)
                    if success then return end

                    if not renderer.IsConfigured() then previewPed(firstCharacterCitizenId) end
                    showConfiguredOverview()
                    ui.showContext('qbx_core_multichar_characters')
                end
            end
        }

        if character then
            ui.registerContext({
                id = 'qbx_core_multichar_character_'..i,
                title = ('%s %s - %s'):format(character.charinfo.firstname, character.charinfo.lastname, character.citizenid),
                canClose = false,
                menu = 'qbx_core_multichar_characters',
                onBack = showConfiguredOverview,
                options = {
                    {
                        title = locale('info.play'),
                        description = locale('info.play_description', name),
                        icon = 'play',
                        onSelect = function()
                            native.DoScreenFadeOut(10)
                            local loaded = callbacks.await('qbx_core:server:loadCharacter', false, character.citizenid)
                            if loaded ~= true then
                                Notify('Não foi possível carregar este personagem. O slot pode estar suspenso.', 'error')
                                native.DoScreenFadeIn(250)
                                destroyPreviewCam()
                                chooseCharacter()
                                return
                            end
                            if native.GetResourceState('qbx_apartments'):find('start') then
                                integrations.setupApartmentSpawn(character.citizenid)
                            elseif native.GetResourceState('qbx_spawn'):find('start') then
                                integrations.setupSpawns(character.citizenid)
                                integrations.openSpawnUI(true)
                            else
                                spawnLastLocation()
                            end
                            destroyPreviewCam()
                        end
                    },
                    config.characters.enableDeleteButton and {
                        title = locale('info.delete_character'),
                        description = locale('info.delete_character_description', name),
                        icon = 'trash',
                        onSelect = function()
                            local alert = ui.alertDialog({
                                header = locale('info.delete_character'),
                                content = locale('info.confirm_delete'),
                                centered = true,
                                cancel = true
                            })
                            if alert == 'confirm' then
                                local success = callbacks.await('qbx_core:server:deleteCharacter', false, character.citizenid)
                                Notify(success and locale('success.character_deleted') or locale('error.character_delete_failed'), success and 'success' or 'error')

                                destroyPreviewCam()
                                chooseCharacter()
                            else
                                ui.showContext('qbx_core_multichar_character_'..i)
                            end
                        end
                    } or nil
                }
            })
        end
    end

    ui.registerContext({
        id = 'qbx_core_multichar_characters',
        title = locale('info.multichar_title'),
        canClose = false,
        options = options
    })

    native.SetTimecycleModifier('default')
    ui.showContext('qbx_core_multichar_characters')
end

network('qbx_core:client:spawnNoApartments', function(isNewCharacter) -- This event is only for no starting apartments
    if isNewCharacter then integrations.deferForAppearance() end
    native.DoScreenFadeOut(500)
    native.Wait(2000)
    native.SetEntityCoords(cache.ped, defaultSpawn.x, defaultSpawn.y, defaultSpawn.z, false, false, false, false)
    native.SetEntityHeading(cache.ped, defaultSpawn.w)
    native.Wait(500)
    destroyPreviewCam()
    native.SetEntityVisible(cache.ped, true, false)
    native.Wait(500)
    native.DoScreenFadeIn(250)
    native.TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    native.TriggerEvent('QBCore:Client:OnPlayerLoaded')
    integrations.setHouseInside(0, false)
    integrations.setApartmentInside(0, 0, false)
    integrations.enableWeatherSync()
    if isNewCharacter then
        openFirstCharacterAppearance()
    end
end)

network('qbx_core:client:playerLoggedOut', function()
    if native.GetInvokingResource() then return end -- Make sure this can only be triggered from the server
    chooseCharacter()
end)

listen('onResourceStop', function(resourceName)
    if resourceName ~= native.GetCurrentResourceName() then return end
    destroyPreviewCam()
end)

thread(function()
    while true do
        native.Wait(0)
        if native.NetworkIsSessionStarted() then
            pcall(function() integrations.setAutoSpawn(false) end)
            native.Wait(250)
            chooseCharacter()
            break
        end
    end
    -- since people apparently die during char select. Since SetEntityInvincible is notoriously unreliable, we'll just loop it to be safe. shrug
    while native.NetworkIsInTutorialSession() do
        native.SetEntityInvincible(native.PlayerPedId(), true)
        native.Wait(250)
    end
    native.SetEntityInvincible(native.PlayerPedId(), false)
end)


    local initialized, initializing = false, false
    function api.Initialize()
        if initialized or initializing then return false end
        initializing = true
        local ok, err = pcall(function()
            randomLocation = config.characters.locations[random(1, #config.characters.locations)]
            native.NetworkStartSoloTutorialSession()
        end)
        initializing = false
        if not ok then error(err, 0) end
        initialized = true
        return true
    end
    function api.GetFallbackLocation() return randomLocation end
    api.characterDialog = characterDialog
    api.checkStrings = checkStrings
    api.capString = capString
    api.openFirstCharacterAppearance = openFirstCharacterAppearance
    api.spawnDefault = spawnDefault
    api.spawnLastLocation = spawnLastLocation
    api.createCharacter = createCharacter
    api.chooseCharacter = chooseCharacter
    return api
end

