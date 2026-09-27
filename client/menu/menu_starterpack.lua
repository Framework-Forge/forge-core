ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local boolValue = Shared.boolValue
local boolDefault = Shared.boolDefault
local boolOptions = Shared.boolOptions

local function fetchPayload()
    local ok, payload = awaitServer(PR.Starterpack.Callbacks.getAll)
    if not ok then
        notifyFailure('notify.starterpack.load_failed', payload)
        return nil
    end

    payload = type(payload) == 'table' and payload or {}
    payload.settings = type(payload.settings) == 'table' and payload.settings or {}
    payload.items = type(payload.items) == 'table' and payload.items or {}
    payload.prologue = type(payload.prologue) == 'table' and payload.prologue or {}
    payload.prologue.stops = type(payload.prologue.stops) == 'table' and payload.prologue.stops or {}
    return payload
end

local function notifySuccess(key, data)
    Shared.notify({
        title = t('starterpack.title'),
        description = t(key, data),
        type = 'success',
    })
end

local function coordsNow()
    local coords = GetEntityCoords(PlayerPedId())
    return {
        x = tonumber(('%0.3f'):format(coords.x)),
        y = tonumber(('%0.3f'):format(coords.y)),
        z = tonumber(('%0.3f'):format(coords.z)),
    }
end

local function headingNow()
    return tonumber(('%0.2f'):format(GetEntityHeading(PlayerPedId())))
end

local function pointFromPlacement(placement)
    placement = type(placement) == 'table' and placement or {}
    local coords = type(placement.coords) == 'table' and placement.coords or placement

    return {
        coords = {
            x = tonumber(('%0.3f'):format(tonumber(coords.x or coords[1]) or 0.0)),
            y = tonumber(('%0.3f'):format(tonumber(coords.y or coords[2]) or 0.0)),
            z = tonumber(('%0.3f'):format(tonumber(coords.z or coords[3]) or 0.0)),
        },
        heading = tonumber(('%0.2f'):format(tonumber(placement.heading) or 0.0)),
    }
end

local function notifyStarterpack(key, notifyType, data)
    Shared.notify({
        title = t('starterpack.title'),
        description = t(key, data),
        type = notifyType or 'inform',
    })
end

local function countEnabledItems(items)
    local total = 0
    for _, item in ipairs(type(items) == 'table' and items or {}) do
        if item.enabled ~= false then total = total + 1 end
    end
    return total
end

