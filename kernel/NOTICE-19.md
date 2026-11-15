# Attribution and inactive scope — lot 19

Complete installed Forge Devs - PierreMoraes shared/inventory.lua,
server/inventory/service.lua and server/inventory/callbacks.lua are ported into
private config/service/callback factories plus canonical composition.
All previously captured QBX copyright/license notices remain intact.

Initialization is explicit and guarded; no files/providers are read or callbacks,
exports/events/timers installed merely by assembly. Existing JSON schemas,
interaction definitions, VIP/group policy and custom OX publication semantics remain.
Three custom definition mutations require explicit future PR integration contracts;
no upstream inventory replacement or direct external export is introduced.

Weapon/consumable administrative services remain named internal dependencies.
Inherited fail-open, missing sync acknowledgements, parser and late-use/session
risks are documented, not silently fixed or authorized for operational use.
