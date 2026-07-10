ForgeCore = ForgeCore or {}

local Sync = {
    registeredWeapons = {},
}

local function oxReady()
    return GetResourceState('ox_inventory'):find('start') ~= nil
end

local function oxCall(method, ...)
    if not oxReady() then return false end

    local args = { ... }
    local ok, result = pcall(function()
        if method == 'SetWeaponItem' then
            return exports.ox_inventory:SetWeaponItem(args[1], args[2], args[3])
        elseif method == 'DisableWeaponItem' then
            return exports.ox_inventory:DisableWeaponItem(args[1], args[2])
        end

        return false
    end)

    return ok and result ~= false
end

local function toOxWeapon(weapon)
    return {
        name = weapon.name,
        label = weapon.label,
        weapontype = weapon.weapontype,
        ammotype = weapon.ammotype,
        damagereason = weapon.damagereason,
        description = weapon.active == false and 'Arma desativada pelo Forge Core.' or nil,
    }
end

local function disableMissing(previous, current)
    for name in pairs(previous) do
        if not current[name] then
            oxCall('DisableWeaponItem', name, {
                name = name,
                label = name,
                description = 'Arma removida do Forge Core.',
            })
        end
    end
end

function Sync.syncAll()
    local registry = ForgeCore.WeaponRegistry
    if not registry then return false end

    local weapons = registry.getWeapons()

    for name, weapon in pairs(weapons or {}) do
        if weapon.active == false then
            oxCall('DisableWeaponItem', name, toOxWeapon(weapon))
        else
            oxCall('SetWeaponItem', name, toOxWeapon(weapon), true)
        end
    end

    disableMissing(Sync.registeredWeapons, weapons)

    Sync.registeredWeapons = {}
    for name in pairs(weapons or {}) do
        Sync.registeredWeapons[name] = true
    end

    return true
end

ForgeCore.WeaponOxSync = Sync
