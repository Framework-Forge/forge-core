-- Administrative records project into the existing canonical runtime catalog, never an external core.
return function(ports)
    local services, kernel, isReady=assert(ports.services),assert(ports.kernel),assert(ports.isReady)
local Sync = {
    registeredWeapons = {},
}

local function coreReady()
    return isReady()
end

local function coreCall(method, ...)
    if not coreReady() then return false end

    local args = { ... }
    local ok, result = pcall(function()
        if method == 'CreateWeapons' then
            return kernel.CreateWeapons(args[1])
        elseif method == 'RemoveWeapon' then
            return kernel.RemoveWeapon(args[1])
        end

        return false
    end)

    return ok and result ~= false
end

local function removeMissing(previous, current)
    for name in pairs(previous) do
        if not current[name] then
            coreCall('RemoveWeapon', name)
        end
    end
end

local function toQbxWeapons(weapons)
    local qbxWeapons = {}

    for name, weapon in pairs(weapons or {}) do
        local qbxWeapon = {}

        for key, value in pairs(weapon) do
            if key ~= 'active' then
                qbxWeapon[key] = value
            end
        end

        if qbxWeapon.ammotype == 'none' then
            qbxWeapon.ammotype = nil
        end

        qbxWeapons[name] = qbxWeapon
    end

    return qbxWeapons
end

function Sync.syncAll()
    local registry = services.WeaponRegistry
    if not registry then return false end

    local weapons = registry.getActiveWeapons()
    if next(weapons) then
        coreCall('CreateWeapons', toQbxWeapons(weapons))
    end

    removeMissing(Sync.registeredWeapons, weapons)

    Sync.registeredWeapons = {}
    for name in pairs(weapons) do
        Sync.registeredWeapons[name] = true
    end

    return true
end

    return Sync
end
