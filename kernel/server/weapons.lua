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
    assert(type(core.Shared) == 'table' and type(core.Shared.Weapons) == 'table', 'canonical weapon catalog required')
local managedWeapons = {}

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

local function normalizeWeapon(data)
    if type(data) ~= 'table' then return nil end

    local weapon = clone(data)
    weapon.name = tostring(weapon.name or ''):lower():gsub('%s+', '_')
    if weapon.name == '' then return nil end

    local hash = tonumber(weapon.hash) or native.GetHashKey(weapon.name)
    weapon.hash = nil

    return hash, weapon
end

local function CreateWeapons(newWeapons)
    if type(newWeapons) ~= 'table' then return false end

    local updates = {}

    for key, weaponData in pairs(newWeapons) do
        if type(weaponData) == 'table' and not weaponData.name then
            weaponData.name = tostring(key)
        end

        local hash, weapon = normalizeWeapon(weaponData)
        if hash and weapon then
            core.Shared.Weapons[hash] = weapon
            managedWeapons[hash] = true
            updates[hash] = weapon
        end
    end

    if next(updates) then
        native.TriggerClientEvent('QBCore:Client:OnSharedUpdateMultiple', -1, 'Weapons', updates)
    end

    return true
end

describeExport('CreateWeapons', CreateWeapons)

local function RemoveWeapon(nameOrHash)
    local hash = tonumber(nameOrHash) or native.GetHashKey(tostring(nameOrHash or ''):lower())
    if not hash or not core.Shared.Weapons[hash] then return false end

    core.Shared.Weapons[hash] = nil
    managedWeapons[hash] = nil
    native.TriggerClientEvent('QBCore:Client:OnSharedRemove', -1, 'Weapons', hash)

    return true
end

describeExport('RemoveWeapon', RemoveWeapon)

local function GetManagedWeapons()
    return clone(managedWeapons)
end

describeExport('GetManagedWeapons', GetManagedWeapons)

local function HasWeapon(nameOrHash)
    local hash = tonumber(nameOrHash) or native.GetHashKey(tostring(nameOrHash or ''):lower())
    if not hash then return false, nil, false, nil end

    local weapon = core.Shared.Weapons[hash]

    return weapon ~= nil, clone(weapon), managedWeapons[hash] == true, hash
end

describeExport('HasWeapon', HasWeapon)

    return api
end

