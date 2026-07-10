ForgeCore = ForgeCore or {}

local Storage = {}
local resourceName = GetCurrentResourceName()

local function encodeJson(data)
    local ok, encoded = pcall(json.encode, data or {})
    if ok and encoded then return encoded end
    return '{}'
end

local function decodeJson(content, fallback)
    if type(content) ~= 'string' or content == '' then return fallback end

    local ok, decoded = pcall(json.decode, content)
    if ok and type(decoded) == 'table' then return decoded end

    return fallback
end

function Storage.load()
    return decodeJson(LoadResourceFile(resourceName, PR.Weapons.Storage.file), {})
end

function Storage.save(weapons)
    local saved = SaveResourceFile(resourceName, PR.Weapons.Storage.file, encodeJson(weapons), -1)
    return saved ~= false and saved ~= nil
end

ForgeCore.WeaponStorage = Storage
