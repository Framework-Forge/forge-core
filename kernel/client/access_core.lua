-- One whitelist client and AFK editor, reusing Forge Session31 and Menu/Shared22/25.
local createRuntime=require 'kernel.client.access_runtime'
local createMenu=require 'kernel.client.menu.whitelist'
local createAfk=require 'kernel.client.menu.afk'
return function(state,ports)
    local producer,work,admin,medical=assert(state.ProducerCore),assert(state.WorkMenus),assert(state.AdministrationMenus),assert(state.AutoMedicClientCore)
    local client=assert(ports.client)
    assert(producer.State==state and work.State==state and admin.State==state and medical.State==state,'canonical state required')
    assert(client==work.Client and client==medical.Client and client.Menu==work.Menu and work.Menu==admin.Menu
        and work.Shared==admin.Shared,'canonical controller/shared required')
    assert(client.ForgeSession==medical.Session.Session and medical.Producer==producer,'canonical Forge Session required')
    assert(state.AccessClientCore==nil,'access client already attached')
    for _,name in ipairs({"openWhitelistMenu","openWhitelistPlayers","openWhitelistPlayerDetails","openWhitelistBanDialog","openWhitelistSettingsEditor","openWhitelistLocationPoint","openWhitelistZoneMenu","openWhitelistLocations","openWhitelistZoneEditor","openWhitelistBlipEditor","openWhitelistPlayerAction","openWhitelistQuestions","openWhitelistQuestionDetails","openWhitelistQuestionEditor","openWhitelistOptions","openWhitelistOptionEditor","openAfkSettingsEditor"})do
        assert(work.Menu[name]==nil,'access menu already attached: '..name)
    end
    local config=assert(ports.config)
    assert(config.Whitelist and config.Afk,'access config required')
    local bindings={config=config,library=assert(ports.library),native=assert(ports.native),translate=assert(ports.translate),
        session=client.ForgeSession,characterIntegration=assert(ports.characterIntegration),menu=work.Menu,shared=work.Shared}
    -- Validate/create runtime before mutating the shared menu.
    local runtime=createRuntime(bindings)
    local menu=createMenu(bindings)
    local afk=createAfk(bindings)
    local api={State=state,Client=client,Session=medical.Session,Menu=work.Menu,Shared=work.Shared,
        Runtime=runtime,Whitelist=runtime.State,WhitelistMenu=menu,AfkMenu=afk,Config=config,
        Events=runtime.Events,Callbacks=runtime.Callbacks,Threads=runtime.Threads}
    state.AccessClientCore=api
    return api
end
