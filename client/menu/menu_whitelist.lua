ForgeCore = ForgeCore or {}
ForgeCore.Client = ForgeCore.Client or {}

local Menu = ForgeCore.Client.Menu
local Shared = ForgeCore.Client.MenuShared

local t = Shared.t
local showContext = Shared.showContext
local inputDialog = Shared.inputDialog
local alertDialog = Shared.alertDialog
local awaitServer = Shared.awaitServer
local notifyFailure = Shared.notifyFailure
local clone = Shared.clone
local boolLabel = Shared.boolLabel
local boolDefault = Shared.boolDefault
local boolValue = Shared.boolValue
local boolOptions = Shared.boolOptions

local whitelistActionLocked = false
local whitelistDevLaserActive = false
local saveWhitelistConfig

local function currentPoint()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    return {
        x = tonumber(('%0.3f'):format(coords.x)),
        y = tonumber(('%0.3f'):format(coords.y)),
        z = tonumber(('%0.3f'):format(coords.z)),
        w = tonumber(('%0.2f'):format(GetEntityHeading(ped))),
    }
end

local function normalizePoint(coords, heading)
    if not coords or coords.x == nil or coords.y == nil or coords.z == nil then return nil end

    return {
        x = tonumber(('%0.3f'):format(tonumber(coords.x) or 0.0)),
        y = tonumber(('%0.3f'):format(tonumber(coords.y) or 0.0)),
        z = tonumber(('%0.3f'):format(tonumber(coords.z) or 0.0)),
        w = tonumber(('%0.2f'):format(tonumber(heading or coords.w or coords.heading) or GetEntityHeading(PlayerPedId()))),
    }
end

local function formatCoords(coords)
    coords = type(coords) == 'table' and coords or {}
    return ('%.2f, %.2f, %.2f'):format(tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0)
end

local function teleportToPoint(coords)
    coords = type(coords) == 'table' and coords or {}
    local ped = PlayerPedId()
    local x = tonumber(coords.x) or 0.0
    local y = tonumber(coords.y) or 0.0
    local z = tonumber(coords.z) or 0.0
    local w = tonumber(coords.w or coords.heading) or GetEntityHeading(ped)

    DoScreenFadeOut(350)
    Wait(400)
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoords(ped, x, y, z, false, false, false, false)
    SetEntityHeading(ped, w)
    FreezeEntityPosition(ped, false)
    Wait(250)
    DoScreenFadeIn(450)
end

local function showDevLaserText()
    if pr_lib and pr_lib.framework and pr_lib.framework.ShowTextUI then
        pr_lib.framework.ShowTextUI(t('menu.whitelist.devlaser_instructions'))
    end
end

local function hideDevLaserText()
    if pr_lib and pr_lib.framework and pr_lib.framework.HideTextUI then
        pr_lib.framework.HideTextUI()
    end
end

local function capturePointWithDevLaser(onCapture, onCancel)
    local devlaser = pr_lib and (pr_lib.devlaser or pr_lib.devLaser or (pr_lib.fivem and (pr_lib.fivem.devlaser or pr_lib.fivem.devLaser)))
    if not devlaser or not devlaser.start or not devlaser.getTarget then
        notifyFailure('notify.whitelist.devlaser_failed', 'devlaser_unavailable')
        if onCancel then onCancel() end
        return false
    end

    if whitelistDevLaserActive then return false end
    whitelistDevLaserActive = true

    showDevLaserText()

    devlaser.start({
        distance = 1000.0,
        flags = -1,
        onStop = function()
            if not whitelistDevLaserActive then return end

            whitelistDevLaserActive = false
            hideDevLaserText()
            if onCancel then onCancel() end
        end,
    })

    CreateThread(function()
        while whitelistDevLaserActive and devlaser.isActive and devlaser.isActive() do
            Wait(0)

            if IsControlJustReleased(0, 201) or IsDisabledControlJustReleased(0, 201) then
                local target = devlaser.getTarget()
                local point = target and normalizePoint(target.coords)

                if point then
                    whitelistDevLaserActive = false
                    hideDevLaserText()
                    devlaser.stop(true)
                    if onCapture then onCapture(point) end
                else
                    notifyFailure('notify.whitelist.devlaser_failed', 'target_not_found')
                end
            elseif IsControlJustReleased(0, 177) or IsDisabledControlJustReleased(0, 177) or IsControlJustReleased(0, 202) or IsDisabledControlJustReleased(0, 202) then
                whitelistDevLaserActive = false
                hideDevLaserText()
                devlaser.stop(true)
                if onCancel then onCancel() end
            end
        end

        if whitelistDevLaserActive then
            whitelistDevLaserActive = false
            hideDevLaserText()
            if onCancel then onCancel() end
        end
    end)

    return true
