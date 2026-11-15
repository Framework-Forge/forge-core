local R=dofile('tests/kernel_spotlights_harness.lua')
local H,n=R.H,0
local function case(name,fn)R.clientCase(name,fn);n=n+1 end
local function worker(r,p)r.value=p or R.seed();assert(r.tick()==1000);return r.tick()end
local function create(r,input)
 r.inputs={input or {'New','true','#abc',50,1,0,20}}
 local co=r.run(r.spotlights.createLight,1,nil,function(v)r.record('created',v)end)
 assert(not r.spotlights.editorActive,'capture not guarded');r.just={[38]=true};r.resume(co);r.resume(co);r.just={}
 assert(r.spotlights.editorActive);return co
end
case('initial delay/empty worker',function(r)assert(r.tick()==1000 and r.tick()==1000 and #r.draws==0)end)
case('unit direction actual draw boundary',function(r)assert(worker(r)==0 and #r.draws==1);local d=r.draws[1];assert(math.abs(d[4]-0.6)<1e-8 and math.abs(d[5]-0.8)<1e-8 and d[6]==0 and d[7]==10 and d[14]==1)end)
case('zero direction vertical fallback',function(r)local p=R.seed();p.lights[1].target=p.lights[1].origin;worker(r,p);local d=r.draws[1];assert(d[4]==0 and d[5]==0 and d[6]==-1)end)
case('near-zero direction',function(r)local p=R.seed();p.lights[1].target={x=1.0001,y=2,z=3};worker(r,p);assert(r.draws[1][6]==-1)end)
case('long direction still unit',function(r)local p=R.seed();p.lights[1].target={x=1001,y=2,z=3};worker(r,p);assert(r.draws[1][4]==1)end)
-- Intentional scheduling change: legacy polls every frame, Forge sleeps while
-- nothing can be drawn. Compare rendering, not the obsolete polling cadence.
for _,ported in ipairs({false,true})do
 local r=R.client(ported);local p=R.seed();p.lights[1].origin.x=999
 assert(worker(r,p)==(ported and 1000 or 0)and #r.draws==0)
end
n=n+1
case('world disabled idle',function(r)local p=R.seed();p.enabled=false;assert(worker(r,p)==1000 and #r.draws==0)end)
for _,ported in ipairs({false,true})do
 local r=R.client(ported);local p=R.seed();p.lights[1].enabled=false
 assert(worker(r,p)==(ported and 1000 or 0)and #r.draws==0)
end
n=n+1
case('nil payload disables',function(r)r.apply(R.seed());r.apply(nil);assert(not r.spotlights.enabled and #r.spotlights.lights==0)end)
case('malformed lights ignored',function(r)r.apply({enabled='yes',lights=false});assert(r.spotlights.enabled and #r.spotlights.lights==0)end)
case('IDs filtered but duplicates retained',function(r)local p=R.seed();p.lights[2]={id=1,groupid=1};p.lights[3]={id=0,groupId=1};p.lights[4]={id=9,groupId=0};r.apply(p);assert(#r.spotlights.lights==2)end)
case('cached normalization',function(r)r.apply({enabled='sim',lights={{id='3.8',groupId='2',origin={1.12345,2.23456,3.34567},color='#f00',distance=-1,brightness=-1,hardness=-1,radius=-1}}});local l=r.spotlights.lights[1];assert(l.id==3 and l.origin.y==2.235 and l.color.r==255 and l.distance==0.1 and l.brightness==0)end)
case('public apply returns nil',function(r)assert(r.spotlights.applyPayload(R.seed())==nil and #r.spotlights.lights==1)end)
case('older revision refused',function(r)local p=R.seed();p.revision=10;r.apply(p);p=R.seed();p.revision=9;p.lights={};r.apply(p);assert(#r.spotlights.lights==1 and r.spotlights.revision==10)end)
case('same revision reapplied',function(r)local p=R.seed();p.revision=10;r.apply(p);p=R.seed();p.revision=10;p.lights={};r.apply(p);assert(#r.spotlights.lights==0)end)
case('missing revision overwrites retains revision',function(r)local p=R.seed();p.revision=10;r.apply(p);r.apply({enabled=false,lights={}});assert(#r.spotlights.lights==0 and r.spotlights.revision==10)end)
case('raycast unavailable',function(r)r.library.raycast=nil;local co,ok,e=r.run(r.spotlights.createLight,1);assert(coroutine.status(co)=='dead'and not ok and e=='raycast_unavailable')end)
case('origin capture cancel',function(r)local co=r.run(r.spotlights.createLight,1);r.just={[177]=true};local ok,e=r.resume(co);assert(not ok and e=='cancelled'and not r.textui.IsTextUIOpen())end)
case('target capture cancel',function(r)local co=r.run(r.spotlights.createLight,1);r.just={[38]=true};r.resume(co);r.just={[202]=true};local ok,e=r.resume(co);assert(not ok and e=='cancelled')end)
case('ray miss then cancel',function(r)r.rayMiss=true;local co=r.run(r.spotlights.createLight,1);r.resume(co);r.just={[177]=true};assert(not r.resume(co))end)
case('ray waiting actual PR module',function(r)r.shapePending=1;local co=r.run(r.spotlights.createLight,1);r.just={[38]=true};r.resume(co);r.resume(co);r.just={[177]=true};assert(not r.resume(co))end)
case('input canceled',function(r)local co=r.run(r.spotlights.createLight,1);r.just={[38]=true};r.resume(co);local ok,e=r.resume(co);assert(not ok and e=='cancelled'and not r.spotlights.editorActive)end)
case('create confirm/rounding/color callback',function(r)local co=create(r);local ok,p=r.finish(co);assert(ok and p.origin.x==1.123 and p.origin.y==2.235 and p.target.x==4 and p.color.r==170 and p.groupId==1 and not r.textui.IsTextUIOpen())end)
case('create disabled bool preserved',function(r)local co=create(r,{'New','false','#abc',50,1,0,20});local ok,p=r.finish(co);assert(ok and not p.enabled)end)
case('create fine-tune cancel',function(r)local co=create(r);local ok,e=r.finish(co,false);assert(not ok and e=='cancelled'and not r.spotlights.editorActive)end)
case('create guard during active editor',function(r)r.spotlights.editorActive=true;local ok,e=r.spotlights.createLight(1);assert(not ok and e=='editor_active')end)
case('palette field',function(r)r.inputHook=function(_,fields)assert(#fields==7 and fields[3].type=='color'and fields[3].format=='hex');return{'x','true','#123',1,2,3,4}end;local co=create(r);assert(r.finish(co))end)
case('capture can overlap',function(r)local a=r.run(r.spotlights.createLight,1);local b=r.run(r.spotlights.createLight,1);assert(not r.spotlights.editorActive);r.just={[177]=true};assert(not r.resume(a)and not r.resume(b))end)
case('raycast exception leaves text visible',function(r)r.shapeError=true;local co=r.run(r.spotlights.createLight,1);assert(not pcall(r.resume,co)and r.textui.IsTextUIOpen())end)
case('input exception after capture',function(r)r.inputHook=function()error('fixture-input',0)end;local co=r.run(r.spotlights.createLight,1);r.just={[38]=true};r.resume(co);assert(not pcall(r.resume,co))end)
case('finish callback exception after cleanup',function(r)r.inputs={{'X','true','#fff',1,2,3,4}};local co=r.run(r.spotlights.createLight,1,nil,function()error('fixture-finish',0)end);r.just={[38]=true};r.resume(co);r.resume(co);assert(not pcall(r.finish,co)and not r.spotlights.editorActive and not r.textui.IsTextUIOpen())end)
case('edit confirm preserves IDs/transforms',function(r)local l=R.seed().lights[1];local co=r.run(r.spotlights.editLight,l,function(v)assert(v.id==1);r.record('updated',v)end);local ok,p=r.finish(co);assert(ok and p.origin.x==1 and p.groupId==1)end)
case('edit cancel',function(r)local co=r.run(r.spotlights.editLight,R.seed().lights[1]);assert(not r.finish(co,false))end)
case('edit without create guard overlaps',function(r)local a=r.run(r.spotlights.editLight,R.seed().lights[1]);local b=r.run(r.spotlights.editLight,R.seed().lights[1]);assert(r.finish(b));local ok,e=r.resume(a);assert(not ok and e=='cancelled')end)
case('malformed edit accepted with defaults',function(r)local co=r.run(r.spotlights.editLight,false);local ok,p=r.finish(co);assert(ok and p.enabled)end)
local controls={{241,'distance',1},{242,'distance',-1},{172,'brightness',0.1},{173,'brightness',-0.1},{174,'hardness',-0.05},{175,'hardness',0.05},{44,'radius',-0.5},{38,'radius',0.5}}
for _,c in ipairs(controls)do case('held '..c[1],function(r)local l=R.seed().lights[1];l.hardness=1;local before=l[c[2]];local co=r.run(r.spotlights.editLight,l);r.controls={[c[1]]=true};r.just={[c[1]]=true};r.resume(co);r.just={};r.now=r.now+500;r.resume(co);local ok,p=r.finish(co);assert(ok and math.abs(p[c[2]]-(before+c[3]*2))<1e-8)end)end
case('repeat not due',function(r)local co=r.run(r.spotlights.editLight,R.seed().lights[1]);r.controls={[241]=true};r.resume(co);r.resume(co);local ok,p=r.finish(co);assert(ok and p.distance==51)end)
case('release resets held',function(r)local co=r.run(r.spotlights.editLight,R.seed().lights[1]);r.controls={[241]=true};r.resume(co);r.controls={};r.resume(co);r.controls={[241]=true};r.resume(co);local ok,p=r.finish(co);assert(ok and p.distance==52)end)
case('control precedence scroll before enter',function(r)local co=r.run(r.spotlights.editLight,R.seed().lights[1]);r.controls={[241]=true};r.just={[201]=true};r.resume(co);assert(coroutine.status(co)=='suspended');local ok,p=r.finish(co);assert(ok and p.distance==51)end)
for _,c in ipairs({{241,'distance',1000},{242,'distance',0.1},{172,'brightness',50},{173,'brightness',0},{174,'hardness',0},{175,'hardness',100},{44,'radius',0},{38,'radius',500}})do
 case('editor clamp '..c[1],function(r)local l=R.seed().lights[1];l[c[2]]=c[3];local co=r.run(r.spotlights.editLight,l);r.controls={[c[1]]=true};r.resume(co);local ok,p=r.finish(co);assert(ok and p[c[2]]==c[3])end)
end
case('editor and renderer both draw',function(r)worker(r);local co=r.run(r.spotlights.editLight,R.seed().lights[1]);r.resume(co);local before=#r.draws;r.tick();assert(#r.draws==before+1);r.finish(co,false)end)
case('external active flag reset cancels after suspended frame',function(r)local co=r.run(r.spotlights.editLight,R.seed().lights[1]);r.spotlights.editorActive=false;local ok,e=r.resume(co);assert(not ok and e=='cancelled')end)
print('PASS spotlights renderer/editor/raycast/TextUI differentials '..n)
