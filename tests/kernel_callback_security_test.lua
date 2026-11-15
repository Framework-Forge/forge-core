local T=dofile('tests/kernel_transport_harness.lua')
local n=0
local function case(label,action,options)n=n+1;T.case('security',label,action,options)end
local function install(r,name,options,fn)
    name=name or'fixture';r.api.register(name,fn or function(...)r.record('handler',...);return nil,false,'ok',nil end,options);return r.handlers[name]
end
case('multiple nil/false returns',function(r)local fn=install(r);local out=table.pack(fn('1','a',nil,'c'));assert(out.n==4 and out[1]==nil and out[2]==false and out[3]=='ok')end)
for _,src in ipairs({0,-1,'bad',false})do case('invalid source '..tostring(src),function(r)local fn=install(r);local ok,err=fn(src);assert(ok==false and err=='invalid_player')end)end
case('nil source',function(r)local ok,err=install(r)(nil);assert(ok==false and err=='invalid_player')end)
for _,ping in ipairs({0,-1})do case('dead ping',function(r)r.ping=ping;local ok,err=install(r)(1);assert(ok==false and err=='invalid_player')end)end
case('admin denied before quota',function(r)r.allow=false;local fn=install(r,'admin',{access='admin',limit=1});local ok,err=fn(1);assert(not ok and err=='no_permission');r.allow=true;fn(1)end)
case('player ignores admin permission',function(r)r.allow=false;install(r)(1);assert(r.api.buckets['1:fixture'].count==1)end)
case('selected job admin names',function(r)
    for _,key in ipairs({'saveGroup','deleteGroup','savePaymentSettings','forcePayment','saveMeiSettings'})do local name=r.config.Job.Callbacks[key];install(r,name);assert(r.api.getRegistrations()[name].access=='admin')end
    for _,key in ipairs({'getAll','createMei','robRegister','getEmployees'})do local name=r.config.Job.Callbacks[key];install(r,name);assert(r.api.getRegistrations()[name].access=='player')end
end)
case('all module classification',function(r)
    for _,name in ipairs({'afk','backup','density','inventory','vehicle','password','staff','vinewood','weapons','weather','automedic','multijob','vip','players','slots','whitelist','farms','skills','starter','stores','billboard','npc','object','spotlight'})do
        install(r,name);assert(r.api.registrations[name].access=='admin',name)
    end
    install(r,'billboard-read');assert(r.api.registrations['billboard-read'].access=='player')
end,function(r)
    local c=r.config
    for key,value in pairs({Afk='afk',DatabaseBackup='backup',Density='density',Inventory='inventory',Vehicles='vehicle',Password='password',Staff='staff',Vinewood='vinewood',Weapons='weapons',Weather='weather',PlayerManagement='players'})do c[key]={Callbacks={any=value}}end
    c.AutoMedic={Callbacks={getSettings='automedic'}};c.MultiJob={Callbacks={addJob='multijob'}};c.Vip={Callbacks={grant='vip'}}
    c.CharacterSlots={callbacks={any='slots'}};c.Whitelist={Callbacks={ban='whitelist'}};c.Farms={Callbacks={createFarm='farms'}}
    c.Skills={Callbacks={addXp='skills'}};c.Starterpack={Callbacks={setItem='starter'}};c.Stores={Callbacks={deleteStore='stores'}}
    c.Billboards={Callbacks={getAll='billboard-read',save='billboard'}};c.Npcs={Callbacks={save='npc'}};c.Objects={Callbacks={save='object'}};c.Spotlights={Callbacks={save='spotlight'}}
end)
case('explicit player override',function(r)r.allow=false;local name=r.config.Job.Callbacks.saveGroup;install(r,name,{access='player'})(1);assert(r.api.registrations[name].access=='player')end)
case('unknown access kept',function(r)r.allow=false;install(r,'fixture',{access='unknown'})(1);assert(r.api.buckets['1:fixture'])end)
case('defaults 15 then refuse',function(r)local fn=install(r);for i=1,15 do fn(1)end;local ok,err=fn(1);assert(ok==false and err=='rate_limited')end)
for _,delta in ipairs({999,1000,5000,-1})do
    case('window edge '..delta,function(r)local fn=install(r,'fixture',{limit=1,window=1000});fn(1);r.now=r.now+delta;local ok,err=fn(1);assert((err=='rate_limited')==(delta<1000))end)
