local R=dofile('tests/kernel_vinewood_harness.lua')
local H,n=R.H,0
H.same(R.config(true),R.config(false),'whole config including eight vectors/headings')
local function case(name,fn)R.case(name,fn);n=n+1 end
case('defaults detached',function(r)local v=r.service.getSettings();assert(v.text=='FORGE');v.text='X';assert(r.service.getSettings().text=='FORGE')end)
case('start once',function(r)assert(r.service.start());local before=#r.m.trace;assert(r.service.start());assert(before==#r.m.trace);r.advance(0)end)
case('load and public copy',function(r)r.service.load();local v=r.state.get('vinewood');v.text='BAD';assert(r.state.get('vinewood').text=='FORGE');r.advance(0)end)
case('fresh revision on read',function(r)local rev=r.service.getSettings().revision;r.now=r.now+1;assert(r.service.getSettings().revision==rev+1)end)
case('denied save',function(r)r.jobResult=false;local ok,e=r.service.save(2,{});assert(not ok and e=='no_permission')end)
case('console JobService precedence',function(r)r.jobResult=false;assert(not r.service.canManage(0))end)
case('console fallback',function(r)r.services.JobService=nil;r.ace=false;assert(r.service.canManage(0));assert(not r.service.canManage(2))end)
case('ACE default',function(r)r.services.JobService=nil;r.config.AdminAce=nil;return r.service.canManage(2)end)
case('Job truthy',function(r)r.jobResult=1;return r.service.save(2,{})end)
case('Job error',function(r)r.jobError=true;return r.service.save(2,{})end)
for _,value in ipairs({'forge','  new city  ','a1b2c3','ABCDEFGHIJKLM','123','áé ç','     ',false,234})do
    case('text '..tostring(value),function(r)return r.service.save(2,{text=value})end)
end
for _,value in ipairs({'#fff','abc',' #0a ff 34 ','#000000','#12345678','#12','#gggggg','white','',false,123456})do
    case('color '..tostring(value),function(r)return r.service.save(2,{color=value})end)
end
for _,value in ipairs({true,false,'true','1','yes','sim','on','false',0,1})do
    case('enabled '..tostring(value),function(r)return r.service.save(2,{enabled=value})end)
end
case('malformed settings',function(r)return r.service.save(2,false)end)
case('unknown fields discarded',function(r)local ok,v=r.service.save(2,{text='AB',extra='drop',revision=1});assert(ok and v.extra==nil and v.revision~=1)end)
case('missing JSON defaults',function(r)r.m.files={};return r.service.load()end)
case('non table JSON defaults',function(r)r.m.seed(r.config.Vinewood.Storage.file,false);return r.service.load()end)
case('backup recovery',function(r)local p=r.config.Vinewood.Storage.file;r.m.files[p]='invalid';r.m.seed(p..'.bak',{text='BACK',color='#abc'});return r.service.load()end)
case('corrupt both',function(r)local p=r.config.Vinewood.Storage.file;r.m.files[p]='bad';r.m.files[p..'.bak']='bad'
    local ok=pcall(r.service.start);assert(not ok and r.service.started);return r.service.start()end)
case('write refusal',function(r)r.service.start();r.m.onWrite=function()return false end
    local before=r.state.getRecord('vinewood');local ok,e=r.service.save(2,{text='NO'});assert(not ok and e=='save_failed');H.same(r.state.getRecord('vinewood'),before)end)
case('native integer writer success',function(r)r.m.onWrite=function()return 1 end;assert(r.service.save(2,{text='OK'}))end)
case('native zero writer refused',function(r)r.m.onWrite=function()return 0 end;local ok,e=r.service.save(2,{text='NO'});assert(not ok and e=='save_failed')end)
for _,value in ipairs({true,false,1,0,{reason='legacy'}})do
    case('raw save acknowledgement '..tostring(value),function(r)r.library.saveJsonRecovery=function()return value end
        local ok,e=r.service.save(2,{});assert(ok==(value==true or type(value)=='table'));return ok,e end)
end
case('raw nil save refused',function(r)r.library.saveJsonRecovery=function()end;return r.service.save(2,{})end)
case('publish fails after file save',function(r)r.state.publish=function()error('fixture-publish',0)end;return r.service.save(2,{text='SAVED'})end)
case('read error leaves started',function(r)r.library.loadJsonRecovery=function()error('fixture-load',0)end;return r.service.start()end)
case('no notify console',function(r)return r.service.save(0,{})end)
case('notification missing optional',function(r)r.library.notify=nil;return r.service.save(2,{})end)
case('trim missing optional',function(r)r.library.utils=nil;return r.service.save(2,{text='  ab  '})end)
case('clone missing optional',function(r)r.library.table=nil;r.library.loadJsonRecovery=function()return false end;return r.service.load()end)
case('read callback denied',function(r)r.jobResult=false;return r.callbacks[r.config.Vinewood.Callbacks.getSettings](2)end)
case('read callback allowed',function(r)return r.callbacks[r.config.Vinewood.Callbacks.getSettings](2)end)
case('write callback',function(r)return r.callbacks[r.config.Vinewood.Callbacks.saveSettings](2,{text='FLOW',color='#ace'})end)
case('same tick publication renderer revision risk',function(r)r.service.start();local rev=r.state.get('vinewood').revision
    r.service.save(2,{text='NEW'});assert(r.state.get('vinewood').revision==rev);r.advance(0)end)
case('no change later tick publishes',function(r)r.service.start();local rev=r.state.getRecord('vinewood').revision
    r.now=r.now+1;r.service.load();assert(r.state.getRecord('vinewood').revision>rev)end)
print('PASS Vinewood server/config differentials '..n)
