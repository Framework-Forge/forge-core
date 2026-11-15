local F=dofile('tests/kernel_character_flow_harness.lua')
local H=F.H
local count=0
local function check(name,fn,config) count=count+1;return F.compare(name,fn,config) end
for _,state in ipairs({'started','starting','stopped','missing'}) do
    check('appearance readiness '..state,function(r)
        local before=r.now;r.api.openFirstCharacterAppearance()
        assert(r.now-before==(state=='started' and 0 or 5000))
    end,function(r) r.resources['illenium-appearance']=state end)
end
check('appearance becomes available while waiting',function(r)
    r.api.openFirstCharacterAppearance();assert(r.now==200)
end,function(r)
    local hits=0;r.resourceHook=function(name)
        if name=='illenium-appearance' then hits=hits+1;return hits>2 and 'started' or 'stopped' end
    end
end)
for _,failed in ipairs({true,false}) do
    check('default spawn pcall '..tostring(failed),function(r) r.api.spawnDefault() end,
        function(r) r.spawnError=failed end)
end
check('default spawn waits for both fade stages',function(r)
    r.api.spawnDefault();assert(r.fadedIn and r.fadedOut)
end,function(r)
    r.fadedOut=false;r.fadedIn=false
    r.onWait=function() if r.waits==1 then r.fadedOut=true elseif r.waits==2 then r.fadedIn=true end end
end)
for _,kind in ipairs({'normal','nil-metadata','no-inside','no-property','zero-property','false-property',
    'string-property','missing-position','spawn-error'}) do
    check('last location '..kind,function(r) r.api.spawnLastLocation() end,function(r)
        if kind=='nil-metadata' then r.core.PlayerData.metadata=nil
        elseif kind=='no-inside' then r.core.PlayerData.metadata={}
        elseif kind=='no-property' then r.core.PlayerData.metadata.inside={}
        elseif kind=='zero-property' then r.core.PlayerData.metadata.inside.property_id=0
        elseif kind=='false-property' then r.core.PlayerData.metadata.inside.property_id=false
        elseif kind=='string-property' then r.core.PlayerData.metadata.inside.property_id='42'
        elseif kind=='missing-position' then r.core.PlayerData.position=nil
        elseif kind=='spawn-error' then r.spawnError=true end
    end)
end
for _,state in ipairs({'missing','stopped','starting','started'}) do
    for _,apartment in ipairs({true,false}) do
        check('new character spawn '..state..' apartment '..tostring(apartment),function(r)
            assert(r.api.createCharacter(1,{})==true)
        end,function(r)
            r.resources.qbx_spawn=state;r.config.characters.startingApartment=apartment
            r.dialogs={{'First','Last','American','info.char_male','1990-01-01'}}
            r.createData={citizenid='NEW',cid=1}
        end)
    end
end
for _,isNew in ipairs({true,false}) do
    check('spawn no apartments '..tostring(isNew),function(r)
        r.handler('qbx_core:client:spawnNoApartments')(isNew)
        assert(r.now==3000)
    end)
end
for _,state in ipairs({'missing','stopped','starting','started'}) do
    check('loading provider state '..state,function(r)
        r.api.chooseCharacter()
        local fallback=0;for _,e in ipairs(r.trace) do if e.kind=='ShutdownLoadingScreen' then fallback=fallback+1 end end
        assert(fallback==(state=='started' and 0 or 1))
    end,function(r) r.resources['forge-loadscreen']=state end)
end
check('inherited failed finish falls back to native shutdown',function(r)
    r.api.chooseCharacter()
    local seen=false;for _,e in ipairs(r.trace) do if e.kind=='ShutdownLoadingScreen' then seen=true end end
    assert(seen)
end,function(r) r.loadingError=true;r.minimumMs=180000 end)
for _,result in ipairs({false,0,'ok'}) do
    check('finish successful call ignores returned value '..tostring(result),function(r)
        r.api.chooseCharacter()
        for _,e in ipairs(r.trace) do assert(e.kind~='ShutdownLoadingScreen') end
    end,function(r) r.loadingResult=result end)
end
for _,minimum in ipairs({0,3,180}) do
    check('installed controller minimum '..minimum,function(r)
        r.now=12500 -- selection's waits consume 2.5s; first Finish call is at 15s.
        F.bindLoadingController(r,{minimumLoadscreenSeconds=minimum})
        local co=coroutine.create(r.api.chooseCharacter)
        F.runCoroutine(co,300)
        assert(r.shown and r.loadingClosedAt>=minimum*1000)
        assert(r.shownAt>=r.loadingClosedAt)
        if minimum==180 then assert(r.loadingClosedAt==180100 and r.shownAt==180100) end
        for _,e in ipairs(r.trace) do assert(e.kind~='ShutdownLoadingScreen','No fallback during successful provider wait') end
    end)
end
check('selector stays hidden while minimum is pending',function(r)
    r.now=12500;F.bindLoadingController(r,{minimumDuration=180})
    local co=coroutine.create(r.api.chooseCharacter)
    for _=1,8 do local ok,value=coroutine.resume(co);assert(ok,value);assert(r.shown==nil) end
    assert(r.now<180000)
    F.runCoroutine(co,300)
    assert(r.shownAt>=180000)
end)
for _,limited in ipairs({true,false}) do
    check('network startup/tutorial lifecycle '..tostring(limited),function(r)
        local id=r.config.characters.limitNationalities and 2 or 1
        if r.config.characters.limitNationalities then r.fillNationalities() end
        assert(r.thread(id)==0) -- first poll
        r.networkStarted=true
        assert(r.thread(id)==250)
        assert(r.thread(id)==1000)
        assert(r.thread(id)==1500)
        assert(r.thread(id)==250) -- invincibility loop after selection
        r.tutorial=false;r.thread(id)
        assert(coroutine.status(r.coroutines[id])=='dead')
    end,function(r) r.networkStarted=false;r.config.characters.limitNationalities=limited end)
end
check('auto spawn error is contained during startup',function(r)
    local id=2;r.fillNationalities()
    for _=1,5 do r.thread(id) end
    r.tutorial=false;r.thread(id)
end,function(r) r.autoSpawnError=true end)
check('tutorial wait is unbounded in origin, observed only for limited steps',function(r)
    r.holdTutorial=true;r.tutorial=false
    local co=coroutine.create(r.api.chooseCharacter)
    for _=1,5 do local ok,value=coroutine.resume(co);assert(ok,value) end
    assert(coroutine.status(co)=='suspended' and r.shown==nil)
    r.tutorial=true;F.runCoroutine(co,10);assert(r.shown)
end)
-- Explicit initialization is private/additive; never changes live startup.
local r=F.new(true)
local fresh=r.factory(r.bindings)
r.clearTrace();r.tutorialYield=true
local co=coroutine.create(fresh.Initialize)
assert(coroutine.resume(co) and not fresh.Initialize())
assert(coroutine.resume(co) and coroutine.status(co)=='dead' and not fresh.Initialize())
assert(fresh.GetFallbackLocation()==r.config.characters.locations[1])
local solo=0;for _,e in ipairs(r.trace) do if e.kind=='NetworkStartSoloTutorialSession' then solo=solo+1 end end
assert(solo==1)
print('PASS character flow spawn: '..count..' differential cases; spawn/appearance/provider branches, installed loadscreen controller enforces 180s after 15s, hidden selector during wait, tutorial/bootstrap and explicit init guard; simulated time/resources only')
