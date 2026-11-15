-- Forge owns delivery; PR owns the public visual settings and their application.
return function(e, rpc)
    local event = 'forge-core:config:interface'
    local server = e.IsDuplicityVersion()
    local closed, started, requesting, delivered = false, false, false, false
    local generation, tokens, lease = 0, {}
    local api = {}
    local function listen(name, fn, network)
        if network then e.RegisterNetEvent(name) end
        tokens[#tokens + 1] = e.AddEventHandler(name, function(...)
            if not closed then return fn(...) end
        end)
    end
    local function receive(record)
        if closed or type(record) ~= 'table' or e.GetResourceState('pr_bridge') ~= 'started' then return false end
        local ok, accepted = pcall(function() return e.exports.pr_bridge:ApplyVisualConfig(record) end)
        if ok and accepted == true then delivered = true; return true end
        return false
    end
    local function request()
        if closed or delivered or requesting or e.GetResourceState('pr_bridge') ~= 'started' then return end
        requesting = true
        local attempt = generation
        e.CreateThread(function()
            if closed or attempt ~= generation then return end
            local ok, record = pcall(rpc.Native.await, event, 10000)
            if closed or attempt ~= generation then return end
            requesting = false
            if (ok and receive(record)) or delivered then return end
            e.print('[forge-core:config] Configuracao visual indisponivel; verifique o PR Bridge no servidor.')
        end)
    end
    function api.Start()
        assert(not started and not closed, 'visual delivery already started/closed')
        started = true
        if server then
            local owner = rpc.Owners.native
            lease = owner.Reserve(event)
            assert(owner.Bind(lease, function()
                if not closed then return e.exports.pr_bridge:GetCachedState('interface') end
            end))
            listen('pr_bridge:ui:configCommitted', function(record)
                if type(record) == 'table' and type(record.data) == 'table' then
                    e.TriggerClientEvent(event, -1, record)
                end
            end)
        else
            listen(event, function(record) if e.source == 65535 then receive(record) end end, true)
            listen('pr_bridge:ui:ready', request)
            listen('onClientResourceStart', function(resource)
                if resource ~= 'pr_bridge' then return end
                generation = generation + 1; delivered, requesting = false, false; request()
            end)
            listen('onClientResourceStop', function(resource)
                if resource ~= 'pr_bridge' then return end
                generation = generation + 1; delivered, requesting = false, false
            end)
            request()
        end
        return true
    end
    function api.Close()
        closed = true; generation = generation + 1
        if lease then assert(rpc.Owners.native.Release(lease)); lease = nil end
        for i = #tokens, 1, -1 do
            assert(e.RemoveEventHandler(tokens[i]) ~= false, 'visual listener removal refused')
            tokens[i] = nil
        end
        return true
    end
    return api
end
