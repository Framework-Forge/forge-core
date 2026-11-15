local R=dofile('tests/kernel_vinewood_harness.lua')
local n=0
local function case(name,fn)R.clientCase(name,fn);n=n+1 end
local function data(rev,text,color)return{revision=rev,text=text or'AB',color=color or'#FFFFFF',enabled=true}end
local function count(r)local n=0;for _ in pairs(r.entities)do n=n+1 end;return n end
case('defaults missing revision initially ignored',function(r)r.run(r.initial[1]);assert(#r.trace==0 and count(r)==0)end)
case('initial current settings',function(r)r.value=data(1);r.run(r.initial[1]);assert(count(r)==2)end)
case('spaces keep position',function(r)r.apply(data(1,'A B'));assert(count(r)==2)end)
case('max eight',function(r)r.apply(data(1,'ABCDEFGHIJK'));assert(count(r)==8)end)
case('empty text',function(r)r.apply(data(1,''));assert(count(r)==0)end)
case('duplicate revision no rebuild',function(r)r.apply(data(1));local before=#r.trace;r.apply(data(1,'C'));assert(#r.trace==before and count(r)==2)end)
case('same revision disabled ignored',function(r)r.apply(data(1));r.apply({revision=1,enabled=false});assert(count(r)==2)end)
case('new revision replaces entities',function(r)r.apply(data(1));r.apply(data(2,'C'));assert(count(r)==1)end)
case('disabled removes entities and texture',function(r)r.apply(data(1));r.apply({revision=2,enabled=false});assert(count(r)==0)end)
case('nil after data returns defaults',function(r)r.apply(data(1));r.apply(nil);assert(count(r)==5)end)
case('malformed initial ignored',function(r)r.apply(false);assert(count(r)==0)end)
case('missing enabled not false',function(r)r.apply({revision=1,text='A'});assert(count(r)==1)end)
for _,color in ipairs({'#123456','#abc','#000000','#FFFFFFFF','invalid'})do
    case('color '..color,function(r)r.apply(data(1,'A',color));assert(count(r)==1)end)
end
case('math exception falls back white',function(r)r.mathError=true;r.apply(data(1));assert(count(r)==2)end)
case('only one pixel configured',function(r)r.apply(data(1,'A','#123456'));local n=0
    for _,e in ipairs(r.trace)do if e.kind=='SetRuntimeTexturePixel'then n=n+1;assert(e.args[2]==0 and e.args[3]==0)end end;assert(n==1)end)
case('other resource stop ignored',function(r)r.apply(data(1));local before=#r.trace;r.stop('pr_bridge');assert(before==#r.trace and count(r)==2)end)
case('own stop cleanup',function(r)r.apply(data(1));r.stop();assert(count(r)==0)end)
case('already deleted entity skipped',function(r)r.apply(data(1));r.entities[101]=nil;r.stop();assert(count(r)==0)end)
case('zero native entity retained by legacy',function(r)r.createZero=true;r.apply(data(1,'A'));assert(r.entities[0]);r.stop();assert(not r.entities[0])end)
case('model loaded after wait',function(r)r.loaded=false;r.waitHook=function()r.loaded=true end;local co=r.apply(data(1));assert(coroutine.status(co)=='suspended');r.resume(co);assert(count(r)==2)end)
case('model timeout not released',function(r)r.loaded=false;local co=r.apply(data(1,'A'))
    for _=1,7 do if coroutine.status(co)=='dead'then break end;r.resume(co)end
    assert(coroutine.status(co)=='dead'and count(r)==0)
    for _,e in ipairs(r.trace)do assert(e.kind~='SetModelAsNoLongerNeeded')end end)
case('session waits then loads',function(r)r.now=0;r.sessionLoaded=false;r.value=data(1)
    r.waitHook=function()r.sessionLoaded=true end;local co=r.run(r.initial[1]);r.resume(co);assert(count(r)==2)end)
case('absolute session timeout',function(r)r.now=10000;r.sessionLoaded=false;r.value=data(1)
    local co=r.run(r.initial[1]);r.resume(co);assert(count(r)==2 and r.waited==1)end)
case('revision marked before timeout no retry',function(r)r.loaded=false;local co=r.apply(data(1,'A'))
    while coroutine.status(co)~='dead'do r.resume(co)end;r.loaded=true;local before=#r.trace;r.apply(data(1,'A'));assert(before==#r.trace and count(r)==0)end)
case('late model completion after stop retained',function(r)r.loaded=false;local co=r.apply(data(1,'A'));r.stop();r.loaded=true;r.resume(co);assert(count(r)==1)end)
case('session change during wait not revalidated',function(r)r.loaded=false;local co=r.apply(data(1,'A'));r.sessionLoaded=false;r.loaded=true;r.resume(co);assert(count(r)==1)end)
print('PASS Vinewood renderer differentials '..n)
