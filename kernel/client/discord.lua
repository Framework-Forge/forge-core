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
    local globalState = assert(ports.globalState, 'global state view required')
local discord = config.discord

if not discord.enabled then
    function api.Initialize() return false end
    return api
end

-- Forge: sem statebag. O servidor envia o contador por evento; MaxPlayers chega antes (events.lua).
network('qbx_core:client:globalState:PlayerCount', function(value)
    if native.source() ~= 65535 or type(value) ~= 'number' then return end
    globalState.PlayerCount = value
    native.SetRichPresence(('Players %s/%s'):format(value, globalState.MaxPlayers or '?'))
end)

local initialized = false
function api.Initialize()
    if initialized then return false end
native.SetDiscordAppId(discord.appId)
native.SetDiscordRichPresenceAsset(discord.largeIcon.icon)
native.SetDiscordRichPresenceAssetText(discord.largeIcon.text)
native.SetDiscordRichPresenceAssetSmall(discord.smallIcon.icon)
native.SetDiscordRichPresenceAssetSmallText(discord.smallIcon.text)
native.SetDiscordRichPresenceAction(0, discord.firstButton.text, discord.firstButton.link)
native.SetDiscordRichPresenceAction(1, discord.secondButton.text, discord.secondButton.link)
    initialized = true
    return true
end

    return api
end