end

local function openPointCaptureMethod(title, description, onCapture, onCancel, parentMenu)
    showContext({
        id = 'forge_core_whitelist_capture_method',
        title = title,
        description = description,
        menu = parentMenu or 'forge_core_whitelist_locations',
        options = {
            {
                title = t('menu.whitelist.capture_current'),
                description = t('menu.whitelist.capture_current_description'),
                icon = 'geo-alt-fill',
                onSelect = function()
                    if onCapture then onCapture(currentPoint()) end
                end,
            },
            {
                title = t('menu.whitelist.capture_devlaser'),
                description = t('menu.whitelist.capture_devlaser_description'),
                icon = 'crosshair',
                onSelect = function()
                    capturePointWithDevLaser(onCapture, onCancel)
                end,
            },
        },
    })
end

local function markConfigPoint(config, title, description, applyPoint, reopen, parentMenu)
    reopen = reopen or function() Menu.openWhitelistLocations(config) end

    openPointCaptureMethod(title, description, function(point)
        applyPoint(point)
        saveWhitelistConfig(config, reopen)
    end, function()
        reopen()
    end, parentMenu)
end

local function modeOptions()
    return {
        { value = 'drawtext', label = t('menu.whitelist.mode_drawtext') },
        { value = 'target', label = t('menu.whitelist.mode_target') },
        { value = 'both', label = t('menu.whitelist.mode_both') },
    }
end

local function fetchWhitelistConfig()
    local ok, payload = awaitServer(PR.Whitelist.Callbacks.getConfig)
    if not ok then
        notifyFailure('notify.whitelist.load_failed', payload)
        return nil
    end

    if type(payload) ~= 'table' then
        notifyFailure('notify.whitelist.load_failed', 'json_config_missing')
        return nil
    end

    return payload
end

saveWhitelistConfig = function(config, reopen)
    if whitelistActionLocked then return false end
    whitelistActionLocked = true

    local ok, response = awaitServer(PR.Whitelist.Callbacks.saveConfig, config)
    if not ok then
        notifyFailure('notify.whitelist.save_failed', response)
    end

    SetTimeout(500, function()
        if reopen then reopen() end
    end)

    SetTimeout(1000, function()
        whitelistActionLocked = false
    end)

    return ok
end

local function runWhitelistAction(callbackName, failureLocale, ...)
    if whitelistActionLocked then return false end
    whitelistActionLocked = true

    local ok, response = awaitServer(callbackName, ...)
    if not ok then
        notifyFailure(failureLocale or 'notify.whitelist.action_failed', response)
    end

    SetTimeout(1000, function()
        whitelistActionLocked = false
    end)

    return ok, response
end

