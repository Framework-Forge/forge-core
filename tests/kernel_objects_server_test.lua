local R=dofile('tests/kernel_objects_harness.lua')
local H,n=R.H,0
H.same(R.config(true),R.config(false),'whole Objects config')
local function case(name,fn,raw)R.case(name,fn,raw);n=n+1 end
case('unstarted query unchanged',function(r)local p=r.service.getAll();assert(p.enabled==false and #p.scenes==0)end,true)
case('start only once',function(r)local before=#r.m.trace;assert(r.service.start());assert(before==#r.m.trace)end)
case('counts and detached objects',function(r)local p=r.service.getAll();assert(p.scenes[1].count==1 and p.scenes[2].count==0)
    p.objects[1].model='CHANGED';assert(r.service.getAll().objects[1].model=='prop_box')end)
case('public projection omits admin fields',function(r)local p=r.state.get('objects');assert(p.objects[1]and not p.scenes and not p.imageServer);r.advance(0)end)
case('Job precedence on console',function(r)r.jobResult=false;assert(not r.service.canManage(0))end)
case('ACE fallback',function(r)r.services.JobService=nil;r.ace=false;assert(r.service.canManage(0)and not r.service.canManage(2))end)
case('ACE default',function(r)r.services.JobService=nil;r.config.AdminAce=nil;assert(r.service.canManage(2))end)
case('Job errors',function(r)r.jobError=true;return r.service.createScene(2,'X')end)
case('Job raw truthy',function(r)r.jobResult=1;return r.service.createScene(2,'X')end)
for _,name in ipairs({'','  ',' New Scene ',123,false})do case('scene name '..tostring(name),function(r)return r.service.createScene(2,name)end)end
case('new scene counter',function(r)local ok,p=r.service.createScene(2,'NEW');assert(ok and p.scenes[3].id==3 and r.service.state.nextSceneId==4)end)
case('rename',function(r)local ok,p=r.service.renameScene(2,'1',' Rename ');assert(ok and p.scenes[1].name=='Rename')end)
case('rename bad name',function(r)return r.service.renameScene(2,1,' ')end)
case('rename missing scene',function(r)return r.service.renameScene(2,999,'X')end)
case('delete nonempty refused',function(r)local ok,e=r.service.deleteScene(2,1);assert(not ok and e=='scene_not_empty')end)
case('delete empty',function(r)local ok,p=r.service.deleteScene(2,'2');assert(ok and #p.scenes==1)end)
case('delete missing',function(r)return r.service.deleteScene(2,'bad')end)
case('object creation multiple returns',function(r)local ok,id,p=r.service.createObject(2,{sceneid='2',model=' prop_chair ',coords={1,'2',3},rotation={x='4'}})
    assert(ok and id==2 and p.objects[2].model=='prop_chair'and p.objects[2].coords.y==2)end)
for _,obj in ipairs({false,{}, {sceneId=999,model='x'},{sceneId=1,model=' '},{sceneId=1,model='not_a_real_model'}})do
    case('object payload '..n,function(r)return r.service.createObject(2,obj)end)
end
case('update retains model scene',function(r)local ok,p=r.service.updateObject(2,1,{model='different',sceneId=2,coords={x='5.5'},heading='4'})
    assert(ok and p.objects[1].model=='prop_box'and p.objects[1].sceneId==1 and p.objects[1].coords.x==5.5 and p.objects[1].rotation.z==0)end)
case('malformed update zero transform',function(r)local ok,p=r.service.updateObject(2,1,false);assert(ok and p.objects[1].coords.x==0)end)
case('update missing',function(r)return r.service.updateObject(2,99,{})end)
case('delete object then scene',function(r)assert(r.service.deleteObject(2,1));local ok,p=r.service.deleteScene(2,1);assert(ok and #p.scenes==1)end)
case('delete object missing',function(r)return r.service.deleteObject(2,999)end)
for _,name in ipairs({'createScene','renameScene','deleteScene','createObject','updateObject','deleteObject'})do
    case('deny '..name,function(r)r.jobResult=false;local ok,e=r.service[name](2,1,'X');assert(not ok and e=='no_permission')end)
end
case('public callback getAll',function(r)r.jobResult=false;local ok,p=r.callbacks[r.config.Objects.Callbacks.getAll](1);assert(ok and #p.scenes==2)end)
case('callbacks full CRUD',function(r)local cb=r.config.Objects.Callbacks;r.callbacks[cb.createScene](2,'NEW');r.callbacks[cb.renameScene](2,3,'RENAMED')
    local ok,id=r.callbacks[cb.createObject](2,{sceneId=3,model='X'});assert(ok);assert(r.callbacks[cb.updateObject](2,id,{heading=90}));assert(r.callbacks[cb.deleteObject](2,id));assert(r.callbacks[cb.deleteScene](2,3))end)
case('invalid loaded IDs normalized',function(r)local s=R.seed();s.scenes={{id=4.8,name='A'},{id=4,name='Duplicate'},{id=0},{id='2',name='B'}}
    s.objects={{id=10,sceneid=4,model=' A '},{id=10,sceneId=4,model='B'},{id=3,sceneId=9,model='Orphan'},{id=0,sceneId=2,model='Bad'}}
    r.m.seed(r.config.Objects.Storage.file,s);local p=r.service.load();assert(#p.scenes==2 and p.scenes[1].id==2 and #p.objects==1)
    assert(r.service.state.nextSceneId==5 and r.service.state.nextObjectId==11)end)
for _,distance in ipairs({-30,0,25,26.5,'800','bad',1000000})do
    case('spawn distance '..distance,function(r)local s=R.seed();s.spawnDistance=distance;r.m.seed(r.config.Objects.Storage.file,s);return r.service.load()end)
end
case('defaults missing JSON',function(r)r.m.files={};local p=r.service.load();assert(p.enabled and #p.scenes==0 and p.spawnDistance==300)end)
case('non table recovery',function(r)r.m.seed(r.config.Objects.Storage.file,false);return r.service.load()end)
case('corruption backup recovery',function(r)local p=r.config.Objects.Storage.file;r.m.files[p]='bad';r.m.seed(p..'.bak',R.seed());return r.service.load()end)
case('corrupt start retains started',function(r)local p=r.config.Objects.Storage.file;r.m.files[p]='bad';r.m.files[p..'.bak']='bad'
    assert(not pcall(r.service.start)and r.service.started);assert(r.service.start())end,true)
case('refused save unchanged state and publication',function(r)local record=r.state.getRecord('objects');r.m.onWrite=function()return false end
    local ok,e=r.service.createScene(2,'FAIL');assert(not ok and e=='save_failed');H.same(r.state.getRecord('objects'),record)end)
case('write exception rolled back',function(r)r.m.onWrite=function()error('fixture-write',0)end;return r.service.deleteObject(2,1)end)
case('integer native writer accepted by PR',function(r)r.m.onWrite=function()return 1 end;assert(r.service.createScene(2,'ONE'))end)
for _,v in ipairs({0,1,true,false,{}})do
    case('raw wrapper return '..tostring(v),function(r)r.library.saveJsonRecovery=function()return v end;local ok,e=r.service.createScene(2,'RAW');assert(ok==(v==true or type(v)=='table'));return ok,e end)
end
case('raw nil refused',function(r)r.library.saveJsonRecovery=function()end;return r.service.createScene(2,'RAW')end)
case('publish failure after save',function(r)r.state.publish=function()error('fixture-publish',0)end;return r.service.createScene(2,'SAVED')end)
case('internal save no admin guard',function(r)r.jobResult=false;r.service.save();assert(r.service.state.revision==r.now)end)
case('same tick revision retained',function(r)local rev=r.service.state.revision;r.service.createScene(2,'SAME');assert(r.service.state.revision==rev)end)
case('new tick revision advances',function(r)r.now=r.now+1;r.service.save();assert(r.service.state.revision==r.now)end)
case('notification optional',function(r)r.library.notify=nil;return r.service.createScene(2,'X')end)
case('trim fallback',function(r)r.library.utils=nil;return r.service.renameScene(2,1,'  X  ')end)
case('mutation lock busy and release',function(r)
    local path=r.config.Objects.Storage.file;local co=coroutine.create(function()return r.library.withJsonLock(path,function()coroutine.yield('locked')end)end)
    assert(coroutine.resume(co));local ok,e=r.service.createScene(2,'BUSY');assert(not ok and e=='busy');assert(coroutine.resume(co));assert(r.service.createScene(2,'AFTER'))end)
print('PASS objects server/config differentials '..n)
