ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    config = {},
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
    if not source or source <= 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('whitelist.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function database()
    local db = pr_lib and pr_lib.db
    if not db or not db.scalar or not db.update then return nil end
    if db.isReady and not db.isReady() then return nil end

    return db
end

local function canManage(source)
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        local ok = ForgeCore.JobService.canManage(source)
        if ok then return true end
    end

    if source == 0 then return true end

    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
        or IsPlayerAceAllowed(source, 'admin')
        or IsPlayerAceAllowed(source, 'group.admin')
end

local function clone(value, seen)
    if type(value) ~= 'table' then return value end

    seen = seen or {}
    if seen[value] then return seen[value] end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[clone(key, seen)] = clone(item, seen)
    end

    return copy
end

local function jsonSafe(value, seen)
    local valueType = type(value)
    if valueType ~= 'table' then
        if valueType == 'number' or valueType == 'string' or valueType == 'boolean' or value == nil then
            return value
        end

        return nil
    end

    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true

    local result = {}
    for key, item in pairs(value) do
        local safeKey = type(key) == 'number' and key or tostring(key)
        result[safeKey] = jsonSafe(item, seen)
    end

    seen[value] = nil
    return result
end

local function mergeDefaults(defaults, value)
    local result = clone(defaults)
    value = type(value) == 'table' and value or {}

    for key, item in pairs(value) do
        if type(item) == 'table' and type(result[key]) == 'table' then
            result[key] = mergeDefaults(result[key], item)
        else
            result[key] = item
        end
    end

    return result
end

local function decodeConfig(value)
    if type(value) ~= 'string' or value == '' then return clone(PR.Whitelist.Defaults) end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == 'table' then
        return mergeDefaults(PR.Whitelist.Defaults, decoded)
    end

    return clone(PR.Whitelist.Defaults)
end

local function decodeLegacyConfig(value)
    if type(value) ~= 'string' or value == '' then return nil end

    local ok, legacy = pcall(json.decode, value)
    if not ok or type(legacy) ~= 'table' then return nil end

    local preExam = legacy.PreExamQuestions or {}

    return mergeDefaults(PR.Whitelist.Defaults, {
        enabled = legacy.Enabled,
        percent = legacy.Percent,
        loadNotify = legacy.loadNotify,
        escapeNotify = legacy.escapeNotify,
        startExamLabel = legacy.StartExamLabel,
        startExamHeader = legacy.StartExamHeader,
        startExamContent = legacy.StartExamContent,
        successHeader = legacy.SuccessHeader,
        successContent = legacy.SuccessContent,
        failedHeader = legacy.FailedHeader,
        failedContent = legacy.FailedContent,
        spawnCoords = legacy.SpawnCoords,
        examCoords = legacy.ExamCoords,
        completionCoords = legacy.CompletionCoords,
        citizenZone = legacy.citizenZone,
        questions = legacy.Questions,
        preExam = {
            enabled = preExam.Enabled,
            formatPhone = preExam.FormatPhone,
            webhook = preExam.WebHook,
            label = preExam.label,
            questions = preExam.information,
        },
    })
end

local function encodeConfig(config)
    return json.encode(jsonSafe(mergeDefaults(PR.Whitelist.Defaults, config)))
end

local function configPath()
    return (PR.Whitelist.Storage and PR.Whitelist.Storage.configFile) or 'data/whitelist.json'
end

local function readJsonConfig()
    return pr_lib.loadJsonRecovery(configPath())
end

local function writeJsonConfig(config)
    return pr_lib.saveJsonRecovery(configPath(), jsonSafe(mergeDefaults(PR.Whitelist.Defaults, config)))
end

local function getQbxPlayer(identifier)
    if tonumber(identifier) then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(tonumber(identifier))
        end)
        if ok then return player end
    end

    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayerByCitizenId(tostring(identifier or ''))
    end)

    if ok then return player end
end

local function waitForQbxPlayer(source)
    local player = getQbxPlayer(source)
    local attempts = 0

    while (not player or not player.PlayerData or not player.PlayerData.citizenid) and attempts < 40 do
        attempts = attempts + 1
        Wait(250)
        player = getQbxPlayer(source)
    end

    return player