function Menu.openStarterpackMenu()
    local payload = fetchPayload()
    if not payload then return end

    local settings = payload.settings
    local prologue = payload.prologue

    showContext({
        id = 'forge_core_starterpack',
        title = t('menu.starterpack.title'),
        menu = 'forge_core_server_settings',
        options = {
            {
                title = t('menu.starterpack.settings'),
                description = t('menu.starterpack.settings_description', {
                    status = settings.enabled == true and t('common.active') or t('common.inactive'),
                    auto = settings.autoGiveOnFirstJoin == true and t('common.yes') or t('common.no'),
                }),
                icon = 'sliders',
                onSelect = function()
                    Menu.openStarterpackSettings(settings)
                end,
            },
            {
                title = t('menu.starterpack.items'),
                description = t('menu.starterpack.items_description', {
                    active = tostring(countEnabledItems(payload.items)),
                    total = tostring(#payload.items),
                }),
                icon = 'gift',
                onSelect = function()
                    Menu.openStarterpackItems()
                end,
            },
            {
                title = t('menu.starterpack.prologue'),
                description = t('menu.starterpack.prologue_description', {
                    status = prologue.enabled == true and t('common.active') or t('common.inactive'),
                    stops = tostring(#prologue.stops),
                }),
                icon = 'film',
                onSelect = function()
                    Menu.openStarterpackPrologue()
                end,
            },
            {
                title = t('menu.starterpack.actions'),
                description = t('menu.starterpack.actions_description', {
                    claimed = tostring(payload.claimedCount or 0),
                }),
                icon = 'magic',
                onSelect = function()
                    Menu.openStarterpackActions()
                end,
            },
        },
    })
end

function Menu.openStarterpackSettings(settings)
    settings = type(settings) == 'table' and settings or {}

    local result = inputDialog(t('menu.starterpack.settings'), {
        {
            type = 'select',
            label = t('inputs.starterpack_enabled'),
            options = boolOptions(),
            default = boolDefault(settings.enabled == true),
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.starterpack_once'),
            options = boolOptions(),
            default = boolDefault(settings.oncePerCharacter ~= false),
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.starterpack_auto'),
            options = boolOptions(),
            default = boolDefault(settings.autoGiveOnFirstJoin == true),
            required = true,
        },
    })

    if not result then return Menu.openStarterpackMenu() end

    local ok, response = awaitServer(PR.Starterpack.Callbacks.saveSettings, {
        enabled = boolValue(result[1]),
        oncePerCharacter = boolValue(result[2]),
        autoGiveOnFirstJoin = boolValue(result[3]),
    })

    if not ok then
        notifyFailure('notify.starterpack.save_failed', response)
    end

    Menu.openStarterpackMenu()
end

function Menu.openStarterpackItems()
    local payload = fetchPayload()
    if not payload then return end

    local options = {
        {
            title = t('menu.starterpack.add_item'),
            description = t('menu.starterpack.add_item_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openStarterpackItemEditor()
            end,
        },
    }

    for _, item in ipairs(payload.items) do
        options[#options + 1] = {
            title = item.label ~= '' and item.label or item.name,
            description = t('menu.starterpack.item_description', {
                item = item.name,
                count = tostring(item.count or 1),
                status = item.enabled == false and t('common.inactive') or t('common.active'),
            }),
            icon = item.enabled == false and 'x-square-fill' or 'check-square-fill',
            onSelect = function()
                Menu.openStarterpackItem(item)
            end,
        }
    end

    showContext({
        id = 'forge_core_starterpack_items',
        title = t('menu.starterpack.items'),
        menu = 'forge_core_starterpack',
        options = options,
    })
end

function Menu.openStarterpackItem(item)
    item = type(item) == 'table' and item or {}

    showContext({
        id = 'forge_core_starterpack_item_' .. tostring(item.id or item.name),
        title = item.label ~= '' and item.label or item.name,
        menu = 'forge_core_starterpack_items',
        options = {
            {
                title = t('menu.starterpack.edit'),
                description = item.name,
                icon = 'pencil',
                onSelect = function()
                    Menu.openStarterpackItemEditor(item)
                end,
            },
            {
                title = t('menu.starterpack.remove'),
                description = t('menu.starterpack.remove_item_description'),
                icon = 'trash',
                iconColor = '#ef4444',
                onSelect = function()
                    local ok, response = awaitServer(PR.Starterpack.Callbacks.removeItem, item.id)
                    if not ok then notifyFailure('notify.starterpack.remove_failed', response) end
                    Menu.openStarterpackItems()
                end,
            },
        },
    })
end

function Menu.openStarterpackItemEditor(item)
    item = type(item) == 'table' and item or {}

    local metadataText = '{}'
    if type(item.metadata) == 'table' then
        local ok, encoded = pcall(json.encode, item.metadata)
        if ok and encoded then metadataText = encoded end
    end

    local result = inputDialog(item.id and t('menu.starterpack.edit_item') or t('menu.starterpack.add_item'), {
        {
            type = 'input',
            label = t('inputs.item_name'),
            default = item.name or '',
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.item_label'),
            default = item.label or '',
            required = false,
        },
        {
            type = 'number',
            label = t('inputs.item_count'),
            default = tonumber(item.count) or 1,
            min = 1,
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.item_enabled'),
            options = boolOptions(),
            default = boolDefault(item.enabled ~= false),
            required = true,
        },
        {
            type = 'textarea',
            label = t('inputs.item_metadata_json'),
            default = metadataText,
            required = false,
        },
    })

    if not result then return Menu.openStarterpackItems() end

    local metadata = {}
    local rawMetadata = tostring(result[5] or '')
    if rawMetadata ~= '' then
        local ok, decoded = pcall(json.decode, rawMetadata)
        if ok and type(decoded) == 'table' then metadata = decoded end
    end

    local ok, response = awaitServer(PR.Starterpack.Callbacks.setItem, {
        id = item.id,
        name = result[1],
        label = result[2],
        count = tonumber(result[3]) or 1,
        enabled = boolValue(result[4]),
        metadata = metadata,
    })

    if not ok then
        notifyFailure('notify.starterpack.item_save_failed', response)
    end

    Menu.openStarterpackItems()
end

function Menu.openStarterpackActions()
    showContext({
        id = 'forge_core_starterpack_actions',
        title = t('menu.starterpack.actions'),
        menu = 'forge_core_starterpack',
        options = {
            {
                title = t('menu.starterpack.claim_self'),
                description = t('menu.starterpack.claim_self_description'),
                icon = 'gift',
                onSelect = function()
                    local ok, response = awaitServer(PR.Starterpack.Callbacks.claim)
                    if not ok then notifyFailure('notify.starterpack.claim_failed', response) end
                    Menu.openStarterpackActions()
                end,
            },
            {
                title = t('menu.starterpack.give_player'),
                description = t('menu.starterpack.give_player_description'),
                icon = 'person-plus-fill',
                onSelect = function()
                    local result = inputDialog(t('menu.starterpack.give_player'), {
                        { type = 'number', label = t('inputs.target_source'), required = true, min = 1 },
                    })

                    if result then
                        local ok, response = awaitServer(PR.Starterpack.Callbacks.giveToPlayer, tonumber(result[1]))
                        if not ok then notifyFailure('notify.starterpack.give_failed', response) end
                    end

                    Menu.openStarterpackActions()
                end,
            },
            {
                title = t('menu.starterpack.reset_claim'),
                description = t('menu.starterpack.reset_claim_description'),
                icon = 'arrow-counterclockwise',
                onSelect = function()
                    local result = inputDialog(t('menu.starterpack.reset_claim'), {
                        { type = 'input', label = t('inputs.citizenid'), required = true },
                    })

                    if result then
                        local ok, response = awaitServer(PR.Starterpack.Callbacks.resetClaim, result[1])
                        if not ok then notifyFailure('notify.starterpack.reset_failed', response) end
                    end

                    Menu.openStarterpackActions()
                end,
            },
        },
    })
end

function Menu.openStarterpackPrologue()
    local payload = fetchPayload()
    if not payload then return end

    local prologue = payload.prologue
    local options = {
        {
            title = t('menu.starterpack.prologue_settings'),
            description = t('menu.starterpack.prologue_settings_description', {
                status = prologue.enabled == true and t('common.active') or t('common.inactive'),
                lamar = prologue.lamarModel or '',
                vehicle = prologue.vehicleModel or '',
            }),
            icon = 'sliders',
            onSelect = function()
                Menu.openStarterpackPrologueSettings(prologue)
            end,
        },
        {
            title = t('menu.starterpack.place_vehicle'),
            description = t('menu.starterpack.place_vehicle_description'),
            icon = 'car-front-fill',
            onSelect = function()
                Menu.placeStarterpackVehicle(prologue)
            end,
        },
        {
            title = t('menu.starterpack.place_lamar'),
            description = t('menu.starterpack.place_lamar_description'),
            icon = 'person-circle',
            onSelect = function()
                Menu.placeStarterpackLamar(prologue)
            end,
        },
        {
            title = t('menu.starterpack.add_stop'),
            description = t('menu.starterpack.add_stop_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openStarterpackStopEditor()
            end,
        },
    }

    for index, stop in ipairs(prologue.stops or {}) do
        options[#options + 1] = {
            title = ('[%s] %s'):format(index, stop.title),
            description = t('menu.starterpack.stop_list_description', {
                status = stop.enabled == false and t('common.inactive') or t('common.active'),
                frames = tostring(#(stop.cameraFrames or {})),
                dialogs = tostring(#(stop.routeDialogs or {})),
                rewards = tostring(#(stop.rewards or {})),
            }),
            icon = stop.enabled == false and 'geo-alt' or 'geo-alt-fill',
            onSelect = function()
                Menu.openStarterpackStop(stop)
            end,
        }
    end

    showContext({
        id = 'forge_core_starterpack_prologue',
        title = t('menu.starterpack.prologue'),
        menu = 'forge_core_starterpack',
        options = options,
    })
end

function Menu.placeStarterpackVehicle(prologue)
    prologue = type(prologue) == 'table' and prologue or {}
    if not pr_lib or not pr_lib.devtools or not pr_lib.devtools.placeVehicle then
        notifyStarterpack('notify.starterpack.devtools_unavailable', 'error')
        return Menu.openStarterpackPrologue()
    end

    local started = pr_lib.devtools.placeVehicle(prologue.vehicleModel or 'asea', 1, function(placement)
        if not placement then
            notifyStarterpack('notify.starterpack.placement_cancelled', 'inform')
            return Menu.openStarterpackPrologue()
        end

        local point = pointFromPlacement(placement)
        prologue.vehicleStart = point
        prologue.start = point

        local ok, response = awaitServer(PR.Starterpack.Callbacks.savePrologue, prologue)
        if ok then
            notifySuccess('notify.starterpack.prologue_saved')
        else
            notifyFailure('notify.starterpack.save_failed', response)
        end

        Menu.openStarterpackPrologue()
    end, {
        preview = true,
        freezePlayer = true,
        heading = type(prologue.vehicleStart) == 'table' and prologue.vehicleStart.heading or nil,
        heightOffset = 0.0,
        heightStep = 0.01,
        modelTimeout = 5000,
    })

    if started ~= true then
        notifyStarterpack('notify.starterpack.devtools_unavailable', 'error')
        Menu.openStarterpackPrologue()
    end
end

function Menu.placeStarterpackLamar(prologue)
    prologue = type(prologue) == 'table' and prologue or {}
    if not pr_lib or not pr_lib.devtools or not pr_lib.devtools.placePed then
        notifyStarterpack('notify.starterpack.devtools_unavailable', 'error')
        return Menu.openStarterpackPrologue()
    end

    local started = pr_lib.devtools.placePed(prologue.lamarModel or 'ig_lamardavis', 1, function(placement)
        if not placement then
            notifyStarterpack('notify.starterpack.placement_cancelled', 'inform')
            return Menu.openStarterpackPrologue()
        end

        prologue.lamarStart = pointFromPlacement(placement)

        local ok, response = awaitServer(PR.Starterpack.Callbacks.savePrologue, prologue)
        if ok then
            notifySuccess('notify.starterpack.prologue_saved')
        else
            notifyFailure('notify.starterpack.save_failed', response)
        end

        Menu.openStarterpackPrologue()
    end, {
        preview = true,
        freezePlayer = true,
        heading = type(prologue.lamarStart) == 'table' and prologue.lamarStart.heading or nil,
        heightOffset = 0.0,
        heightStep = 0.01,
        modelTimeout = 5000,
    })

    if started ~= true then
        notifyStarterpack('notify.starterpack.devtools_unavailable', 'error')
        Menu.openStarterpackPrologue()
    end
end

function Menu.openStarterpackPrologueSettings(prologue)
    prologue = type(prologue) == 'table' and prologue or {}

    local result = inputDialog(t('menu.starterpack.prologue_settings'), {
        {
            type = 'select',
            label = t('inputs.prologue_enabled'),
            options = boolOptions(),
            default = boolDefault(prologue.enabled == true),
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.prologue_lamar_model'),
            default = prologue.lamarModel or 'ig_lamardavis',
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.prologue_vehicle_model'),
            default = prologue.vehicleModel or 'asea',
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.prologue_autopilot_speed'),
            default = tonumber(prologue.autopilotMaxSpeed) or PR.Starterpack.Defaults.prologue.autopilotMaxSpeed,
            min = 5,
            max = 60,
            required = true,
        },
        {
            type = 'input',
            label = t('inputs.prologue_finish_behavior'),
            default = prologue.finishBehavior or 'lamar_drives_away',
            required = true,
        },
    })

    if not result then return Menu.openStarterpackPrologue() end

    prologue.enabled = boolValue(result[1])
    prologue.lamarModel = result[2]
    prologue.vehicleModel = result[3]
    prologue.autopilotMaxSpeed = tonumber(result[4]) or PR.Starterpack.Defaults.prologue.autopilotMaxSpeed
    prologue.finishBehavior = result[5]

    local ok, response = awaitServer(PR.Starterpack.Callbacks.savePrologue, prologue)
    if not ok then notifyFailure('notify.starterpack.save_failed', response) end

    Menu.openStarterpackPrologue()
end

function Menu.openStarterpackStopEditor(stop)
    stop = type(stop) == 'table' and stop or {}
    local coords = type(stop.coords) == 'table' and stop.coords or coordsNow()

    local result = inputDialog(stop.id and t('menu.starterpack.edit_stop') or t('menu.starterpack.add_stop'), {
        { type = 'input', label = t('inputs.stop_title'), default = stop.title or '', required = true },
        { type = 'select', label = t('inputs.stop_enabled'), options = boolOptions(), default = boolDefault(stop.enabled ~= false), required = true },
        { type = 'textarea', label = t('inputs.stop_route_text'), default = stop.routeText or '', required = false },
        { type = 'textarea', label = t('inputs.stop_arrival_text'), default = stop.arrivalText or '', required = false },
        { type = 'textarea', label = t('inputs.stop_next_text'), default = stop.nextText or '', required = false },
        { type = 'number', label = t('inputs.blip_sprite'), default = tonumber(stop.blipSprite) or 1, min = 1, required = true },
        { type = 'number', label = t('inputs.blip_color'), default = tonumber(stop.blipColor) or 5, min = 0, required = true },
    })

    if not result then return Menu.openStarterpackPrologue() end

    local ok, response = awaitServer(PR.Starterpack.Callbacks.setStop, {
        id = stop.id,
        title = result[1],
        enabled = boolValue(result[2]),
        routeText = result[3],
        arrivalText = result[4],
        nextText = result[5],
        blipSprite = tonumber(result[6]) or 1,
        blipColor = tonumber(result[7]) or 5,
        coords = coords,
        heading = stop.heading or headingNow(),
        routeDialogs = stop.routeDialogs or {},
        rewards = stop.rewards or {},
        cameraFrames = stop.cameraFrames or {},
    })

    if not ok then notifyFailure('notify.starterpack.stop_save_failed', response) end

    Menu.openStarterpackPrologue()
end

function Menu.openStarterpackStop(stop)
    stop = type(stop) == 'table' and stop or {}

    showContext({
        id = 'forge_core_starterpack_stop_' .. tostring(stop.id),
        title = stop.title,
        menu = 'forge_core_starterpack_prologue',
        options = {
            {
                title = t('menu.starterpack.edit'),
                description = t('menu.starterpack.stop_description', {
                    frames = tostring(#(stop.cameraFrames or {})),
                }),
                icon = 'pencil',
                onSelect = function()
                    Menu.openStarterpackStopEditor(stop)
                end,
            },
            {
                title = t('menu.starterpack.mark_stop_coords'),
                description = t('menu.starterpack.mark_stop_coords_description'),
                icon = 'geo-alt-fill',
                onSelect = function()
                    stop.coords = coordsNow()
                    stop.heading = headingNow()

                    local ok, response = awaitServer(PR.Starterpack.Callbacks.setStop, stop)
                    if not ok then notifyFailure('notify.starterpack.stop_save_failed', response) end

                    Menu.openStarterpackStop(stop)
                end,
            },
            {
                title = t('menu.starterpack.route_dialogs'),
                description = t('menu.starterpack.route_dialogs_description', {
                    count = tostring(#(stop.routeDialogs or {})),
                }),
                icon = 'chat-square-text-fill',
                onSelect = function()
                    Menu.openStarterpackStopDialogs(stop)
                end,
            },
            {
                title = t('menu.starterpack.camera_frames'),
                description = t('menu.starterpack.camera_frames_description', {
                    count = tostring(#(stop.cameraFrames or {})),
                }),
                icon = 'camera-video-fill',
                onSelect = function()
                    if pr_lib and pr_lib.menus and pr_lib.menus.HideContext then pr_lib.menus.HideContext(false) end
                    TriggerEvent(PR.Starterpack.Events.editStopKeyframes, stop)
                end,
            },
            {
                title = t('menu.starterpack.route_rewards'),
                description = t('menu.starterpack.route_rewards_description', {
                    count = tostring(#(stop.rewards or {})),
                }),
                icon = 'gift',
                onSelect = function()
                    Menu.openStarterpackStopRewards(stop)
                end,
            },
            {
                title = t('menu.starterpack.remove'),
                description = t('menu.starterpack.remove_stop_description'),
                icon = 'trash',
                iconColor = '#ef4444',
                onSelect = function()
                    local ok, response = awaitServer(PR.Starterpack.Callbacks.removeStop, stop.id)
                    if not ok then notifyFailure('notify.starterpack.remove_failed', response) end

                    Menu.openStarterpackPrologue()
                end,
            },
        },
    })
end

function Menu.openStarterpackStopRewards(stop)
    stop = type(stop) == 'table' and stop or {}
    stop.rewards = type(stop.rewards) == 'table' and stop.rewards or {}

    local options = {
        {
            title = t('menu.starterpack.add_reward'),
            description = t('menu.starterpack.add_reward_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openStarterpackRewardEditor(stop)
            end,
        },
    }

    for index, reward in ipairs(stop.rewards) do
        options[#options + 1] = {
            title = t('menu.starterpack.reward_title', {
                index = tostring(index),
                progress = tostring(reward.progress or 0),
            }),
            description = t('menu.starterpack.reward_description', {
                item = reward.item or '',
                count = tostring(reward.count or 1),
            }),
            icon = reward.enabled == false and 'gift' or 'gift-fill',
            onSelect = function()
                Menu.openStarterpackReward(stop, index)
            end,
        }
    end

    showContext({
        id = 'forge_core_starterpack_stop_rewards_' .. tostring(stop.id),
        title = t('menu.starterpack.route_rewards'),
        menu = 'forge_core_starterpack_stop_' .. tostring(stop.id),
        options = options,
    })
end

function Menu.openStarterpackReward(stop, rewardIndex)
    stop = type(stop) == 'table' and stop or {}
    local reward = type(stop.rewards) == 'table' and stop.rewards[rewardIndex] or nil
    if not reward then return Menu.openStarterpackStopRewards(stop) end

    showContext({
        id = 'forge_core_starterpack_reward_' .. tostring(stop.id) .. '_' .. tostring(rewardIndex),
        title = t('menu.starterpack.reward_title', {
            index = tostring(rewardIndex),
            progress = tostring(reward.progress or 0),
        }),
        menu = 'forge_core_starterpack_stop_rewards_' .. tostring(stop.id),
        options = {
            {
                title = t('menu.starterpack.edit'),
                description = reward.item or '',
                icon = 'pencil',
                onSelect = function()
                    Menu.openStarterpackRewardEditor(stop, rewardIndex)
                end,
            },
            {
                title = t('menu.starterpack.remove'),
                description = t('menu.starterpack.remove_reward_description'),
                icon = 'trash',
                iconColor = '#ef4444',
                onSelect = function()
                    table.remove(stop.rewards, rewardIndex)
                    local ok, response = awaitServer(PR.Starterpack.Callbacks.setStop, stop)
                    if not ok then notifyFailure('notify.starterpack.stop_save_failed', response) end
                    Menu.openStarterpackStopRewards(stop)
                end,
            },
        },
    })
end

function Menu.openStarterpackRewardEditor(stop, rewardIndex)
    stop = type(stop) == 'table' and stop or {}
    stop.rewards = type(stop.rewards) == 'table' and stop.rewards or {}

    local reward = rewardIndex and stop.rewards[rewardIndex] or {}
    reward = type(reward) == 'table' and reward or {}

    local result = inputDialog(rewardIndex and t('menu.starterpack.edit_reward') or t('menu.starterpack.add_reward'), {
        {
            type = 'input',
            label = t('inputs.reward_item'),
            default = reward.item or '',
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.reward_count'),
            default = tonumber(reward.count) or 1,
            min = 1,
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.reward_progress'),
            default = tonumber(reward.progress) or 0,
            min = 0,
            max = 100,
            required = true,
        },
        {
            type = 'textarea',
            label = t('inputs.reward_dialogue'),
            default = reward.dialogue or '',
            required = false,
        },
        {
            type = 'number',
            label = t('inputs.reward_duration'),
            default = tonumber(reward.duration) or 5000,
            min = 1000,
            max = 30000,
            required = true,
        },
        {
            type = 'select',
            label = t('inputs.reward_enabled'),
            options = boolOptions(),
            default = boolDefault(reward.enabled ~= false),
            required = true,
        },
    })

    if not result then return Menu.openStarterpackStopRewards(stop) end

    local updated = {
        id = reward.id,
        item = result[1],
        count = tonumber(result[2]) or 1,
        progress = tonumber(result[3]) or 0,
        dialogue = result[4],
        duration = tonumber(result[5]) or 5000,
        enabled = boolValue(result[6]),
        metadata = reward.metadata or {},
    }

    if rewardIndex then
        stop.rewards[rewardIndex] = updated
    else
        stop.rewards[#stop.rewards + 1] = updated
    end

    local ok, response = awaitServer(PR.Starterpack.Callbacks.setStop, stop)
    if not ok then notifyFailure('notify.starterpack.stop_save_failed', response) end
    Menu.openStarterpackStopRewards(stop)
end

function Menu.openStarterpackStopDialogs(stop)
    stop = type(stop) == 'table' and stop or {}
    stop.routeDialogs = type(stop.routeDialogs) == 'table' and stop.routeDialogs or {}

    local options = {
        {
            title = t('menu.starterpack.add_dialog'),
            description = t('menu.starterpack.add_dialog_description'),
            icon = 'plus',
            onSelect = function()
                Menu.openStarterpackDialogEditor(stop)
            end,
        },
    }

    for index, dialog in ipairs(stop.routeDialogs) do
        options[#options + 1] = {
            title = t('menu.starterpack.dialog_title', {
                index = tostring(index),
                progress = tostring(dialog.progress or 0),
            }),
            description = dialog.text or '',
            icon = 'chat-square-fill',
            onSelect = function()
                Menu.openStarterpackDialog(stop, index)
            end,
        }
    end

    showContext({
        id = 'forge_core_starterpack_stop_dialogs_' .. tostring(stop.id),
        title = t('menu.starterpack.route_dialogs'),
        menu = 'forge_core_starterpack_stop_' .. tostring(stop.id),
        options = options,
    })
end

function Menu.openStarterpackDialog(stop, dialogIndex)
    stop = type(stop) == 'table' and stop or {}
    local dialog = type(stop.routeDialogs) == 'table' and stop.routeDialogs[dialogIndex] or nil
    if not dialog then return Menu.openStarterpackStopDialogs(stop) end

    showContext({
        id = 'forge_core_starterpack_dialog_' .. tostring(stop.id) .. '_' .. tostring(dialogIndex),
        title = t('menu.starterpack.dialog_title', {
            index = tostring(dialogIndex),
            progress = tostring(dialog.progress or 0),
        }),
        menu = 'forge_core_starterpack_stop_dialogs_' .. tostring(stop.id),
        options = {
            {
                title = t('menu.starterpack.edit'),
                description = dialog.text or '',
                icon = 'pencil',
                onSelect = function()
                    Menu.openStarterpackDialogEditor(stop, dialogIndex)
                end,
            },
            {
                title = t('menu.starterpack.remove'),
                description = t('menu.starterpack.remove_dialog_description'),
                icon = 'trash',
                iconColor = '#ef4444',
                onSelect = function()
                    table.remove(stop.routeDialogs, dialogIndex)

                    local ok, response = awaitServer(PR.Starterpack.Callbacks.setStop, stop)
                    if not ok then notifyFailure('notify.starterpack.stop_save_failed', response) end

                    Menu.openStarterpackStopDialogs(stop)
                end,
            },
        },
    })
end

function Menu.openStarterpackDialogEditor(stop, dialogIndex)
    stop = type(stop) == 'table' and stop or {}
    stop.routeDialogs = type(stop.routeDialogs) == 'table' and stop.routeDialogs or {}

    local dialog = dialogIndex and stop.routeDialogs[dialogIndex] or {}
    dialog = type(dialog) == 'table' and dialog or {}

    local result = inputDialog(dialogIndex and t('menu.starterpack.edit_dialog') or t('menu.starterpack.add_dialog'), {
        {
            type = 'number',
            label = t('inputs.dialog_progress'),
            default = tonumber(dialog.progress) or 0,
            min = 0,
            max = 100,
            required = true,
        },
        {
            type = 'textarea',
            label = t('inputs.dialog_text'),
            default = dialog.text or '',
            required = true,
        },
        {
            type = 'number',
            label = t('inputs.dialog_duration'),
            default = tonumber(dialog.duration) or 5000,
            min = 1000,
            max = 30000,
            required = true,
        },
    })

    if not result then return Menu.openStarterpackStopDialogs(stop) end

    local updated = {
        id = dialog.id,
        progress = tonumber(result[1]) or 0,
        text = result[2],
        duration = tonumber(result[3]) or 5000,
    }

    if dialogIndex then
        stop.routeDialogs[dialogIndex] = updated
    else
        stop.routeDialogs[#stop.routeDialogs + 1] = updated
    end

    local ok, response = awaitServer(PR.Starterpack.Callbacks.setStop, stop)
    if not ok then notifyFailure('notify.starterpack.stop_save_failed', response) end

    Menu.openStarterpackStopDialogs(stop)
end
