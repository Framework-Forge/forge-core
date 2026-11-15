-- Same local Job/Staff/Security holders. No service start or listener/callback installation.
local createPasswordConfig=require 'kernel.config.forge_password'
local createBackupConfig=require 'kernel.config.forge_database_backup'
local createPassword=require 'kernel.server.password'
local createBackup=require 'kernel.server.database_backup'
local createPasswordCallbacks=require 'kernel.server.password_callbacks'
local createBackupCallbacks=require 'kernel.server.database_backup_callbacks'
return function(base,ports)
    local pc,catalog,groups=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.Groups)
    local transport,deps=assert(catalog.Transport),assert(catalog.Dependencies)
    assert(pc.Groups==groups and catalog.Groups==groups and base.Callbacks==transport.Security,'canonical state/Security required')
    local access=assert(base.AccessCore,'canonical access32 required')
    assert(access.Base==base and access.Security==base.Callbacks and deps.AfkService==access.Afk.Service
        and deps.WhitelistService==access.Whitelist.Service,'canonical access services required')
    assert(base.StaffCore==nil or base.StaffCore.Service==deps.StaffService,'canonical StaffService required')
    assert(base.ServerSettingsCore==nil and deps.PasswordService==nil and deps.DatabaseBackupService==nil,'server settings already attached')
    local cfg=ports.config or{}
    local config={Password=cfg.Password or createPasswordConfig(),DatabaseBackup=cfg.DatabaseBackup or createBackupConfig(),
        NotifyPos=cfg.NotifyPos,AdminAce=cfg.AdminAce}
    local services=setmetatable({JobService=assert(catalog.Service)},{__index=function(_,key)return deps[key]end})
    local bindings={config=config,library=assert(ports.library),native=assert(ports.native),services=services,translate=assert(ports.translate)}
    local password,backup=createPassword(bindings),createBackup(bindings)
    local api={Base=base,PlayerCore=pc,Security=transport.Security,Access=access,Services=services,
        Config=config,Password=password,Backup=backup,Events=password.Events,Callbacks={}}
    for _,pair in ipairs({{createPasswordCallbacks,password.Service},{createBackupCallbacks,backup.Service}})do
        for _,entry in ipairs(pair[1]({config=config,service=pair[2]}))do api.Callbacks[#api.Callbacks+1]=entry end
    end
    deps.PasswordService,deps.DatabaseBackupService,base.ServerSettingsCore=password.Service,backup.Service,api
    return api
end
