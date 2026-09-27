PR = PR or {}

-- Sentar dinamico: raycast sob demanda, sem varredura constante.
PR.Sit = {
    Enabled = true,
    Command = 'sit',
    StandCommand = 'stand',
    Keybind = 'C',
    Cooldown = 1500,
    RayDistance = 0.8,
    GroundScanDistance = 1.5,

    Offsets = {
        edge_fall = { forward = -0.03, z = 2.0 },
        ledge = { forward = -0.3, z = 0.95 },
        bench = { forward = -0.2, z = 1.0 },
        lean = { forward = 0.1, z = 0.0 },
        ground = { forward = 0.1, z = -0.95 },
    },

    Scenarios = {
        'WORLD_HUMAN_SEAT_WALL',
        'WORLD_HUMAN_SEAT_LEDGE',
        'PROP_HUMAN_SEAT_BENCH',
        'PROP_HUMAN_SEAT_CHAIR',
        'PROP_HUMAN_SEAT_BUS_STOP_WAIT',
        'PROP_HUMAN_SEAT_ARMCHAIR',
        'PROP_HUMAN_SEAT_STRIP_WATCH',
    },
}
-- Encostar em veículos: aproximação e alinhamento controlados antes da animação.
PR.Lean = {
    Enabled = true,
    Keybind = 'O',
    Cooldown = 1000,
    SearchRadius = 2.2,
    SideOffset = 0.28,
    SurfaceOffset = 0.22,
    EntryOffset = 0.42,
    RearInset = 0.35,
    WalkSpeed = 1.0,
    ApproachTimeout = 3500,
    ArriveDistance = 0.65,
    SettleTime = 100,
    EnterTailCutMs = 1100,
    IdleMinMs = 5500,
    IdleMaxMs = 10500,
}
