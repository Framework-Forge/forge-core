# Lote122

Core-local owned PR callback composition. Installed native/ox adapters,engine and registry are reused;no fabricated protocol,legacy-engine adoption or foreign namespace cleanup. New requests/leases close before draining accepted requests/inbound callbacks and removing owned listeners. Timers and external effects are not retroactively cancelled. Native/SQL/provider operations remain virtual in tests.
