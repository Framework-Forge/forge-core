ForgeCore = ForgeCore or {}

local Service = {
    started = false,
}

local adminDetectionAces = {
    PR.AdminAce or 'forge-core.admin',
    'admin',
    'group.admin',
    'command',
    'command.car',
    'command.optin',
    'txAdmin',
    'txAdmin.menu',
    'txAdmin.Menu',
    'txAdmin.players.kick',
    'txAdmin.players.ban',
    'txAdmin.Playerlist.Menu',
}

local globalGroupAces = {
    ['group.admin'] = {
        PR.AdminAce or 'forge-core.admin',
        'admin',
        'mod',
        'staff',
        'group.admin',
        'group.mod',
        'group.staff',
        'command',
        'qbadmin.join',
        'command.tp',
        'command.tpm',
        'command.togglepvp',
        'command.addpermission',
        'command.removepermission',
        'command.openserver',
        'command.closeserver',
        'command.car',
        'command.dv',
        'command.givemoney',
        'command.setmoney',
        'command.setjob',
        'command.changejob',
        'command.addjob',
        'command.removejob',
        'command.setgang',
        'command.logout',
        'command.deletechar',
        'command.optin',
        'command.admin',
        'command.noclip',
        'command.names',
        'command.blips',
        'command.admincar',
        'command.setmodel',
        'command.vec2',
        'command.vec3',
        'command.vec4',
        'command.heading',
    },
    ['group.mod'] = {
        'mod',
        'staff',
        'group.mod',
        'group.staff',
        'command.admin',
        'command.noclip',
        'command.names',
        'command.blips',
    },
    ['group.staff'] = {
        'staff',
        'support',
        'group.staff',
        'group.support',
    },
}

local function debug(level, message)
    local debugApi = pr_lib and pr_lib.debug
    if not debugApi then return end

    local fn = debugApi[level]
    if type(fn) == 'function' then
        fn(message)
    elseif type(debugApi) == 'function' then
        debugApi(level, message)
    end
end

local function notify(source, data)
    if not source then return end

    if source <= 0 then
        debug(data.type or 'info', data.description or data.title or ForgeCore.t('staff.title'))
        return
    end

    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('staff.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function canManage(source)
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        local ok = ForgeCore.JobService.canManage(source)
        if ok then return true end
    end

    if source == 0 then return true end

    for _, permission in ipairs(adminDetectionAces) do
        if IsPlayerAceAllowed(source, permission) then return true end
    end

    return false
end

local function roleKey(role)
    role = tostring(role or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
    role = role:gsub('^group%.', '')
    role = role:gsub('[^%w_%-]', '')
    if role == '' then return nil end

    return role
end

local function normalizeRole(role)
    role = roleKey(role)
    if not role then return nil end

    return 'group.' .. role
end

local function roleLabel(role)
    role = tostring(role or ''):gsub('^group%.', '')

    for _, item in ipairs(PR.Staff.Roles or {}) do
        if item.value == role then return item.label end
    end

    return role
end

local function getFullName(playerData)
    local charinfo = playerData and playerData.charinfo or {}
    local firstname = charinfo.firstname or charinfo.firstName or ''
    local lastname = charinfo.lastname or charinfo.lastName or ''
    local name = (('%s %s'):format(firstname, lastname):gsub('^%s+', ''):gsub('%s+$', ''))

    return name ~= '' and name or tostring(playerData and playerData.citizenid or 'unknown')
end

local function getQbxPlayer(source)
    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)

    if ok then return player end
end

local function getOnlineByCitizenid(citizenid)
    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayerByCitizenId(citizenid)
    end)

    if ok then return player end
end

local function getOfflineByCitizenid(citizenid)
    local ok, player = pcall(function()
        return exports.qbx_core:GetOfflinePlayer(citizenid)
    end)

    if ok then return player end
end

local function saveOffline(player)
    if not player or not player.PlayerData then return false end

    local ok, saved = pcall(function()
        return exports.qbx_core:SaveOffline(player.PlayerData)
    end)

    return ok and saved ~= false
end

local function sourcePrincipals(source)
    return {
        ('player.%s'):format(source),
    }
end

local function roleGrants(role)
    local key = roleKey(role)
    if not key then return nil end

    local grants = PR.Staff.RolePermissions and PR.Staff.RolePermissions[key]
    if grants then return grants end

    return {
        principals = { 'group.' .. key },
        aces = { key, 'group.' .. key },
        optin = key == 'admin' or key == 'mod',
    }
end

