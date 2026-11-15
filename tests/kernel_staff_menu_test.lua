local Q=dofile('tests/kernel_staff_harness.lua')
local member={source=1,citizenId='ONE',name='One',permissions={'group.mod'},role='group.mod',roleLabel='Mod',displayName='[ON] One'}
local catalog={{value='group.mod',label='Mod'},{value='pr_bridge.developer',label='Developer'}}
local function data(r)
    r.reply(r.config.Staff.Callbacks.catalog,true,catalog)
    r.reply(r.config.Staff.Callbacks.getPlayers,true,{member})
    r.reply(r.config.Staff.Callbacks.getAll,true,{staff={member},onlineStaff=1,offlineStaff=0})
end
Q.uiCase('root hierarchy',function(r)r.menu.openStaffMenu();return r.last end)
for i=1,3 do Q.uiCase('root select '..i,function(r)data(r);r.menu.openStaffMenu();r.select(i)end)end
Q.uiCase('add cancel initial',function(r)r.menu.openStaffAddById()end)
Q.uiCase('add lookup failure',function(r)r.inputs={{1}};r.reply(r.config.Staff.Callbacks.getPlayers,false,'denied');r.menu.openStaffAddById()end)
Q.uiCase('add lookup malformed',function(r)r.inputs={{1}};r.reply(r.config.Staff.Callbacks.getPlayers,true,'bad');r.menu.openStaffAddById()end)
Q.uiCase('add lookup empty',function(r)r.inputs={{1}};r.menu.openStaffAddById()end)
Q.uiCase('add catalog error',function(r)r.reply(r.config.Staff.Callbacks.catalog,false,'error');r.menu.openStaffAddById(member)end)
Q.uiCase('add catalog malformed',function(r)r.reply(r.config.Staff.Callbacks.catalog,true,'bad');r.menu.openStaffAddById(member)end)
Q.uiCase('add existing cancellation',function(r)data(r);r.menu.openStaffAddById(member)end)
Q.uiCase('add full by id offset',function(r)data(r);r.inputs={{1},{1,true,false}};r.menu.openStaffAddById();return r.lastRequest()end)
Q.uiCase('add selection strict true',function(r)data(r);r.inputs={{1,1,'true'}};r.menu.openStaffAddById(member);return r.lastRequest()end)
Q.uiCase('add empty selection',function(r)data(r);r.inputs={{1,false,false}};r.menu.openStaffAddById(member);r.runTimers(500);r.runTimers(1000)end)
Q.uiCase('add failure',function(r)data(r);r.reply(r.config.Staff.Callbacks.add,false,'failed');r.inputs={{1,true,true}};r.menu.openStaffAddById(member);r.runTimers()end)
Q.uiCase('add lock duplicate after form',function(r)data(r);r.inputs={{1,true,false},{1,false,true}};r.menu.openStaffAddById(member);r.menu.openStaffAddById(member);return #r.timers end)
Q.uiCase('add await error sticks lock',function(r)
    data(r);r.inputs={{1,true,false},{1,false,true}}
    r.awaitHook=function(name)if name==r.config.Staff.Callbacks.catalog then return true,catalog end;error('fixture-await',0)end
    assert(not pcall(r.menu.openStaffAddById,member));r.awaitHook=nil;r.menu.openStaffAddById(member);return #r.timers
end)
Q.uiCase('nearby no players',function(r)r.menu.openStaffNearbyList()end)
Q.uiCase('nearby failure',function(r)r.reply(r.config.Staff.Callbacks.getPlayers,false,'denied');r.menu.openStaffNearbyList()end)
Q.uiCase('nearby select',function(r)data(r);r.menu.openStaffNearbyList();r.select(1)end)
Q.uiCase('list malformed',function(r)r.reply(r.config.Staff.Callbacks.getAll,true,{staff='bad'});r.menu.openStaffList()end)
Q.uiCase('list failure',function(r)r.reply(r.config.Staff.Callbacks.getAll,false,'denied');r.menu.openStaffList()end)
Q.uiCase('list select detail',function(r)data(r);r.menu.openStaffList();r.select(1)end)
Q.uiCase('list offline labels',function(r)
    r.reply(r.config.Staff.Callbacks.getAll,true,{staff={{citizenId='OFF',name='Offline',offline=true,role='mod'}},offlineStaff=1})
    r.menu.openStaffList();r.select(1)
end)
for _,confirmed in ipairs({'confirm','cancel'})do
    Q.uiCase('remove '..confirmed,function(r)data(r);r.alerts={confirmed};r.menu.openStaffDetails(member);r.select(2);r.runTimers(500)end)
end
Q.uiCase('remove failure',function(r)data(r);r.alerts={'confirm'};r.reply(r.config.Staff.Callbacks.remove,false,'failed');r.menu.openStaffDetails(member);r.select(2);r.runTimers(500)end)
Q.uiCase('remove no action lock',function(r)
    data(r);r.alerts={'confirm','confirm'};r.menu.openStaffDetails(member);local frame=r.last;r.select(2,frame);r.select(2,frame);return #r.timers
end)
Q.uiCase('change cancel',function(r)data(r);r.menu.openStaffChangeRole(member)end)
Q.uiCase('change checkbox payload clone',function(r)data(r);r.inputs={{false,true}};r.menu.openStaffChangeRole(member);r.runTimers();assert(member.permissions[1]=='group.mod')end)
Q.uiCase('change empty calls remove',function(r)data(r);r.inputs={{false,false}};r.menu.openStaffChangeRole(member);return r.lastRequest()end)
Q.uiCase('change failure',function(r)data(r);r.inputs={{true,false}};r.reply(r.config.Staff.Callbacks.add,false,'failed');r.menu.openStaffChangeRole(member);r.runTimers()end)
Q.uiCase('change catalog failure',function(r)r.reply(r.config.Staff.Callbacks.catalog,false,'failed');r.menu.openStaffChangeRole(member)end)
for _,permissions in ipairs({'group.mod',{permissions={'group.mod'}},{['group.mod']=true}, {}})do
    Q.uiCase('selection input '..tostring(permissions),function(r)data(r);local m=Q.H.copy(member);m.permissions=permissions;r.menu.openStaffChangeRole(m)end)
end
Q.uiCase('timer reopens old list',function(r)data(r);r.inputs={{1,true,false}};r.menu.openStaffAddById(member);r.last=nil;r.runTimers(500);assert(r.last)end)
Q.uiCase('stale catalog maps retained index',function(r)
    data(r);r.inputHook=function()r.reply(r.config.Staff.Callbacks.catalog,true,{{value='new.permission'}});return{false,true}end
    r.menu.openStaffChangeRole(member);return r.lastRequest()
end)
Q.uiCase('open callback acknowledges',function(r)return r.staff.Callbacks[r.config.Staff.Callbacks.openMenu]()end)
Q.uiCase('renderer false ignored',function(r)r.uiReturn=false;return r.staff.Callbacks[r.config.Staff.Callbacks.openMenu]()end)
print('PASS staff menus: '..Q.count..' differential cases; six complete menus/client callback, checkbox indices/parents/payloads/cancel/errors/locks/timers; no real UI')