end
case('per name and source buckets',function(r)local a,b=install(r,'a',{limit=1}),install(r,'b',{limit=1});a(1);b(1);a(11);assert(r.api.buckets['1:a'].count==1 and r.api.buckets['11:a'].count==1)end)
case('clamped options',function(r)install(r,'fixture',{limit=-4,window=1,maxPayload=1});local v=r.api.registrations.fixture;assert(v.limit==1 and v.window==1000 and v.maxPayload==1024)end)
case('floored options',function(r)install(r,'fixture',{limit='2.9',window='2000.9',maxPayload='3000.9'});local v=r.api.registrations.fixture;assert(v.limit==2 and v.window==2000 and v.maxPayload==3000)end)
for _,bytes in ipairs({1023,1024,1025,65536,65537})do
    case('payload edge '..bytes,function(r)r.bytes=bytes;local fn=install(r,'fixture',{maxPayload=bytes<2000 and 1024 or nil});local ok,err=fn(1);assert((err=='payload_too_large')==(bytes==1025 or bytes==65537))end)
end
case('codec failure consumes quota',function(r)r.encodeError=true;local fn=install(r,'fixture',{limit=1});local ok,err=fn(1);assert(not ok and err=='payload_too_large');r.encodeError=false;ok,err=fn(1);assert(not ok and err=='rate_limited')end)
case('handler exception caught',function(r)local fn=install(r,nil,nil,function()error('fixture-handler',0)end);local ok,err=fn(1);assert(not ok and err=='internal_error')end)
case('drop cleans only source prefix',function(r)local fn=install(r);fn(1);fn(11);r.dispatch('playerDropped',1);assert(not r.api.buckets['1:fixture']and r.api.buckets['11:fixture'])end)
case('registration metadata stays live but closure limit fixed',function(r)local fn=install(r,'fixture',{limit=1});r.api.getRegistrations().fixture.limit=100;fn(1);local _,err=fn(1);assert(err=='rate_limited')end)
case('invalid registration name',function(r)local ok,err=pcall(r.api.register,'',function()end);assert(not ok);return T.message(err)end)
case('invalid handler',function(r)local ok,err=pcall(r.api.register,'fixture',{});assert(not ok);return T.message(err)end)
for _,allowed in ipairs({true,false,1,0,'true'})do
    case('native ACE '..tostring(allowed),function(r)r.nativeAce=allowed;assert(r.api.isPlayerAceAllowed('1','permission')==(allowed==true or allowed==1))end)
    case('library ACE '..tostring(allowed),function(r)assert(r.api.isPlayerAceAllowed(1,'permission')==(allowed==true or allowed==1))end,
        function(r)r.library.ace={isPlayerAceAllowed=function(...)r.record('library-ace',...);return allowed end}end)
end
case('native ACE exception refused',function(r)r.results.nativeAce='throw';assert(not r.api.isPlayerAceAllowed(1,'permission'))end)
case('invalid ACE and console',function(r)assert(r.api.isPlayerAceAllowed(0,'')and not r.api.isPlayerAceAllowed(1,''));assert(not r.api.isPlayerAceAllowed(1,{}))end)
case('JobService absent fallback ACE',function(r)install(r,'fixture',{access='admin'})(1)end,function(r)r.services.JobService=nil end)
case('late handler retains source, not character ownership',function(r)
    r.identity='OLD';local fn=install(r,nil,nil,function(src)coroutine.yield('wait');return src,r.identity end)
    local co=coroutine.create(function()return fn(1)end);local ok,value=coroutine.resume(co);assert(ok and value=='wait')
    r.identity='NEW';local out=table.pack(coroutine.resume(co));assert(out[1]and out[2]==1 and out[3]=='NEW','inherited session gap')
end)
print('PASS '..n..' callback protection differential cases; full classification/ACE/quota/payload/pcall/nil/drop semantics and retained session gap; no transport installed')