local function executeAccessCommand(action, principal, value, aceType)
    if not principal or not value then return end

    if action == 'add_principal' or action == 'remove_principal' then
        ExecuteCommand(('%s %s %s'):format(action, principal, value))
        return
    end

    ExecuteCommand(('%s %s %s %s'):format(action, principal, value, aceType or 'allow'))
end

local function applyRoleAccess(source, role)
    source = tonumber(source)
    if not source or source <= 0 then return false end

    local grants = roleGrants(role)
    if not grants then return false end

    for _, principal in ipairs(sourcePrincipals(source)) do
        for _, targetPrincipal in ipairs(grants.principals or {}) do
            executeAccessCommand('add_principal', principal, targetPrincipal)
        end

        for _, ace in ipairs(grants.aces or {}) do
            executeAccessCommand('add_ace', principal, ace, 'allow')
        end
    end

    TriggerClientEvent('QBCore:Client:OnPermissionUpdate', source)
    TriggerEvent('QBCore:Server:OnPermissionUpdate', source)

    return true
end

local function removeRoleAccess(source, role)
    source = tonumber(source)
    if not source or source <= 0 then return false end

    local grants = roleGrants(role)
    if not grants then return false end

    for _, principal in ipairs(sourcePrincipals(source)) do
        for _, ace in ipairs(grants.aces or {}) do
            executeAccessCommand('remove_ace', principal, ace, 'allow')
        end

        for _, targetPrincipal in ipairs(grants.principals or {}) do
            executeAccessCommand('remove_principal', principal, targetPrincipal)
        end
    end

    TriggerClientEvent('QBCore:Client:OnPermissionUpdate', source)
    TriggerEvent('QBCore:Server:OnPermissionUpdate', source)

    return true
end

local function shouldOptin(role)
    local grants = roleGrants(role)
    return grants and grants.optin == true
end

local function setOnlineOptin(player, enabled)
    if not player or not player.PlayerData or not player.Functions or not player.Functions.SetMetaData then return end

    player.PlayerData.metadata = player.PlayerData.metadata or {}
    player.PlayerData.metadata.optin = enabled == true
    player.Functions.SetMetaData('optin', player.PlayerData.metadata.optin)
end

local function setOfflineOptin(player, enabled)
    if not player or not player.PlayerData then return end

    player.PlayerData.metadata = player.PlayerData.metadata or {}
    player.PlayerData.metadata.optin = enabled == true
end

local function isConfiguredAdmin(source)
    if not source or source <= 0 then return false end

    for _, permission in ipairs(adminDetectionAces) do
        if IsPlayerAceAllowed(source, permission) then return true end
    end

    return false
end

local function applyGlobalGroupAces()
    for principal, aces in pairs(globalGroupAces) do
        for _, ace in ipairs(aces) do
            executeAccessCommand('add_ace', principal, ace, 'allow')
        end
    end
end

local function getStoredRole(player)
    local metadata = player and player.PlayerData and player.PlayerData.metadata
    local role = metadata and metadata[PR.Staff.Metadata]
    if role == '' then role = nil end
    return role
end

local function setOnlineRole(player, role)
    local oldRole = getStoredRole(player)
    local source = player and player.PlayerData and player.PlayerData.source

    if oldRole then removeRoleAccess(source, oldRole) end
    if role then applyRoleAccess(source, role) end

    setOnlineOptin(player, role and shouldOptin(role))

    player.Functions.SetMetaData(PR.Staff.Metadata, role)
    return true
end

local function setOfflineRole(player, role)
    player.PlayerData.metadata = player.PlayerData.metadata or {}
    player.PlayerData.metadata[PR.Staff.Metadata] = role
    setOfflineOptin(player, role and shouldOptin(role))
    return saveOffline(player)
end

local function playerEntry(player, citizenid, offline)
    local playerData = player and player.PlayerData or {}
    local source = playerData.source
    local role = getStoredRole(player)

    return {
        source = source,
        citizenId = citizenid or playerData.citizenid,
        citizenid = citizenid or playerData.citizenid,
        name = getFullName(playerData),
        displayName = ('%s %s'):format(offline and '[OFF]' or '[ON]', getFullName(playerData)),
        role = role,
        roleLabel = roleLabel(role),
        offline = offline == true,
    }
end

local function fetchCitizenids()
    local db = pr_lib and pr_lib.db
    if not db or not db.query then return {} end

    return db.query('SELECT citizenid FROM players') or {}
end

function Service.canManage(source)
    return canManage(source)
end

function Service.forceApply(source, role)
    role = role or 'group.admin'

    local player = getQbxPlayer(source)
    applyGlobalGroupAces()
    applyRoleAccess(source, role)
    setOnlineOptin(player, shouldOptin(role))

    return true
end

