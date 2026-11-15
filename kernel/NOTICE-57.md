# Private worker scheduling preparation

Retains installed QBX/Forge behavior and earlier notices/LICENSE-QBX. New ownership utility belongs in PR Bridge; Forge receives its factory explicitly. No public bridge bootstrap, manifest, original source or data changes.

Cancellation is cooperative at owned Wait/explicit Boundary, not forced termination, queue removal, rollback or domain teardown. PR/streaming awaits that bypass these boundaries and bodies that catch cancellation may still finish effects. Close is not onResourceStop and does not duplicate original cleanup handlers. Actual runtime/providers/readiness/server initialization/cleanup and compatibility remain unverified operationally.
