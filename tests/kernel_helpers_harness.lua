-- Isolated Cfx/native/library doubles; never a resource, network or native runner.
local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local T = {H = H, P = P}

function T.vector(kind, x, y, z, w)
    return {__kind = kind, x = x, y = y, z = z, w = w, r = x, g = y, b = z, a = w}
end
function T.type(value)
    return type(value) == 'table' and rawget(value, '__kind') or type(value)
end
function T.env(extra)
    local env = H.environment(extra)
    env.type = T.type
    return env
end

function T.new(ported, side)
    local r = {trace = {}, side = side or 'server', cache = {ped = 10}, states = {}, entities = {},
        callbacks = {}, audioResult = true, owner = 17, plate = '  ABC  ', vehicleType = 'automobile',
        spawnCount = 0, tick = 0, exists = true, model = 1, variation = 0, bankLoaded = true,
        heading = 90, extraExists = {[1] = true, [2] = true, [20] = true}}
    function r.record(kind, ...) r.trace[#r.trace + 1] = {kind = kind, args = P.snapshot(table.pack(...))} end
    local function recordCall(name, result)
        return function(...) r.record(name, ...); return result end
    end
    local native = {}
    for _, name in ipairs({'SetTextScale','SetTextFont','SetTextColour','SetTextDropShadow','SetTextOutline',
        'SetTextCentre','BeginTextCommandDisplayText','AddTextComponentSubstringPlayerName','EndTextCommandDisplayText',
        'SetDrawOrigin','DrawRect','ClearDrawOrigin','SetEntityAsMissionEntity','SetVehicleExtra',
        'PlaySoundFromCoord','PlaySoundFromEntity','PlaySoundFrontend','ReleaseSoundId','SetEntityOrphanMode','SetPedIntoVehicle'}) do
        native[name] = recordCall(name)
    end
    native.vec2 = function(x, y) return T.vector('vector2', x, y) end
    native.vector3 = function(x, y, z) return T.vector('vector3', x, y, z) end
    native.vec4 = function(x, y, z, w) return T.vector('vector4', x, y, z, w) end
    native.joaat = function(value)
        if value == 'mp_m_freemode_01' then return 1 end
        -- Deterministic numeric test hash; not the actual Cfx joaat algorithm.
        return type(value) == 'number' and value or 100 + #tostring(value)
    end
    native.GetResourceState = function(name) r.record('resource', name); return r.states[name] or 'stopped' end
    native.GetEntityCoords = function(entity) r.record('coords', entity); return native.vector3(1, 2, 3) end
    native.GetEntityHeading = function(entity) r.record('heading', entity); return r.heading end
    native.GetVehicleNumberPlateText = function(entity)
        r.record('plate', entity)
        if r.plateHook then return r.plateHook(entity) end
        return r.plate
    end
    native.GetEntityRoutingBucket = function(entity) r.record('getBucket', entity); return 9 end
    native.CreateVehicle = function(...) r.record('tempVehicle', ...); return 200 end
    native.GetVehicleType = function(entity) r.record('vehicleType', entity); return r.vehicleType end
    native.CreateVehicleServerSetter = function(...)
        r.spawnCount = r.spawnCount + 1
        r.record('spawn', ...)
        return 100 + r.spawnCount
    end
    native.DoesEntityExist = function(entity)
        r.record('exists', entity)
        if r.existsHook then return r.existsHook(entity) end
        if r.entities[entity] ~= nil then return r.entities[entity] end
        return r.exists
    end
    native.DeleteEntity = function(entity) r.record('deleteEntity', entity); r.entities[entity] = false end
    native.DeleteVehicle = function(entity)
        r.record('deleteVehicle', entity)
        if not r.deleteFails then r.entities[entity] = false end
    end
    native.NetworkGetEntityOwner = function(entity)
        r.record('owner', entity)
        return r.ownerHook and r.ownerHook(entity) or r.owner
    end
    native.NetworkGetNetworkIdFromEntity = function(entity) r.record('netId', entity); return entity + 1000 end
    native.TriggerClientEvent = function(...) r.record('client', ...); if r.clientHook then r.clientHook(...) end end
    native.Entity = function(entity)
        r.record('entity', entity)
        if r.noEntity then return nil end
        if r.noState then return {} end
        return {state = {set = function(_, ...) r.record('state', entity, ...) end}}
    end
    native.Wait = function(ms)
        r.record('wait', ms); r.tick = r.tick + ms
        assert(#r.trace < 3000, 'Runaway native wait in helper test')
        if r.waitHook then r.waitHook(ms) end
    end
    native.NetworkDoesEntityExistWithNetworkId = function(id) r.record('networkExists', id); return r.networkExists ~= false end
    native.NetworkGetEntityFromNetworkId = function(id)
        r.record('networkEntity', id)
        if r.networkEntity == false then return false end
        return r.networkEntity or 501
    end
    native.AddStateBagChangeHandler = function(key, filter, handler)
        r.record('stateHandler', key, filter); r.callbacks[key] = handler; return 73
    end
    native.GetEntityModel = function(entity) r.record('model', entity); return r.model end
    native.GetPedDrawableVariation = function(entity, component) r.record('variation', entity, component); return r.variation end
    native.GetLabelText = function(label) r.record('label', label); return 'LABEL_' .. tostring(label) end
    for _, name in ipairs({'GetDisplayNameFromVehicleModel','GetMakeNameFromVehicleModel','GetModTextLabel','GetLiveryName','GetNameOfZone'}) do
        native[name] = recordCall(name, 'TEST_LABEL')
    end
    native.GetStreetNameAtCoord = function(...) r.record('street', ...); return 123, 456 end
    native.GetStreetNameFromHashKey = function(hash) r.record('streetName', hash); return 'STREET_' .. hash end
    native.DoesExtraExist = function(entity, extra) r.record('extraExists', entity, extra); return r.extraExists[extra] or false end
    native.RequestScriptAudioBank = function(...) r.record('bank', ...); return r.bankLoaded end
    native.GetSoundId = recordCall('soundId', 88)
    r.native = native
    r.library = {table = {freeze = H.copy}, string = {random = function(pattern) r.record('random', pattern); return 'a1b2' end},
        print = {error = function(...) r.record('error', ...) end}}
    r.library.waitFor = function(callback, message, timeout)
        r.record('waitFor', message, timeout)
        if r.waitForHook then return r.waitForHook(callback, message, timeout) end
        for _ = 1, 4 do local value = callback(); if value then return value end end
        if r.waitReturnsNil then return nil end
        error(message or 'waitFor timeout', 0)
    end
    r.core = {
        getVehiclesByHash = function(hash) r.record('catalog', hash); return r.catalogResult or {type = r.vehicleType} end,
        setEntityBucket = function(...) r.record('bucket', ...) end,
        enablePersistence = function(...) r.record('persistence', ...); return true end,
    }
    r.audio = {}
    for _, name in ipairs({'PlayNativeSoundFromCoords','PlayNativeSoundFromEntity','PlayNativeSound',
        'PlayLocalNativeSoundFromCoords','PlaySharedNativeSoundFromCoords','PlayLocalNativeSoundFromEntity',
        'PlaySharedNativeSoundFromEntity','PlayLocalNativeSound'}) do
        r.audio[name] = function(...)
            r.record('audio-' .. name, ...)
            if r.audioFails then error('simulated audio failure') end
            return r.audioResult
        end
    end
    r.ports = {isServer = r.side == 'server', native = native, library = r.library, cache = r.cache,
        core = r.core, audio = r.audio, warn = function(...) r.record('warn', ...) end}
    local env = T.env()
    if ported then r.api = H.load('kernel/modules/lib.lua', env)(r.ports)
    else
        for name, fn in pairs(native) do env[name] = fn end
        env.IsDuplicityVersion = function() return r.side == 'server' end
        env.lib, env.cache, env.warn = r.library, r.cache, r.ports.warn
        env.exports = {qbx_core = {
            GetVehiclesByHash = function(_, ...) return r.core.getVehiclesByHash(...) end,
            SetEntityBucket = function(_, ...) return r.core.setEntityBucket(...) end,
            EnablePersistence = function(_, ...) return r.core.enablePersistence(...) end,
        }, pr_3dsound = {}}
        for name, fn in pairs(r.audio) do env.exports.pr_3dsound[name] = function(_, ...) return fn(...) end end
        -- Translate only Cfx hash literals, never Markdown fences spanning comments.
        local text = P.source('modules/lib.lua'):gsub('`([%w_]+)`', 'joaat("%1")')
        P.loadOrigin('modules/lib.lua', env, text)
        r.api = env.qbx
    end
    assert(#r.trace == 0 and next(r.callbacks) == nil, 'No native/registration/runtime effect in helper constructor')
    r.env = env
    return r
end

function T.compare(side, name, action)
    local a, b = T.new(false, side), T.new(true, side)
    local left, right = table.pack(action(a)), table.pack(action(b))
    H.same(P.snapshot(right), P.snapshot(left), name .. ': returns')
    H.same(b.trace, a.trace, name .. ': calls')
    H.same(P.snapshot(b.api), P.snapshot(a.api), name .. ': namespace/data')
end

return T
