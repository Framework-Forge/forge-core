local R=dofile('tests/kernel_assembly_harness.lua');local H=R.H
local r=R.new();local api=r.mount();local pc,slots=api.PlayerCore,api.Slots.Service
r.c.settings({maxSlots=4,requireItem=true,minimumAgeEnabled=false,termsEnabled=false,starterItems={{name='water',amount=2}}})
r.characterRow('OWNED',2);r.c.blocked[101]={[2]=true}
local callbacks=pc.Characters.Character.Callbacks
local ok,reason=callbacks['qbx_core:server:loadCharacter'](1,'OWNED')
assert(not ok and reason=='character_slot_locked'and pc.Lookup.GetPlayer(1)==nil,'initial Player Login consults same already constructed slot policy')
local list,max,scene=callbacks['qbx_core:server:getCharacters'](1)
assert(#list==1 and max==4 and scene.blocked[2]and scene.previews[1]==nil,'slots use actual internal Storage and absent preview remains explicit')
assert(slots.setSpecificSlot(1,2,true));assert(callbacks['qbx_core:server:loadCharacter'](1,'OWNED'))
local player=assert(pc.Lookup.GetPlayer(1));assert(player.PlayerData.citizenid=='OWNED'and pc.State.Players[1]==player)
local records=pc.Lookup.GetQBPlayers();local groups,buckets,usables=pc.Groups,pc.State.Player_Buckets,pc.State.UsableItems
assert(pc.Players.AddMoney(1,'cash',5)and player.PlayerData.money.cash==15,'same Player money')
assert(pc.Lifecycle.Functions.SetPlayerBucket(1,7)and buckets[1]==7)
assert(slots.setSpecificSlot(1,2,false));assert(pc.Lookup.GetPlayer(1)==nil and r.c.blocked[101][2],'slot suspension calls actual same Player Logout')
assert(r.c.purchased[101][2],'suspension retains purchased entitlement')
assert(slots.setSpecificSlot(1,2,true));assert(callbacks['qbx_core:server:loadCharacter'](1,'OWNED'))
local W=dofile('tests/kernel_world_harness.lua');local world=W.world(true,true)
r.base.JobCatalog.Dependencies.State=world.state
local config=api.Config
local admin=H.load('kernel/server/character_admin_core.lua',R.env())(r.base,{config=config,library=r.library,
 native={GetPlayerName=r.native.getPlayerName,TriggerClientEvent=r.n.native.TriggerClientEvent,SetTimeout=r.native.setTimeout},
 clock={date=os.date},print=function()end,slotPolicy=slots,isReady=function()return r.base.PlayerCore==pc end})
assert(admin.Usable==api.Parts.Consumption.Usable and admin.SlotPolicy==slots,'character admin reuses existing consumption/slot policy, no fallback adapter')
r.m.seed(config.CharacterSlots.previewStorage,{{x=21,y=22,z=23,heading=270,animation='phone'}})
list,max,scene=callbacks['qbx_core:server:getCharacters'](1)
assert(scene.previews[1].x==21 and scene.previews[1].scenario=='WORLD_HUMAN_STAND_MOBILE','real admin46 scene in first canonical payload')
assert(world.state.get('characterPreviews')[1].heading==270 and admin.Service.loaded,'same normalized world record')
local old=r.base.CharacterAdminCore;r.base.CharacterAdminCore={PlayerCore={},SlotPolicy=slots}
local pass,err=pcall(callbacks['qbx_core:server:getCharacters'],1)
-- The new assembly refuses a substituted authority before calling the preview export.
assert(not pass and tostring(err):find('canonical preview consumer required',1,true),'substituted preview authority refused')
r.base.CharacterAdminCore=old
assert(pc.State.Players==records and pc.Groups==groups and pc.State.Player_Buckets==buckets and pc.State.UsableItems==usables,'canonical maps unchanged')
local saved=r.base.PlayerCore;r.base.PlayerCore={}
assert(not pcall(slots.getState,1),'deferred dependency refuses replaced Player authority')
r.base.PlayerCore=saved;assert(slots.getState(1).settings.maxSlots==4,'same authority restored only in test fixture')
assert(r.base.ServerAssembly==api and api.State=='prepared-inactive','actions do not imply activation')
print('PASS lot47 character composition: policy constructed before Player; actual Storage/owned login/suspension/Logout/money/buckets; same admin46/Consumption20/preview record, no shadow holders')
