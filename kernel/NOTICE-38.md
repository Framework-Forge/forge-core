# Objects migration slice — inactive

Prepared 21/10/2026 from the installed Forge Core Objects configuration, server service/callbacks, client renderer/editor and menus. Original sources, authorship and notices remain unchanged.

Seven factories attach to the canonical JobService/Security/World35/Menu34 and one Objects state. Public getAll remains player-accessible; the six mutations are admin-only. Workers, subscriptions, stop handler, callbacks and command registration remain descriptors. No manifest or live JSON is changed and no worker starts by construction.

Tests compare five whole installed sources. PR persistence/cache/RPC/context/streaming/blips execute with virtual native/file/network boundaries. Gizmo finish/start/stop protocol is a declared double; real focus/camera/CEF and models are not verified. Keep existing failure, cancellation, model-reuse, late-wait and menu-timer behavior pending a separate decision. Do not install beside the active original handlers.
