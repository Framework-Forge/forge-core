local R=dofile('tests/kernel_vehicles_harness.lua')
local H,n=R.H,0
local function case(name,fn)R.case(name,fn);n=n+1 end
H.same(R.config(true),R.config(false),'whole config');n=n+1
case('initial catalog',function(r)assert(r.d.revision==1 and r.d.get('sultan').hash==R.hash('sultan'));assert(not r.d.get('disabled'));assert(r.d.getEntry('disabled').active==false)end)
case('initial effects parity',function(r)return r.initTrace end)
case('deferred sync and owner start',function(r)r.runTimers(0);r.fireCoreStarted();r.runTimers(500);assert(r.syncCount==2)end)
case('console policy first',function(r)r.jobResult=false;assert(r.d.canManage(0));assert(not r.d.canManage(2))end)
case('Job result raw',function(r)r.jobResult=1;assert(r.d.canManage(2)==1)end)
case('Job throws',function(r)r.jobError=true;return r.d.canManage(2)end)
for _,ace in ipairs({'forge-core.admin','admin','group.admin','none'})do
    case('ACE '..ace,function(r)r.services.JobService=nil;r.aces[ace]=true;return r.d.canManage(2)end)
end
case('copied reads',function(r)local p=r.d.getPayload();p.vehicles[1].name='tamper';local c=r.d.getAll();c.sultan.name='tamper';assert(r.d.get('sultan').name=='Sultan')end)
case('normalization all fields',function(r)return r.d.upsert({model='  TEST Model!* ',name=' X ',brand=' Y ',price=-5,stock=9.9,category='Custom Category',class=' s+ ',type='CUSTOM',store=' Shop ',hash='-123',custom={x=1}})end)
for _,hash in ipairs({'','  sultan ','123','-123','12.3',42,false})do
    case('hash '..tostring(hash),function(r)local ok,v=r.d.upsert({model='new',hash=hash});assert(ok);return v,r.d.get('new')end)
end
for _,active in ipairs({true,false,0,'false'})do
    case('active strict '..tostring(active),function(r)return r.d.upsert({model='new',active=active})end)
end
for _,class in ipairs({'S+','S','A','B','C','D','E','z',''})do
    case('class '..class,function(r)return r.d.upsert({model='new',class=class})end)
end
case('missing model',function(r)local ok,e=r.d.upsert({});assert(not ok and e=='missing_model')end)
case('malformed vehicle',function(r)return r.d.upsert(false)end)
case('empty catalog fallback',function(r)r.files[r.config.Vehicles.Storage]='';return r.d.reload(),r.d.getPayload()end)
case('invalid decode fallback',function(r)r.decodeError=true;return r.d.reload(),r.d.getPayload()end)
case('invalid entry skipped',function(r)r.files[r.config.Vehicles.Storage]=r.codec.encode({one={model='one',class='BAD'},two=false});return r.d.reload()end)
case('bad JSON type',function(r)r.files[r.config.Vehicles.Storage]=r.codec.encode('bad');return r.d.reload()end)
for _,ack in ipairs({false,0,'ok',true})do
    case('raw write '..tostring(ack),function(r)r.saved=ack;return r.d.upsert({model='new'})end)
end
case('write nil refused',function(r)r.saved=nil;return r.d.upsert({model='new'})end)
case('encode refused',function(r)r.encodeError=true;return r.d.upsert({model='new'})end)
case('writer throws',function(r)r.writeError=true;return r.d.upsert({model='new'})end)
case('sync inactive after commit',function(r)r.coreState='stopped';local ok,e=r.d.upsert({model='new'});assert(not ok and e=='qbx_core_not_started');assert(r.d.getEntry('new')and r.files[r.config.Vehicles.Storage])end)
case('sync starts not fully started',function(r)r.coreState='starting';return r.d.sync()end)
case('sync throws',function(r)r.syncHook=function()error('fixture-sync',0)end;local ok,e=r.d.upsert({model='new'});assert(not ok and e=='sync_failed')end)
case('sync rejected default',function(r)r.syncHook=function()return false end;return r.d.upsert({model='new'})end)
case('sync rejection reason',function(r)r.syncHook=function()return false,'custom'end;return r.d.sync()end)
case('sync nil acknowledgement accepted',function(r)r.syncHook=function()return nil end;return r.d.sync()end)
case('remove valid',function(r)assert(r.d.remove(' SULTAN '));assert(not r.d.get('sultan'))end)
case('remove missing',function(r)return r.d.remove('unknown')end)
for _,active in ipairs({true,false,1,'true'})do
    case('setActive '..tostring(active),function(r)local ok,e=r.d.setActive('sultan',active);assert(ok and e.active==(active==true));return r.d.get('sultan')end)
end
case('setActive missing',function(r)return r.d.setActive('',true)end)
case('four exports same service',function(r)assert(r.exports.GetVehicles('sultan').model=='sultan');r.exports.UpsertVehicle({model='new'});r.exports.RemoveVehicle('new');return r.exports.ReloadVehicles()end)
print('PASS vehicle catalog differentials '..n)
