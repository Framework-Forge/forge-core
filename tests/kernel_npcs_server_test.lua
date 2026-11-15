local R=dofile('tests/kernel_npcs_harness.lua')
local H,n=R.H,0
H.same(R.config(true),R.config(false),'whole NPC settings/models/types/animation presets')
assert(#R.config(true).PedModels>500 and #R.config(true).AnimationPresets==14)
local function case(name,fn,raw)R.case(name,fn,raw);n=n+1 end
case('inert query',function(r)assert(not r.service.getAll().enabled)end,true)
case('start once',function(r)local size=#r.m.trace;assert(r.service.start());assert(size==#r.m.trace)end)
case('detached public projection',function(r)local p=r.service.getAll();assert(p.groups[1].count==1 and p.groups[2].count==0);p.npcs[1].model='X';assert(r.service.getAll().npcs[1].model~='X');assert(not r.state.get('npcs').groups)end)
case('Job precedence',function(r)r.jobResult=false;assert(not r.service.canManage(0))end)
case('ACE fallback',function(r)r.services.JobService=nil;r.ace=false;assert(r.service.canManage(0)and not r.service.canManage(2))end)
case('Job errors',function(r)r.jobError=true;return r.service.createGroup(2,'X')end)
for _,name in ipairs({'','  ',' Group ',123,false,{name=' Table ',description=' D '}})do case('name '..n,function(r)return r.service.createGroup(2,name)end)end
case('rename',function(r)local ok,p=r.service.renameGroup(2,'1',{name=' New ',description=' Desc '});assert(ok and p.groups[1].name=='New'and p.groups[1].description=='Desc')end)
case('rename missing',function(r)return r.service.renameGroup(2,99,'X')end)
case('rename empty',function(r)return r.service.renameGroup(2,1,' ')end)
case('delete nonempty',function(r)local ok,e=r.service.deleteGroup(2,1);assert(not ok and e=='group_not_empty')end)
case('delete empty',function(r)local ok,p=r.service.deleteGroup(2,2);assert(ok and #p.groups==1)end)
case('delete missing',function(r)return r.service.deleteGroup(2,99)end)
case('create returns id',function(r)local ok,id,p=r.service.createNpc(2,{groupid='2',model=' m ',coords={1,'2',3},heading=-45,interaction={mode='both',access={jobGrade='3',gangGrade=-2}}});assert(ok and id==2);local v=p.npcs[2];assert(v.model=='m'and v.heading==315 and v.interaction.access.grade==3 and v.interaction.access.gangGrade==0)end)
for _,data in ipairs({false,{}, {groupId=99,model='x'},{groupId=1,model=' '},{groupId=1,model='not_real'}})do case('create payload '..n,function(r)return r.service.createNpc(2,data)end)end
case('update merge preserves id/group but changes model',function(r)local ok,p=r.service.updateNpc(2,1,{id=55,groupId=2,model='new',coords={x=9},interaction={access={job='police'}}});local v=p.npcs[1];assert(ok and v.id==1 and v.groupId==1 and v.model=='new'and v.coords.y==2 and v.interaction.label=='Talk')end)
case('malformed update preserves transform',function(r)local ok,p=r.service.updateNpc(2,1,false);assert(ok and p.npcs[1].coords.x==1)end)
case('update missing',function(r)return r.service.updateNpc(2,99,{})end)
case('delete then group',function(r)assert(r.service.deleteNpc(2,1));assert(r.service.deleteGroup(2,1))end)
case('delete missing NPC',function(r)return r.service.deleteNpc(2,99)end)
for _,key in ipairs({'createGroup','renameGroup','deleteGroup','createNpc','updateNpc','deleteNpc'})do case('denied '..key,function(r)r.jobResult=false;local ok,e=r.service[key](2,1,'X');assert(not ok and e=='no_permission')end)end
case('public callback',function(r)r.jobResult=false;local ok,p=r.callbacks[r.config.Npcs.Callbacks.getAll](1);assert(ok and #p.npcs==1)end)
case('callback CRUD',function(r)local c=r.config.Npcs.Callbacks;assert(r.callbacks[c.createGroup](2,'New'));assert(r.callbacks[c.renameGroup](2,3,'Rename'));local ok,id=r.callbacks[c.createNpc](2,{groupId=3,model='m'});assert(ok);assert(r.callbacks[c.updateNpc](2,id,{name='n'}));assert(r.callbacks[c.deleteNpc](2,id));assert(r.callbacks[c.deleteGroup](2,3))end)
case('normalization IDs',function(r)local v=R.seed();v.groups={{id=4.8},{id=4},{id=0},{id='2'}};v.npcs={{id=10,groupId=4,model='m'},{id=10,groupId=4,model='dup'},{id=9,groupId=99,model='orphan'}};r.m.seed(r.config.Npcs.Storage.file,v);local p=r.service.load();assert(#p.groups==2 and #p.npcs==1 and r.service.state.nextNpcId==11 and r.service.state.nextGroupId==5)end)
for _,mode in ipairs({'target','drawtext','both','none','unknown',' TARGET '})do case('interaction mode '..mode,function(r)local ok,id,p=r.service.createNpc(2,{groupId=1,model='m',interaction={mode=mode,distance=-2}});assert(ok and p.npcs[2].interaction.distance==1);return p.npcs[2].interaction end)end
for _,value in ipairs({-30,0,25,26.5,'800','bad',1000000})do case('distance '..value,function(r)local v=R.seed();v.spawnDistance=value;r.m.seed(r.config.Npcs.Storage.file,v);return r.service.load()end)end
for _,value in ipairs({true,false,'yes','sim','1','FALSE',0})do case('enabled '..tostring(value),function(r)local v=R.seed();v.enabled=value;v.npcs[1].enabled=value;r.m.seed(r.config.Npcs.Storage.file,v);return r.service.load()end)end
case('missing JSON defaults',function(r)r.m.files={};local p=r.service.load();assert(p.enabled and #p.groups==0 and p.spawnDistance==120)end)
case('backup recovery',function(r)local p=r.config.Npcs.Storage.file;r.m.files[p]='bad';r.m.seed(p..'.bak',R.seed());return r.service.load()end)
case('start failure flag retained',function(r)local p=r.config.Npcs.Storage.file;r.m.files[p]='bad';r.m.files[p..'.bak']='bad';assert(not pcall(r.service.start)and r.service.started);assert(r.service.start())end,true)
case('refused save no publish',function(r)local before=r.state.getRecord('npcs');r.m.onWrite=function()return false end;local ok,e=r.service.createGroup(2,'FAIL');assert(not ok and e=='save_failed');H.same(r.state.getRecord('npcs'),before)end)
case('save throws',function(r)r.m.onWrite=function()error('fixture-write',0)end;return r.service.deleteNpc(2,1)end)
for _,v in ipairs({0,1,true,false,{}})do case('raw writer '..n,function(r)r.library.saveJsonRecovery=function()return v end;local ok=r.service.createGroup(2,'RAW');assert(ok==(v==true or type(v)=='table'))end)end
case('nil writer refused',function(r)r.library.saveJsonRecovery=function()end;return r.service.createGroup(2,'X')end)
case('internal save no admin guard',function(r)r.jobResult=false;assert(r.service.save())end)
case('same tick revision',function(r)local rev=r.service.state.revision;r.service.createGroup(2,'X');assert(r.service.state.revision==rev)end)
case('notification optional',function(r)r.library.notify=nil;return r.service.createGroup(2,'X')end)
case('trim fallback',function(r)r.library.utils=nil;return r.service.renameGroup(2,1,' X ')end)
case('lock busy released',function(r)local p=r.config.Npcs.Storage.file;local co=coroutine.create(function()return r.library.withJsonLock(p,function()coroutine.yield('locked')end)end);assert(coroutine.resume(co));local ok,e=r.service.createGroup(2,'BUSY');assert(not ok and e=='busy');assert(coroutine.resume(co));assert(r.service.createGroup(2,'AFTER'))end)
print('PASS NPC server/config differentials '..n)
