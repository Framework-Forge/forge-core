local R=dofile('tests/kernel_player_admin_harness.lua');local n=0
local function case(name,fn)R.case(name,fn);n=n+1 end
local modules={'afk','density','job','password','skill','staff','weapon','weather','whitelist'}
case('constructor descriptors only',function(r)assert(#r.registrations==0 and #r.timerQueue==0);return #r.events end)
for _,m in ipairs(modules)do case('load '..m,function(r)return r.pluginLoad(m)end)end
for _,m in ipairs({'afk','density','password','staff','weapon','whitelist'})do case('load denied '..m,function(r)r.manage=false;local ok,e=r.pluginLoad(m,1);assert(not ok and e=='no_permission');return ok,e end)end
case('job starts lazily',function(r)r.services.JobService.started=false;local ok,p=r.pluginLoad('job');assert(r.services.JobService.started);return ok,p end)
case('whitelist success playersError legacy expression',function(r)local ok,p=r.pluginLoad('whitelist');assert(ok and p.playersError==r.wl);return ok,p end)
case('whitelist list failure remains success payload',function(r)r.wlOk=false;r.wl='error';return r.pluginLoad('whitelist')end)
case('weather refused',function(r)r.weatherOk=false;r.weather='no_permission';return r.pluginLoad('weather')end)
case('weather scalar normalized',function(r)r.weather=true;return r.pluginLoad('weather')end)
case('weather adapts returned reference',function(r)r.weather={currentWeather={weather='RAIN',time=12}};local ok,p=r.pluginLoad('weather');assert(ok and p==r.weather and p.weather=='RAIN'and p.duration==12);return ok,p end)
for _,m in ipairs({'bad','',false,32})do case('unknown module '..tostring(m),function(r)return r.pluginLoad(m)end)end
local actions={
 afk={'save'},density={'save'},job={'saveGroup','deleteGroup','savePayments','saveMei','createMei','forcePayment'},password={'save'},
 skill={'saveSkill','deleteSkill','saveReputation','deleteReputation'},staff={'add','remove'},weapon={'save','delete','setActive'},
 weather={'setWeather','setDuration','addWeather','removeWeather','setTime','setTimeScale','setFreezeTime'},whitelist={'saveConfig','add','remove','ban'}}
local function payload()return{settings={enabled=false},payments={mei={enabled=true}},data={name='Data'},group={name='group',type='gang'},groupType='job',
 name='test',skill={name='skill'},reputation={name='rep'},weapon={name='weapon_pistol'},active=true,index=3,weather='RAIN',duration=22,event={id=5},
 currentWeather={weather='CLEAR'},currentTime={hour=13,minute=20},hour=0,minute=0,scale=5000,timeScale=6000,enabled=false,freezeTime=true,config={enabled=true},identifier='CID1',mei={enabled=true}}end
for m,list in pairs(actions)do for _,a in ipairs(list)do
 case('action full '..m..a,function(r)return r.pluginAction(m,a,payload())end)
 case('action empty '..m..a,function(r)return r.pluginAction(m,a,nil)end)
 case('action refused '..m..a,function(r)r.actionResult=false;r.actionPayload='no_permission';return r.pluginAction(m,a,payload())end)
end end
for _,a in ipairs({'','unknown',true,33})do case('invalid action '..tostring(a),function(r)return r.pluginAction('job',a,{})end)end
case('invalid module action',function(r)return r.pluginAction('bad','save',{})end)
for _,state in ipairs({'stopped','starting','missing','started'})do case('pluginsReady '..state,function(r)r.resource=state;r.fire('forge-management:server:pluginsReady');assert(#r.registrations==(state=='started'and 9 or 0))end)end
case('registry protocol fields',function(r)
 r.fire('forge-management:server:pluginsReady');for _,p in pairs(r.pluginDescriptors)do
  assert(p.renderer=='native'and p.category=='forge-core'and p.minProtocolVersion==2 and p.version=='2.0'and #p.capabilities==6)
  assert(p.capabilityPerms.write[1]=='forge-core.admin'and p.native.load=='forge-core:server:plugin:load')
 end;return r.pluginDescriptors
end)
case('version missing default',function(r)r.version=nil;r.fire('forge-management:server:pluginsReady');assert(r.pluginDescriptors['forge-job'].version=='dev')end)
case('register false logs each',function(r)r.registerResult=false;r.fire('forge-management:server:pluginsReady');assert(next(r.pluginDescriptors)==nil);return r.pluginDescriptors end)
case('register numeric truthy',function(r)r.registerResult=1;r.fire('forge-management:server:pluginsReady');assert(r.pluginDescriptors['forge-job'])end)
case('register throw propagated',function(r)r.registerError=true;return r.fire('forge-management:server:pluginsReady')end)
case('duplicate ready registers twice inherited',function(r)r.fire('forge-management:server:pluginsReady');r.fire('forge-management:server:pluginsReady');assert(#r.registrations==18)end)
for _,name in ipairs({'forge-core','forge-management','unrelated'})do case('start '..name,function(r)r.fire('onResourceStart',name);r.runTimers();assert(#r.registrations==(name=='unrelated'and 0 or 9))end)end
case('stop clears even unregister false inherited',function(r)r.fire('forge-management:server:pluginsReady');r.unregisterResult=false;r.fire('onResourceStop','forge-core');assert(next(r.pluginDescriptors)==nil);r.fire('onResourceStop','forge-core')end)
case('provider stopped retains registered',function(r)r.fire('forge-management:server:pluginsReady');r.resource='stopped';r.fire('onResourceStop','forge-core');assert(r.pluginDescriptors['forge-job'])end)
case('foreign stop ignored',function(r)r.fire('forge-management:server:pluginsReady');r.fire('onResourceStop','other');assert(r.pluginDescriptors['forge-job'])end)
case('old timer registers after stop inherited',function(r)r.fire('onResourceStart','forge-core');r.fire('onResourceStop','forge-core');r.runTimers();assert(#r.registrations==9)end)
print('PASS plugins: '..n..' differential cases; nine modules, payload routing, protocol, errors, registration/stop/timer behavior')
