local F=dofile('tests/kernel_character_flow_harness.lua')
local H=F.H
local count=0
local root='qbx_core_multichar_characters'
local child='qbx_core_multichar_character_2'
local function check(name,fn,config) count=count+1;return F.compare(name,fn,config) end
local scene={{x=21,y=22,z=23,heading=24,scenario='WORLD_HUMAN_STAND_IMPATIENT'}}
for _,payload in ipairs({false,'invalid',{}, {previews=scene,settings={},unlocked={}},
    {previews={{x='bad',y=22,z=23,w=24}}},{previews={{x=21,y=22,z=23,w='24'}}},
    {previews=scene,settings={requireItem=true},unlocked={['1']=true,['3']=true},blocked={['2']=true}},
    {settings={requireItem=true},unlocked={[1]=true},blocked={[1]=true}},
    {settings={requireItem=false},blocked={[3]=true}}}) do
    check('selection payload '..count,function(r)
        r.api.chooseCharacter()
        assert(r.shown==root and r.menus[root].canClose==false)
        assert(r.menus[child].menu==root and r.menus[child].onBack)
    end,function(r) r.payload=H.copy(payload) end)
end
for _,amount in ipairs({0,1,2,5}) do
    check('slot amount '..amount,function(r)
        r.api.chooseCharacter();assert(#r.menus[root].options==amount)
    end,function(r) r.amount=amount end)
end
check('cid mapping sparse/string and duplicate last wins',function(r)
    r.api.chooseCharacter()
    assert(r.menus[root].options[2].title:find('B',1,true))
    assert(r.menus[root].options[1].disabled==false)
end,function(r) r.characters={F.character('2','A'),F.character(2,'B')} end)
check('cid fallback uses array index',function(r)
    r.api.chooseCharacter()
    assert(r.menus[root].options[1].title:find('A',1,true))
end,function(r) r.characters[1].charinfo.cid=nil end)
for _,kind in ipairs({'nil-characters','nil-amount','bad-blocked','no-job','bad-settings','empty-characters'}) do
    check('installed malformed payload '..kind,function(r) return r.api.chooseCharacter() end,function(r)
        if kind=='nil-characters' then r.characters=nil
        elseif kind=='nil-amount' then r.amount=nil
        elseif kind=='bad-blocked' then r.payload.blocked=1
        elseif kind=='no-job' then r.characters[1].job=nil
        elseif kind=='bad-settings' then r.payload.settings=false
        elseif kind=='empty-characters' then r.characters={} end
    end)
end
check('failed configured ped build uses fallback',function(r)
    r.api.chooseCharacter()
end,function(r) r.payload.previews=H.copy(scene);r.buildResult=false end)
check('exact metadata and locked slots',function(r)
    r.api.chooseCharacter()
    local options=r.menus[root].options
    assert(options[1].disabled==false and options[2].disabled==false and options[3].disabled==true)
    assert(options[2].metadata.Bank=='G:500' and options[2].metadata['Job Grade']=='Driver')
    assert(options[2].metadata['Phone Number']=='555')
end)
for _,configured in ipairs({true,false}) do
    check('occupied selection '..tostring(configured),function(r)
        r.api.chooseCharacter();r.menus[root].options[2].onSelect();r.menus[child].onBack()
        assert(r.shown==child)
    end,function(r) if configured then r.payload.previews=H.copy(scene) end end)
    check('new registration cancel returns root '..tostring(configured),function(r)
        r.api.chooseCharacter();r.menus[root].options[1].onSelect()
        assert(r.shown==root)
    end,function(r) if configured then r.payload.previews=H.copy(scene) end;r.dialogs={false} end)
end
for _,state in ipairs({'started','starting','stopped','missing'}) do
    check('play apartment provider '..state,function(r)
        r.api.chooseCharacter();r.menus[child].options[1].onSelect()
    end,function(r) r.resources.qbx_apartments=state end)
    check('play spawn provider '..state,function(r)
        r.api.chooseCharacter();r.menus[child].options[1].onSelect()
    end,function(r) r.resources.qbx_spawn=state end)
end
for _,loaded in ipairs({false,0,'true',true}) do
    check('load strict result '..tostring(loaded),function(r)
        r.api.chooseCharacter();r.menus[child].options[1].onSelect()
        if loaded~=true then assert(r.shown==root) end
    end,function(r) r.loadResult=loaded end)
end
for _,alert in ipairs({'confirm','cancel','close'}) do
    for _,deleted in ipairs({true,false}) do
        check('delete '..alert..' '..tostring(deleted),function(r)
            r.api.chooseCharacter();r.menus[child].options[2].onSelect()
            assert(r.shown==(alert=='confirm' and root or child))
        end,function(r) r.alert=alert;r.deleteResult=deleted end)
    end
end
check('delete button disabled retains absent second option',function(r)
    r.api.chooseCharacter()
    assert(r.menus[child].options[2]==nil)
end,function(r) r.config.characters.enableDeleteButton=false end)
check('new character success does not reopen root',function(r)
    r.api.chooseCharacter();r.shown=nil
    r.menus[root].options[1].onSelect()
    assert(r.shown==nil)
end,function(r)
    r.dialogs={{'First','Last','American','info.char_male','1990-01-01'}}
    r.createData={citizenid='NEW',cid=1}
end)
check('logout caller guard and remote return',function(r)
    r.invoking='foreign';r.handler('qbx_core:client:playerLoggedOut')()
    assert(r.shown==nil)
    r.invoking=nil;r.handler('qbx_core:client:playerLoggedOut')();assert(r.shown==root)
end)
check('resource cleanup only for actual owner',function(r)
    r.clearTrace()
    r.handler('onResourceStop')('foreign');r.handler('onResourceStop')('forge-core')
    local deletes=0;for _,e in ipairs(r.trace) do if e.kind=='destroyPreviewCam' then deletes=deletes+1 end end
    assert(deletes==1)
end)
check('fade-out predicate keeps installed AND behavior',function(r)
    r.api.chooseCharacter()
    -- Same cached ped means selection skips the initial fade wait even if not faded.
    assert(r.waits==2)
end,function(r) r.fadedOut=false end)
check('inherited concurrent selection has no generation gate',function(r)
    r.callbackYield='qbx_core:server:getCharacters'
    local first=coroutine.create(r.api.chooseCharacter)
    local second=coroutine.create(r.api.chooseCharacter)
    local ok,pending=coroutine.resume(first);assert(ok and pending=='callback pending')
    ok,pending=coroutine.resume(second);assert(ok and pending=='callback pending')
    r.callbackYield=nil
    F.runCoroutine(second,10);F.runCoroutine(first,10)
    local shown=0;for _,e in ipairs(r.trace) do if e.kind=='showContext' and e.args[1]==root then shown=shown+1 end end
    assert(shown==2)
end)
check('inherited input can resume after resource cleanup',function(r)
    r.inputYield=true
    local co=coroutine.create(function() return r.api.createCharacter(1,{}) end)
    local ok,pending=coroutine.resume(co);assert(ok and pending=='input pending')
    r.handler('onResourceStop')('forge-core')
    local cleanedAt=#r.trace
    r.inputYield=false;F.runCoroutine(co,10)
    local late=false
    for i=cleanedAt+1,#r.trace do if r.trace[i].kind=='callback' then late=true end end
    assert(late)
end,function(r) r.dialogs={{'First','Last','American','info.char_male','1990-01-01'}} end)
print('PASS character flow menus: '..count..' differential cases; first payload/scenes/slots, parent-child/back/metadata/disabled, play/delete/cancel/return, caller/owner guards and retained malformed-input/reentry behavior; no real UI')
