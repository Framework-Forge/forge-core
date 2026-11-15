-- Complete central/work UI attached to the same local menu/replica/zone holder; never opens or installs it.
local createCentral=require 'kernel.client.menu.central'
local createJobs=require 'kernel.client.menu.jobs'
local createBusiness=require 'kernel.client.menu.business_admin'
local createMei=require 'kernel.client.menu.mei'
local createCreator=require 'kernel.client.menu.creator'
return function(state,ports)
    local producer,legacy,jobs,zones,admin=assert(state.ProducerCore),assert(state.LegacyCore),assert(state.JobClientCore),assert(state.JobZoneCore),assert(state.AdministrationMenus)
    assert(producer.State==state and legacy.State==state and jobs.State==state and zones.State==state and admin.State==state,'canonical client state required')
    assert(state.WorkMenus==nil,'work menus already attached')
    local client=assert(ports.client)
    assert(client==jobs.Client and client==zones.Client and client.Menu==admin.Menu and client.JobState==jobs.JobState,'canonical controller/replica required')
    assert(client.JobCreator==nil,'creator already attached')
    local menu,shared=admin.Menu,admin.Shared
    for _,name in ipairs({"openMain","openJobsMenu","openGroupList","openPaymentSettings","openPaymentEditor","openGroupCreator","openGroupDetails","openGroupEditor","openGroupPointList","openGroupPointDetails","openGroupPointEditor","openGroupStashEditor","openGroupDutyEditor","removeGroupPoint","openGradeList","openGradeDetails","openGradeEditor","removeGrade","openBossPanel","openBossEmployees","openBossEmployeeActions","openStationBusinessList","openStationBusinessPointDetails","openStationBusinessPointEditor","openStationShopItems","openStationShopItemEditor","openStationApplicationQuestions","openStationQuestionEditor","openStationCandidates","openStationCandidateActions","openBossApplications","openMeiSettingsEditor","openMeiCreator"})do
        assert(menu[name]==nil,'work menu already attached: '..name)
    end
    local bindings={menu=menu,shared=shared,client=client,library=ports.library,config=ports.config,
        native=ports.native,translate=ports.translate,integrations=ports.integrations}
    local central=createCentral(bindings)
    local jobMenus=createJobs(bindings)
    local businessMenus=createBusiness(bindings)
    local mei=createMei(bindings)
    local creator=createCreator(bindings)
    local api={State=state,Menu=menu,Shared=shared,Client=client,Central=central,Jobs=jobMenus,
        Business=businessMenus,Mei=mei,Creator=creator.Creator,Events=central.Events,Callbacks=mei.Callbacks,Exports=mei.Exports}
    api.Keybinds={
        {name='forge_core_open_menu',description='Forge Core: painel administrativo',
         defaultKey=ports.config.Keybind or {'ALT','7'},onPressed=function() return menu.openMain() end},
        {name='forge_core_open_player_menu',description='Forge Core: menu do jogador',
         defaultKey=ports.config.PlayerKeybind or {'F9'},onPressed=function() return menu.openPlayerMenu() end},
    }
    client.JobCreator,state.WorkMenus=creator.Creator,api
    return api
end

