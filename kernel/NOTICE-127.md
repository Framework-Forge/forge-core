# Lote127

Native Forge IO bindings through installed PRCore/persistence. No replacement JSON format,path migration,persistence rewrite,background worker or real write in tests. Existing locks/backups/runtime restoration and Cfx BOOL handling are reused. New calls are revoked on close;accepted operations and retained callback references keep their existing lifecycle limits.