function Menu.openWhitelistMenu()
    local config = fetchWhitelistConfig()
    if not config then return false end

    showContext({
        id = 'forge_core_whitelist',
        title = t('menu.whitelist.title'),
        menu = 'forge_core_server_settings',
        options = {
            {
                title = t('menu.whitelist.settings'),
                description = t('menu.whitelist.settings_summary', {
                    status = config.enabled and t('common.active') or t('common.inactive'),
                    percent = tostring(config.percent or 70),
                }),
                icon = 'gear-fill',
                onSelect = function()
                    Menu.openWhitelistSettingsEditor(config)
                end,
            },
            {
                title = t('menu.whitelist.questions'),
                description = t('menu.whitelist.questions_summary', { count = tostring(#(config.questions or {})) }),
                icon = 'clipboard2-check-fill',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistQuestions(config)
                end,
            },
            {
                title = t('menu.whitelist.locations'),
                description = t('menu.whitelist.locations_description'),
                icon = 'pin-map-fill',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistLocations(config)
                end,
            },
            {
                title = t('menu.whitelist.players'),
                description = t('menu.whitelist.players_description'),
                icon = 'people-fill',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistPlayers()
                end,
            },
            {
                title = t('menu.whitelist.add_player'),
                description = t('menu.whitelist.add_player_description'),
                icon = 'person-plus-fill',
                onSelect = function()
                    Menu.openWhitelistPlayerAction('add')
                end,
            },
            {
                title = t('menu.whitelist.remove_player'),
                description = t('menu.whitelist.remove_player_description'),
                icon = 'person-dash-fill',
                iconColor = 'red',
                onSelect = function()
                    Menu.openWhitelistPlayerAction('remove')
                end,
            },
        },
    })

    return true
end

function Menu.openWhitelistPlayers()
    local ok, payload = awaitServer(PR.Whitelist.Callbacks.listPlayers)
    if not ok then
        notifyFailure('notify.whitelist.load_failed', payload)
        return Menu.openWhitelistMenu()
    end

    payload = type(payload) == 'table' and payload or {}
    local players = type(payload.players) == 'table' and payload.players or {}
    local options = {}

    for _, player in ipairs(players) do
        local status = player.whitelisted and t('menu.whitelist.has_whitelist') or t('menu.whitelist.no_whitelist')
        local source = player.online and tostring(player.source) or t('common.offline')

        options[#options + 1] = {
            title = player.name or player.citizenid,
            description = t('menu.whitelist.player_status', {
                status = status,
                source = source,
                citizenid = tostring(player.citizenid or ''),
            }),
            icon = player.whitelisted and 'person-check-fill' or 'person-x-fill',
            iconColor = player.whitelisted and 'green' or 'red',
            arrow = true,
            onSelect = function()
                Menu.openWhitelistPlayerDetails(player)
            end,
        }
    end

    if #options == 0 then
        options[#options + 1] = {
            title = t('menu.whitelist.no_players'),
            icon = 'info-circle-fill',
            disabled = true,
        }
    end

    showContext({
        id = 'forge_core_whitelist_players',
        title = t('menu.whitelist.players'),
        description = t('menu.whitelist.players_summary', {
            whitelisted = tostring(payload.whitelisted or 0),
            pending = tostring(payload.pending or 0),
        }),
        menu = 'forge_core_whitelist',
        options = options,
    })
end

function Menu.openWhitelistPlayerDetails(player)
    local identifier = player.source or player.citizenid
    local options = {}

    if player.whitelisted then
        options[#options + 1] = {
            title = t('menu.whitelist.remove_player'),
            description = t('menu.whitelist.remove_player_description'),
            icon = 'person-dash-fill',
            iconColor = 'red',
            onSelect = function()
                local ok = runWhitelistAction(PR.Whitelist.Callbacks.remove, 'notify.whitelist.remove_failed', identifier)
                SetTimeout(500, function()
                    if ok then Menu.openWhitelistPlayers() else Menu.openWhitelistPlayerDetails(player) end
                end)
            end,
        }
    else
        options[#options + 1] = {
            title = t('menu.whitelist.add_player'),
            description = t('menu.whitelist.add_player_description'),
            icon = 'person-plus-fill',
            iconColor = 'green',
            onSelect = function()
                local ok = runWhitelistAction(PR.Whitelist.Callbacks.add, 'notify.whitelist.add_failed', identifier)
                SetTimeout(500, function()
                    if ok then Menu.openWhitelistPlayers() else Menu.openWhitelistPlayerDetails(player) end
                end)
            end,
        }
    end

    options[#options + 1] = {
        title = t('menu.whitelist.ban_player'),
        description = t('menu.whitelist.ban_player_description'),
        icon = 'ban',
        iconColor = 'red',
        onSelect = function()
            Menu.openWhitelistBanDialog(player)
        end,
    }

    showContext({
        id = 'forge_core_whitelist_player_' .. tostring(player.citizenid),
        title = player.name or player.citizenid,
        description = t('menu.whitelist.player_status', {
            status = player.whitelisted and t('menu.whitelist.has_whitelist') or t('menu.whitelist.no_whitelist'),
            source = player.online and tostring(player.source) or t('common.offline'),
            citizenid = tostring(player.citizenid or ''),
        }),
        menu = 'forge_core_whitelist_players',
        options = options,
    })
end

function Menu.openWhitelistBanDialog(player)
    local result = inputDialog(t('menu.whitelist.ban_player'), {
        { type = 'input', label = t('inputs.ban_reason'), default = t('menu.whitelist.default_ban_reason'), required = true },
        { type = 'number', label = t('inputs.ban_hours'), default = 0, min = 0 },
        { type = 'number', label = t('inputs.ban_days'), default = 0, min = 0 },
        { type = 'number', label = t('inputs.ban_months'), default = 0, min = 0 },
    })

    if not result then return Menu.openWhitelistPlayerDetails(player) end

    local ok = runWhitelistAction(PR.Whitelist.Callbacks.ban, 'notify.whitelist.ban_failed', {
        identifier = player.source or player.citizenid,
        reason = result[1],
        hours = tonumber(result[2]) or 0,
        days = tonumber(result[3]) or 0,
        months = tonumber(result[4]) or 0,
    })

    SetTimeout(500, function()
        if ok then Menu.openWhitelistPlayers() else Menu.openWhitelistPlayerDetails(player) end
    end)
end

function Menu.openWhitelistSettingsEditor(config)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if not config then return false end

    local result = inputDialog(t('menu.whitelist.settings'), {
        { type = 'select', label = t('inputs.whitelist_enabled'), options = boolOptions(), default = boolDefault(config.enabled), required = true },
        { type = 'number', label = t('inputs.whitelist_percent'), default = tonumber(config.percent) or 70, min = 0, max = 100, required = true },
        { type = 'select', label = t('inputs.whitelist_interaction_mode'), options = modeOptions(), default = config.interactionMode or 'drawtext', required = true },
        { type = 'select', label = t('inputs.whitelist_marker_enabled'), options = boolOptions(), default = boolDefault(config.markerEnabled ~= false), required = true },
        { type = 'select', label = t('inputs.whitelist_blip_enabled'), options = boolOptions(), default = boolDefault(type(config.blip) == 'table' and config.blip.enabled == true), required = true },
        { type = 'input', label = t('inputs.whitelist_load_notify'), default = config.loadNotify, required = true },
        { type = 'input', label = t('inputs.whitelist_escape_notify'), default = config.escapeNotify, required = true },
        { type = 'input', label = t('inputs.whitelist_start_label'), default = config.startExamLabel, required = true },
    })

    if not result then return Menu.openWhitelistMenu() end

    config.enabled = boolValue(result[1])
    config.percent = tonumber(result[2]) or 70
    config.interactionMode = tostring(result[3] or 'drawtext')
    config.targetEnabled = config.interactionMode == 'target' or config.interactionMode == 'both'
    config.markerEnabled = boolValue(result[4])
    config.blip = type(config.blip) == 'table' and config.blip or clone(PR.Whitelist.Defaults.blip or {})
    config.blip.enabled = boolValue(result[5])
    config.loadNotify = result[6]
    config.escapeNotify = result[7]
    config.startExamLabel = result[8]
    config.blip.label = config.blip.label or config.startExamLabel

    saveWhitelistConfig(config, function()
        Menu.openWhitelistMenu()
    end)
end

function Menu.openWhitelistLocationPoint(config, pointType)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if not config then return false end

    local points = {
        spawn = {
            id = 'forge_core_whitelist_location_spawn',
            title = t('menu.whitelist.location_spawn'),
            coords = config.spawnCoords,
            markTitle = t('menu.whitelist.mark_spawn'),
            markDescription = t('menu.whitelist.mark_spawn_description'),
            teleportTitle = t('menu.whitelist.teleport_spawn'),
            icon = 'geo-alt-fill',
            apply = function(point) config.spawnCoords = point end,
        },
        exam = {
            id = 'forge_core_whitelist_location_exam',
            title = t('menu.whitelist.location_exam'),
            coords = config.examCoords,
            markTitle = t('menu.whitelist.mark_exam'),
            markDescription = t('menu.whitelist.mark_exam_description'),
            teleportTitle = t('menu.whitelist.teleport_exam'),
            icon = 'clipboard2-check-fill',
            apply = function(point) config.examCoords = point end,
        },
        completion = {
            id = 'forge_core_whitelist_location_completion',
            title = t('menu.whitelist.location_completion'),
            coords = config.completionCoords,
            markTitle = t('menu.whitelist.mark_completion'),
            markDescription = t('menu.whitelist.mark_completion_description'),
            teleportTitle = t('menu.whitelist.teleport_completion'),
            icon = 'flag-fill',
            apply = function(point) config.completionCoords = point end,
        },
    }

    local point = points[pointType]
    if not point then return Menu.openWhitelistLocations(config) end

    local reopen = function()
        Menu.openWhitelistLocationPoint(config, pointType)
    end

    showContext({
        id = point.id,
        title = point.title,
        menu = 'forge_core_whitelist_locations',
        options = {
            {
                title = point.markTitle,
                description = point.markDescription,
                icon = point.icon,
                onSelect = function()
                    markConfigPoint(config, point.markTitle, point.markDescription, point.apply, reopen, point.id)
                end,
            },
            {
                title = point.teleportTitle,
                description = t('menu.whitelist.teleport_description', { coords = formatCoords(point.coords) }),
                icon = 'airplane-engines-fill',
                onSelect = function()
                    teleportToPoint(point.coords)
                    reopen()
                end,
            },
        },
    })
end

function Menu.openWhitelistZoneMenu(config)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if not config then return false end

    local zone = type(config.citizenZone) == 'table' and config.citizenZone or {}
    local zoneMenuId = 'forge_core_whitelist_location_zone'
    local reopen = function()
        Menu.openWhitelistZoneMenu(config)
    end

    showContext({
        id = zoneMenuId,
        title = t('menu.whitelist.location_zone'),
        menu = 'forge_core_whitelist_locations',
        options = {
            {
                title = t('menu.whitelist.mark_zone_center'),
                description = t('menu.whitelist.mark_zone_center_description'),
                icon = 'bounding-box',
                onSelect = function()
                    markConfigPoint(config, t('menu.whitelist.mark_zone_center'), t('menu.whitelist.mark_zone_center_description'), function(point)
                        config.citizenZone = type(config.citizenZone) == 'table' and config.citizenZone or clone(PR.Whitelist.Defaults.citizenZone or {})
                        config.citizenZone.coords = { x = point.x, y = point.y, z = point.z }
                    end, reopen, zoneMenuId)
                end,
            },
            {
                title = t('menu.whitelist.edit_zone'),
                description = t('menu.whitelist.edit_zone_description'),
                icon = 'box',
                onSelect = function()
                    Menu.openWhitelistZoneEditor(config)
                end,
            },
            {
                title = t('menu.whitelist.teleport_zone'),
                description = t('menu.whitelist.teleport_description', { coords = formatCoords(zone.coords) }),
                icon = 'airplane-engines-fill',
                onSelect = function()
                    teleportToPoint(zone.coords)
                    reopen()
                end,
            },
        },
    })
end

function Menu.openWhitelistLocations(config)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if not config then return false end

    showContext({
        id = 'forge_core_whitelist_locations',
        title = t('menu.whitelist.locations'),
        menu = 'forge_core_whitelist',
        options = {
            {
                title = t('menu.whitelist.location_spawn'),
                description = t('menu.whitelist.location_description', { coords = formatCoords(config.spawnCoords) }),
                icon = 'geo-alt-fill',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistLocationPoint(config, 'spawn')
                end,
            },
            {
                title = t('menu.whitelist.location_exam'),
                description = t('menu.whitelist.location_description', { coords = formatCoords(config.examCoords) }),
                icon = 'clipboard2-check-fill',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistLocationPoint(config, 'exam')
                end,
            },
            {
                title = t('menu.whitelist.location_completion'),
                description = t('menu.whitelist.location_description', { coords = formatCoords(config.completionCoords) }),
                icon = 'flag-fill',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistLocationPoint(config, 'completion')
                end,
            },
            {
                title = t('menu.whitelist.location_zone'),
                description = t('menu.whitelist.location_description', { coords = formatCoords(type(config.citizenZone) == 'table' and config.citizenZone.coords or nil) }),
                icon = 'bounding-box',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistZoneMenu(config)
                end,
            },
            {
                title = t('menu.whitelist.edit_blip'),
                description = t('menu.whitelist.edit_blip_description'),
                icon = 'map',
                onSelect = function()
                    Menu.openWhitelistBlipEditor(config)
                end,
            },
        },
    })
end

function Menu.openWhitelistZoneEditor(config)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if not config then return false end

    local zone = type(config.citizenZone) == 'table' and config.citizenZone or clone(PR.Whitelist.Defaults.citizenZone or {})
    local coords = type(zone.coords) == 'table' and zone.coords or {}
    local size = type(zone.size) == 'table' and zone.size or {}

    local result = inputDialog(t('menu.whitelist.edit_zone'), {
        { type = 'number', label = 'X', default = tonumber(coords.x) or 0.0, required = true },
        { type = 'number', label = 'Y', default = tonumber(coords.y) or 0.0, required = true },
        { type = 'number', label = 'Z', default = tonumber(coords.z) or 0.0, required = true },
        { type = 'number', label = t('inputs.whitelist_zone_size_x'), default = tonumber(size.x) or 28.0, min = 1, required = true },
        { type = 'number', label = t('inputs.whitelist_zone_size_y'), default = tonumber(size.y) or 22.0, min = 1, required = true },
        { type = 'number', label = t('inputs.whitelist_zone_size_z'), default = tonumber(size.z) or 6.0, min = 1, required = true },
    })

    if not result then return Menu.openWhitelistZoneMenu(config) end

    config.citizenZone = {
        coords = { x = tonumber(result[1]) or 0.0, y = tonumber(result[2]) or 0.0, z = tonumber(result[3]) or 0.0 },
        size = { x = tonumber(result[4]) or 28.0, y = tonumber(result[5]) or 22.0, z = tonumber(result[6]) or 6.0 },
    }

    saveWhitelistConfig(config, function() Menu.openWhitelistZoneMenu(config) end)
end

function Menu.openWhitelistBlipEditor(config)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if not config then return false end

    local blip = type(config.blip) == 'table' and config.blip or clone(PR.Whitelist.Defaults.blip or {})
    local result = inputDialog(t('menu.whitelist.edit_blip'), {
        { type = 'select', label = t('inputs.whitelist_blip_enabled'), options = boolOptions(), default = boolDefault(blip.enabled == true), required = true },
        { type = 'number', label = t('inputs.blip_sprite'), default = tonumber(blip.sprite) or 525, min = 1, required = true },
        { type = 'number', label = t('inputs.blip_color'), default = tonumber(blip.color) or 3, min = 0, required = true },
        { type = 'number', label = t('inputs.blip_scale'), default = tonumber(blip.scale) or 0.8, min = 0.1, required = true },
        { type = 'input', label = t('inputs.blip_label'), default = blip.label or config.startExamLabel or '', required = true },
    })

    if not result then return Menu.openWhitelistLocations(config) end

    config.blip = {
        enabled = boolValue(result[1]),
        sprite = tonumber(result[2]) or 525,
        color = tonumber(result[3]) or 3,
        scale = tonumber(result[4]) or 0.8,
        label = tostring(result[5] or ''),
    }

    saveWhitelistConfig(config, function() Menu.openWhitelistLocations(config) end)
end

function Menu.openWhitelistPlayerAction(action)
    local result = inputDialog(action == 'add' and t('menu.whitelist.add_player') or t('menu.whitelist.remove_player'), {
        {
            type = 'input',
            label = t('inputs.whitelist_identifier'),
            description = t('inputs.whitelist_identifier_description'),
            required = true,
        },
    })

    if not result then return Menu.openWhitelistMenu() end

    local identifier = result[1]
    if tonumber(identifier) then identifier = tonumber(identifier) end

    local callback = action == 'add' and PR.Whitelist.Callbacks.add or PR.Whitelist.Callbacks.remove
    local failure = action == 'add' and 'notify.whitelist.add_failed' or 'notify.whitelist.remove_failed'

    runWhitelistAction(callback, failure, identifier)

    SetTimeout(500, function()
        Menu.openWhitelistMenu()
    end)
end

function Menu.openWhitelistQuestions(config)
    config = type(config) == 'table' and config or fetchWhitelistConfig()
    if not config then return false end

    local options = {
        {
            title = t('menu.whitelist.create_question'),
            icon = 'plus',
            onSelect = function()
                Menu.openWhitelistQuestionEditor(config, nil)
            end,
        },
    }

    for index, question in ipairs(config.questions or {}) do
        options[#options + 1] = {
            title = question.question,
            description = t('menu.whitelist.question_summary', {
                index = tostring(index),
                options = tostring(#(question.options or {})),
            }),
            icon = 'clipboard2-check-fill',
            arrow = true,
            onSelect = function()
                Menu.openWhitelistQuestionDetails(config, index)
            end,
        }
    end

    showContext({
        id = 'forge_core_whitelist_questions',
        title = t('menu.whitelist.questions'),
        menu = 'forge_core_whitelist',
        options = options,
    })
end

function Menu.openWhitelistQuestionDetails(config, index)
    local question = config.questions[index]
    if not question then return Menu.openWhitelistQuestions(config) end

    showContext({
        id = 'forge_core_whitelist_question_' .. tostring(index),
        title = question.question,
        menu = 'forge_core_whitelist_questions',
        options = {
            {
                title = t('menu.actions.edit'),
                icon = 'pen',
                onSelect = function()
                    Menu.openWhitelistQuestionEditor(config, index)
                end,
            },
            {
                title = t('menu.whitelist.options'),
                description = t('menu.whitelist.options_summary', { count = tostring(#(question.options or {})) }),
                icon = 'list',
                arrow = true,
                onSelect = function()
                    Menu.openWhitelistOptions(config, index)
                end,
            },
            {
                title = t('menu.actions.remove'),
                icon = 'trash',
                iconColor = 'red',
                onSelect = function()
                    local confirmed = alertDialog({
                        header = t('dialogs.remove_whitelist_question_header'),
                        content = t('dialogs.remove_whitelist_question_content'),
                        centered = true,
                        cancel = true,
                    })

                    if confirmed == 'confirm' then
                        table.remove(config.questions, index)
                        saveWhitelistConfig(config, function()
                            Menu.openWhitelistQuestions(config)
                        end)
                    end
                end,
            },
        },
    })
end

function Menu.openWhitelistQuestionEditor(config, index)
    local question = index and config.questions[index] or { question = '', options = {} }
    local result = inputDialog(index and t('dialogs.edit_whitelist_question') or t('menu.whitelist.create_question'), {
        {
            type = 'input',
            label = t('inputs.whitelist_question'),
            default = question.question,
            required = true,
            min = 3,
        },
    })

    if not result then return index and Menu.openWhitelistQuestionDetails(config, index) or Menu.openWhitelistQuestions(config) end

    question.question = result[1]
    question.options = question.options or {}

    if index then
        config.questions[index] = question
    else
        config.questions[#config.questions + 1] = question
    end

    saveWhitelistConfig(config, function()
        Menu.openWhitelistQuestions(config)
    end)
end

function Menu.openWhitelistOptions(config, questionIndex)
    local question = config.questions[questionIndex]
    if not question then return Menu.openWhitelistQuestions(config) end

    local options = {
        {
            title = t('menu.whitelist.create_option'),
            icon = 'plus',
            onSelect = function()
                Menu.openWhitelistOptionEditor(config, questionIndex, nil)
            end,
        },
    }

    for index, option in ipairs(question.options or {}) do
        options[#options + 1] = {
            title = option.label,
            description = t('menu.whitelist.option_summary', { correct = boolLabel(option.value == true) }),
            icon = option.value == true and 'check-circle-fill' or 'x-circle-fill',
            iconColor = option.value == true and 'green' or 'red',
            onSelect = function()
                Menu.openWhitelistOptionEditor(config, questionIndex, index)
            end,
        }
    end

    showContext({
        id = 'forge_core_whitelist_options_' .. tostring(questionIndex),
        title = t('menu.whitelist.options'),
        menu = 'forge_core_whitelist_question_' .. tostring(questionIndex),
        options = options,
    })
end

function Menu.openWhitelistOptionEditor(config, questionIndex, optionIndex)
    local question = config.questions[questionIndex]
    if not question then return Menu.openWhitelistQuestions(config) end

    local option = optionIndex and question.options[optionIndex] or { label = '', value = false }
    local result = inputDialog(optionIndex and t('dialogs.edit_whitelist_option') or t('menu.whitelist.create_option'), {
        { type = 'input', label = t('inputs.whitelist_option'), default = option.label, required = true, min = 1 },
        { type = 'select', label = t('inputs.whitelist_option_correct'), options = boolOptions(), default = boolDefault(option.value), required = true },
    })

    if not result then return Menu.openWhitelistOptions(config, questionIndex) end

    option.label = result[1]
    option.value = boolValue(result[2])
    question.options = question.options or {}

    if optionIndex then
        question.options[optionIndex] = option
    else
        question.options[#question.options + 1] = option
    end

    config.questions[questionIndex] = question

    saveWhitelistConfig(config, function()
        Menu.openWhitelistOptions(config, questionIndex)
    end)
end
