ForgeCore = ForgeCore or {}

local Service = {
    started = false,
    state = {},
    incidents = {},
}

local resourceName = GetCurrentResourceName()

local function logStarter(level, message)
    level = level or 'info'
    message = tostring(message or '')

    local debugApi = pr_lib and pr_lib.debug
    local fn = debugApi and debugApi[level]
    if type(fn) == 'function' then
        fn(('[forge-core:starterpack] %s'):format(message))
        if level ~= 'warn' and level ~= 'error' then return end
    end

    if PR.Debug == true or level == 'warn' or level == 'error' then
        print(('[forge-core:starterpack][%s] %s'):format(level, message))
    end
end

local function notify(source, data)
    if not source or source <= 0 then return end
    if not pr_lib or not pr_lib.notify or not pr_lib.notify.NotifyPlayer then return end

    pr_lib.notify.NotifyPlayer(source, {
        title = data.title or ForgeCore.t('starterpack.title'),
        description = data.description,
        type = data.type,
        position = data.position or PR.NotifyPos,
    })
end

local function clone(value)
    return pr_lib and pr_lib.table and pr_lib.table.clone and pr_lib.table.clone(value) or value
end

local function trim(value)
    if pr_lib and pr_lib.utils and pr_lib.utils.trim then return pr_lib.utils.trim(value) end
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function boolValue(value, fallback)
    if value == nil then return fallback == true end
    if type(value) == 'boolean' then return value end

    local lowered = tostring(value):lower()
    return lowered == 'true' or lowered == '1' or lowered == 'yes' or lowered == 'sim'
end

local function numberValue(value, fallback)
    return tonumber(value) or fallback or 0
end

local function normalizeId(value)
    value = trim(value):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    value = value:gsub('_+', '_'):gsub('^_+', ''):gsub('_+$', '')
    return value
end

local function readJson(path, fallback)
    return pr_lib.loadJsonRecovery(path) or clone(fallback)
end

local function writeJson(path, data, frequent)
    return pr_lib.saveJsonRecovery(path, data, { backup = frequent and 'on_failure' or 'always' })
end

local function canManage(source)
    if source == 0 then return true end
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end

    return IsPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function playerData(source)
    if pr_lib and pr_lib.framework and pr_lib.framework.GetPlayerData then
        local data = pr_lib.framework.GetPlayerData(source)
        if type(data) == 'table' then return data end
    end

    return {}
end

local function citizenId(source)
    local data = playerData(source)
    return trim(data.citizenid or data.citizenId or data.citizenID or '')
end

local function playerName(source)
    local data = playerData(source)
    local charinfo = type(data.charinfo) == 'table' and data.charinfo or {}
    local full = trim(('%s %s'):format(charinfo.firstname or '', charinfo.lastname or ''))
    return full ~= '' and full or GetPlayerName(source) or tostring(source)
end

local function itemExists(name)
    name = trim(name)
    if name == '' then return false end
    if not pr_lib or not pr_lib.inventory or not pr_lib.inventory.Items then return true end

    return pr_lib.inventory.Items(name) ~= nil
end

local function itemLabel(name)
    name = trim(name)
    if pr_lib and pr_lib.inventory then
        if pr_lib.inventory.GetItemLabel then
            local label = pr_lib.inventory.GetItemLabel(name)
            if label and label ~= '' then return label end
        end

        if pr_lib.inventory.Items then
            local item = pr_lib.inventory.Items(name)
            if type(item) == 'table' and item.label then return item.label end
        end
    end

    return name
end

local function canCarry(source, name, count, metadata)
    if pr_lib and pr_lib.inventory and pr_lib.inventory.CanCarryItem then
        local ok = pr_lib.inventory.CanCarryItem(source, name, count, metadata)
        if ok ~= nil then return ok == true end
    end

    if GetResourceState('ox_inventory'):find('start') ~= nil then
        local ok = exports.ox_inventory:CanCarryItem(source, name, count, metadata)
        if ok ~= nil then return ok == true end
    end

    return true
end

