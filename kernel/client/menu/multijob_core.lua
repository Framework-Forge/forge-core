-- Extend the canonical 25 menu, retaining 22 Shared and 23/24 state.
local createMenus=require 'kernel.client.menu.multijob'
return function(state,ports)
    local work,admin,jobs=assert(state.WorkMenus),assert(state.AdministrationMenus),assert(state.JobClientCore)
    assert(work.State==state and admin.State==state and jobs.State==state,'canonical client state required')
    assert(state.MultiJobMenus==nil,'multi-job menus already attached')
    local client=assert(ports.client)
    assert(client==work.Client and client==jobs.Client and client.Menu==work.Menu and work.Menu==admin.Menu
        and work.Shared==admin.Shared,'canonical controller/shared required')
    local config=assert(ports.config)
    assert(type(config.MultiJob)=='table','multi-job config required')
    for _,name in ipairs({'openMultiJobMenu','openMultiJobDetails','openMultiJobAdminMenu','openMultiJobSettingsEditor',
        'openMultiJobAdminAdd','openMultiJobAdminRemove','openMultiJobAdminView'})do
        assert(work.Menu[name]==nil,'multi-job method already attached: '..name)
    end
    local api=createMenus({menu=work.Menu,shared=work.Shared,config=config,native=ports.native})
    api.State,api.Client,api.Config=state,client,config.MultiJob
    state.MultiJobMenus=api
    return api
end

