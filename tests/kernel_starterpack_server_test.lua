local R=dofile('tests/kernel_starterpack_harness.lua');local H=R.H;local n=0
local function case(name,fn,noStart)R.case(name,fn,noStart);n=n+1 end
H.same(R.config(true),R.config(false),'whole starterpack config');n=n+1
case('inert',function(r)return r.service.started,#r.queue end,true)
case('start idempotent',function(r)return r.service.start(),r.service.getAll()end)
case('public payload excludes claims/incidents',function(r)local p=r.service.getAll();assert(not p.claimed and not p.rewardClaims and not p.incidents and p.claimedCount==0);return p end)
case('defaults file absent',function(r)r.m.files[r.config.Starterpack.Storage.file]=nil;r.service.load();return r.service.getAll()end)
for _,flag in ipairs({'enabled','oncePerCharacter','autoGiveOnFirstJoin'})do
 for _,v in ipairs({false,true,0,1,'yes','sim','false','true'})do case(flag..tostring(v),function(r)return r.service.saveSettings(1,{[flag]=v})end)end
end
for _,method in ipairs({'saveSettings','savePrologue','setItem','removeItem','setStop','removeStop','giveToPlayer','resetClaim','startPrologueTest'})do
 case('deny '..method,function(r)r.jobResult=false;local ok,e=r.service[method](1,{});assert(not ok and e=='no_permission');return ok,e end)
end
case('console',function(r)r.jobResult=false;return r.service.saveSettings(0,{enabled=false})end)
case('ACE fallback deny',function(r)r.services.JobService=nil;r.ace=false;return r.service.saveSettings(1,{})end)
case('ACE fallback allow',function(r)r.services.JobService=nil;return r.service.saveSettings(1,{})end)
case('normalize malformed data',function(r)
 r.m.seed(r.config.Starterpack.Storage.file,{settings='bad',items={{name=' burger ',id=' Food ! ',count=-1},{}},claimed='bad',rewardClaims='bad',
  prologue={autopilotMaxSpeed=200,stops={{title='',coords={1,2,3},cameraFrames={{duration=0,fov=500}},
   routeDialogs={{text=' ',progress=1},{text='Later',progress=200,duration=0},{text='Early',progress=-3}},
   rewards={{item='water',progress=100},{item='burger',progress=-10,count=-4},{item=''}}}}}})
 r.service.load();local p=r.service.getAll();assert(p.items[1].id=='food'and p.items[1].count==1 and p.prologue.autopilotMaxSpeed==60)
 assert(p.prologue.stops[1].routeDialogs[1].text=='Early'and p.prologue.stops[1].rewards[1].item=='burger');return p
end)
case('legacy vehicleStart alias',function(r)local ok,p=r.service.savePrologue(1,{start={coords={3,4,5},heading=45},autopilotMaxSpeed=0});assert(ok and p.prologue.start.coords.x==3 and p.prologue.autopilotMaxSpeed==5);return p end)
for _,method in ipairs({'setItem','setStop'})do case('upsert '..method,function(r)
 local value=method=='setItem'and{id='food',name='burger',count=3}or{id='one',title='Changed'};assert(r.service[method](1,value));return r.service.getAll()
end)end
case('new item generated id',function(r)return r.service.setItem(1,{name='water',count=2,label=''})end)
case('new stop fallback',function(r)return r.service.setStop(1,{id='! ',title=' ',rewards={{item='water'}}})end)
for _,method in ipairs({'removeItem','removeStop'})do for _,id in ipairs({'missing',method=='removeItem'and'food'or'one'})do case(method..id,function(r)return r.service[method](1,id)end)end end
for _,item in ipairs({'','unknown'})do case('invalid item '..item,function(r)return r.service.setItem(1,{name=item})end)end
case('missing Items permissive',function(r)r.library.inventory.Items=nil;r.library.inventory.GetItemLabel=nil;return r.service.setItem(1,{name='unknown'})end)
for _,method in ipairs({'saveSettings','savePrologue','setItem','removeItem','setStop','removeStop','resetClaim'})do case('save fail '..method,function(r)
 r.m.onWrite=function()return false end
 local arg=({setItem={id='food',name='burger'},removeItem='food',setStop={id='one'},removeStop='one',resetClaim='CID1'})[method]or{}
 local before=r.service.getAll();local ok,e=r.service[method](1,arg);assert(not ok and e=='save_failed');H.same(r.service.getAll(),before,'no replace on fail');return ok,e
end)end
case('concurrent JSON lock busy',function(r)
 local co=coroutine.create(function()r.library.withJsonLock(r.config.Starterpack.Storage.file,function()coroutine.yield()end)end)
 assert(coroutine.resume(co));local ok,e=r.service.claim(1,false);assert(not ok and e=='busy'and r.addCalls==0)
 assert(coroutine.resume(co));assert(r.service.claim(1,false));return ok,e
end)
case('reentrant JSON lock',function(r)return r.library.withJsonLock(r.config.Starterpack.Storage.file,function()return r.service.claim(1,false)end)end)
case('incident reload stays blocked',function(r)
 r.failAddAt=1;r.throwAdd=true;assert(not r.service.claim(1,false));assert(r.service.incidents.CID1)
 r.service.load();local ok,e=r.service.claim(1,true);assert(not ok and e=='reconciliation_required');return ok,e
end)
case('claim once',function(r)local ok,p=r.service.claim(1,false);assert(ok and p.claimedCount==1 and r.service.state.claimed.CID1.name=='One Player');return ok,p end)
case('claim duplicate',function(r)assert(r.service.claim(1,false));local ok,e=r.service.claim(1,false);assert(not ok and e=='already_claimed');return ok,e end)
case('claim repeat allowed',function(r)r.service.state.settings.oncePerCharacter=false;assert(r.service.claim(1,false));return r.service.claim(1,false)end)
case('claim disabled',function(r)r.service.state.settings.enabled=false;return r.service.claim(1,false)end)
case('claim forced disabled duplicate',function(r)assert(r.service.claim(1,false));r.service.state.settings.enabled=false;return r.service.claim(1,true)end)
case('all items disabled',function(r)for _,i in ipairs(r.service.state.items)do i.enabled=false end;return r.service.claim(1,false)end)
case('empty kit',function(r)r.service.state.items={};return r.service.claim(1,false)end)
case('claim missing item',function(r)r.catalog.water=nil;return r.service.claim(1,false)end)
case('capacity false',function(r)r.carryResult=false;return r.service.claim(1,false)end)
case('capacity numeric1 not true',function(r)r.carryResult=1;return r.service.claim(1,false)end)
case('capacity nil raw fallback then permissive',function(r)r.carryResult=nil;return r.service.claim(1,false)end)
case('PR capacity missing raw',function(r)r.library.inventory.CanCarryItem=nil;return r.service.claim(1,false)end)
case('raw stopped capacity permissive',function(r)r.library.inventory.CanCarryItem=nil;r.resource='stopped';return r.service.claim(1,false)end)
case('PR add missing raw',function(r)r.library.inventory.AddItem=nil;return r.service.claim(1,false)end)
case('raw add stopped',function(r)r.library.inventory.AddItem=nil;r.resource='stopped';return r.service.claim(1,false)end)
for _,value in ipairs({false,1})do case('AddItem strict '..tostring(value),function(r)r.addResult=value;return r.service.claim(1,false)end)end
case('second grant false rollback first',function(r)r.failAddAt=2;local ok,e=r.service.claim(1,false);assert(not ok and e=='add_failed'and not r.service.state.claimed.CID1);return ok,e end)
case('second grant throw incident and rollback',function(r)r.failAddAt=2;r.throwAdd=true;local ok,e=r.service.claim(1,false);assert(not ok and e=='reconciliation_required'and r.service.incidents.CID1);return ok,e end)
case('rollback false incident',function(r)r.failAddAt=2;r.removeResult=false;local ok,e=r.service.claim(1,false);assert(not ok and e=='reconciliation_required');return ok,e end)
case('rollback throw incident',function(r)r.failAddAt=2;r.removeError=true;return r.service.claim(1,false)end)
case('claim save fail rollback',function(r)r.m.onWrite=function()return false end;local ok,e=r.service.claim(1,false);assert(not ok and e=='save_failed');return ok,e end)
for _,field in ipairs({'citizenId','citizenID'})do case('identity '..field,function(r)r.players[1].PlayerData.citizenid=nil;r.players[1].PlayerData[field]='ALT';assert(r.service.claim(1,false));assert(r.service.state.claimed.ALT)end)end
case('identity trim',function(r)r.players[1].PlayerData.citizenid='  CID1  ';return r.service.claim(1,false)end)
case('unready',function(r)r.players[1]=nil;return r.service.claim(1,false)end)
case('name native fallback',function(r)r.players[1].PlayerData.charinfo={};return r.service.claim(1,false)end)
case('name source fallback',function(r)r.players[1].PlayerData.charinfo={};r.missingName=true;return r.service.claim(1,false)end)
for _,method in ipairs({'giveToPlayer','startPrologueTest'})do for _,id in ipairs({0,-1,1,'2','bad'})do case(method..tostring(id),function(r)return r.service[method](2,id)end)end end
case('missing native player',function(r)r.missingName=true;return r.service.giveToPlayer(2,1)end)
case('reward',function(r)local ok,p=r.service.grantReward(1,'one','token');assert(ok and r.service.state.rewardClaims['CID1:one:token']);return ok,p end)
case('reward duplicate success',function(r)assert(r.service.grantReward(1,'one','token'));local ok,e=r.service.grantReward(1,'one','token');assert(ok and e=='already_granted');return ok,e end)
case('reward repeats when once false',function(r)r.service.state.settings.oncePerCharacter=false;assert(r.service.grantReward(1,'one','token'));return r.service.grantReward(1,'one','token')end)
case('reward no route disabled system/prologue/stop inherited',function(r)
 r.service.state.settings.enabled=false;r.service.state.prologue.enabled=false;r.service.state.prologue.stops[1].enabled=false;assert(r.service.grantReward(1,'one','token'))
end)
case('reward disabled',function(r)r.service.state.prologue.stops[1].rewards[1].enabled=false;return r.service.grantReward(1,'one','token')end)
case('reward missing stop',function(r)return r.service.grantReward(1,'bad','token')end)
case('reward missing reward',function(r)return r.service.grantReward(1,'one','bad')end)
case('reward invalid item',function(r)r.catalog.token=nil;return r.service.grantReward(1,'one','token')end)
case('reward full',function(r)r.carryResult=false;return r.service.grantReward(1,'one','token')end)
case('reward save fail',function(r)r.m.onWrite=function()return false end;return r.service.grantReward(1,'one','token')end)
case('reward add throw',function(r)r.failAddAt=1;r.throwAdd=true;return r.service.grantReward(1,'one','token')end)
case('complete without route inherited',function(r)local ok,p=r.service.completePrologue(1);assert(ok and r.service.state.claimed.CID1.prologue and #r.items[1]==3);return ok,p end)
case('complete duplicate',function(r)assert(r.service.completePrologue(1));return r.service.completePrologue(1)end)
case('complete disabled',function(r)r.service.state.settings.enabled=false;return r.service.completePrologue(1)end)
case('complete save failure',function(r)r.m.onWrite=function()return false end;return r.service.completePrologue(1)end)
for _,method in ipairs({'claim','grantReward','completePrologue','resetClaim'})do case('incident prevents '..method,function(r)
 r.service.incidents.CID1={operation='fixture'};return r.service[method](1,method=='resetClaim'and'CID1'or'one','token')
end)end
case('reset removes only exact cid prefix',function(r)
 assert(r.service.claim(1,false));assert(r.service.grantReward(1,'one','token'));r.service.state.rewardClaims['CID10:one:token']={}
 assert(r.service.resetClaim(2,'CID1'));assert(not r.service.state.claimed.CID1 and not r.service.state.rewardClaims['CID1:one:token']and r.service.state.rewardClaims['CID10:one:token'])
end)
case('reset invalid id',function(r)return r.service.resetClaim(1,'  ')end)
case('auto disabled no timer',function(r)local before=#r.queue;r.service.handlePlayerLoaded(1);assert(#r.queue==before)end)
case('auto before start no timer',function(r)r.service.handlePlayerLoaded(1);assert(#r.queue==0)end,true)
case('auto scheduled correct delay',function(r)r.service.state.settings.autoGiveOnFirstJoin=true;r.service.handlePlayerLoaded(1);r.advance(3499);assert(not r.service.state.claimed.CID1);r.advance(1);assert(r.service.state.claimed.CID1)end)
case('auto different identity cancelled',function(r)r.service.state.settings.autoGiveOnFirstJoin=true;r.service.handlePlayerLoaded(1);r.players[1].PlayerData.citizenid='NEW';r.advance(3500);assert(not next(r.service.state.claimed))end)
case('auto same identity new session inherited',function(r)r.service.state.settings.autoGiveOnFirstJoin=true;r.service.handlePlayerLoaded(1);r.players[1]={PlayerData={citizenid='CID1'}};r.advance(3500);assert(r.service.state.claimed.CID1)end)
case('auto disconnected cancelled',function(r)r.service.state.settings.autoGiveOnFirstJoin=true;r.service.handlePlayerLoaded(1);r.missingName=true;r.advance(3500);assert(not next(r.service.state.claimed))end)
for _,pr in ipairs({false,true})do
 case('command descriptor '..tostring(pr),function(r)local c=r.bindCommands(pr);assert(c.name=='teststartpack');if pr then assert(c.properties.canAccess(2))end;return c.provider end)
 for _,id in ipairs({0,1,2,'bad'})do case('command '..tostring(pr)..tostring(id),function(r)local c=r.bindCommands(pr);return c.handler(2,{id=id},'teststartpack')end)end
 case('command console no target '..tostring(pr),function(r)local c=r.bindCommands(pr);return c.handler(0,{},'')end)
 case('command permission fallback '..tostring(pr),function(r)local c=r.bindCommands(pr);r.jobResult=false;return c.handler(2,{id=1},'')end)
end
print('PASS starterpack server/config/commands: '..n..' differential cases; actual PR recovery/draft/lock/incidents/OX adapter, virtual provider/IO/time')
