ForgeCore = ForgeCore or {}

local Storage = {}
local resourceName = GetCurrentResourceName()

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

local function encodeJson(data)
    local ok, encoded = pcall(json.encode, data or {})
    if ok and encoded then return encoded end

    debug('error', ForgeCore.t('debug.storage.encode_failed', { error = tostring(encoded) }))
    return '{}'
end

local function decodeJson(content, fallback, path)
    if type(content) ~= 'string' or content == '' then return fallback end

    local ok, decoded = pcall(json.decode, content)
    if ok and type(decoded) == 'table' then return decoded end

    debug('warn', ForgeCore.t('debug.storage.invalid_json', { path = path }))
    return fallback
end

function Storage.load()
    local path = PR.Skills.Storage.file
    return decodeJson(LoadResourceFile(resourceName, path), {}, path)
end

function Storage.save(data)
    local path = PR.Skills.Storage.file
    local saved = SaveResourceFile(resourceName, path, encodeJson(data), -1)
    if not saved then
        debug('error', ForgeCore.t('debug.storage.save_failed', { path = path }))
    end

    return saved ~= false and saved ~= nil
end

ForgeCore.SkillStorage = Storage
