local R=dofile('tests/kernel_farms_harness.lua')
local H=R.H;local n=0
local function case(name,fn,noStart)R.case(name,fn,noStart);n=n+1 end
local a,ta=R.config(false);local b,tb=R.config(true);H.same(R.P.snapshot(b),R.P.snapshot(a),'whole farm config');H.same(tb,ta,'all preset translations');assert(#ta==14);n=n+1
local function farm(r)return r.service.state.farms[1]end
local function item(r)return farm(r).items[1]end
case('constructor no writes',function(r)return r.service.started,#r.farmEvents end,true)
case('start idempotent',function(r)assert(r.service.start());return r.service.getAll()end)
for _,v in ipairs({false,0,1,'yes','sim','false','true'})do case('settings '..tostring(v),function(r)return r.service.saveSettings(1,{enabled=v})end)end
for _,method in ipairs({'saveSettings','createFarm','updateFarm','deleteFarm','getGroups','getItems','getVehicles'})do
 case('admin denied '..method,function(r)r.jobResult=false;local ok,e=r.service[method](1,{});assert(not ok and e=='no_permission');return ok,e end)
end
case('console allowed',function(r)r.jobResult=false;return r.service.saveSettings(0,{enabled=false})end)
case('ACE fallback',function(r)r.services.JobService=nil;r.ace=false;return r.service.createFarm(1,{})end)
case('normalization malformed and duplicate',function(r)
 r.m.seed(r.config.Farms.Storage.file,{farms={{id=2,name='',items={{reward=' Burger ',min=-3,max=7.9,collectTime=0,extraItems={{item='water',min=-1,max=2.1}}}}},{id=2},{id=0}}})
 r.service.load();local p=r.service.getAll();assert(#p.farms==1 and p.farms[1].items[1].collectTime==1000);return p
end)
case('missing file defaults',function(r)r.m.files[r.config.Farms.Storage.file]=nil;r.service.load();assert(#r.service.getAll().farms==0)end)
case('create assign next id',function(r)local ok,p=r.service.createFarm(1,R.seed().farms[1]);assert(ok and p.farms[2].id==2);return ok,p end)
case('update full replacement',function(r)return r.service.updateFarm(1,1,{name='New'})end)
for _,id in ipairs({1,999})do
 case('update '..id,function(r)return r.service.updateFarm(1,id,R.seed().farms[1])end)
 case('delete '..id,function(r)return r.service.deleteFarm(1,id)end)
end
case('save failure state preserved',function(r)r.m.onWrite=function()return false end;local ok,e=r.service.saveSettings(1,{enabled=false});assert(not ok and e=='save_failed'and r.service.state.settings.enabled);return ok,e end)
for _,groupType in ipairs({'job','gang','unknown'})do case('registry '..groupType,function(r)return r.service.getGroups(1,groupType)end)end
case('registry absent',function(r)r.services.JobRegistry=nil;return r.service.getGroups(1,'job')end)
case('item catalog',function(r)return r.service.getItems(1)end)
case('item raw fallback',function(r)r.library.inventory.Items=nil;return r.service.getItems(1)end)
case('item unavailable',function(r)r.library.inventory.Items=nil;r.resource='stopped';return r.service.getItems(1)end)
case('catalog item throw caught',function(r)r.itemsError=true;return r.service.getItems(1)end)
case('vehicles local',function(r)return r.service.getVehicles(1)end)
case('vehicles stopped',function(r)r.coreState='stopped';return r.service.getVehicles(1)end)
case('vehicles getter throw',function(r)r.vehicleError=true;return r.service.getVehicles(1)end)
case('start no persistent limits avoids write',function(r)
 local before=#r.m.trace;assert(r.service.startRoute(1,1,'crop'));assert(#r.m.trace==before and r.service.activeRoutes['1:1:crop'])
end)
case('collect no route',function(r)local ok,e=r.service.collect(1,1,'crop');assert(not ok and e=='route_not_started');return ok,e end)
case('collect tool and extras',function(r)
 assert(r.service.startRoute(1,1,'crop'));local ok,p=r.service.collect(1,1,'crop');assert(ok and p.count==2 and r.items[1][3].metadata.durability==90);return ok,p
end)
for _,field in ipairs({'enabled','public'})do case('farm flag '..field,function(r)farm(r)[field]=false;return r.service.startRoute(1,1,'crop')end)end
case('system disabled',function(r)r.service.state.settings.enabled=false;return r.service.startRoute(1,1,'crop')end)
case('item disabled',function(r)item(r).enabled=false;return r.service.startRoute(1,1,'crop')end)
case('item missing',function(r)return r.service.startRoute(1,1,'missing')end)
case('farm missing',function(r)return r.service.startRoute(1,999,'crop')end)
for _,kind in ipairs({'job','gang'})do for _,grade in ipairs({0,1,2,3})do case('primary access '..kind..grade,function(r)
 farm(r).public=false;farm(r).groupType=kind;farm(r).groupName=kind=='job'and'police'or'ballas';farm(r).minGrade=grade
 r.players[1].PlayerData.gang={name='ballas',grade={value=1}};return r.service.startRoute(1,1,'crop')
end)end end
case('secondary job alone does not grant farm',function(r)
 farm(r).public=false;farm(r).groupName='police';r.players[1].PlayerData.job={name='unemployed',grade=0}
 local ok,e=r.service.startRoute(1,1,'crop');assert(not ok and e=='no_permission');return ok,e
end)
case('access rechecked on collect',function(r)assert(r.service.startRoute(1,1,'crop'));farm(r).public=false;farm(r).groupName='other';return r.service.collect(1,1,'crop')end)
case('same route resumes without extra usage check',function(r)
 item(r).limits={enabled=true,onceDaily=true};assert(r.service.startRoute(1,1,'crop'));local before=#r.m.trace;assert(r.service.startRoute(1,1,'crop'));assert(#r.m.trace==before)
end)
case('once daily after finish',function(r)
 item(r).limits={enabled=true,onceDaily=true};assert(r.service.startRoute(1,1,'crop'));assert(r.service.finishRoute(1,1,'crop'))
 local ok,e=r.service.startRoute(1,1,'crop');assert(not ok and e=='daily_limit');return ok,e
end)
for _,scope in ipairs({'item','farm'})do case('usage scope '..scope,function(r)
 item(r).limits={enabled=true,scope=scope,cooldownMinutes=10};assert(r.service.startRoute(1,1,'crop'))
 assert(r.service.state.usage['CID1:1:'..(scope=='farm'and'farm'or'crop')]);r.service.finishRoute(1,1,'crop')
 local ok,e=r.service.startRoute(1,1,'crop');assert(not ok and e=='cooldown_active');return ok,e
end)end
case('cooldown expiry',function(r)
 item(r).limits={enabled=true,cooldownMinutes=10};assert(r.service.startRoute(1,1,'crop'));r.service.finishRoute(1,1,'crop');r.seconds=1792530600;return r.service.startRoute(1,1,'crop')
end)
case('next day',function(r)item(r).limits={enabled=true,onceDaily=true};assert(r.service.startRoute(1,1,'crop'));r.service.finishRoute(1,1,'crop');r.date='2026-10-22';return r.service.startRoute(1,1,'crop')end)
case('usage save failure prevents activation',function(r)item(r).limits={enabled=true};r.m.onWrite=function()return false end;local ok,e=r.service.startRoute(1,1,'crop');assert(not ok and not next(r.service.activeRoutes));return ok,e end)
for _,field in ipairs({'citizenId','identifier','license'})do case('usage identity '..field,function(r)
 r.players[1].PlayerData.citizenid=nil;r.players[1].PlayerData[field]='ALT';item(r).limits={enabled=true};assert(r.service.startRoute(1,1,'crop'));assert(r.service.state.usage['ALT:1:crop'])
end)end
case('identifier native fallback',function(r)r.players[1]=nil;item(r).limits={enabled=true};return r.service.startRoute(1,1,'crop')end)
case('identifier index fallback',function(r)r.players[1]=nil;r.noIdentifierType=true;item(r).limits={enabled=true};return r.service.startRoute(1,1,'crop')end)
case('source fallback',function(r)r.players[1]=nil;r.noIdentifierType=true;r.noIdentifier=true;item(r).limits={enabled=true};return r.service.startRoute(1,1,'crop')end)
case('empty search table zero durability inherited',function(r)item(r).required.durability=0;r.searchResult={};assert(r.service.startRoute(1,1,'crop'));assert(r.service.collect(1,1,'crop'))end)
case('insufficient tool durability',function(r)r.items[1][3].metadata={durability=1};assert(r.service.startRoute(1,1,'crop'));return r.service.collect(1,1,'crop')end)
case('missing tool search non-table',function(r)r.searchResult=false;assert(r.service.startRoute(1,1,'crop'));return r.service.collect(1,1,'crop')end)
case('no tool with positive durability still reward inherited',function(r)item(r).required.item='';assert(r.service.startRoute(1,1,'crop'));assert(r.service.collect(1,1,'crop'))end)
case('raw search and durability',function(r)
 r.library.inventory.Search=nil;r.library.inventory.SetDurability=nil;assert(r.service.startRoute(1,1,'crop'));return r.service.collect(1,1,'crop')
end)
case('raw add fallback',function(r)r.library.inventory.AddItem=nil;assert(r.service.startRoute(1,1,'crop'));return r.service.collect(1,1,'crop')end)
case('missing inventory unavailable',function(r)r.library.inventory.AddItem=nil;r.resource='stopped';item(r).required={};assert(r.service.startRoute(1,1,'crop'));return r.service.collect(1,1,'crop')end)
case('durability false return ignored',function(r)r.durabilityResult=false;assert(r.service.startRoute(1,1,'crop'));assert(r.service.collect(1,1,'crop'))end)
case('delivery failure loses tool durability inherited',function(r)
 r.addResult=false;assert(r.service.startRoute(1,1,'crop'));local ok,e=r.service.collect(1,1,'crop');assert(not ok and e=='add_item_failed'and r.items[1][3].metadata.durability==90);return ok,e
end)
case('numeric inventory success truthy',function(r)r.addResult=1;assert(r.service.startRoute(1,1,'crop'));assert(r.service.collect(1,1,'crop'))end)
case('delivery throw preserves route tool already spent',function(r)
 r.addError=true;assert(r.service.startRoute(1,1,'crop'));assert(not pcall(r.service.collect,1,1,'crop')and r.service.activeRoutes['1:1:crop']and r.items[1][3].metadata.durability==90)
end)
case('reward missing rejected',function(r)r.catalog.burger=nil;assert(r.service.startRoute(1,1,'crop'));return r.service.collect(1,1,'crop')end)
case('missing Items api permissive',function(r)r.library.inventory.Items=nil;r.library.inventory.GetItemLabel=nil;assert(r.service.startRoute(1,1,'crop'));return r.service.collect(1,1,'crop')end)
case('range inverted normalized at RNG',function(r)item(r).min=5;item(r).max=2;r.randomHigh=true;assert(r.service.startRoute(1,1,'crop'));local ok,p=r.service.collect(1,1,'crop');assert(ok and p.count==5);return ok,p end)
case('zero reward can succeed',function(r)item(r).min=0;item(r).max=0;assert(r.service.startRoute(1,1,'crop'));return r.service.collect(1,1,'crop')end)
case('max per route not enforced server inherited',function(r)item(r).limits={enabled=true,maxPerRoute=1};assert(r.service.startRoute(1,1,'crop'));assert(r.service.collect(1,1,'crop'));assert(r.service.collect(1,1,'crop'))end)
case('vehicle and time not checked server inherited',function(r)item(r).required.vehicle='adder';item(r).collectTime=100000;assert(r.service.startRoute(1,1,'crop'));assert(r.service.collect(1,1,'crop'))end)
case('drop exact source prefix',function(r)assert(r.service.startRoute(1,1,'crop'));assert(r.service.startRoute(11,1,'crop'));r.drop(1);assert(not r.service.activeRoutes['1:1:crop']and r.service.activeRoutes['11:1:crop'])end)
case('raw farm id alias inherited',function(r)assert(r.service.startRoute(1,'01','crop'));r.service.finishRoute(1,1,'crop');assert(r.service.activeRoutes['1:01:crop'])end)
case('delete leaves route until drop',function(r)assert(r.service.startRoute(1,1,'crop'));assert(r.service.deleteFarm(1,1));assert(r.service.activeRoutes['1:1:crop']);return r.service.collect(1,1,'crop')end)
case('usage update not public payload',function(r)item(r).limits={enabled=true};local rev=r.state.getRecord('farms');assert(r.service.startRoute(1,1,'crop'));H.same(r.state.getRecord('farms'),rev,'no usage publication')end)
print('PASS farms server/config differentials '..n)
