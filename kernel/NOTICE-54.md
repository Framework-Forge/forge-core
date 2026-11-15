# Private state/input registration — lot54

This inactive addition registers the original private client50 statebag/entity/keybind descriptors on explicitly supplied ports. It uses the existing local QBX-derived Lib resolver and the installed PR keybind provider; retain LICENSE-QBX and earlier notices. The manifest and live PR/QBX/OX sources are unchanged.

Only the audited Hospital.Initialize description step is invoked explicitly by Install, never in the constructor; it does not start its parent/session service. Cookie-owned statebags are removed. PR keybind entries are disabled and removed only by exact owned identity, but their native commands, mappings and suggestion timers are NOT physically unregistered. Unknown tokens, already running bodies/workers and full context shutdown remain outside this contract. Tests use virtual platform/time/network/IO, not a FiveM boot or real inventory/SQL test. R01/R04/R06/R07 remain open.
