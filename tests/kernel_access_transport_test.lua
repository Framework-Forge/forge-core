local A=dofile('tests/kernel_access_harness.lua')
local n=0
local function case(name,fn)A.case(name,fn);n=n+1 end
case('exact-classification',function(r)
    local admin,player=0,0;for _,v in pairs(r.security.registrations)do if v.access=='admin'then admin=admin+1 else player=player+1 end end
    assert(admin==8 and player==2);return r.security.registrations
end)
for _,key in ipairs({'getConfig','saveConfig','listPlayers','add','remove','ban'})do
    case('deny-'..key,function(r)r.manage=false;local ok,e=r.callbacks[r.config.Whitelist.Callbacks[key]](1,2);assert(not ok and e=='no_permission')end)
end
for _,key in ipairs({'getSettings','saveSettings'})do
    case('afk-deny-'..key,function(r)r.manage=false;local ok,e=r.callbacks[r.config.Afk.Callbacks[key]](1,{});assert(not ok and e=='no_permission')end)
end
case('public-check',function(r)r.manage=false;local ok,c=r.callbacks[r.config.Whitelist.Callbacks.check](1);assert(not ok and c.questions[1].options[1].value==true)end)
case('public-pre-exam',function(r)r.manage=false;assert(r.callbacks[r.config.Whitelist.Callbacks.submitPreExam](1,{}))end)
case('self-add-blocked-by-transport',function(r)r.manage=false;local ok,e=r.callbacks[r.config.Whitelist.Callbacks.add](1);assert(not ok and e=='no_permission'and not r.records.C1)end)
case('admin-get',function(r)assert(r.callbacks[r.config.Whitelist.Callbacks.getConfig](1))end)
case('admin-afk-save',function(r)assert(r.callbacks[r.config.Afk.Callbacks.saveSettings](1,{enabled=true,minutes=3}))end)
case('invalid-source',function(r)local ok,e=r.callbacks[r.config.Whitelist.Callbacks.check](0);assert(not ok and e=='invalid_player')end)
case('rate-limited',function(r)local cb=r.callbacks[r.config.Whitelist.Callbacks.check];for i=1,15 do cb(1)end;local ok,e=cb(1);assert(not ok and e=='rate_limited')end)
case('drop-clears-quota',function(r)local cb=r.callbacks[r.config.Whitelist.Callbacks.check];for i=1,16 do cb(1)end;r.event('playerDropped');local _,e=cb(1);assert(type(e)=='table')end)
print('PASS access callback differentials '..n)
