ForgeCore = ForgeCore or {}

local Registry = {
    weapons = {},
    revision = 0,
}

local function trim(value)
    return (tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function normalizeName(value)
    value = trim(value):lower()
    value = value:gsub('%s+', '_'):gsub('[^%w_%-]', '')
    if value ~= '' and not value:find('^weapon_') and not value:find('^gadget_') then
        value = 'weapon_' .. value
    end
    return value
end

local function normalizeAccess(access)
    access = type(access) == 'table' and access or {}

    local mode = trim(access.mode):lower()
    if mode ~= 'job' and mode ~= 'gang' and mode ~= 'admin' then
        mode = 'free'
    end

    return {
        mode = mode,
        name = normalizeName(access.name):gsub('^weapon_', ''),
        grade = math.max(0, math.floor(tonumber(access.grade) or 0)),
    }
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

local function normalizeWeapon(rawWeapon, fallbackName)
    if type(rawWeapon) ~= 'table' then return nil, 'invalid_weapon' end

    local weapon = clone(PR.Weapons.Defaults)
    for key, value in pairs(rawWeapon) do
        weapon[key] = clone(value)
    end

    weapon.name = normalizeName(weapon.name or fallbackName)
    if weapon.name == '' then return nil, 'missing_name' end

    weapon.label = trim(weapon.label) ~= '' and trim(weapon.label) or weapon.name
    weapon.weapontype = trim(weapon.weapontype) ~= '' and trim(weapon.weapontype) or PR.Weapons.Defaults.weapontype
    weapon.throwable = weapon.weapontype == 'Throwable'
    weapon.ammotype = trim(weapon.ammotype) ~= '' and trim(weapon.ammotype) or 'none'
    if weapon.ammotype:lower() == 'nil' then weapon.ammotype = 'none' end
    weapon.damagereason = trim(weapon.damagereason) ~= '' and trim(weapon.damagereason) or PR.Weapons.Defaults.damagereason
    weapon.active = weapon.active ~= false
    weapon.access = normalizeAccess(weapon.access)

    return weapon
end

local function mapWeapons(weapons)
    local mapped = {}

    for key, value in pairs(weapons or {}) do
        local fallbackName = type(key) == 'number' and value and value.name or key
        local weapon = normalizeWeapon(value, fallbackName)
        if weapon then
            mapped[weapon.name] = weapon
        end
    end

    return mapped
end

local function listWeapons(weapons)
    local list = {}

    for _, weapon in pairs(weapons or {}) do
        list[#list + 1] = clone(weapon)
    end

    table.sort(list, function(left, right)
        return tostring(left.label or left.name) < tostring(right.label or right.name)
    end)

    return list
end

function Registry.setAll(weapons)
    Registry.weapons = mapWeapons(weapons)
    Registry.revision = Registry.revision + 1
end

function Registry.normalizeWeapon(weapon)
    return normalizeWeapon(weapon)
end

function Registry.upsert(weapon)
    local normalized, err = normalizeWeapon(weapon)
    if not normalized then return false, err end

    Registry.weapons[normalized.name] = normalized
    Registry.revision = Registry.revision + 1

    return true, normalized
end

function Registry.remove(name)
    local normalizedName = normalizeName(name)
    if not Registry.weapons[normalizedName] then return false, 'not_found' end

    Registry.weapons[normalizedName] = nil
    Registry.revision = Registry.revision + 1

    return true
end

function Registry.setActive(name, active)
    local normalizedName = normalizeName(name)
    local weapon = Registry.weapons[normalizedName]
    if not weapon then return false, 'not_found' end

    weapon.active = active ~= false
    Registry.revision = Registry.revision + 1

    return true, clone(weapon)
end

function Registry.getWeapons()
    return clone(Registry.weapons)
end

function Registry.getActiveWeapons()
    local activeWeapons = {}

    for name, weapon in pairs(Registry.weapons or {}) do
        if weapon.active ~= false then
            activeWeapons[name] = clone(weapon)
        end
    end

    return activeWeapons
end

function Registry.list()
    return listWeapons(Registry.weapons)
end

function Registry.payload()
    return {
        weapons = Registry.list(),
        revision = Registry.revision,
    }
end

ForgeCore.WeaponRegistry = Registry