local function addItem(source, name, count, metadata)
    if pr_lib and pr_lib.inventory and pr_lib.inventory.AddItem then
        return pr_lib.inventory.AddItem(source, name, count, metadata)
    end

    if GetResourceState('ox_inventory'):find('start') ~= nil then
        return exports.ox_inventory:AddItem(source, name, count, metadata)
    end

    return false
end

local function normalizeCoords(value)
    value = type(value) == 'table' and value or {}
    return {
        x = numberValue(value.x or value[1]),
        y = numberValue(value.y or value[2]),
        z = numberValue(value.z or value[3]),
    }
end

local function normalizeSettings(settings)
    settings = type(settings) == 'table' and settings or {}
    local defaults = PR.Starterpack.Defaults.settings

    return {
        enabled = boolValue(settings.enabled, defaults.enabled),
        oncePerCharacter = boolValue(settings.oncePerCharacter, defaults.oncePerCharacter),
        autoGiveOnFirstJoin = boolValue(settings.autoGiveOnFirstJoin, defaults.autoGiveOnFirstJoin),
    }
end

local function normalizeItem(item)
    item = type(item) == 'table' and item or {}

    local name = trim(item.name)
    local id = normalizeId(item.id ~= nil and item.id or name)
    local count = math.max(1, math.floor(numberValue(item.count, 1)))
    local label = trim(item.label)

    return {
        id = id ~= '' and id or normalizeId(name),
        name = name,
        label = label ~= '' and label or itemLabel(name),
        count = count,
        enabled = boolValue(item.enabled, true),
        metadata = type(item.metadata) == 'table' and item.metadata or {},
    }
end

local function normalizeReward(reward, index)
    reward = type(reward) == 'table' and reward or {}

    local item = trim(reward.item or reward.name)
    local progress = math.max(0, math.min(100, math.floor(numberValue(reward.progress, 0))))
    local id = normalizeId(reward.id ~= nil and reward.id or ('%s_%s_%s'):format(item, progress, index or 1))
    local dialogue = trim(reward.dialogue or reward.text)

    return {
        id = id ~= '' and id or ('reward_%s'):format(os.time()),
        item = item,
        count = math.max(1, math.floor(numberValue(reward.count, 1))),
        progress = progress,
        dialogue = dialogue,
        duration = math.max(1000, math.floor(numberValue(reward.duration, 5000))),
        enabled = boolValue(reward.enabled, true),
        metadata = type(reward.metadata) == 'table' and reward.metadata or {},
    }
end

