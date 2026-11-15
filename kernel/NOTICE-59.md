# Private server initialization preparation

Forge server/main startup order and player-event behavior retained through explicit descriptors; earlier QBX/Forge notices/LICENSE-QBX preserved. Server48 is built once on the supplied state; external scheduling is injected from PR57, including the server spawn alias.

Some real startup bodies can run SQL/schema/JSON/hooks/ACE/inventory synchronization or request quit. They are executed only against virtual providers in this preparation. No operational authorization, live manifest change, database migration or resource restart is implied. Close revokes known tasks cooperatively, not partial startup effects or arbitrary awaits. Extra bootstrap events, resource-start lifecycle, providers/readiness/teardown/compat remain to coordinate.
