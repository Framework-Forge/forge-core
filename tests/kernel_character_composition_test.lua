local C=dofile('tests/kernel_character_harness.lua')
local L=dofile('tests/kernel_lifecycle_harness.lua')
local H,P=C.H,C.P
local p,character,documents,l=P.new(true),C.character(true),C.documents(true),L.new(true)
local players
local slotFixture=C.slots(true,function(r)
    -- One slot Service is delivered into Player ports before constructing that Player.
    r.bindings.storage=p.storage
    p.storage.fetchAllPlayerEntities=function(...) r.record('characters',...);return H.copy(r.characters) end
    p.storage.fetchPlayerSkin=function(id) return character.bindings.storage.fetchPlayerSkin(id) end
    r.bindings.native.GetPlayerIdentifierByType=p.platform.getIdentifier
    r.bindings.getPlayer=p.lookup.GetPlayer
    r.bindings.logout=function(...) return assert(players,'Player not composed').Logout(...) end
end)
local bindings={};for key,value in pairs(p.bindings) do bindings[key]=value end
bindings.characterSlots=slotFixture.module.Service
players=H.load('kernel/server/player.lua',H.environment())(bindings)
p.core.Player_Buckets,p.core.Entity_Buckets,p.core.UsableItems={},{},{}
local fb={};for key,value in pairs(l.bindings) do fb[key]=value end
fb.core,fb.players,fb.lookup=p.core,players,p.lookup
local functions=H.load('kernel/server/functions.lua',H.environment())(fb)
local core={State=p.core,Players=players,Lookup=p.lookup,Storage=p.storage,Lifecycle={Functions=functions}}
local base={PlayerCore=core}
local env,loaded=H.environment(),{}
local paths={['kernel.server.character']='kernel/server/character.lua',['kernel.server.document_items']='kernel/server/document_items.lua'}
env.require=function(name)
    local file=assert(paths[name],'External import forbidden: '..tostring(name))
    if not loaded[name] then loaded[name]=H.load(file,env) end;return loaded[name]
end
local compose=H.load('kernel/server/character_core.lua',env)
local ports={};for key,value in pairs(character.bindings) do ports[key]=value end
ports.slots,ports.slotPolicy,ports.documents=slotFixture.module,slotFixture.service,documents.bindings
ports.config,ports.logger=p.config,p.bindings.logger
local api=compose(base,core,ports)
assert(api.State==p.core and api.Slots==slotFixture.module and api.Slots.Service==bindings.characterSlots)
assert(core.Characters==api and #p.trace==0 and #slotFixture.trace==0 and #character.trace==0 and #documents.trace==0)
assert(not pcall(compose,base,core,ports),'No duplicate character composition')
local otherCore={State=p.core,Players=players,Storage=p.storage,Lookup=p.lookup,Lifecycle={Functions=functions}}
local wrong={};for key,value in pairs(ports) do wrong[key]=value end;wrong.slotPolicy={}
assert(not pcall(compose,{PlayerCore=otherCore},otherCore,wrong),'Reject shadow slot policy identity')
slotFixture.settings({maxSlots=3,termsEnabled=true,minimumAgeEnabled=false,starterItems={{name='water',amount=2},{name='id_card',amount=1}}})
p.offline.A={citizenid='A',license='license:test',userId=101,charinfo={cid=2},position=P.vector(1,2,3,4)}
slotFixture.characters={p.offline.A}
slotFixture.blocked[101]={[2]=true}
local callback=api.Character.Callbacks
local ok,reason=callback['qbx_core:server:loadCharacter'](1,'A')
assert(not ok and reason=='character_slot_locked' and p.lookup.GetPlayer(1)==nil,'Actual Player Login must consult this same slot policy')
slotFixture.blocked[101]={}
assert(callback['qbx_core:server:loadCharacter'](1,'A') and p.lookup.GetPlayer(1).PlayerData.citizenid=='A')
local list,max,state=callback['qbx_core:server:getCharacters'](1)
assert(list[1].citizenid=='A' and max==3 and state.previews==character.previews and slotFixture.purchased[101][2])
assert(state.previews[1].scenario,'Normalized public preview returned on first response')
assert(api.Slots.Service.setSpecificSlot(1,2,false))
assert(p.lookup.GetPlayer(1)==nil and slotFixture.blocked[101][2] and slotFixture.purchased[101][2], 'Actual Logout with suspension retains entitlement')
assert(api.Slots.Service.setSpecificSlot(1,2,true))
local before=#p.trace
api.Character.Events[1].handler(1,'A')
assert(not slotFixture.purchased[101][2],'Ownership checked delete invokes this same policy to remove purchased slot')
local deleted=false
for i=before+1,#p.trace do if p.trace[i].kind=='delete' and p.trace[i].args[1]=='A' then deleted=true end end
assert(deleted)
-- A foreign character must not be deleted through the legacy event.
p.offline.Foreign={citizenid='Foreign',license='license:other',userId=999,charinfo={cid=2}}
before=#p.trace;api.Character.Events[1].handler(1,'Foreign')
local dropped=false
for i=before+1,#p.trace do assert(p.trace[i].kind~='delete');if p.trace[i].kind=='drop' then dropped=true end end
assert(dropped,'Must not bind the unguarded administrative force-delete export')
slotFixture.characters={};slotFixture.purchased[101]={}
local created=callback['qbx_core:server:createCharacter'](1,{cid=1,firstname='New',birthdate='2000-01-01',termsAccepted=true})
assert(created and not created.charinfo.termsAccepted and p.lookup.GetPlayer(1),'Actual internal Login creates the canonical player')
assert(slotFixture.terms[101]['1.0'])
local water,docs=0,0
for _,entry in ipairs(character.trace) do if entry.kind=='AddItem' then
    if entry.args[2]=='water' then water=water+1 elseif entry.args[2]=='id_card' then docs=docs+1 end
end end
assert(water==1 and docs==0,'PR inventory receives starter kit once; documents only classified, never issued')
assert(not pcall(env.require,'pr_lib.framework'))
for _,name in ipairs({'QBX','QBXCharacterSlots','exports','MySQL','CreateThread','RegisterNetEvent'}) do assert(rawget(env,name)==nil,'No ambient runtime '..name) end
print('PASS character composition: same actual Player/lookup/storage/slot policy, blocked login/real logout/owned deletion, initial normalized previews and canonical creation/terms/kit; no self-export, duplicate authority or constructor effects')
