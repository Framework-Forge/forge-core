-- Private legacy consumer view, NOT the canonical client state or an authority.
-- Do not install these unguarded legacy handlers on the core; see client/events.
return function(ports)
    assert(type(ports) == 'table' and type(ports.isServer) == 'boolean', 'side required')
    if ports.isServer then return end
    local getPlayerData = assert(ports.getPlayerData, 'local player-data getter required')
    local view = {PlayerData = {}}
    local initialized = false
    local api = {View = view, Events = {
        {name = 'QBCore:Client:OnPlayerUnload', network = true, handler = function() view.PlayerData = {} end},
        {name = 'QBCore:Player:SetPlayerData', network = true, handler = function(value) view.PlayerData = value end},
    }}
    function api.Initialize()
        if initialized then return false end
        view.PlayerData = getPlayerData() or {}
        initialized = true
        return true
    end
    return api
end
