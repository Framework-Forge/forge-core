-- Inactive installed-QBX port; see NOTICE-09.md and LICENSE-QBX.
return function(ports)
    assert(type(ports) == 'table', 'explicit runtime ports required')
    local core = assert(ports.core, 'canonical client state required')
    local native = assert(ports.native, 'platform ports required')
    local cache = assert(ports.cache, 'cache port required')
    local config = assert(ports.config, 'local client configuration required')
    local api = {Events = {}, Callbacks = {}, Threads = {}, Exports = {}, StateBags = {}, EntityStateHandlers = {}}
    local function listen(name, handler, network)
        api.Events[#api.Events + 1] = {name = name, handler = handler, network = network == true}
    end
    local function network(name, handler) listen(name, handler, true) end
    local function callback(name, handler) api.Callbacks[name] = handler end
    local function thread(handler) api.Threads[#api.Threads + 1] = handler end
    local function describeExport(name, handler) api.Exports[name] = handler end
    local random = assert(ports.random, 'explicit RNG port required')
local statusInterval = config.statusIntervalSeconds
thread(function()
    local timeout = 1000 * statusInterval
    while true do
        native.Wait(timeout)

        if core.IsLoggedIn then
            if ((core.Status.hunger or 0) <= 0 or (core.Status.thirst or 0) <= 0) and not core.Session.isDead() then
                local currentHealth = native.GetEntityHealth(cache.ped)
                local decreaseThreshold = random(5, 10)
                native.SetEntityHealth(cache.ped, currentHealth - decreaseThreshold)
            end
        end
    end
end)

    return api
end

