-- One explicit initial request plus producer events. No polling or player scan.
local delivered, requesting, generation = false, false, 0

local function receive(record)
    if type(record) ~= 'table' or GetResourceState('pr_bridge') ~= 'started' then return false end
    local ok, accepted = pcall(function() return exports.pr_bridge:ApplyVisualConfig(record) end)
    if ok and accepted == true then delivered = true; return true end
    return false
end

local function request()
    if delivered or requesting or GetResourceState('pr_bridge') ~= 'started' then return end
    requesting = true
    local attempt = generation
    CreateThread(function()
        local ok, record = pcall(pr_lib.callback.await, 'forge-core:config:interface', 10000)
        if attempt ~= generation then return end
        requesting = false
        if (ok and receive(record)) or delivered then return end
        print('[forge-core:config] Configuracao visual indisponivel; verifique o PR Bridge no servidor.')
    end)
end

RegisterNetEvent('forge-core:config:interface', function(record)
    if source ~= 65535 then return end
    receive(record)
end)

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= 'pr_bridge' then return end
    generation = generation + 1
    delivered, requesting = false, false
    request()
end)
AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= 'pr_bridge' then return end
    generation = generation + 1
    delivered, requesting = false, false
end)
-- A late NUI mount may retry a failed bootstrap; no timer or cache emitter.
AddEventHandler('pr_bridge:ui:ready', request)
CreateThread(request)
