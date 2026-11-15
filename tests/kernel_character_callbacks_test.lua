local C=dofile('tests/kernel_character_harness.lua')
local count=0
local function test(name,fn) C.compare('character',name,fn);count=count+1 end
local function callback(r,name,...) return r.callbacks['qbx_core:server:'..name](1,...) end
local function data() return {cid=1,firstname='Test',lastname='Player',birthdate='2000-01-01',termsAccepted=true} end
test('characters and normalized previews same response',function(r)
    local characters,slots,state=callback(r,'getCharacters')
    assert(characters==r.state.characters and slots==3 and state.previews==r.previews and state.settings==r.settings)
    assert(state.previews[1].scenario=='WORLD_HUMAN_STAND_IMPATIENT')
    return characters,slots,state
end)
for _,state in ipairs({'starting','stopped','missing'}) do test('preview not ready '..state,function(r) r.previewState=state;return callback(r,'getCharacters') end) end
test('preview throws',function(r) r.previewError=true;return callback(r,'getCharacters') end)
test('preview invalid result',function(r) r.previews='wrong';return callback(r,'getCharacters') end)
test('preview nil result',function(r) r.previews=nil;return callback(r,'getCharacters') end)
test('slots fallback',function(r) r.state=nil;return callback(r,'getCharacters') end)
test('skin exists',function(r) return callback(r,'getPreviewPedData','A') end)
test('skin missing',function(r) return callback(r,'getPreviewPedData','B') end)
test('skin no model',function(r) r.skins.A.model=nil;return callback(r,'getPreviewPedData','A') end)
test('skin numeric model',function(r) r.skins.A.model=42;return callback(r,'getPreviewPedData','A') end)
test('load accepted/log details',function(r) return callback(r,'loadCharacter','A') end)
test('load reason',function(r) r.loginResult=false;r.loginReason='slot_locked';return callback(r,'loadCharacter','A') end)
test('load fallback error',function(r) r.loginResult=false;return callback(r,'loadCharacter','A') end)
test('load identifiers fallback',function(r) r.identifiers.license2=nil;r.identifiers.discord=nil;r.identifiers.ip=nil;return callback(r,'loadCharacter','A') end)
test('load all identifiers absent',function(r) r.identifiers={};return callback(r,'loadCharacter','A') end)
for _,invalid in ipairs({false,'wrong',3}) do test('create invalid '..tostring(invalid),function(r) return callback(r,'createCharacter',invalid or nil) end) end
test('create policy denied',function(r) r.allowed=false;r.allowReason='terms_required';return callback(r,'createCharacter',data()) end)
test('create login failed',function(r) r.loginResult=false;return callback(r,'createCharacter',data()) end)
test('create terms excluded/metadata retained',function(r)
    local input=data();input.custom={x=2};local result=callback(r,'createCharacter',input)
    assert(result.charinfo.termsAccepted==nil and result.charinfo.custom==input.custom and result.charinfo.cid==1)
    return result
end)
test('create terms failed ignored',function(r) r.termsResult=false;return callback(r,'createCharacter',data()) end)
for _,state in ipairs({'missing','stopped','starting','started'}) do test('inventory '..state,function(r) r.inventoryState=state;return callback(r,'createCharacter',data()) end) end
test('wait readiness then kit',function(r) r.inventoryReadyAfter=3;return callback(r,'createCharacter',data()) end)
test('bounded wait without timeout retained',function(r)
    r.inventoryReadyAfter=math.huge;r.yieldWait=true
    local co=coroutine.create(function() return callback(r,'createCharacter',data()) end)
    for _=1,3 do local ok,value=coroutine.resume(co);assert(ok and value==100) end
    assert(coroutine.status(co)=='suspended')
end)
test('metadata closure',function(r)
    r.bindings.starterItems[1].metadata=function(source) r.record('metadata',source);return {owner=source} end
    return callback(r,'createCharacter',data())
end)
test('metadata name mapping last definition',function(r)
    r.bindings.starterItems[2]={name='water',amount=1,metadata={last=true}};return callback(r,'createCharacter',data())
end)
test('all documents suppressed',function(r) r.documentSet.water=true;return callback(r,'createCharacter',data()) end)
test('configured unknown item no metadata',function(r) r.configured[3]={name='new_item',amount=3};return callback(r,'createCharacter',data()) end)
for _,result in ipairs({false,true}) do test('AddItem result ignored '..tostring(result),function(r) r.addResult=result;return callback(r,'createCharacter',data()) end) end
test('empty kit',function(r) r.settings.starterItems={};return callback(r,'createCharacter',data()) end)
for _,result in ipairs({false,true}) do test('legacy owned delete '..tostring(result),function(r)
    r.deleteResult=result;r.events['qbx_core:server:deleteCharacter'](7,'A')
end) end
local r=C.character(true);local total=0;for _ in pairs(r.callbacks) do total=total+1 end;assert(total==4 and #r.module.Events==1)
print('PASS character callbacks: '..count..' differential cases; four callbacks/legacy owned delete, first-response previews, metadata/terms/kit/document filtering and retained readiness/failure behavior')