end

local function getCitizenid(source)
    local player = waitForQbxPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid
end

local function getIdentifierByType(source, identifierType)
    local identifierApi = pr_lib and pr_lib.identifiers
    if identifierApi and identifierApi.getByType then
        return identifierApi.getByType(source, identifierType)
    end

    local value = GetPlayerIdentifierByType(source, identifierType)
    if value and value ~= '' then return value end
end

local function playerIdentifiers(source)
    source = tonumber(source)
    if not source or source <= 0 then return {} end

    local identifierApi = pr_lib and pr_lib.identifiers
    if identifierApi and identifierApi.getAll then
        return identifierApi.getAll(source)
    end

    return {
        license = getIdentifierByType(source, 'license'),
        license2 = getIdentifierByType(source, 'license2'),
        primaryLicense = getIdentifierByType(source, 'license2') or getIdentifierByType(source, 'license'),
        discord = getIdentifierByType(source, 'discord'),
        fivem = getIdentifierByType(source, 'fivem'),
        ip = getIdentifierByType(source, 'ip'),
    }
end

local function addUniqueIdentifier(list, value)
    if type(value) ~= 'string' or value == '' then return end

    for index = 1, #list do
        if list[index] == value then return end
    end

    list[#list + 1] = value
end

local function licenseValues(identifiers)
    identifiers = identifiers or {}

    local values = {}
    addUniqueIdentifier(values, identifiers.playerLicense)
    addUniqueIdentifier(values, identifiers.license)
    addUniqueIdentifier(values, identifiers.license2)
    addUniqueIdentifier(values, identifiers.primaryLicense)

    return values
end

local function persistentLicense(identifiers)
    local values = licenseValues(identifiers)
    return values[1]
end

local function getPlayerNameFromData(player)
    local playerData = player and player.PlayerData or {}
    local charinfo = playerData.charinfo or {}
    local fullname = ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')

    return fullname ~= '' and fullname or playerData.name or playerData.citizenid or 'Desconhecido'
end

local function decodeCharinfo(value)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return {} end

    local ok, decoded = pcall(json.decode, value)
    return ok and type(decoded) == 'table' and decoded or {}
end

local function recordName(row)
    local charinfo = decodeCharinfo(row and row.charinfo)
    local fullname = ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')

    return fullname ~= '' and fullname or tostring(row and (row.name or row.citizenid) or 'Desconhecido')
end

local function setPlayerBucket(source, bucket)
    if not source or source <= 0 then return end
    exports.qbx_core:SetPlayerBucket(source, bucket)
end

local function ensureSchema()
    local db = database()
    if not db then return false end
    db.update(([[CREATE TABLE IF NOT EXISTS `%s` (`id` INT NOT NULL AUTO_INCREMENT, `citizen` VARCHAR(50) NOT NULL, `license` VARCHAR(80) NULL, `discord` VARCHAR(80) NULL, `fivem` VARCHAR(80) NULL, `name` VARCHAR(120) NULL, `whitelisted_at` INT NULL, `added_by` VARCHAR(80) NULL, PRIMARY KEY (`id`), UNIQUE KEY `citizen` (`citizen`))]]):format(PR.Whitelist.Storage.playersTable))
    local columns={license='VARCHAR(80) NULL',discord='VARCHAR(80) NULL',fivem='VARCHAR(80) NULL',name='VARCHAR(120) NULL',whitelisted_at='INT NULL',added_by='VARCHAR(80) NULL'}
    for column,definition in pairs(columns) do
        local exists=db.scalar('SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',{PR.Whitelist.Storage.playersTable,column})
        if not tonumber(exists) or tonumber(exists)<=0 then db.update(('ALTER TABLE `%s` ADD COLUMN `%s` %s'):format(PR.Whitelist.Storage.playersTable,column,definition)) end
    end
    db.update(([[CREATE TABLE IF NOT EXISTS `%s` (`id` INT NOT NULL, `config` LONGTEXT NOT NULL, PRIMARY KEY (`id`))]]):format(PR.Whitelist.Storage.configTable))
    db.update(([[CREATE TABLE IF NOT EXISTS `%s` (`citizen` VARCHAR(50) NOT NULL, `answers` LONGTEXT NULL, `submitted_at` INT NULL, PRIMARY KEY (`citizen`))]]):format(PR.Whitelist.Storage.answersTable))
    return true
end

local function legacyTableExists(tableName)
    local db = database()
    if not db then return false end

    local exists = db.scalar('SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?', { tableName })
    return tonumber(exists) and tonumber(exists) > 0
end

local function migrateLegacyPlayers()
    local db = database()
    if not db or not legacyTableExists('mri_qwhitelist') then return end

    db.update(('INSERT IGNORE INTO `%s` (`citizen`) SELECT `citizen` FROM `mri_qwhitelist`'):format(PR.Whitelist.Storage.playersTable))
end

local function legacyConfig()
    local db = database()
    if not db or not legacyTableExists('mri_qwhitelistcfg') then return nil end

    local stored = db.scalar('SELECT `config` FROM `mri_qwhitelistcfg` WHERE `id` = 1 LIMIT 1')
    return decodeLegacyConfig(stored)
end

local function hasWhitelist(citizenid, identifiers)
    local db = database()
    if not db or not citizenid then return false end

    identifiers = identifiers or {}
    local licenses = licenseValues(identifiers)
    while #licenses < 4 do
        licenses[#licenses + 1] = ''
    end

    local found = db.scalar(([[ 
        SELECT `citizen` FROM `%s`
        WHERE `citizen` = ?
            OR (`license` IS NOT NULL AND `license` IN (?, ?, ?, ?))
            OR (`discord` IS NOT NULL AND `discord` = ?)
            OR (`fivem` IS NOT NULL AND `fivem` = ?)
        LIMIT 1
    ]]):format(PR.Whitelist.Storage.playersTable), {
        citizenid,
        licenses[1],
        licenses[2],
        licenses[3],
        licenses[4],
        identifiers.discord or '',
        identifiers.fivem or '',
    })

    return found ~= nil
end

local function hasWhitelistByPlayerRecord(citizenid)
    local db = database()
    if not db or not citizenid then return false end

    local found = db.scalar(([[ 
        SELECT w.`citizen`
        FROM players p
        INNER JOIN `%s` w
            ON w.`citizen` = p.`citizenid`
            OR (w.`license` IS NOT NULL AND w.`license` = p.`license`)
        WHERE p.`citizenid` = ?
        LIMIT 1
    ]]):format(PR.Whitelist.Storage.playersTable), { citizenid })

    return found ~= nil
end

local function pendingConfig(config, reason)
    local payload = clone(config)
    payload.pending = true
    payload.pendingReason = reason
    return payload
end

local function syncWhitelistIdentifiers(citizenid, identifiers, name)
    local db = database()
    if not db or not citizenid then return end

    identifiers = identifiers or {}
    db.update(([[ 
        UPDATE `%s`
        SET
            `license` = COALESCE(?, `license`),
            `discord` = COALESCE(?, `discord`),
            `fivem` = COALESCE(?, `fivem`),
            `name` = COALESCE(?, `name`)
        WHERE `citizen` = ?
    ]]):format(PR.Whitelist.Storage.playersTable), {
        persistentLicense(identifiers),
        identifiers.discord,
        identifiers.fivem,
        name,
        citizenid,
    })
end

local function getOfflineRecord(identifier)
    local db = database()
    if not db or not identifier then return nil end

    return (db.query([[
        SELECT citizenid, license, name, charinfo
        FROM players
        WHERE citizenid = ? OR license = ?
        LIMIT 1
    ]], { tostring(identifier), tostring(identifier) }) or {})[1]
end

local function targetData(identifier)
    local target = getQbxPlayer(identifier)
    if target and target.PlayerData then
        local source = target.PlayerData.source
        local ids = playerIdentifiers(source)
        ids.playerLicense = target.PlayerData.license

        return {
            online = true,
            source = source,
            citizenid = target.PlayerData.citizenid,
            license = persistentLicense(ids),
            discord = ids.discord,
            fivem = ids.fivem,
            ip = ids.ip,
            name = getPlayerNameFromData(target),
        }
    end

    local record = getOfflineRecord(identifier)
    if record then
        return {
            online = false,
            citizenid = record.citizenid,
            license = record.license,
            name = recordName(record),
        }
    end
end

local function rgbToLong(color)
    color = color or {}
    return ((tonumber(color.r) or 0) * 65536) + ((tonumber(color.g) or 0) * 256) + (tonumber(color.b) or 0)
end

function Service.canManage(source)
    return canManage(source)
end

local function refreshOnlineClients(config)
    config = config or Service.getConfig()

    CreateThread(function()
        for _, playerSource in ipairs(GetPlayers()) do
            local targetSource = tonumber(playerSource)
            if targetSource then
                pr_lib.callback.await(targetSource, PR.Whitelist.Callbacks.clientConfigUpdated, 1500, config)
            end
        end
    end)
end

function Service.getConfig()
    local fileConfig = readJsonConfig()
    if fileConfig then
        Service.config = fileConfig
        return fileConfig
    end

    if type(Service.config) == 'table' and next(Service.config) then
        return mergeDefaults(PR.Whitelist.Defaults, Service.config)
    end

    Service.config = clone(PR.Whitelist.Defaults)
    writeJsonConfig(Service.config)

    return mergeDefaults(PR.Whitelist.Defaults, Service.config)
end

function Service.saveConfig(source, config)
    if not canManage(source) then return false, 'no_permission' end

    local draft = mergeDefaults(PR.Whitelist.Defaults, config)
    if not writeJsonConfig(draft) then return false, 'json_save_failed' end
    Service.config = draft

    notify(source, {
        description = ForgeCore.t('notify.whitelist.config_saved'),
        type = 'success',
    })

    local freshConfig = Service.getConfig()
    refreshOnlineClients(freshConfig)

    return true, freshConfig
end

function Service.loadConfig()
    local fileConfig = readJsonConfig()
    if fileConfig then
        Service.config = fileConfig
        return fileConfig
    end

    local db = database()
    local stored = db and db.scalar(('SELECT `config` FROM `%s` WHERE `id` = 1 LIMIT 1'):format(PR.Whitelist.Storage.configTable))
    Service.config = stored and decodeConfig(stored) or legacyConfig() or clone(PR.Whitelist.Defaults)
    writeJsonConfig(Service.config)

    return mergeDefaults(PR.Whitelist.Defaults, Service.config)
end

function Service.check(source)
    local config = Service.getConfig()
    if not config.enabled then return true, config end

    local db = database()
    if not db then return false, pendingConfig(config, 'database_unavailable') end

    local player = waitForQbxPlayer(source)
    local citizenid = player and player.PlayerData and player.PlayerData.citizenid
    if not citizenid then return false, pendingConfig(config, 'player_not_loaded') end

    local identifiers = playerIdentifiers(source)
    identifiers.playerLicense = player.PlayerData.license
    local allowed = hasWhitelist(citizenid, identifiers) or hasWhitelistByPlayerRecord(citizenid)
    if allowed then
        syncWhitelistIdentifiers(citizenid, identifiers, getPlayerNameFromData(player))
        setPlayerBucket(source, 0)
    else
        setPlayerBucket(source, 1000 + source)
    end

    return allowed, config
end

function Service.listPlayers(source)
    if not canManage(source) then return false, 'no_permission' end

    local db = database()
    if not db then return false, 'database_unavailable' end

    local rows = db.query(([[ 
        SELECT p.citizenid, p.license, p.name, p.charinfo, w.citizen AS whitelisted
        FROM players p
        LEFT JOIN `%s` w ON w.citizen = p.citizenid OR (w.license IS NOT NULL AND w.license = p.license)
        ORDER BY whitelisted DESC, p.name ASC
        LIMIT 300
    ]]):format(PR.Whitelist.Storage.playersTable)) or {}

    local onlineByCitizen = {}
    for _, playerSource in ipairs(GetPlayers()) do
        local player = getQbxPlayer(tonumber(playerSource))
        local onlineCitizenid = player and player.PlayerData and player.PlayerData.citizenid
        if onlineCitizenid then
            onlineByCitizen[onlineCitizenid] = tonumber(playerSource)
        end
    end

    local players = {}
    local whitelisted = 0
    local pending = 0

    for _, row in ipairs(rows) do
        local has = row.whitelisted ~= nil
        if has then whitelisted = whitelisted + 1 else pending = pending + 1 end

        players[#players + 1] = {
            citizenid = row.citizenid,
            citizenId = row.citizenid,
            license = row.license,
            name = recordName(row),
            source = onlineByCitizen[row.citizenid],
            online = onlineByCitizen[row.citizenid] ~= nil,
            whitelisted = has,
        }
    end

    return true, {
        players = players,
        whitelisted = whitelisted,
        pending = pending,
    }
end

function Service.add(source, identifier)
    if source ~= 0 and identifier ~= nil and not canManage(source) then return false, 'no_permission' end

    local target = targetData(identifier or source)
    if not target or not target.citizenid then return false, 'invalid_player' end

    local db = database()
    if not db then return false, 'database_unavailable' end

    local citizenid = target.citizenid
    db.update(([[ 
        INSERT INTO `%s` (`citizen`, `license`, `discord`, `fivem`, `name`, `whitelisted_at`, `added_by`)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `license` = VALUES(`license`),
            `discord` = VALUES(`discord`),
            `fivem` = VALUES(`fivem`),
            `name` = VALUES(`name`),
            `whitelisted_at` = VALUES(`whitelisted_at`),
            `added_by` = VALUES(`added_by`)
    ]]):format(PR.Whitelist.Storage.playersTable), {
        citizenid,
        target.license,
        target.discord,
        target.fivem,
        target.name,
        os.time(),
        source and source > 0 and getCitizenid(source) or 'console',
    })

    if target.online and target.source then
        setPlayerBucket(target.source, 0)
        pr_lib.callback.await(target.source, PR.Whitelist.Callbacks.clientAdded, 5000)
    end

    if source and source > 0 and source ~= target.source then
        notify(source, {
            description = ForgeCore.t('notify.whitelist.added', { citizenid = citizenid }),
            type = 'success',
        })
    end

    return true, citizenid
end

function Service.remove(source, identifier)
    if not canManage(source) then return false, 'no_permission' end

    local target = targetData(identifier)
    if not target or not target.citizenid then return false, 'invalid_player' end

    local db = database()
    if not db then return false, 'database_unavailable' end

    local citizenid = target.citizenid
    db.update(('DELETE FROM `%s` WHERE `citizen` = ?'):format(PR.Whitelist.Storage.playersTable), { citizenid })

    if target.online and target.source then
        setPlayerBucket(target.source, 1000 + target.source)
        pr_lib.callback.await(target.source, PR.Whitelist.Callbacks.clientRemoved, 5000, Service.getConfig())
    end

    notify(source, {
        description = ForgeCore.t('notify.whitelist.removed', { citizenid = citizenid }),
        type = 'success',
    })

    return true, citizenid
end

function Service.ban(source, data)
    if not canManage(source) then return false, 'no_permission' end

    data = type(data) == 'table' and data or {}
    local target = targetData(data.identifier or data.citizenid or data.source)
    if not target or not target.citizenid then return false, 'invalid_player' end

    local db = database()
    if not db then return false, 'database_unavailable' end

    local reason = tostring(data.reason or 'Banido pela whitelist')
    local hours = tonumber(data.hours) or 0
    local days = tonumber(data.days) or 0
    local months = tonumber(data.months) or 0
    local duration = (hours * 3600) + (days * 86400) + (months * 2629743)
    local expire = duration > 0 and (os.time() + duration) or 2147483647

    Service.remove(source, target.citizenid)

    db.update('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        target.name or target.citizenid,
        target.license,
        target.discord,
        target.ip,
        reason,
        expire,
        source > 0 and GetPlayerName(source) or 'Forge Core',
    })

    if target.online and target.source then
        DropPlayer(target.source, reason)
    end

    notify(source, {
        description = ForgeCore.t('notify.whitelist.banned', { citizenid = target.citizenid }),
        type = 'success',
    })

    return true, target.citizenid
end

function Service.submitPreExam(source, data)
    local config=Service.getConfig(); local preExam=config.preExam or {}; local player=getQbxPlayer(source)
    if not player or not player.PlayerData then return false,'invalid_player' end
    local db=database()
    if db then
        local rows=db.query(('SELECT `answers` FROM `%s` WHERE `citizen` = ? LIMIT 1'):format(PR.Whitelist.Storage.answersTable),{player.PlayerData.citizenid}) or {}
        local stored={}
        if rows[1] and rows[1].answers then local ok,decoded=pcall(json.decode,rows[1].answers);if ok and type(decoded)=='table'then stored=decoded end end
        for label,answer in pairs(type(data)=='table' and data or {})do stored[label]=answer end
        db.update(([[INSERT INTO `%s` (`citizen`, `answers`, `submitted_at`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `answers`=VALUES(`answers`), `submitted_at`=VALUES(`submitted_at`)]]):format(PR.Whitelist.Storage.answersTable),{player.PlayerData.citizenid,json.encode(stored),os.time()})
    end
    if not preExam.webhook or preExam.webhook=='' then return true end
    local fields={{name='Identificador',value=tostring(player.PlayerData.name or source),inline=true},{name='CitizenID',value=tostring(player.PlayerData.citizenid or ''),inline=true}}
    local charinfo=player.PlayerData.charinfo or {}; fields[#fields+1]={name='Nome do personagem',value=('%s %s'):format(charinfo.firstname or '',charinfo.lastname or ''),inline=false}
    for label,item in pairs(type(data)=='table' and data or {}) do local value=item.value; if item.kind=='phone' and preExam.formatPhone then value=('https://wa.me/55%s'):format(value) end; fields[#fields+1]={name=tostring(label),value=tostring(value or ''),inline=false} end
    local payload=json.encode({embeds={{title='Dados Pre-Exame',fields=fields,footer={text='Forge Core - '..os.date('%d/%m/%Y %X')},color=rgbToLong({r=0,g=255,b=255})}}})
    PerformHttpRequest(preExam.webhook,function()end,'POST',payload,{['Content-Type']='application/json'}); return true
end

function Service.getPlayerRecord(source, identifier)
    if not canManage(source) then return false, 'no_permission' end
    local target = targetData(identifier)
    if not target or not target.citizenid then return false, 'invalid_player' end
    local db = database()
    if not db then return false, 'database_unavailable' end
    local whitelistRows = db.query(('SELECT `citizen`, `whitelisted_at`, `added_by`, `name` FROM `%s` WHERE `citizen` = ? LIMIT 1'):format(PR.Whitelist.Storage.playersTable), { target.citizenid }) or {}
    local submittedRows = db.query(('SELECT `answers`, `submitted_at` FROM `%s` WHERE `citizen` = ? LIMIT 1'):format(PR.Whitelist.Storage.answersTable), { target.citizenid }) or {}
    local whitelist = whitelistRows[1]
    local submitted = submittedRows[1]
    local answers = {}
    if submitted and submitted.answers then
        local ok, decoded = pcall(json.decode, submitted.answers)
        if ok and type(decoded) == 'table' then answers = decoded end
    end
    return true, { citizenid = target.citizenid, whitelisted = whitelist ~= nil, whitelistedAt = whitelist and whitelist.whitelisted_at or nil, addedBy = whitelist and whitelist.added_by or nil, answers = answers, submittedAt = submitted and submitted.submitted_at or nil }
end
function Service.start()
    if Service.started then return true end
    Service.started = true

    if ensureSchema() then
        migrateLegacyPlayers()
        Service.loadConfig()
    else
        Service.loadConfig()
    end

    debug('success', ForgeCore.t('debug.whitelist.started'))
    return true
end

pr_lib.wrapJsonMutations(configPath(), Service, { 'saveConfig' })

ForgeCore.WhitelistService = Service
