# Private server lifecycle coordination

Earlier QBX/Forge notices and LICENSE-QBX remain unchanged. This preparation composes server48/51–53/59 and the private shutdown58 utility; installed protocols and resource names are retained. Only explicit providers are used. No live manifest/bootstrap/SQL/JSON or restart is enabled.

Known listeners are removed by exact token; inventory hooks lack a public PR removal port and retain revoked shells returning nil without executing the body. This is not an inventory-denial policy: R01 still requires an explicit decision before activation. Manual stop drains known work; native stop remains best effort. This is not complete provider/await teardown, rollback or operational readiness. Own resource-start delivery can run schema statements and is exercised with virtual providers only; operational ordering/DDL/readiness remains gated separately.
