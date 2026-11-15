local R=dofile('tests/kernel_server_settings_harness.lua')
local count=0
local function case(n,fn)R.case(n,fn);count=count+1 end
R.H.same(R.config(true),R.config(false),'whole configs');count=count+1
case('default not loaded',function(r)assert(r.p.getSettings().password==''and not r.p.getSettings().enabled)end)
case('load safe clone',function(r)r.p.load();local s=r.p.getSafeSettings();assert(s.password=='********');s.enabled=false;assert(r.p.getSettings().enabled)end)
case('start repeats load',function(r)r.p.start();r.p.start()end)
for _,value in ipairs({true,false,1,'sim','yes','false'})do
    case('normalize '..tostring(value),function(r)return r.p.save(1,{enabled=value,password='fixture-new',support_link='Link',
        card_title='Title',card_description='Body',submit_text='Go'})end)
end
case('empty enabled refused',function(r)local ok,why=r.p.save(1,{enabled=true});assert(not ok and why=='empty_password')end)
case('disabled empty allowed',function(r)assert(r.p.save(1,{enabled=false,password=''}))end)
case('mask sentinel retains',function(r)r.p.start();assert(r.p.save(1,{enabled=true,password='********'}));assert(r.p.getSettings().password=='fixture-pass')end)
case('mask before load empty refused',function(r)local ok,e=r.p.save(1,{enabled=true,password='********'});assert(not ok and e=='empty_password')end)
case('job denies no ace fallback',function(r)r.jobResult=false;assert(not r.p.canManage(0));return r.p.save(1,{password='fixture-new'})end)
case('job truthy raw',function(r)r.jobResult=1;assert(r.p.canManage(1)==1);return r.p.save(1,{password='fixture-new'})end)
case('job absent console',function(r)r.services.JobService=nil;assert(r.p.canManage(0));return r.p.save(0,{password='fixture-new'})end)
case('job absent ace',function(r)r.services.JobService=nil;r.ace=false;assert(not r.p.canManage(1));r.ace=true;assert(r.p.canManage(1))end)
case('job error',function(r)r.jobError=true;return r.p.save(1,{password='fixture-new'})end)
case('save failure retains state',function(r)r.p.load();r.m.onWrite=function()return false end;local ok,e=r.p.save(1,{enabled=true,password='fixture-new'});assert(not ok and e=='save_failed'and r.p.getSettings().password=='fixture-pass')end)
case('corrupt load',function(r)r.m.files[r.config.Password.Storage.file]='corrupt';assert(not pcall(r.p.load))end)
case('backup recovery',function(r)
    local path=r.config.Password.Storage.file;r.m.files[path..'.bak']=r.m.files[path];r.m.files[path]='corrupt'
    assert(r.p.load().password=='fixture-pass')
end)
case('get callback safe only',function(r)r.p.start();local ok,s=r.callbacks[r.config.Password.Callbacks.getSettings](1);assert(ok and s.password=='********')end)
case('get callback denied',function(r)r.jobResult=false;local ok,e=r.callbacks[r.config.Password.Callbacks.getSettings](1);assert(not ok and e=='no_permission')end)
case('save callback raw retained',function(r)
    local ok,s=r.callbacks[r.config.Password.Callbacks.saveSettings](1,{password='fixture-new'});assert(ok and s.password=='fixture-new')
end)
case('mutation lock across coroutine',function(r)
    r.p.load();local used=false
    r.m.onWrite=function()if not used then used=true;coroutine.yield('holding-json')end;return true end
    local co=coroutine.create(function()assert(r.p.save(1,{password='fixture-first'}))end)
    local ok,msg=coroutine.resume(co);assert(ok and msg=='holding-json')
    local saved,why=r.p.save(2,{password='fixture-second'});assert(not saved and why=='busy')
    assert(coroutine.resume(co));assert(r.p.getSettings().password=='fixture-first')
end)
print('PASS server password differentials '..count)
