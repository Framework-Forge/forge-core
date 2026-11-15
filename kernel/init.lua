-- Prepared server-side core composition, intentionally NOT loaded by fxmanifest.lua.
-- Loading this file only resolves private factories. It does not select a provider,
-- register exports/events/threads, read player data or activate an authority.
local createShared = require 'kernel.shared.main'
local createMembership = require 'kernel.shared.functions'
local createGroups = require 'kernel.server.groups'

return function(ports)
    assert(type(ports) == 'table', 'kernel bindings required')
    local shared = createShared(ports.shared)
    local membership = createMembership(ports.membership)
    local groups = createGroups(ports.groups)
    return {Shared = shared, Membership = membership, Groups = groups}
end
