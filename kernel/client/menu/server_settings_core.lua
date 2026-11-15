-- Extend the same controller; AFK33 remains the only AFK editor.
local createMenu=require 'kernel.client.menu.server_settings'
return function(state,ports)
    local work,admin,access=assert(state.WorkMenus),assert(state.AdministrationMenus),assert(state.AccessClientCore)
    local client=assert(ports.client)
    assert(work.State==state and admin.State==state and access.State==state,'canonical state required')
    assert(client==work.Client and client==access.Client and client.Menu==work.Menu and work.Menu==admin.Menu
        and work.Shared==admin.Shared and access.Shared==work.Shared,'canonical controller/shared required')
    assert(access.Session.Session==client.ForgeSession and type(work.Menu.openAfkSettingsEditor)=='function','canonical access33 required')
    assert(state.ServerSettingsMenus==nil,'server settings menu already attached')
    for _,name in ipairs({'openServerSettingsMenu','openDatabaseBackupMenu','openPasswordSettingsEditor'})do
        assert(work.Menu[name]==nil,'server settings method already attached: '..name)
    end
    local config=assert(ports.config)
    assert(config.Password and config.DatabaseBackup and config.Afk==access.Config.Afk,'canonical settings config required')
    local api=createMenu({menu=work.Menu,shared=work.Shared,config=config,library=ports.library,native=ports.native,
        panelIntegration=ports.panelIntegration})
    api.State,api.Client,api.Access,api.Config=state,client,access,config
    state.ServerSettingsMenus=api
    return api
end
