ForgeCore = ForgeCore or {}

function ForgeCore.isPlayerAceAllowed(source, permission)
    if source == 0 then return true end
    if type(permission) ~= 'string' or permission == '' then return false end

    local aceApi = pr_lib and pr_lib.ace
    if aceApi and type(aceApi.isPlayerAceAllowed) == 'function' then
        local allowed = aceApi.isPlayerAceAllowed(source, permission)
        return allowed == true or allowed == 1
    end

    local ok, allowed = pcall(IsPlayerAceAllowed, tonumber(source) or source, permission)
    return ok and (allowed == true or allowed == 1)
end

local Security = {
    registrations = {},
    buckets = {},
}

local DEFAULT_LIMIT = 15
local DEFAULT_WINDOW = 5000
local MAX_PAYLOAD_BYTES = 65536
local adminCallbacks = {}

local function markAdmin(callbacks)
    for _, name in pairs(callbacks or {}) do
        adminCallbacks[name] = true
    end
end

local function markSelected(callbacks, keys)
    callbacks = callbacks or {}
    for i = 1, #keys do
        local name = callbacks[keys[i]]
        if name then adminCallbacks[name] = true end
    end
end

markAdmin(PR.Afk and PR.Afk.Callbacks)
markAdmin(PR.DatabaseBackup and PR.DatabaseBackup.Callbacks)
markAdmin(PR.Density and PR.Density.Callbacks)
markAdmin(PR.Inventory and PR.Inventory.Callbacks)
markAdmin(PR.Vehicles and PR.Vehicles.Callbacks)
markAdmin(PR.Password and PR.Password.Callbacks)
markAdmin(PR.Staff and PR.Staff.Callbacks)
markAdmin(PR.Vinewood and PR.Vinewood.Callbacks)
markAdmin(PR.Weapons and PR.Weapons.Callbacks)
markAdmin(PR.Weather and PR.Weather.Callbacks)
markSelected(PR.AutoMedic and PR.AutoMedic.Callbacks, {
    'getSettings', 'saveSettings',
})

markSelected(PR.Job and PR.Job.Callbacks, {
    'saveGroup', 'deleteGroup', 'savePaymentSettings', 'forcePayment', 'saveMeiSettings',
})
markSelected(PR.MultiJob and PR.MultiJob.Callbacks, {
    'getSettings', 'saveSettings', 'addJob', 'removeJob', 'getTargetJobs',
})
markSelected(PR.Vip and PR.Vip.Callbacks, {
    'get', 'getTiers', 'saveTier', 'deleteTier', 'grant', 'revoke',
})
markAdmin(PR.PlayerManagement and PR.PlayerManagement.Callbacks)
markAdmin(PR.CharacterSlots and PR.CharacterSlots.callbacks)
markSelected(PR.Whitelist and PR.Whitelist.Callbacks, {
    'getConfig', 'saveConfig', 'listPlayers', 'add', 'remove', 'ban',
})
markSelected(PR.Farms and PR.Farms.Callbacks, {
    'saveSettings', 'createFarm', 'updateFarm', 'deleteFarm',
})
markSelected(PR.Skills and PR.Skills.Callbacks, {
    'saveSkill', 'deleteSkill', 'saveReputation', 'deleteReputation', 'addXp',
})
markSelected(PR.Starterpack and PR.Starterpack.Callbacks, {
    'saveSettings', 'savePrologue', 'setItem', 'removeItem', 'setStop', 'removeStop',
    'giveToPlayer', 'resetClaim',
})
markSelected(PR.Stores and PR.Stores.Callbacks, {
    'saveSettings', 'createStore', 'updateStore', 'deleteStore',
})

for _, module in ipairs({ PR.Billboards, PR.Npcs, PR.Objects, PR.Spotlights }) do
    local callbacks = module and module.Callbacks or {}
    for key, name in pairs(callbacks) do
        if key ~= 'getAll' then adminCallbacks[name] = true end
    end
end

local function canManage(source)
    if source == 0 then return true end
    if ForgeCore.JobService and ForgeCore.JobService.canManage then
        return ForgeCore.JobService.canManage(source)
    end
    return ForgeCore.isPlayerAceAllowed(source, PR.AdminAce or 'forge-core.admin')
end

local function payloadSize(...)
    local ok, encoded = pcall(json.encode, { ... })
    if not ok then return MAX_PAYLOAD_BYTES + 1 end
    return #encoded
end

local function consume(source, name, limit, window)
    local now = GetGameTimer()
    local key = ('%s:%s'):format(source, name)
    local bucket = Security.buckets[key]

    if not bucket or now - bucket.started >= window then
        Security.buckets[key] = { started = now, count = 1 }
        return true
    end

    bucket.count = bucket.count + 1
    return bucket.count <= limit
end

local function deny(source, name, reason)
    print(('[forge-core] callback denied source=%s name=%s reason=%s'):format(source, name, reason))
    return false, reason
end

function Security.register(name, handler, options)
    assert(type(name) == 'string' and name ~= '', 'callback name must be a non-empty string')
    assert(type(handler) == 'function', ('callback %s handler must be a function'):format(name))

    options = type(options) == 'table' and options or {}
    local access = options.access or (adminCallbacks[name] and 'admin' or 'player')
    local limit = math.max(1, math.floor(tonumber(options.limit) or DEFAULT_LIMIT))
    local window = math.max(1000, math.floor(tonumber(options.window) or DEFAULT_WINDOW))
    local maxPayload = math.max(1024, math.floor(tonumber(options.maxPayload) or MAX_PAYLOAD_BYTES))

    Security.registrations[name] = {
        access = access,
        limit = limit,
        window = window,
        maxPayload = maxPayload,
    }

    return pr_lib.callback.register(name, function(source, ...)
        source = tonumber(source) or 0
        if source <= 0 or GetPlayerPing(source) <= 0 then
            return deny(source, name, 'invalid_player')
        end
        if access == 'admin' and not canManage(source) then
            return deny(source, name, 'no_permission')
        end
        if not consume(source, name, limit, window) then
            return deny(source, name, 'rate_limited')
        end
        if payloadSize(...) > maxPayload then
            return deny(source, name, 'payload_too_large')
        end

        local result = table.pack(pcall(handler, source, ...))
        if not result[1] then
            print(('[forge-core] callback failed source=%s name=%s error=%s'):format(source, name, tostring(result[2])))
            return false, 'internal_error'
        end

        return table.unpack(result, 2, result.n)
    end)
end

function Security.getRegistrations()
    return Security.registrations
end

AddEventHandler('playerDropped', function()
    local prefix = ('%s:'):format(source)
    for key in pairs(Security.buckets) do
        if key:sub(1, #prefix) == prefix then Security.buckets[key] = nil end
    end
end)

ForgeCore.Callbacks = Security