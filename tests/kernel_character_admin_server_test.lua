local R=dofile('tests/kernel_character_admin_harness.lua');local H,n=R.H,0
local function case(name,fn)R.case(name,fn);n=n+1 end
H.same(R.config(true),R.config(false),'whole slot configuration')
case('settings and independent clones',function(r)local a=r.service.getSettings();a.maxSlots=50;assert(r.service.getSettings().maxSlots==3);return r.rpc('CharacterSlots','getSettings')end)
case('settings save',function(r)return r.rpc('CharacterSlots','saveSettings',{maxSlots=5,starterItems={{name='water',amount=3}}}),r.service.getSettings()end)
for _,data in ipairs({false,{}, {starterItems=false},{starterItems={{name='missing',amount=1}}},{starterItems={{name='water',amount=1},{name='water',amount=2}}}})do
 case('invalid settings '..tostring(n),function(r)return r.rpc('CharacterSlots','saveSettings',data)end)
end
for _,amount in ipairs({0,-1,1.5,1000001,'bad',0/0,1,1000000})do case('amount '..tostring(amount),function(r)return r.rpc('CharacterSlots','saveSettings',{starterItems={{name='water',amount=amount}}})end)end
for _,mode in ipairs({'stopped','throw','false','nil'})do case('internal failure '..mode,function(r)
 if mode=='stopped'then r.ready=false else r.callHook=function()if mode=='throw'then error('fixture-internal',0)end;if mode=='false'then return false,'test'end end end
 return r.service.getSettings(),r.service.getPlayer(1),r.service.logout(1)
end)end
case('player characters occupied blocked',function(r)
 r.slots.characters={{citizenid='A',charinfo={cid=1,firstname='John',lastname='Doe'}},{citizenid='B',charinfo={cid=2,firstname='Jane',lastname='Doe'}}}
 r.slots.blocked[7]={[2]=true};local ok,d=r.rpc('CharacterSlots','getPlayer','1');assert(ok and d.occupied[2]=='Jane Doe'and d.blocked[2]);return r.playerRpc('getCharacters',1)
end)
case('display empty offline',function(r)r.offline=true;return r.service.getPlayer(1),r.service.setPlayerSlot(1,1,true)end)
case('bad target',function(r)return r.service.getPlayer('bad'),r.service.setPlayerSlot('bad',1,true)end)
for _,value in ipairs({true,false,'true',1})do case('slot strict '..tostring(value),function(r)return r.rpc('CharacterSlots','setPlayerSlot',1,2,value),r.slots.blocked end)end
case('logout absent emits legacy event',function(r)return r.playerRpc('logout',1)end)
case('logout present succeeds',function(r)r.slots.players[1]={};return r.service.logout(1)end)
case('logout failure',function(r)r.slots.players[1]={};r.logoutResult=false;return r.service.logout(1)end)
case('logout concurrent switching',function(r)
 r.slots.players[1]={};r.callHook=function(name,src)
  if name=='GetPlayer'then return r.slots.players[src]end
  assert(name=='Logout');local ok,reason=r.service.logout(1);assert(not ok and reason=='operation_in_progress');return true
 end
 return r.service.logout(1)
end)
case('start explicit repeat registration',function(r)r.service.start();r.service.start();assert(r.service.registered and r.service.loaded);return r.service.getPreviews()end)
case('item exists no upsert',function(r)r.existingItem={};r.service.start()end)
case('optional internal inventory absent',function(r)r.services.InventoryService=nil;r.service.start()end)
for _,value in ipairs({true,1,false,0})do case('registration strict '..tostring(value),function(r)r.registerResult=value;r.service.start();return r.service.registered end)end
case('inventory reload timer and drop busy',function(r)r.service.busy[1]=true;r.fire('playerDropped',1);assert(not r.service.busy[1]);r.fire('forge-core:server:inventory:reloaded');assert(#r.queue==1);r.timers()end)
case('unlock item strict result and slot',function(r)r.service.start();assert(r.useItem(1,{slot=8})==false and r.stock==1 and r.slots.purchased[7][2]);return r.slots.purchased end)
case('unlock disabled no consume',function(r)r.slots.settings({requireItem=false});r.service.start();assert(r.useItem(1)==false and r.stock==2)end)
case('remove item fails',function(r)r.removeResult=false;r.service.start();return r.useItem(1,{slot=3})end)
for _,refund in ipairs({true,false})do case('unlock save failure refund '..tostring(refund),function(r)r.slots.txResult=false;r.addResult=refund;r.service.start();return r.useItem(1,{slot=5}),r.stock end)end
case('busy and invalid source',function(r)r.service.start();r.service.busy[1]=true;return r.useItem('bad'),r.useItem(1)end)
case('remove exception inherited busy retained',function(r)r.service.start();r.removeError=true;assert(not pcall(r.useItem,1));assert(r.service.busy[1]);r.fire('playerDropped',1)end)
case('previews lazy public load',function(r)
 r.m.seed(r.config.CharacterSlots.previewStorage,{{x='1',y=2,z=3,w=-10,animation='phone'},{x=1,y=2,z=3,heading=0,animation='missing'}})
 local scene=r.exports.GetCharacterPreviews();assert(#scene==1 and scene[1].heading==350 and scene[1].scenario=='WORLD_HUMAN_STAND_MOBILE');return scene
end)
for _,data in ipairs({false,{}, {x=0/0,y=2,z=3,heading=0}, {x=math.huge,y=2,z=3,heading=0}, {x=1,y=2,z=3,heading=0,animation='bad'}})do case('invalid preview '..tostring(n),function(r)return r.service.savePreview(nil,data)end)end
case('preview save update delete normalization',function(r)
 local p={x=1,y=2,z=3,heading=450,animation='arms_crossed',extra='ignored'};assert(r.rpc('CharacterSlots','savePreview',nil,p));assert(r.public.characterPreviews[1].animFlag==1)
 p.heading=-45;assert(r.service.savePreview('1.9',p));assert(r.service.getPreviews()[1].heading==315);return r.rpc('CharacterSlots','deletePreview','1.9')
end)
case('preview indices not found',function(r)return r.service.savePreview(1,{x=1,y=2,z=3,heading=0}),r.service.deletePreview(0),r.service.deletePreview('bad')end)
case('preview limit50 load append',function(r)
 local values={};for i=1,55 do values[i]={x=i,y=2,z=3,heading=0}end;r.m.seed(r.config.CharacterSlots.previewStorage,values)
 assert(#r.exports.GetCharacterPreviews()==50);return r.service.savePreview(nil,{x=1,y=2,z=3,heading=0})
end)
case('failed preview save no publish',function(r)r.m.onWrite=function()return false end;return r.service.savePreview(nil,{x=1,y=2,z=3,heading=0})end)
case('preview delete compacts and raw ref',function(r)
 for i=1,3 do assert(r.service.savePreview(nil,{x=i,y=2,z=3,heading=0}))end;assert(r.service.deletePreview(2));assert(r.service.getPreviews()[2].x==3)
 local raw=r.service.getPreviews();raw[1].x=99;assert(r.service.getPreviews()[1].x==99)
end)
case('VIP Standard and target fallback',function(r)return r.rpc('Vip','get'),r.rpc('Vip','get','bad'),r.rpc('Vip','get',1),r.rpc('Vip','getTiers')end)
case('VIP grant get revoke local',function(r)assert(r.rpc('Vip','grant',1,'gold',2));local ok,active=r.rpc('Vip','get','1');assert(ok and active.tier=='gold'and active.color);assert(r.rpc('Vip','revoke',1));return r.rpc('Vip','get',1)end)
case('VIP permission denied',function(r)r.vip.allowed=false;return r.rpc('Vip','grant',1,'gold',1),r.rpc('Vip','revoke',1)end)
case('VIP class save delete',function(r)
 assert(r.rpc('Vip','saveTier',{id='trial',label='Trial',color='#abcdef',principal='group.trial',slots=1,weight=100,xpMultiplier=1,salary={enabled=false,account='bank',amount=0}}))
 assert(r.rpc('Vip','deleteTier','trial'));return r.rpc('Vip','getTiers')
end)
case('VIP active tier cannot delete',function(r)assert(r.rpc('Vip','grant',1,'gold',1));return r.rpc('Vip','deleteTier','gold')end)
print('PASS lot46 server/config/VIP: '..n..' whole-installed differential cases; actual slots11/VIP16/PR recovery with virtual SQL/provider/codec')
