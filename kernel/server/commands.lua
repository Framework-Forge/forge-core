-- Inactive installed-QBX port; see NOTICE-10.md and LICENSE-QBX.
return function(ports)
    assert(type(ports) == 'table', 'explicit server runtime ports required')
    local core = assert(ports.core, 'canonical server state required')
    local native = assert(ports.native, 'platform ports required')
    local api = {Events = {}, Exports = {}}
    local function describeExport(name, handler) api.Exports[name] = handler; api[name] = handler end
    local function network(name, handler)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = true}
    end
    local config = assert(ports.config, 'local server configuration required')
    local logger = assert(ports.logger, 'local logger required')
    local library = assert(ports.library, 'explicit library ports required')
    local helpers = assert(ports.helpers, 'local Lib required')
    local globalState = assert(ports.globalState, 'global state delivery required')
    local locale = assert(ports.locale, 'local translator required')
    local json = assert(ports.json, 'codec port required')
    local removeKeyItem = assert(ports.removeKeyItem, 'PR temporary key item integration required')
    local chatMessage = assert(ports.chatMessage, 'PR chat integration required')
    local services = assert(ports.services, 'local core services required')
    local IsOptin = assert(services.IsOptin, 'internal IsOptin required')
    local Notify = assert(services.Notify, 'internal Notify required')
    local GetPlayer = assert(services.GetPlayer, 'internal GetPlayer required')
    local AddPermission = assert(services.AddPermission, 'internal AddPermission required')
    local RemovePermission = assert(services.RemovePermission, 'internal RemovePermission required')
    local DeleteVehicle = assert(services.DeleteVehicle, 'internal DeleteVehicle required')
    local SetPlayerPrimaryJob = assert(services.SetPlayerPrimaryJob, 'internal SetPlayerPrimaryJob required')
    local AddPlayerToJob = assert(services.AddPlayerToJob, 'internal AddPlayerToJob required')
    local RemovePlayerFromJob = assert(services.RemovePlayerFromJob, 'internal RemovePlayerFromJob required')
    local Logout = assert(services.Logout, 'internal Logout required')
    local ForceDeleteCharacter = assert(services.ForceDeleteCharacter, 'internal ForceDeleteCharacter required')
    local ToggleOptin = assert(services.ToggleOptin, 'internal ToggleOptin required')
    api.Commands = {}
    local function describeCommand(name, options, handler, externalOwner, isEnabled)
        api.Commands[#api.Commands + 1] = {name = name, options = options, handler = handler,
            externalOwner = externalOwner, isEnabled = isEnabled}
    end

local initialized = false
function api.Initialize()
    if initialized then return false end
    globalState.PVPEnabled = config.server.pvp
    initialized = true
    return true
end

local function isResourceStarted(resource)
    local state = native.GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

local function removeTemporaryVehicleKey(source, vehicle)
    if not isResourceStarted('pr_carkeys') then return end
    local plate = helpers.getVehiclePlate(vehicle)
    if not plate then return end

    pcall(function()
        removeKeyItem(source, plate)
    end)
end

