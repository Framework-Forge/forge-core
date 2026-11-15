local R=dofile('tests/kernel_spotlights_harness.lua')
local H,n=R.H,0
H.same(R.P.snapshot(R.config(true)),R.P.snapshot(R.config(false)),'whole config/color APIs')
local function case(name,fn,raw)R.case(name,fn,raw);n=n+1 end
for _,v in ipairs({'#abc','abc','#abcdef','AABBCC','#aabbccdd','#aabbccd','rgb(1, 2, 3)','rgba(1.5, 256, 0, 0.5)','1, 2, 3','-1,2,3','bad','',false,0,
 {r=-5,g=12.5,b=999},{x=5,y='6',z=7},{1,2,3},{}})do
 case('color '..n,function(r)local c=r.config.Spotlights;return c.NormalizeColor(v),c.ColorToHex(v)end)
end
case('fallback color',function(r)local c=r.config.Spotlights;H.same(c.NormalizeColor(false,{r=-1,g='12.5',b=999}),{r=0,g=13,b=255});assert(c.ColorToHex('#abc')=='#aabbcc')end)
case('inert state',function(r)assert(not r.service.getAll().enabled and #r.service.getAll().lights==0)end,true)
case('start once',function(r)local before=#r.m.trace;assert(r.service.start()and #r.m.trace==before)end)
case('counts/copy/public projection',function(r)local p=r.service.getAll();assert(p.groups[1].count==1 and p.groups[2].count==0);p.lights[1].name='changed';assert(r.service.getAll().lights[1].name=='Light A');assert(not r.state.get('spotlights').groups)end)
case('job precedence console',function(r)r.jobResult=false;assert(not r.service.canManage(0))end)
case('ACE fallback',function(r)r.services.JobService=nil;r.ace=false;assert(r.service.canManage(0)and not r.service.canManage(2))end)
case('job throws',function(r)r.jobError=true;return r.service.createGroup(2,'x')end)
for _,v in ipairs({'','  ',' New ',123,false})do case('group name '..n,function(r)return r.service.createGroup(2,v)end)end
case('rename',function(r)local ok,p=r.service.renameGroup(2,'1',' Renamed ');assert(ok and p.groups[1].name=='Renamed')end)
case('rename invalid',function(r)return r.service.renameGroup(2,1,' ')end)
case('rename missing',function(r)return r.service.renameGroup(2,99,'X')end)
case('delete nonempty',function(r)local ok,e=r.service.deleteGroup(2,1);assert(not ok and e=='group_not_empty')end)
case('delete empty',function(r)assert(r.service.deleteGroup(2,2))end)
case('delete missing',function(r)return r.service.deleteGroup(2,99)end)
case('create aliases',function(r)local ok,id,p=r.service.createLight(2,{groupid='2',name=' New ',initalCoords={1,'2',3},secondCoords={4,5,6},data={rgb='#abc',distance=90,brightness=2,hardness=3,radius=4}});local v=p.lights[2];assert(ok and id==2 and v.origin.y==2 and v.target.z==6 and v.color.r==170 and v.distance==90 and v.name=='New')end)
case('alternative initialCoords',function(r)local ok,id,p=r.service.createLight(2,{groupId=1,initialCoords={7,8,9}});assert(ok and p.lights[2].origin.x==7)end)
case('invalid group',function(r)return r.service.createLight(2,{groupId=99})end)
case('malformed create',function(r)return r.service.createLight(2,false)end)
case('move group',function(r)local ok,p=r.service.updateLight(2,1,{groupId=2});assert(ok and p.groups[1].count==0 and p.groups[2].count==1 and p.lights[1].origin.x==1)end)
case('move to missing group refused',function(r)local ok,e=r.service.updateLight(2,1,{groupId=99});assert(not ok and e=='group_not_found')end)
case('update false enabled',function(r)local ok,p=r.service.updateLight(2,1,{enabled=false,color='#ff0000',brightness=0,distance=0});assert(ok and not p.lights[1].enabled and p.lights[1].brightness==0 and p.lights[1].distance==0.1)end)
case('malformed update unchanged',function(r)local ok,p=r.service.updateLight(2,1,false);assert(ok and p.lights[1].origin.x==1)end)
case('id cannot change',function(r)local ok,p=r.service.updateLight(2,1,{id=9,name='New'});assert(ok and p.lights[1].id==1)end)
case('update missing',function(r)return r.service.updateLight(2,99,{})end)
case('delete light and group',function(r)assert(r.service.deleteLight(2,1));assert(r.service.deleteGroup(2,1))end)
case('delete missing light',function(r)return r.service.deleteLight(2,99)end)
for _,key in ipairs({'createGroup','renameGroup','deleteGroup','createLight','updateLight','deleteLight'})do
 case('deny '..key,function(r)r.jobResult=false;local ok,e=r.service[key](2,1,'X');assert(not ok and e=='no_permission')end)
end
case('public getAll callback',function(r)r.jobResult=false;local ok,p=r.callbacks[r.config.Spotlights.Callbacks.getAll](1);assert(ok and #p.groups==2)end)
case('callbacks CRUD',function(r)local c=r.config.Spotlights.Callbacks;assert(r.callbacks[c.createGroup](2,'New'));assert(r.callbacks[c.renameGroup](2,3,'Rename'));local ok,id=r.callbacks[c.createLight](2,{groupId=3});assert(ok);assert(r.callbacks[c.updateLight](2,id,{name='New'}));assert(r.callbacks[c.deleteLight](2,id));assert(r.callbacks[c.deleteGroup](2,3))end)
case('normalize IDs/orphans/counters',function(r)local p=R.seed();p.groups={{id=4.8},{id=4},{id=0},{id='2',name='B'}};p.lights={{id=10,groupId=4},{id=10,groupId=4},{id=3,groupId=99},{id=0,groupId=2}};r.m.seed(r.config.Spotlights.Storage.file,p);local s=r.service.load();assert(#s.groups==2 and #s.lights==1 and s.groups[1].id==2 and r.service.state.nextLightId==11 and r.service.state.nextGroupId==5)end)
for _,v in ipairs({-10,0,25,26.5,'800','bad',1000000})do case('drawDistance '..v,function(r)local p=R.seed();p.drawDistance=v;r.m.seed(r.config.Spotlights.Storage.file,p);return r.service.load()end)end
for _,v in ipairs({true,false,'yes','sim','1','FALSE',0})do case('enabled '..tostring(v),function(r)local p=R.seed();p.enabled=v;p.lights[1].enabled=v;r.m.seed(r.config.Spotlights.Storage.file,p);return r.service.load()end)end
case('minimum parameters',function(r)local ok,id,p=r.service.createLight(2,{groupId=1,distance=-1,brightness=-1,hardness=-1,radius=-1});local v=p.lights[2];assert(ok and v.distance==0.1 and v.brightness==0 and v.radius==0 and v.hardness==0)end)
case('no upper server clamp',function(r)local ok,id,p=r.service.createLight(2,{groupId=1,distance=5000,brightness=900,hardness=800,radius=700});assert(ok and p.lights[2].brightness==900 and p.lights[2].distance==5000)end)
case('defaults missing JSON',function(r)r.m.files={};local p=r.service.load();assert(p.enabled and p.drawDistance==450 and #p.lights==0)end)
case('backup recovery',function(r)local p=r.config.Spotlights.Storage.file;r.m.files[p]='bad';r.m.seed(p..'.bak',R.seed());return r.service.load()end)
case('load failure started flag retained',function(r)local p=r.config.Spotlights.Storage.file;r.m.files[p]='bad';r.m.files[p..'.bak']='bad';assert(not pcall(r.service.start)and r.service.started);assert(r.service.start())end,true)
case('save refused no publication',function(r)local before=r.state.getRecord('spotlights');r.m.onWrite=function()return false end;local ok,e=r.service.deleteLight(2,1);assert(not ok and e=='save_failed');H.same(r.state.getRecord('spotlights'),before)end)
case('writer exception',function(r)r.m.onWrite=function()error('fixture-write',0)end;return r.service.deleteLight(2,1)end)
for _,v in ipairs({0,1,true,false,{}})do case('raw writer '..n,function(r)r.library.saveJsonRecovery=function()return v end;local ok=r.service.createGroup(2,'RAW');assert(ok==(v==true or type(v)=='table'))end)end
case('raw nil refused',function(r)r.library.saveJsonRecovery=function()end;return r.service.createGroup(2,'X')end)
case('internal save no guard',function(r)r.jobResult=false;assert(r.service.save())end)
case('same tick save increments revision',function(r)local rev=r.service.state.revision;assert(r.service.createGroup(2,'X'));assert(r.service.state.revision==rev+1);assert(r.service.createGroup(2,'Y'));assert(r.service.state.revision==rev+2)end)
case('new tick revision floor',function(r)r.now=r.now+100;assert(r.service.save());assert(r.service.state.revision==r.now)end)
case('load may reduce revision',function(r)r.service.save();local rev=r.service.state.revision;r.service.load();assert(r.service.state.revision<rev)end)
case('optional notify and trim fallback',function(r)r.library.notify=nil;r.library.utils=nil;return r.service.renameGroup(2,1,' Name ')end)
case('lock busy/release',function(r)local p=r.config.Spotlights.Storage.file;local co=coroutine.create(function()return r.library.withJsonLock(p,function()coroutine.yield('locked')end)end);assert(coroutine.resume(co));local ok,e=r.service.createGroup(2,'BUSY');assert(not ok and e=='busy');assert(coroutine.resume(co));assert(r.service.createGroup(2,'AFTER'))end)
print('PASS spotlights server/config/color differentials '..n)
