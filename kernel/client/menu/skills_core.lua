-- Extend the existing work menus and client skill replica, without replacing state.
local createMenu=require 'kernel.client.menu.skills'
return function(state,ports)
    local work,admin,jobs,skills=assert(state.WorkMenus),assert(state.AdministrationMenus),assert(state.JobClientCore),assert(state.SkillClientCore)
    assert(work.State==state and admin.State==state and jobs.State==state and skills.State==state,'canonical client state required')
    assert(state.SkillMenus==nil,'skills menus already attached')
    local client=assert(ports.client)
    assert(client==work.Client and client==jobs.Client and client==skills.Client and client.Menu==work.Menu
        and work.Menu==admin.Menu and work.Shared==admin.Shared,'canonical controller/shared required')
    for _,name in ipairs({"openSkillsMenu","openPlayerSkillsMenu","openPlayerReputationsMenu","openPlayerSkillDetails","openSkillList","openSkillDetails","openSkillEditor","openReputationList","openReputationDetails","openReputationEditor","openSkillLevelList","openSkillLevelDetails","openSkillLevelEditor"})do
        assert(work.Menu[name]==nil,'skills method already attached: '..name)
    end
    local config=assert(ports.config)
    assert(config.Skills==skills.Config,'canonical skills config required')
    local api=createMenu({menu=work.Menu,shared=work.Shared,config=config,library=ports.library,native=ports.native})
    api.State,api.Client,api.Config=state,client,config.Skills
    state.SkillMenus=api
    return api
end