describeCommand('tp', {
    help = locale('command.tp.help'),
    params = {
        { name = locale('command.tp.params.x.name'), help = locale('command.tp.params.x.help'), optional = false },
        { name = locale('command.tp.params.y.name'), help = locale('command.tp.params.y.help'), optional = true },
        { name = locale('command.tp.params.z.name'), help = locale('command.tp.params.z.help'), optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    if args[locale('command.tp.params.x.name')] and not args[locale('command.tp.params.y.name')] and not args[locale('command.tp.params.z.name')] then
        local target = native.GetPlayerPed(tonumber(args[locale('command.tp.params.x.name')]) --[[@as number]])
        if target ~= 0 then
            local coords = native.GetEntityCoords(target)
            native.TriggerClientEvent('QBCore:Command:TeleportToPlayer', source, coords)
        else
            Notify(source, locale('error.not_online'), 'error')
        end
    else
        if args[locale('command.tp.params.x.name')] and args[locale('command.tp.params.y.name')] and args[locale('command.tp.params.z.name')] then
            local x = tonumber((args[locale('command.tp.params.x.name')]:gsub(',',''))) + .0
            local y = tonumber((args[locale('command.tp.params.y.name')]:gsub(',',''))) + .0
            local z = tonumber((args[locale('command.tp.params.z.name')]:gsub(',',''))) + .0
            if x ~= 0 and y ~= 0 and z ~= 0 then
                native.TriggerClientEvent('QBCore:Command:TeleportToCoords', source, x, y, z)
            else
                Notify(source, locale('error.wrong_format'), 'error')
            end
        else
            Notify(source, locale('error.missing_args'), 'error')
        end
    end
end)

describeCommand('tpm', {
    help = locale('command.tpm.help'),
    restricted = 'group.admin'
}, function(source)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    native.TriggerClientEvent('QBCore:Command:GoToMarker', source)
end)

describeCommand('togglepvp', {
    help = locale('command.togglepvp.help'),
    restricted = 'group.admin'
}, function(source)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    config.server.pvp = not config.server.pvp
    globalState.PVPEnabled = config.server.pvp
end)

describeCommand('addpermission', {
    help = locale('command.addpermission.help'),
    params = {
        { name = locale('command.addpermission.params.id.name'), help = locale('command.addpermission.params.id.help'), type = 'playerId' },
        { name = locale('command.addpermission.params.permission.name'), help = locale('command.addpermission.params.permission.help'), type = 'string' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args[locale('command.addpermission.params.id.name')])
    local permission = args[locale('command.addpermission.params.permission.name')]
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    ---@diagnostic disable-next-line: deprecated
    AddPermission(player.PlayerData.source, permission)
end)

describeCommand('removepermission', {
    help = locale('command.removepermission.help'),
    params = {
        { name = locale('command.removepermission.params.id.name'), help = locale('command.removepermission.params.id.help'), type = 'playerId' },
        { name = locale('command.removepermission.params.permission.name'), help = locale('command.removepermission.params.permission.help'), type = 'string' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args[locale('command.removepermission.params.id.name')])
    local permission = args[locale('command.removepermission.params.permission.name')]
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    ---@diagnostic disable-next-line: deprecated
    RemovePermission(player.PlayerData.source, permission)
end)

describeCommand('openserver', {
    help = locale('command.openserver.help'),
    restricted = 'group.admin'
}, function(source)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    if not config.server.closed then
        Notify(source, locale('error.server_already_open'), 'error')
        return
    end

    if native.IsPlayerAceAllowed(source, 'admin') then
        config.server.closed = false
        Notify(source, locale('success.server_opened'), 'success')
    else
        native.DropPlayer(source, locale('error.no_permission'))
    end
end)

describeCommand('closeserver', {
    help = locale('command.openserver.help'),
    params = {
        { name = locale('command.closeserver.params.reason.name'), help = locale('command.closeserver.params.reason.help'), type = 'string' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    if config.server.closed then
        Notify(source, locale('error.server_already_closed'), 'error')
        return
    end

    if native.IsPlayerAceAllowed(source, 'admin') then
        local reason = args[locale('command.closeserver.params.reason.name')] or 'No reason specified'
        config.server.closed = true
        config.server.closedReason = reason
        for k in pairs(core.Players) do
            if not native.IsPlayerAceAllowed(k --[[@as string]], config.server.whitelistPermission) then
                native.DropPlayer(k --[[@as string]], reason)
            end
        end

        Notify(source, locale('success.server_closed'), 'success')
    else
        native.DropPlayer(source, locale('error.no_permission'))
    end
end)

describeCommand('car', {
    help = locale('command.car.help'),
    params = {
        { name = locale('command.car.params.model.name'), help = locale('command.car.params.model.help') },
        { name = locale('command.car.params.keepCurrentVehicle.name'), help = locale('command.car.params.keepCurrentVehicle.help'), optional = true },
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    if not args then return end

    local ped, bucket = native.GetPlayerPed(source), native.GetPlayerRoutingBucket(source)
    local keepCurrentVehicle = args[locale('command.car.params.keepCurrentVehicle.name')]
    local currentVehicle = not keepCurrentVehicle and native.GetVehiclePedIsIn(ped, false)
    if currentVehicle and currentVehicle ~= 0 then
        DeleteVehicle(currentVehicle)
    end

    local _, vehicle = helpers.spawnVehicle({
        model = args[locale('command.car.params.model.name')],
        spawnSource = ped,
        warp = true,
        bucket = bucket
    })

    local plate = helpers.getVehiclePlate(vehicle)
    config.giveVehicleKeys(source, plate, vehicle)
end)

describeCommand('dv', {
    help = locale('command.dv.help'),
    params = {
        { name = locale('command.dv.params.radius.name'), help = locale('command.dv.params.radius.help'), type = 'number', optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local ped = native.GetPlayerPed(source)
    local pedCars = {native.GetVehiclePedIsIn(ped, false)}
    local radius = args[locale('command.dv.params.radius.name')]

    if pedCars[1] == 0 or radius then -- Only execute when player is not in a vehicle or radius is explicitly defined
        pedCars = library.callback.await('qbx_core:client:getVehiclesInRadius', source, radius)
    else
        pedCars[1] = native.NetworkGetNetworkIdFromEntity(pedCars[1])
    end

    if #pedCars ~= 0 then
        for i = 1, #pedCars do
            local pedCar = native.NetworkGetEntityFromNetworkId(pedCars[i])
            if pedCar and native.DoesEntityExist(pedCar) then
                removeTemporaryVehicleKey(source, pedCar)
                DeleteVehicle(pedCar)
            end
        end
    end
end)

describeCommand('givemoney', {
    help = locale('command.givemoney.help'),
    params = {
        { name = locale('command.givemoney.params.id.name'), help = locale('command.givemoney.params.id.help'), type = 'playerId' },
        { name = locale('command.givemoney.params.moneytype.name'), help = locale('command.givemoney.params.moneytype.help'), type = 'string' },
        { name = locale('command.givemoney.params.amount.name'), help = locale('command.givemoney.params.amount.help'), type = 'number' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args[locale('command.givemoney.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    player.Functions.AddMoney(args[locale('command.givemoney.params.moneytype.name')], args[locale('command.givemoney.params.amount.name')])
end)

describeCommand('setmoney', {
    help = locale('command.setmoney.help'),
    params = {
        { name = locale('command.setmoney.params.id.name'), help = locale('command.setmoney.params.id.help'), type = 'playerId' },
        { name = locale('command.setmoney.params.moneytype.name'), help = locale('command.setmoney.params.moneytype.help'), type = 'string' },
        { name = locale('command.setmoney.params.amount.name'), help = locale('command.setmoney.params.amount.help'), type = 'number' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args[locale('command.setmoney.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    player.Functions.SetMoney(args[locale('command.setmoney.params.moneytype.name')], args[locale('command.setmoney.params.amount.name')])
end)

describeCommand('job', {
    help = locale('command.job.help')
}, function(source)
    local PlayerJob = GetPlayer(source).PlayerData.job
    Notify(source, locale('info.job_info', (PlayerJob and PlayerJob.label), (PlayerJob and PlayerJob.grade.name), (PlayerJob and PlayerJob.onduty)))
end)

describeCommand('setjob', {
    help = locale('command.setjob.help'),
    params = {
        { name = locale('command.setjob.params.id.name'), help = locale('command.setjob.params.id.help'), type = 'playerId' },
        { name = locale('command.setjob.params.job.name'), help = locale('command.setjob.params.job.help'), type = 'string' },
        { name = locale('command.setjob.params.grade.name'), help = locale('command.setjob.params.grade.help'), type = 'number', optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args[locale('command.setjob.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = player.Functions.SetJob(args[locale('command.setjob.params.job.name')], args[locale('command.setjob.params.grade.name')] or 0)
    assert(success, json.encode(errorResult))
end)

describeCommand('changejob', {
    help = locale('command.changejob.help'),
    params = {
        { name = locale('command.changejob.params.id.name'), help = locale('command.changejob.params.id.help'), type = 'playerId' },
        { name = locale('command.changejob.params.job.name'), help = locale('command.changejob.params.job.help'), type = 'string' },
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args[locale('command.changejob.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = SetPlayerPrimaryJob(player.PlayerData.citizenid, args[locale('command.changejob.params.job.name')])
    assert(success, json.encode(errorResult))
end)

describeCommand('addjob', {
    help = locale('command.addjob.help'),
    params = {
        { name = locale('command.addjob.params.id.name'), help = locale('command.addjob.params.id.help'), type = 'playerId' },
        { name = locale('command.addjob.params.job.name'), help = locale('command.addjob.params.job.help'), type = 'string' },
        { name = locale('command.addjob.params.grade.name'), help = locale('command.addjob.params.grade.help'), type = 'number', optional = true}
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args[locale('command.addjob.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = AddPlayerToJob(player.PlayerData.citizenid, args[locale('command.addjob.params.job.name')], args[locale('command.addjob.params.grade.name')] or 0)
    assert(success, json.encode(errorResult))
end)

describeCommand('removejob', {
    help = locale('command.removejob.help'),
    params = {
        { name = locale('command.removejob.params.id.name'), help = locale('command.removejob.params.id.help'), type = 'playerId' },
        { name = locale('command.removejob.params.job.name'), help = locale('command.removejob.params.job.help'), type = 'string' }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args[locale('command.removejob.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = RemovePlayerFromJob(player.PlayerData.citizenid, args[locale('command.removejob.params.job.name')])
    assert(success, json.encode(errorResult))
end)

describeCommand('gang', {
    help = locale('command.gang.help')
}, function(source)
    local PlayerGang = GetPlayer(source).PlayerData.gang
    Notify(source, locale('info.gang_info', (PlayerGang and PlayerGang.label), (PlayerGang and PlayerGang.grade.name)))
end)

describeCommand('setgang', {
    help = locale('command.setgang.help'),
    params = {
        { name = locale('command.setgang.params.id.name'), help = locale('command.setgang.params.id.help'), type = 'playerId' },
        { name = locale('command.setgang.params.gang.name'), help = locale('command.setgang.params.gang.help'), type = 'string' },
        { name = locale('command.setgang.params.grade.name'), help = locale('command.setgang.params.grade.help'), type = 'number', optional = true }
    },
    restricted = 'group.admin'
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args[locale('command.setgang.params.id.name')])
    if not player then
        Notify(source, locale('error.not_online'), 'error')
        return
    end

    local success, errorResult = player.Functions.SetGang(args[locale('command.setgang.params.gang.name')], args[locale('command.setgang.params.grade.name')] or 0)
    assert(success, json.encode(errorResult))
end)

describeCommand('ooc', {
    help = locale('command.ooc.help')
}, function(source, args)
    local message = table.concat(args, ' ')
    local players = native.GetPlayers()
    local player = GetPlayer(source)
    if not player then return end

    local playerCoords = native.GetEntityCoords(native.GetPlayerPed(source))
    for _, v in pairs(players) do
        if v == source then
            chatMessage(v --[[@as Source]], {
                color = { 0, 0, 255},
                multiline = true,
                args = {('OOC | %s'):format(native.GetPlayerName(source)), message}
            })
        elseif #(playerCoords - native.GetEntityCoords(native.GetPlayerPed(v))) < 20.0 then
            chatMessage(v --[[@as Source]], {
                color = { 0, 0, 255},
                multiline = true,
                args = {('OOC | %s'):format(native.GetPlayerName(source)), message}
            })
        elseif native.IsPlayerAceAllowed(v --[[@as string]], 'admin') then
            if IsOptin(v --[[@as Source]]) then
                chatMessage(v--[[@as Source]], {
                    color = { 0, 0, 255},
                    multiline = true,
                    args = {('Proximity OOC | %s'):format(native.GetPlayerName(source)), message}
                })
                logger.log({
                    source = 'qbx_core',
                    webhook  = 'ooc',
                    event = 'OOC',
                    color = 'white',
                    tags = config.logging.role,
                    message = ('**%s** (CitizenID: %s | ID: %s) **Message:** %s'):format(native.GetPlayerName(source), player.PlayerData.citizenid, source, message)
                })
            end
        end
    end
end)

describeCommand('me', {
    help = locale('command.me.help'),
    params = {
        { name = locale('command.me.params.message.name'), help = locale('command.me.params.message.help'), type = 'string' }
    }
}, function(source, args)
    args[1] = args[locale('command.me.params.message.name')]
    args[locale('command.me.params.message.name')] = nil
    if #args < 1 then Notify(source, locale('error.missing_args2'), 'error') return end
    local msg = table.concat(args, ' '):gsub('[~<].-[>~]', '')
    -- Forge: sem statebag. Envia o texto do /me por evento; cada cliente filtra pela distancia.
    native.TriggerClientEvent('qbx_core:client:me', -1, source, msg)
end, 'forge-chat', function()
    -- The installed chat owns the public command and its configured message/bubble delivery.
    -- Evaluate only during explicit installation; keep the inherited command as a standalone fallback.
    return not isResourceStarted('forge-chat')
end)

describeCommand('id', {help = locale('info.check_id')}, function(source)
    Notify(source, 'ID: ' .. source)
end)

describeCommand('logout', {
    help = locale('info.logout_command_help'),
    restricted = 'group.admin',
}, Logout)

describeCommand('deletechar', {
    help = locale('info.deletechar_command_help'),
    restricted = 'group.admin',
    params = {
        { name = 'id', help = locale('info.deletechar_command_arg_player_id'), type = 'number' },
    }
}, function(source, args)
    if not IsOptin(source) then Notify(source, locale('error.not_optin'), 'error') return end

    local player = GetPlayer(args.id)
    if not player then return end

    local citizenId = player.PlayerData.citizenid
    ForceDeleteCharacter(citizenId)
    Notify(source, locale('success.character_deleted_citizenid', citizenId))
end)

describeCommand('optin', {
    help = locale('command.optin.help'),
    restricted = 'group.admin'
}, function(source, args)
    ToggleOptin(source)
    Notify(source, locale('success.optin_set', IsOptin(source) and 'in' or 'out'))
end)

    return api
end

