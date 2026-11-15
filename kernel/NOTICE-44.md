# Private preparation — lot44

Whole installed Forge starterpack configuration/service/callbacks/command/client/menu, adapted to explicit local core and PR ports. Preserve the original project notices/licenses; this is not a replacement of the customized inventory with upstream code.

Eight modules are outside the active manifest. Constructors do not load/save operational files, start workers, register public commands/events or spawn entities. The explicit client Initializers describe the original preparation timer; action work is scheduled only on invocation. Integration, disposal and real FiveM tests remain pending. No migration/cut/SQL/resource-restart authorization is implied.