function Service.permissionStatus(source)
    local status = {}
    local aces = {
        PR.AdminAce or 'forge-core.admin',
        'admin',
        'mod',
        'staff',
        'group.admin',
        'group.mod',
        'command',
        'command.tpm',
        'command.dv',
        'command.car',
        'command.optin',
        'command.admin',
        'command.noclip',
        'txAdmin.players.kick',
        'txAdmin.Playerlist.Menu',
    }

    for _, ace in ipairs(aces) do
        status[#status + 1] = {
            ace = ace,
            allowed = source == 0 or IsPlayerAceAllowed(source, ace),
        }
    end

    return status
end

function Service.list()
    local entries = {}
    local onlineStaff = 0
    local offlineStaff = 0

    for _, row in ipairs(fetchCitizenids()) do
        local citizenid = row.citizenid
        local player = getOnlineByCitizenid(citizenid)
        local offline = false

        if not player then
            player = getOfflineByCitizenid(citizenid)
            offline = true
        end

        if player and getStoredRole(player) then
            if offline then offlineStaff = offlineStaff + 1 else onlineStaff = onlineStaff + 1 end
            entries[#entries + 1] = playerEntry(player, citizenid, offline)
        end
    end

    table.sort(entries, function(left, right)
        return tostring(left.name) < tostring(right.name)
    end)

    return {
        staff = entries,
        onlineStaff = onlineStaff,
        offlineStaff = offlineStaff,
    }
end

function Service.getPlayers(sources)
    local players = {}
    sources = type(sources) == 'table' and sources or {}

    for _, playerSource in ipairs(sources) do
        playerSource = tonumber(playerSource)
        local player = playerSource and getQbxPlayer(playerSource)
        if player and player.PlayerData then
            players[#players + 1] = playerEntry(player, player.PlayerData.citizenid, false)
        end
    end

    table.sort(players, function(left, right)
        return tostring(left.name) < tostring(right.name)
    end)

    return players
end

function Service.add(source, data)
    if not canManage(source) then return false, 'no_permission' end

    data = type(data) == 'table' and data or {}
    local role = normalizeRole(data.role)
    if not role then return false, 'missing_role' end

    local targetSource = tonumber(data.source)
    local player = targetSource and getQbxPlayer(targetSource)
    local offline = false

    if not player and data.citizenId then
        player = getOfflineByCitizenid(data.citizenId)
        offline = true
    end

    if not player then return false, 'player_not_found' end

    local ok = offline and setOfflineRole(player, role) or setOnlineRole(player, role)
    if not ok then return false, 'save_failed' end

    notify(targetSource, {
        description = ForgeCore.t('notify.staff.received', { role = roleLabel(role) }),
        type = 'success',
    })
    notify(source, {
        description = ForgeCore.t('notify.staff.added', { name = getFullName(player.PlayerData), role = roleLabel(role) }),
        type = 'success',
    })

    return true, playerEntry(player, data.citizenId, offline)
end

function Service.remove(source, data)
    if not canManage(source) then return false, 'no_permission' end

    data = type(data) == 'table' and data or {}
    local targetSource = tonumber(data.source)
    local player = targetSource and getQbxPlayer(targetSource)
    local offline = false

    if not player and data.citizenId then
        player = getOfflineByCitizenid(data.citizenId)
        offline = true
    end

    if not player then return false, 'player_not_found' end

    local oldRole = getStoredRole(player)
    if not oldRole then return false, 'not_staff' end

    local ok = offline and setOfflineRole(player, nil) or setOnlineRole(player, nil)
    if not ok then return false, 'save_failed' end

    notify(targetSource, {
        description = ForgeCore.t('notify.staff.removed_target', { role = roleLabel(oldRole) }),
        type = 'info',
    })
    notify(source, {
        description = ForgeCore.t('notify.staff.removed', { name = getFullName(player.PlayerData), role = roleLabel(oldRole) }),
        type = 'success',
    })

    return true
end

function Service.applyPlayer(source)
    local player = getQbxPlayer(source)
    local role = getStoredRole(player)
    if role then
        applyRoleAccess(source, role)
        setOnlineOptin(player, shouldOptin(role))
        return true
    end

    if isConfiguredAdmin(source) then
        applyRoleAccess(source, 'group.admin')
        setOnlineOptin(player, true)
        return true
    end

    return false
end

function Service.start()
    if Service.started then return true end

    Service.started = true
    applyGlobalGroupAces()

    SetTimeout(1000, function()
        for _, playerSource in ipairs(GetPlayers()) do
            Service.applyPlayer(tonumber(playerSource))
        end
    end)

    debug('success', ForgeCore.t('debug.staff.started'))
    return true
end

ForgeCore.StaffService = Service
