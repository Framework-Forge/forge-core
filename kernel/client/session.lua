-- Inactive port of installed QBX source; see NOTICE-03.md and LICENSE-QBX.
-- Event descriptors are not runtime registrations. Server handlers take eventSource first.
return function(ports)
    assert(type(ports) == 'table', 'explicit producer ports required')
    local api = {Events = {}, Threads = {}, Exports = {}, Callbacks = {}}
    local function listen(name, handler, network)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = network == true}
    end
    local function describeExport(name, handler) api.Exports[name] = handler end
    local function thread(handler) api.Threads[#api.Threads + 1] = handler end
    local function callback(name, handler) api.Callbacks[name] = handler end
    local function network(name, handler) listen(name, handler, true) end
    local core = assert(ports.core, 'core state required')
    local native = assert(ports.native, 'native platform ports required')
    local TriggerEvent = assert(native.TriggerEvent, 'TriggerEvent port required')
    local PlayerPedId = assert(native.PlayerPedId, 'PlayerPedId port required')
    local IsEntityDead = assert(native.IsEntityDead, 'IsEntityDead port required')
    local IsPedFatallyInjured = assert(native.IsPedFatallyInjured, 'IsPedFatallyInjured port required')

-- QBX owns its session cache. Do not depend on PRBridge here: QBX boots first.
local Session = {}
local record, revision = nil, 0

local function refresh(publish)
    local player = type(core.PlayerData) == 'table' and core.PlayerData or {}
    local metadata = type(player.metadata) == 'table' and player.metadata or {}
    local data = {
        character = player.citizenid,
        loaded = core.IsLoggedIn == true and player.citizenid ~= nil,
        dead = metadata.isdead == true or metadata.inlaststand == true,
        cuffed = metadata.ishandcuffed == true,
    }
    local changed = not record
    for key, value in pairs(data) do
        if not record or record.data[key] ~= value then changed = true end
    end
    if record and record.data.character ~= data.character then changed = true end
    if changed then
        revision = revision + 1
        record = {revision=revision,data=data}
        if publish then
            TriggerEvent('pr_bridge:resourceState:changed', 'qbx_core', 'session', Session.snapshot())
        end
    end
    return record
end

function Session.snapshot()
    local current = refresh(false)
    local data = {}; for key, value in pairs(current.data) do data[key] = value end
    return {revision=current.revision,data=data}
end
function Session.isLoaded() return refresh(false).data.loaded end
function Session.isDead()
    -- Metadata covers persisted death/laststand; natives cover its immediate transition.
    local ped = PlayerPedId()
    return refresh(false).data.dead or IsEntityDead(ped) or IsPedFatallyInjured(ped)
end
function Session.refresh()
    refresh(true)
    core.BridgeCache.session(core.IsLoggedIn)
end
function Session.setLoaded(loaded)
    core.IsLoggedIn = loaded == true
    refresh(true)
    core.BridgeCache.session(core.IsLoggedIn, not core.IsLoggedIn)
end
api.Session = Session
network('QBCore:Client:OnPlayerLoaded', function() Session.setLoaded(true) end)
network('QBCore:Client:OnPlayerUnload', function() Session.setLoaded(false) end)
describeExport('IsPlayerLoaded', Session.isLoaded)
describeExport('GetCachedState', function(domain) return domain == 'session' and Session.snapshot() or nil end)
function api.Initialize() refresh(false) end
    return api
end
