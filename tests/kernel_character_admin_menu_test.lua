local R=dofile('tests/kernel_character_admin_harness.lua');local n=0
local function case(name,fn)R.menuCase(name,fn);n=n+1 end
local function slotForm(items)return{6,'true',2,'false','First','Last','true',21,'true','Title','2','Text',items or{}}end
case('management route classes',function(r)r.menu.openPlayersManagement();r.select(2);assert(r.last.id=='forge_core_vip_classes')end)
case('management route creation',function(r)r.menu.openPlayersManagement();r.select(1);assert(r.last.id=='forge_core_character_creation_settings')end)
case('VIP parent and alias',function(r)r.menu.openVipClassesMenu('custom');assert(r.last.menu=='custom');r.menu.openVipMenu();assert(r.last.menu=='forge_core_players_management')end)
case('empty VIP tiers',function(r)r.tiers={};r.menu.openVipClassesMenu();assert(#r.last.options==1)end)
case('VIP tier submenu parent',function(r)r.menu.openVipClassesMenu();r.select(2);assert(r.last.menu=='forge_core_vip_classes')end)
local tierForm={'new','New','#123456','group.new',2,3000,1.5,'true','bank',500}
for _,edit in ipairs({false,true})do
 case('tier cancel '..tostring(edit),function(r)r.menu.openVipClassesMenu('custom');if edit then r.select(2);r.select(1)else r.select(1)end;assert(r.last.menu=='forge_core_players_management','inherited parent lost')end)
 case('tier save '..tostring(edit),function(r)r.inputs={tierForm};r.menu.openVipClassesMenu('custom');if edit then r.select(2);r.select(1)else r.select(1)end;r.runTimers();assert(r.last.menu=='forge_core_players_management')end)
end
for _,answer in ipairs({'confirm','cancel'})do case('delete tier '..answer,function(r)r.alerts={answer};r.menu.openVipClassesMenu('custom');r.select(2);r.select(2);r.runTimers();assert(r.last.menu=='custom')end)end
for _,vip in ipairs({'standard','gold'})do
 case('player VIP '..vip,function(r)r.current={tier=vip,label='Gold',expiresAtFormatted='Tomorrow'};r.menu.openPlayerVipAdmin(1);assert(#r.last.options==(vip=='gold'and 2 or 1)and r.last.menu=='forge_core_managed_player')end)
 case('grant VIP '..vip,function(r)r.current={tier=vip,label='Gold',expiresAtFormatted='Tomorrow'};r.inputs={{'gold',30}};r.menu.openPlayerVipAdmin(1);r.select(1);r.runTimers()end)
end
case('grant cancel returns player VIP',function(r)r.menu.openPlayerVipAdmin(1);r.select(1);assert(r.last.id=='forge_core_player_vip')end)
for _,answer in ipairs({'confirm','cancel'})do case('revoke '..answer,function(r)r.current={tier='gold',label='Gold',expiresAtFormatted='Tomorrow'};r.alerts={answer};r.menu.openPlayerVipAdmin(1);r.select(2);r.runTimers()end)end
for _,method in ipairs({'openVipClassesMenu','openPlayerVipAdmin','openCharacterSlotSettings','openCharacterPreviewSettings','openPlayerCharacterSlots'})do
 case('RPC denied '..method,function(r)r.adminHook=function()return false,'no_permission'end;r.menu[method](1)end)
end
case('creation root custom parent',function(r)r.menu.openCharacterCreationSettings('custom');assert(r.last.menu=='custom');r.select(2);assert(r.last.menu=='forge_core_character_creation_settings')end)
case('settings cancel with parent returns root',function(r)r.menu.openCharacterSlotSettings('custom');assert(r.last.menu=='custom')end)
case('settings cancel without parent',function(r)r.menu.openCharacterSlotSettings()end)
case('settings save without kit',function(r)r.inputs={slotForm()};r.menu.openCharacterSlotSettings('custom');r.runTimers();assert(r.last.id=='forge_core_character_creation_settings')end)
case('settings selected kit two dialogs',function(r)r.inputs={slotForm({'water','phone'}),{3,1}};r.menu.openCharacterSlotSettings('custom');r.runTimers()end)
case('settings kit quantities cancelled',function(r)r.inputs={slotForm({'water'})};r.menu.openCharacterSlotSettings('custom')end)
for _,flag in ipairs({true,'true',1,'1',false,'false',0})do case('boolean conversion '..tostring(flag),function(r)local f=slotForm();f[2],f[4],f[7],f[9]=flag,flag,flag,flag;r.inputs={f};r.menu.openCharacterSlotSettings('custom')end)end
case('preview no positions',function(r)r.settings.previews={};r.menu.openCharacterPreviewSettings();assert(#r.last.options==2 and r.last.options[2].disabled)end)
case('preview row and actions',function(r)r.menu.openCharacterPreviewSettings();r.select(2);assert(r.last.menu=='forge_core_character_preview_settings')end)
case('preview unknown animation label',function(r)r.settings.previews[1].animation='unknown';r.menu.openCharacterPreviewSettings()end)
for _,answer in ipairs({'confirm','cancel'})do case('delete preview '..answer,function(r)r.alerts={answer};r.menu.openCharacterPreviewSettings();r.select(2);r.select(2);r.runTimers()end)end
for _,edit in ipairs({false,true})do
 for _,result in ipairs({'save','cancel','not-started'})do case('place '..tostring(edit)..result,function(r)
  r.placementFalse=result=='not-started';r.menu.openCharacterPreviewSettings('custom');if edit then r.select(2);r.select(1)else r.select(1)end
  if result~='not-started'then r.finishPlacement(result=='save'and{x=1,y=2,z=3,heading=90,animation='phone'}or nil)end;r.runTimers()
 end)end
end
case('placement missing PR provider',function(r)r.library.fivem=nil;r.menu.openCharacterPreviewSettings();r.select(1)end)
case('placement alternate aliases',function(r)local fn=r.library.fivem.devtools.placeAnimatedPed;r.library.fivem={devTools={PlaceAnimatedPed=fn}};r.menu.openCharacterPreviewSettings();r.select(1);r.finishPlacement(nil)end)
case('placement result late targets previous index',function(r)r.menu.openCharacterPreviewSettings();r.select(2);r.select(1);r.settings.previews={};r.finishPlacement({x=1,y=2,z=3,heading=0});r.runTimers()end)
case('slots mixed numeric string and suspended',function(r)r.menu.openPlayerCharacterSlots(1);assert(r.last.menu=='forge_core_managed_player'and #r.last.options==7)end)
for _,i in ipairs({2,3,4,5,6,7})do case('slot toggle/grant '..i,function(r)r.menu.openPlayerCharacterSlots(1);r.select(i);r.runTimers()end)end
for _,target in ipairs({'saveSettings','savePreview','deletePreview','setPlayerSlot'})do case('slot mutation refused '..target,function(r)
 local cb=r.config.CharacterSlots.callbacks;local parent=r.library.callback.await;r.library.callback.await=function(name,timeout,...)if name==cb[target]then r.record('refusal',name,...);return false,'fixture-denied'end;return parent(name,timeout,...)end
 if target=='saveSettings'then r.inputs={slotForm()};r.menu.openCharacterSlotSettings('custom')
 elseif target=='savePreview'then r.menu.openCharacterPreviewSettings();r.select(1);r.finishPlacement({x=1,y=2,z=3,heading=0})
 elseif target=='deletePreview'then r.alerts={'confirm'};r.menu.openCharacterPreviewSettings();r.select(2);r.select(2)
 else r.menu.openPlayerCharacterSlots(1);r.select(2)end;r.runTimers()
end)end
print('PASS lot46 menus: '..n..' whole-installed differential cases; PR menu/RPC/input/placement boundaries virtual, no CEF/FiveM')
