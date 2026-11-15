# Attribution and inactive scope — lot 18

The installed Forge Devs - PierreMoraes sources server/callback_security.lua,
server/job/callbacks.lua, server/job/commands.lua and server/compat.lua are ported
in full into private factories/descriptors with explicit local services and PR ports.
Prior installed QBX copyright/license notices remain in their previously captured files.

No callbacks, commands, events, exports or resources are installed by assembly.
Shared protection/classification and private-server caller authorization are preserved.
InventoryService remains an explicit future custom-service dependency; Items/transport
and utility helper loading are PR contracts, never direct OX or self-framework calls.

Current source-only quota/permission checks, unfiltered administrative payload,
ignored save acknowledgements and late-session behavior are retained and documented.
Passing isolated tests does not authorize bootstrap, network bindings or operational use.
