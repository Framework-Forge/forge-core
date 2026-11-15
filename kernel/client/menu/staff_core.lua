-- Extend canonical 22/25 menu references without duplicate state or bindings.
local createMenu=require 'kernel.client.menu.staff'
return function(state,ports)
    local work,admin,jobs=assert(state.WorkMenus),assert(state.AdministrationMenus),assert(state.JobClientCore)
    assert(work.State==state and admin.State==state and jobs.State==state,'canonical client state required')
    assert(state.StaffMenus==nil,'staff menus already attached')
    local client=assert(ports.client)
    assert(client==work.Client and client==jobs.Client and client.Menu==work.Menu and work.Menu==admin.Menu
        and work.Shared==admin.Shared,'canonical controller/shared required')
    for _,name in ipairs({'openStaffMenu','openStaffAddById','openStaffNearbyList','openStaffList','openStaffDetails','openStaffChangeRole'})do
        assert(work.Menu[name]==nil,'staff method already attached: '..name)
    end
    local config=assert(ports.config);assert(type(config.Staff)=='table','staff config required')
    local api=createMenu({menu=work.Menu,shared=work.Shared,config=config,native=ports.native})
    api.State,api.Client,api.Config=state,client,config.Staff
    state.StaffMenus=api
    return api
end