local function normalizeStop(stop)
    stop = type(stop) == 'table' and stop or {}

    local title = trim(stop.title)
    local id = normalizeId(stop.id ~= nil and stop.id or title)
    local frames = {}
    local dialogs = {}
    local rewards = {}

    for _, frame in ipairs(type(stop.cameraFrames) == 'table' and stop.cameraFrames or {}) do
        frame = type(frame) == 'table' and frame or {}
        frames[#frames + 1] = {
            coords = normalizeCoords(frame.coords),
            rot = normalizeCoords(frame.rot),
            fov = numberValue(frame.fov, 50.0),
            duration = math.max(250, math.floor(numberValue(frame.duration, 2500))),
        }
    end

    for _, dialog in ipairs(type(stop.routeDialogs) == 'table' and stop.routeDialogs or {}) do
        dialog = type(dialog) == 'table' and dialog or {}
        local text = trim(dialog.text)
        if text ~= '' then
            local progress = math.max(0, math.min(100, math.floor(numberValue(dialog.progress, 0))))
            dialogs[#dialogs + 1] = {
                id = normalizeId(dialog.id ~= nil and dialog.id or text) ~= '' and normalizeId(dialog.id ~= nil and dialog.id or text) or ('dialog_%s'):format(#dialogs + 1),
                text = text,
                progress = progress,
                duration = math.max(1000, math.floor(numberValue(dialog.duration, 5000))),
            }
        end
    end

    table.sort(dialogs, function(left, right)
        return (tonumber(left.progress) or 0) < (tonumber(right.progress) or 0)
    end)

    for rewardIndex, reward in ipairs(type(stop.rewards) == 'table' and stop.rewards or {}) do
        local normalized = normalizeReward(reward, rewardIndex)
        if normalized.id ~= '' and normalized.item ~= '' then
            rewards[#rewards + 1] = normalized
        end
    end

    table.sort(rewards, function(left, right)
        return (tonumber(left.progress) or 0) < (tonumber(right.progress) or 0)
    end)

    return {
        id = id ~= '' and id or ('stop_%s'):format(os.time()),
        title = title ~= '' and title or ForgeCore.t('menu.starterpack.stop_default_title'),
        enabled = boolValue(stop.enabled, true),
        coords = normalizeCoords(stop.coords),
        heading = numberValue(stop.heading),
        blipSprite = math.floor(numberValue(stop.blipSprite, 1)),
        blipColor = math.floor(numberValue(stop.blipColor, 5)),
        routeText = trim(stop.routeText),
        arrivalText = trim(stop.arrivalText),
        nextText = trim(stop.nextText),
        routeDialogs = dialogs,
        rewards = rewards,
        cameraFrames = frames,
    }
end

local function normalizePrologue(prologue)
    prologue = type(prologue) == 'table' and prologue or {}
    local defaults = PR.Starterpack.Defaults.prologue
    local stops = {}
    local legacyStart = type(prologue.start) == 'table' and prologue.start or {}
    local vehicleStart = type(prologue.vehicleStart) == 'table' and prologue.vehicleStart or legacyStart
    local lamarStart = type(prologue.lamarStart) == 'table' and prologue.lamarStart or {}

    for _, stop in ipairs(type(prologue.stops) == 'table' and prologue.stops or {}) do
        local normalized = normalizeStop(stop)
        if normalized.id ~= '' then stops[#stops + 1] = normalized end
    end

    return {
        enabled = boolValue(prologue.enabled, defaults.enabled),
        lamarModel = trim(prologue.lamarModel) ~= '' and trim(prologue.lamarModel) or defaults.lamarModel,
        vehicleModel = trim(prologue.vehicleModel) ~= '' and trim(prologue.vehicleModel) or defaults.vehicleModel,
        autopilotMaxSpeed = math.max(5.0, math.min(60.0, numberValue(prologue.autopilotMaxSpeed, defaults.autopilotMaxSpeed or 22.0))),
        finishBehavior = trim(prologue.finishBehavior) ~= '' and trim(prologue.finishBehavior) or defaults.finishBehavior,
        start = {
            coords = normalizeCoords(type(vehicleStart) == 'table' and vehicleStart.coords or nil),
            heading = numberValue(type(vehicleStart) == 'table' and vehicleStart.heading, 0.0),
        },
        vehicleStart = {
            coords = normalizeCoords(type(vehicleStart) == 'table' and vehicleStart.coords or nil),
            heading = numberValue(type(vehicleStart) == 'table' and vehicleStart.heading, 0.0),
        },
        lamarStart = {
            coords = normalizeCoords(type(lamarStart) == 'table' and lamarStart.coords or nil),
            heading = numberValue(type(lamarStart) == 'table' and lamarStart.heading, 0.0),
        },
        stops = stops,
    }
end

local function normalizeState(state)
    state = type(state) == 'table' and state or {}

    local items = {}
    for _, item in ipairs(type(state.items) == 'table' and state.items or {}) do
        local normalized = normalizeItem(item)
        if normalized.id ~= '' and normalized.name ~= '' then items[#items + 1] = normalized end
    end

    return {
        settings = normalizeSettings(state.settings),
        items = items,
        claimed = type(state.claimed) == 'table' and state.claimed or {},
        rewardClaims = type(state.rewardClaims) == 'table' and state.rewardClaims or {},
        prologue = normalizePrologue(state.prologue),
    }
end

local function claimedCount(claimed)
    local total = 0
    for _ in pairs(type(claimed) == 'table' and claimed or {}) do
        total = total + 1
    end
    return total
end

local function publicPayload()
    return {
        settings = clone(Service.state.settings),
        items = clone(Service.state.items),
        prologue = clone(Service.state.prologue),
        claimedCount = claimedCount(Service.state.claimed),
    }
end

local function saveState(draft, frequent)
    draft = normalizeState(draft)
    local saved = writeJson(PR.Starterpack.Storage.file, draft, frequent)
    if saved then
        Service.state = draft
        ForgeCore.State.publish('starterpack', publicPayload())
    end
    return saved
end

local function recordIncident(source, operation, details)
    local cid = citizenId(source)
    Service.incidents[cid] = { at = os.time(), operation = operation, details = details }
    pr_lib.recordJsonIncident(PR.Starterpack.Storage.file, cid, Service.incidents[cid])
    return false, 'reconciliation_required'
end

local function undoGrants(source, granted)
    local failed = {}
    for index = #granted, 1, -1 do
        local item = granted[index]
        local ok, removed = pcall(pr_lib.inventory.RemoveItem, source, item.name, item.count, item.metadata)
        if not ok or removed ~= true then failed[#failed + 1] = item end
    end
    if #failed > 0 then return recordIncident(source, 'starterpack-rollback', failed) end
    return true
end

local function grant(source, item, granted)
    local ok, added = pcall(addItem, source, item.name, item.count, item.metadata)
    if not ok then return recordIncident(source, 'starterpack-grant-error', item) end
    if added ~= true then return false, 'add_failed' end
    granted[#granted + 1] = item
    return true
end

local function itemById(itemId, state)
    itemId = trim(itemId)
    for index, item in ipairs((state or Service.state).items or {}) do
        if item.id == itemId then return item, index end
    end

    return nil, nil
end

local function stopById(stopId, state)
    stopId = trim(stopId)
    for index, stop in ipairs((state or Service.state).prologue.stops or {}) do
        if stop.id == stopId then return stop, index end
    end

    return nil, nil
end

local function rewardById(stop, rewardId)
    rewardId = trim(rewardId)
    for index, reward in ipairs(stop and stop.rewards or {}) do
        if reward.id == rewardId then return reward, index end
    end

    return nil, nil
end

function Service.getAll()
    return publicPayload()
end

function Service.canManage(source)
    return canManage(source)
end

function Service.load()
    Service.state = normalizeState(readJson(PR.Starterpack.Storage.file, PR.Starterpack.Defaults))
    Service.incidents = pr_lib.loadJsonRecovery(PR.Starterpack.Storage.file .. '.incidents.json') or {}
    ForgeCore.State.publish('starterpack',publicPayload())
    return Service.state
end

function Service.saveSettings(source, settings)
    local draft = pr_lib.jsonDraft(Service.state, {})
    if not canManage(source) then return false, 'no_permission' end

    draft.settings = normalizeSettings(settings)
    if not saveState(draft) then return false, 'save_failed' end

    notify(source, { description = ForgeCore.t('notify.starterpack.settings_saved'), type = 'success' })
    return true, publicPayload()
end

function Service.savePrologue(source, prologue)
    local draft = pr_lib.jsonDraft(Service.state, {})
    if not canManage(source) then return false, 'no_permission' end

    draft.prologue = normalizePrologue(prologue)
    if not saveState(draft) then return false, 'save_failed' end

    notify(source, { description = ForgeCore.t('notify.starterpack.prologue_saved'), type = 'success' })
    return true, publicPayload()
end

function Service.setItem(source, item)
    local draft = pr_lib.jsonDraft(Service.state, { items = 'shallow' })
    if not canManage(source) then return false, 'no_permission' end

    local normalized = normalizeItem(item)
    if normalized.name == '' or normalized.id == '' then return false, 'invalid_item' end
    if not itemExists(normalized.name) then return false, 'invalid_item' end

    local _, index = itemById(normalized.id, draft)
    if index then
        draft.items[index] = normalized
    else
        draft.items[#draft.items + 1] = normalized
    end

    if not saveState(draft) then return false, 'save_failed' end
    notify(source, { description = ForgeCore.t('notify.starterpack.item_saved'), type = 'success' })
    return true, publicPayload()
end

function Service.removeItem(source, itemId)
    local draft = pr_lib.jsonDraft(Service.state, { items = 'shallow' })
    if not canManage(source) then return false, 'no_permission' end

    local _, index = itemById(itemId, draft)
    if not index then return false, 'item_not_found' end

    table.remove(draft.items, index)
    if not saveState(draft) then return false, 'save_failed' end

    notify(source, { description = ForgeCore.t('notify.starterpack.item_removed'), type = 'success' })
    return true, publicPayload()
end

function Service.setStop(source, stop)
    local draft = pr_lib.jsonDraft(Service.state, { prologue = { stops = 'shallow' } })
    if not canManage(source) then return false, 'no_permission' end

    local normalized = normalizeStop(stop)
    if normalized.id == '' then return false, 'invalid_stop' end

    local _, index = stopById(normalized.id, draft)
    if index then
        draft.prologue.stops[index] = normalized
    else
        draft.prologue.stops[#draft.prologue.stops + 1] = normalized
    end

    if not saveState(draft) then return false, 'save_failed' end
    notify(source, { description = ForgeCore.t('notify.starterpack.stop_saved'), type = 'success' })
    return true, publicPayload()
end

function Service.removeStop(source, stopId)
    local draft = pr_lib.jsonDraft(Service.state, { prologue = { stops = 'shallow' } })
    if not canManage(source) then return false, 'no_permission' end

    local _, index = stopById(stopId, draft)
    if not index then return false, 'stop_not_found' end

    table.remove(draft.prologue.stops, index)
    if not saveState(draft) then return false, 'save_failed' end

    notify(source, { description = ForgeCore.t('notify.starterpack.stop_removed'), type = 'success' })
    return true, publicPayload()
end

function Service.claim(source, forced)
    local draft = Service.state -- read-only until validation succeeds
    if Service.incidents[citizenId(source)] then return false, 'reconciliation_required' end
    local settings = draft.settings or {}
    if settings.enabled ~= true and forced ~= true then return false, 'disabled' end

    local cid = citizenId(source)
    if cid == '' then return false, 'player_not_ready' end
    if settings.oncePerCharacter == true and draft.claimed[cid] and forced ~= true then return false, 'already_claimed' end
    if #(draft.items or {}) <= 0 then return false, 'no_items' end

    local giveList = {}
    for _, item in ipairs(draft.items or {}) do
        if item.enabled == true then
            if not itemExists(item.name) then return false, ('invalid_item:%s'):format(item.name) end
            if not canCarry(source, item.name, item.count, item.metadata) then return false, ('cannot_carry:%s'):format(item.name) end
            giveList[#giveList + 1] = item
        end
    end

    if #giveList <= 0 then return false, 'no_items' end

    draft = pr_lib.jsonDraft(Service.state, { claimed = 'shallow' })
    local granted = {}
    for _, item in ipairs(giveList) do
        local ok, err = grant(source, item, granted)
        if not ok then
            local restored = undoGrants(source, granted)
            return false, restored and err or 'reconciliation_required'
        end
    end

    draft.claimed[cid] = {
        at = os.time(),
        name = playerName(source),
        source = source,
    }

    if not saveState(draft, true) then
        local restored = undoGrants(source, granted)
        return false, restored and 'save_failed' or 'reconciliation_required'
    end

    notify(source, { description = ForgeCore.t('notify.starterpack.claimed'), type = 'success' })
    return true, publicPayload()
end

function Service.giveToPlayer(source, targetSource)
    if not canManage(source) then return false, 'no_permission' end

    targetSource = tonumber(targetSource)
    if not targetSource or targetSource <= 0 or not GetPlayerName(targetSource) then return false, 'invalid_player' end

    return Service.claim(targetSource, true)
end

function Service.startPrologueTest(source, targetSource)
    if not canManage(source) then return false, 'no_permission' end

    targetSource = tonumber(targetSource)
    if not targetSource or targetSource <= 0 or not GetPlayerName(targetSource) then return false, 'invalid_player' end

    TriggerClientEvent(PR.Starterpack.Events.startTest, targetSource, publicPayload())
    return true, publicPayload()
end

function Service.grantReward(source, stopId, rewardId)
    local draft = Service.state -- read-only until validation succeeds
    local cid = citizenId(source)
    if Service.incidents[cid] then return false, 'reconciliation_required' end
    if cid == '' then return false, 'player_not_ready' end

    local stop = stopById(stopId, draft)
    local reward = rewardById(stop, rewardId)
    if not stop or not reward then return false, 'reward_not_found' end
    if reward.enabled ~= true then return false, 'reward_disabled' end
    if not itemExists(reward.item) then return false, ('invalid_item:%s'):format(reward.item) end

    local claimKey = ('%s:%s:%s'):format(cid, stop.id, reward.id)
    if draft.settings.oncePerCharacter == true and draft.rewardClaims[claimKey] then
        return true, 'already_granted'
    end
    if not canCarry(source, reward.item, reward.count, reward.metadata) then
        return false, ('cannot_carry:%s'):format(reward.item)
    end

    draft = pr_lib.jsonDraft(Service.state, { rewardClaims = 'shallow' })
    local granted = {}
    local ok, err = grant(source, { name = reward.item, count = reward.count, metadata = reward.metadata }, granted)
    if not ok then return false, err end

    draft.rewardClaims[claimKey] = {
        at = os.time(),
        citizenid = cid,
        item = reward.item,
        count = reward.count,
    }

    if not saveState(draft, true) then
        local restored = undoGrants(source, granted)
        return false, restored and 'save_failed' or 'reconciliation_required'
    end

    return true, reward
end

function Service.completePrologue(source)
    local draft = Service.state -- read-only until validation succeeds
    local settings = draft.settings or {}
    if settings.enabled ~= true then return false, 'disabled' end

    local cid = citizenId(source)
    if cid == '' then return false, 'player_not_ready' end
    if Service.incidents[cid] then return false, 'reconciliation_required' end
    if settings.oncePerCharacter == true and draft.claimed[cid] then return true, 'already_claimed' end

    draft = pr_lib.jsonDraft(Service.state, { claimed = 'shallow' })
    draft.claimed[cid] = {
        at = os.time(),
        name = playerName(source),
        source = source,
        prologue = true,
    }

    if not saveState(draft, true) then return false, 'save_failed' end

    return true, publicPayload()
end

function Service.resetClaim(source, cid)
    local draft = pr_lib.jsonDraft(Service.state, { claimed = 'shallow', rewardClaims = 'shallow' })
    if not canManage(source) then return false, 'no_permission' end

    cid = trim(cid)
    if cid == '' then return false, 'invalid_citizenid' end
    if Service.incidents[cid] then return false, 'reconciliation_required' end
    draft.claimed[cid] = nil
    for key in pairs(draft.rewardClaims or {}) do
        if key:sub(1, #cid + 1) == cid .. ':' then
            draft.rewardClaims[key] = nil
        end
    end

    if not saveState(draft) then return false, 'save_failed' end
    notify(source, { description = ForgeCore.t('notify.starterpack.claim_reset'), type = 'success' })
    return true, publicPayload()
end

function Service.handlePlayerLoaded(source)
    if not Service.started then return end
    if not Service.state.settings or Service.state.settings.autoGiveOnFirstJoin ~= true then return end

    local loadedCharacter = citizenId(source)
    SetTimeout(3500, function()
        if loadedCharacter ~= '' and GetPlayerName(source) and citizenId(source) == loadedCharacter then
            Service.claim(source, false)
        end
    end)
end

function Service.start()
    if Service.started then return true end

    Service.started = true
    Service.load()
    logStarter('success', ForgeCore.t('debug.starterpack.started'))
    return true
end

pr_lib.wrapJsonMutations(PR.Starterpack.Storage.file, Service, {
    'saveSettings', 'savePrologue', 'setItem', 'removeItem', 'setStop', 'removeStop', 'claim', 'grantReward', 'completePrologue', 'resetClaim',
})

ForgeCore.StarterpackService = Service
