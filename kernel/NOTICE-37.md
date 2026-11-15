# Vinewood migration slice — inactive

Prepared 20/10/2026, completed 21/10/2026. Derived from the installed Forge Core Vinewood configuration, server service/callbacks, client renderer and menu. Original sources and notices remain unchanged; this private slice does not change authorship or licensing.

Factories require explicit native/platform and PR-library ports. Server attaches to the canonical JobService, Security and World35; client reuses World35, Session31 and the existing Menu/Shared controller. Threads, events, subscriptions, callbacks and command registrations are descriptors only. No manifest, live config, JSON data, database or running resource is modified by constructing this slice.

Tests compare whole installed implementations with in-memory persistence, clocks, entities and transport. They do not prove FiveM rendering, model assets, texture correctness, real recovery durability or startup. Existing revision, wait/stop, texture-pixel and menu-lock behavior is retained and documented in LOTE-37.md. Do not install alongside the active original handlers.
