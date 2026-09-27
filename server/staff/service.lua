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

local function isAceAllowedResult(value)
    return value == true or value == 1
end

local function isPlayerAceAllowedCompat(source, permission)
    local aceApi = pr_lib and pr_lib.ace
    if aceApi and type(aceApi.isPlayerAceAllowed) == 'function' then
        return isAceAllowedResult(aceApi.isPlayerAceAllowed(source, permission))
    end

    local principal = ('player.%s'):format(tostring(tonumber(source) or source or ''))
    if principal ~= 'player.' then
        local ok, allowed = pcall(IsPrincipalAceAllowed, principal, permission)
        if ok and isAceAllowedResult(allowed) then return true end
    end

    local numericSource = tonumber(source)
    if numericSource and isAceAllowedResult(IsPlayerAceAllowed(numericSource, permission)) then return true end

    local textSource = tostring(source or '')
    if textSource ~= '' and isAceAllowedResult(IsPlayerAceAllowed(textSource, permission)) then return true end

    return false
end

local function canManage(source)
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        local ok = ForgeCore.JobService.canManage(source)
        if ok then return true end
    end

    if source == 0 then return true end

    for _, permission in ipairs(adminDetectionAces) do
        if isPlayerAceAllowedCompat(source, permission) then return true end
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
    local principals, seen = {}, {}
    local function push(value)
        if value and not seen[value] then seen[value] = true; principals[#principals + 1] = value end
    end

    push(('player.%s'):format(source))
    local ok, identifiers = pcall(GetPlayerIdentifiers, source)
    if ok and type(identifiers) == 'table' then
        for _, identifier in ipairs(identifiers) do
            local identifierType = tostring(identifier):match('^([^:]+):')
            if identifierType == 'license'
                or identifierType == 'license2'
                or identifierType == 'fivem'
                or identifierType == 'discord'
            then
                push('identifier.' .. identifier)
            end
        end
    end

    return principals
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

-- FXServer refuses add_ace/remove_ace when the target is one of the principals
-- in the current player context ("Changing ones own access is not permitted").
-- Direct ACEs therefore live on a stable Forge-owned principal inherited by
-- the player and their persistent identifiers.
local function permissionPrincipal(permission)
    local encoded = tostring(permission or ''):gsub('.', function(character)
        return ('%02x'):format(character:byte())
    end)

    return 'forge.permission.' .. encoded
end

local function permissionParent(permission)
    if tostring(permission):find('^group%.') then return permission end
    return permissionPrincipal(permission)
end

local function ensurePermissionParent(permission)
    local parent = permissionParent(permission)
    if tostring(permission):find('^group%.') then return parent end

    if type(IsPrincipalAceAllowed) ~= 'function' or not isAceAllowedResult(IsPrincipalAceAllowed(parent, permission)) then
        executeAccessCommand('add_ace', parent, permission, 'allow')
    end

    return parent
end

local function grantPermission(principal, permission)
    executeAccessCommand('add_principal', principal, ensurePermissionParent(permission))
end

local function revokePermission(principal, permission)
    executeAccessCommand('remove_principal', principal, permissionParent(permission))
end

local function hasPermission(source, permission)
    return isPlayerAceAllowedCompat(source, permission)
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
            grantPermission(principal, ace)
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
            revokePermission(principal, ace)
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
        if isPlayerAceAllowedCompat(source, permission) then return true end
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
        'pr_bridge.developer',
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
            allowed = source == 0 or isPlayerAceAllowedCompat(source, ace),
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

-- Permission sets (metadata v2). Legacy string roles remain readable and are
-- migrated on the next login/edit without removing existing staff access.
local function normalizePermission(value)
    value = tostring(value or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
    if value == '' or value:find('%s') or not value:match('^[%w_%.:%-]+$') then return nil end
    if not value:find('%.', 1, true) then
        for _, role in ipairs(PR.Staff.Roles or {}) do
            if role.value == value then return 'group.' .. value end
        end
    end
    return value
end

local function normalizePermissions(raw)
    local result, seen = {}, {}
    local function push(value)
        value = normalizePermission(value)
        if value and not seen[value] then seen[value] = true; result[#result + 1] = value end
    end

    if type(raw) == 'string' then
        push(raw)
    elseif type(raw) == 'table' then
        if type(raw.permissions) == 'table' then raw = raw.permissions end
        for key, value in pairs(raw) do
            if type(key) == 'number' then push(value)
            elseif value == true then push(key) end
        end
    end
    table.sort(result)
    return result
end

local function permissionMetadata(permissions)
    return { version = 2, permissions = normalizePermissions(permissions) }
end

local function storedPermissionValue(player)
    local metadata = player and player.PlayerData and player.PlayerData.metadata or {}
    return metadata[PR.Staff.Metadata]
end

local function storedPermissions(player)
    local metadata = player and player.PlayerData and player.PlayerData.metadata or {}
    return normalizePermissions(metadata[PR.Staff.Metadata])
end

local function catalogFallback()
    local catalog, seen = {}, {}
    local function push(entry)
        local value = normalizePermission(type(entry) == 'table' and entry.value or entry)
        if not value or seen[value] or (PR.Staff.HiddenPermissions or {})[value] then return end
        seen[value] = true
        entry = type(entry) == 'table' and entry or {}
        catalog[#catalog + 1] = { value = value, label = entry.label or value, description = entry.description, kind = entry.kind or (value:find('^group%.') and 'principal' or 'ace'), source = entry.source or 'forge-core' }
    end
    for _, entry in ipairs(PR.Staff.PermissionCatalog or {}) do
        push(entry)
    end
    for _, grants in pairs(PR.Staff.RolePermissions or {}) do
        for _, permission in ipairs(grants.principals or {}) do push(permission) end
        for _, permission in ipairs(grants.aces or {}) do push(permission) end
    end
    table.sort(catalog, function(left, right) return tostring(left.label) < tostring(right.label) end)
    return catalog
end

function Service.getPermissionCatalog()
    local aceApi = pr_lib and pr_lib.ace
    if aceApi and type(aceApi.getPermissionCatalog) == 'function' then
        local ok, catalog = pcall(aceApi.getPermissionCatalog, {
            files = PR.Staff.PermissionFiles,
            fallback = catalogFallback(),
            hidden = PR.Staff.HiddenPermissions,
        })
        if ok and type(catalog) == 'table' and #catalog > 0 then return catalog end
    end
    return catalogFallback()
end

local function catalogMap()
    local map = {}
    for _, entry in ipairs(Service.getPermissionCatalog()) do map[entry.value] = entry end
    return map
end

local function validatedPermissions(raw)
    local allowed, result = catalogMap(), {}
    for _, permission in ipairs(normalizePermissions(raw)) do
        if allowed[permission] then result[#result + 1] = permission end
    end
    return result
end

local function permissionLabels(permissions)
    local map, labels = catalogMap(), {}
    for _, permission in ipairs(permissions or {}) do
        labels[#labels + 1] = map[permission] and map[permission].label or permission
    end
    return labels
end

local function addPermissionAccess(source, permission)
    for _, principal in ipairs(sourcePrincipals(source)) do grantPermission(principal, permission) end
end

local function removePermissionAccess(source, permission)
    for _, principal in ipairs(sourcePrincipals(source)) do revokePermission(principal, permission) end
end

local function refreshPermissionEvents(source)
    TriggerClientEvent('QBCore:Client:OnPermissionUpdate', source)
    TriggerEvent('QBCore:Server:OnPermissionUpdate', source)
end

local function applyPermissionSet(source, permissions)
    source = tonumber(source)
    if not source or source <= 0 then return false end
    for _, permission in ipairs(permissions or {}) do addPermissionAccess(source, permission) end
    local missing = {}
    for _, permission in ipairs(permissions or {}) do
        if not hasPermission(source, permission) then missing[#missing + 1] = permission end
    end
    refreshPermissionEvents(source)
    if #missing > 0 then
        debug('error', ('[staff] ACE apply failed source=%s missing=%s'):format(source, table.concat(missing, ',')))
        return false, 'ace_apply_failed:' .. table.concat(missing, ',')
    end
    return true
end

local function removePermissionSet(source, permissions)
    source = tonumber(source)
    if not source or source <= 0 then return false end
    for _, permission in ipairs(permissions or {}) do removePermissionAccess(source, permission) end
    refreshPermissionEvents(source)
    return true
end

local function setOnlinePermissions(player, permissions)
    local old = storedPermissions(player)
    local source = player and player.PlayerData and player.PlayerData.source
    local raw = storedPermissionValue(player)
    if type(raw) == 'string' then removeRoleAccess(source, raw)
    else removePermissionSet(source, old) end
    local applied, applyError = applyPermissionSet(source, permissions)
    if not applied then return false, applyError end
    local optin = false
    for _, permission in ipairs(permissions) do
        if permission == 'group.admin' or permission == 'group.mod' then optin = true break end
    end
    setOnlineOptin(player, optin)
    player.Functions.SetMetaData(PR.Staff.Metadata, #permissions > 0 and permissionMetadata(permissions) or nil)
    if player.Functions.Save then player.Functions.Save() end
    return true
end

local function setOfflinePermissions(player, permissions)
    player.PlayerData.metadata = player.PlayerData.metadata or {}
    player.PlayerData.metadata[PR.Staff.Metadata] = #permissions > 0 and permissionMetadata(permissions) or nil
    local optin = false
    for _, permission in ipairs(permissions) do
        if permission == 'group.admin' or permission == 'group.mod' then optin = true break end
    end
    setOfflineOptin(player, optin)
    return saveOffline(player)
end

function Service.getPlayerPermissions(playerOrSource)
    local player = type(playerOrSource) == 'table' and playerOrSource or getQbxPlayer(playerOrSource)
    return storedPermissions(player)
end

function Service.permissionDiagnostics(source)
    source = tonumber(source)
    if not source or source <= 0 then return {} end

    local status = Service.permissionStatus(source)
    local indexed = {}
    for _, item in ipairs(status) do indexed[item.ace] = item end

    local stored = storedPermissions(getQbxPlayer(source))
    for _, permission in ipairs(stored) do
        local item = indexed[permission]
        if not item then
            item = { ace = permission, allowed = hasPermission(source, permission) }
            status[#status + 1] = item
            indexed[permission] = item
        end
        item.stored = true
    end

    for _, item in ipairs(status) do
        item.stored = item.stored == true
        item.parent = permissionParent(item.ace)
        item.parentAllowed = type(IsPrincipalAceAllowed) == 'function'
            and isAceAllowedResult(IsPrincipalAceAllowed(item.parent, item.ace))
            or false
    end

    table.sort(status, function(left, right) return left.ace < right.ace end)
    return status
end

local legacyAdd, legacyRemove, legacyApplyPlayer = Service.add, Service.remove, Service.applyPlayer

function Service.add(source, data)
    if not canManage(source) then return false, 'no_permission' end
    data = type(data) == 'table' and data or {}
    local requested = data.permissions or data.role
    local permissions = validatedPermissions(requested)
    if #permissions == 0 then return false, 'missing_permissions' end
    local targetSource = tonumber(data.source)
    local player = targetSource and getQbxPlayer(targetSource)
    local offline = false
    if not player and (data.citizenId or data.citizenid) then
        player = getOfflineByCitizenid(data.citizenId or data.citizenid)
        offline = true
    end
    if not player then return false, 'player_not_found' end
    local ok, applyError
    if offline then
        ok = setOfflinePermissions(player, permissions)
    else
        ok, applyError = setOnlinePermissions(player, permissions)
    end
    if not ok then return false, applyError or 'save_failed' end
    local labels = table.concat(permissionLabels(permissions), ', ')
    notify(targetSource, { description = ForgeCore.t('notify.staff.received', { role = labels }), type = 'success' })
    notify(source, { description = ForgeCore.t('notify.staff.added', { name = getFullName(player.PlayerData), role = labels }), type = 'success' })
    return true, playerEntry(player, data.citizenId or data.citizenid, offline)
end

function Service.remove(source, data)
    if not canManage(source) then return false, 'no_permission' end
    data = type(data) == 'table' and data or {}
    local targetSource = tonumber(data.source)
    local player = targetSource and getQbxPlayer(targetSource)
    local offline = false
    if not player and (data.citizenId or data.citizenid) then
        player = getOfflineByCitizenid(data.citizenId or data.citizenid)
        offline = true
    end
    if not player then return false, 'player_not_found' end
    local old = storedPermissions(player)
    if #old == 0 then return false, 'not_staff' end
    local ok = offline and setOfflinePermissions(player, {}) or setOnlinePermissions(player, {})
    if not ok then return false, 'save_failed' end
    local labels = table.concat(permissionLabels(old), ', ')
    notify(targetSource, { description = ForgeCore.t('notify.staff.removed_target', { role = labels }), type = 'info' })
    notify(source, { description = ForgeCore.t('notify.staff.removed', { name = getFullName(player.PlayerData), role = labels }), type = 'success' })
    return true
end

function Service.applyPlayer(source)
    local player = getQbxPlayer(source)
    local permissions = storedPermissions(player)
    if #permissions > 0 then
        local raw = storedPermissionValue(player)
        if type(raw) == 'string' then removeRoleAccess(source, raw) end
        local applied, applyError = applyPermissionSet(source, permissions)
        if not applied then return false, applyError end
        if type(raw) ~= 'table' then
            player.Functions.SetMetaData(PR.Staff.Metadata, permissionMetadata(permissions))
            if player.Functions.Save then player.Functions.Save() end
        end
        return true
    end
    return legacyApplyPlayer(source)
end

local legacyPlayerEntry = playerEntry
playerEntry = function(player, citizenid, offline)
    local entry = legacyPlayerEntry(player, citizenid, offline)
    entry.permissions = storedPermissions(player)
    entry.permissionLabels = permissionLabels(entry.permissions)
    entry.role = entry.permissions[1]
    entry.roleLabel = table.concat(entry.permissionLabels, ', ')
    return entry
end

ForgeCore.StaffService = Service
