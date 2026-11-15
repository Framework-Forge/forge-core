# Private coordinated client shutdown

Existing QBX/Forge sources and notices/LICENSE-QBX retained. New composition uses unchanged51–57 factories, explicit PR/native providers and one canonical client state. No public bootstrap or live manifest change.

Manual Stop revokes ingress/owned registrations and Poll waits for cooperative quiescence before domain teardown. Native resource-stop is best effort, explicitly reporting in-flight workers. Neither mode proves cancellation of arbitrary external awaits or physical removal of commands, mappings, transport listeners or inert shells. Cleanup errors and already-entered bodies remain visible; no rollback or R07 completion claimed.
