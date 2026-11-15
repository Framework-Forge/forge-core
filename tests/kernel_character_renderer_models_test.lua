local R=dofile('tests/kernel_character_renderer_harness.lua')
local H=R.H
local count=0
local function check(label,action,config)
    count=count+1; return R.compare(label,action,config)
end
for _,value in ipairs({false,1,'text',{}, {previews=false},{previews={}}, {previews={{x=7}}}}) do
    check('payload '..tostring(value),function(r)
        local result=r.api.configuredPreviewLocations(value)
        if type(value)=='table' and type(value.previews)=='table' then assert(result==value.previews) end
        return result
    end)
end
check('nil payload',function(r) return r.api.configuredPreviewLocations(nil) end)
for _,index in ipairs({1,2}) do
    local b=check('complete random preset '..index,function(r)
        r.swapPed=20; r.api.randomPed()
        assert(r.cache.ped==20)
    end,function(r) r.randomValues={index} end)
    local data
    for _,e in ipairs(b.trace) do if e.kind=='setPedAppearance' then data=e.args[2] end end
    assert(data and #data.components==12 and #data.props==5)
    if index==1 then assert(data.model==1885233650 and data.headOverlays.beard.opacity==1)
    else assert(data.model==2627665880 and data.headBlend.shapeFirst==31 and data.hair.style==15) end
end
for _,kind in ipairs({'nil','missing','saved','bad','false','scalar','no-model','callback-error','appearance-error','streaming-error'}) do
    check('preview '..kind,function(r) r.api.previewPed(kind~='nil' and 'A' or nil) end,function(r)
        if kind=='saved' or kind=='appearance-error' then r.skins.A={'skin','model'}; r.decoded={skin={model='saved',test=true}} end
        if kind=='bad' then r.skins.A={'bad',123} end
        if kind=='false' then r.skins.A={false,123} end
        if kind=='scalar' then r.skins.A={'scalar',123};r.decoded={scalar=5} end
        if kind=='no-model' then r.skins.A={'skin'} end
        r.previewError=kind=='callback-error';r.appearanceError=kind=='appearance-error';r.streamingError=kind=='streaming-error'
    end)
end
local place={x=12,y=34,z=56,heading=90}
for _,kind in ipairs({'empty','saved-number','saved-string','bad','scalar','missing-model','appearance-error','zero','nil','callback-error','streaming-error'}) do
    check('slot ped '..kind,function(r)
        return r.api.createSlotPreviewPed(kind=='empty' and nil or {citizenid='A'},H.copy(place))
    end,function(r)
        if kind=='saved-number' or kind=='saved-string' or kind=='appearance-error' then
            r.skins.A={'skin',kind=='saved-number' and 42 or 'saved-model'}; r.decoded={skin={model='skin',custom=9}}
        elseif kind=='bad' then r.skins.A={'bad',42}
        elseif kind=='scalar' then r.skins.A={'scalar',42};r.decoded={scalar=4}
        elseif kind=='missing-model' then r.skins.A={'skin',false};r.decoded={skin={custom=1}} end
        r.failPed=kind=='zero' or kind=='nil';r.failPedValue=kind=='zero' and 0 or nil
        r.appearanceError=kind=='appearance-error';r.previewError=kind=='callback-error';r.streamingError=kind=='streaming-error'
    end)
end
for _,animation in ipairs({
    {},{scenario='WORLD_HUMAN_STAND_IMPATIENT',animDict='ignored',animName='ignored'},
    {scenario='',animDict='dict',animName='idle'}, {animDict='dict'}, {animName='idle'},
    {animDict='dict',animName='idle',animFlag='49'},{animDict='dict',animName='idle',animFlag='invalid'}
}) do
    check('animation '..count,function(r) r.api.playSlotPreviewAnimation(10,H.copy(animation)) end)
end
for _,input in ipairs({
    {amount=0,locations={}}, {amount=2,locations={{x=1,y=2,z=3,w=45}}},
    {amount=1,locations={{x='1',y='2',z='3',heading='90',animDict='a',animName='b',animFlag=2}}},
    {amount=2,locations={{x=1,y=2,z=3,heading=0},{x='bad',y=2,z=3,heading=0}}},
    {amount=2,locations={{x=1,y=2,z=3,heading=0},false}},
    {amount=1,locations={{x=1,y=2,z=3}}}
}) do
    check('build validation '..count,function(r)
        local success=r.api.buildConfiguredPreviews({[1]={citizenid='A'}},input.amount,H.copy(input.locations))
        return success,r.api.IsConfigured(),r.api.configuredOverview()
    end)
end
check('all ped creates fail',function(r)
    assert(not r.api.buildConfiguredPreviews({},1,{H.copy(place)}))
    assert(not r.api.IsConfigured())
end,function(r) r.failPed=true;r.failPedValue=0 end)
check('rebuild deletes old local peds',function(r)
    r.api.buildConfiguredPreviews({},2,{H.copy(place),H.copy(place)})
    assert(r.entities[101] and r.entities[102])
    r.api.buildConfiguredPreviews({},1,{H.copy(place)})
    assert(not r.entities[101] and not r.entities[102] and r.entities[103])
    r.api.clearConfiguredPreviews()
    assert(not r.entities[103] and r.entities[10] and not r.api.IsConfigured())
end)
check('overview occupied before empty and smallest occupied slot',function(r)
    r.api.buildConfiguredPreviews({[3]={citizenid='A'},[2]={citizenid='B'}},3,
        {{x=1,y=0,z=0,heading=0},{x=2,y=0,z=0,heading=0},{x=3,y=0,z=0,heading=0}})
    assert(r.api.configuredOverview().x==2)
    return r.api.configuredOverview()
end)
check('overview smallest empty slot',function(r)
    r.api.buildConfiguredPreviews({},2,{{x=1,y=0,z=0,heading=0},{x=2,y=0,z=0,heading=0}})
    assert(r.api.configuredOverview().x==1)
end)
check('cleanup missing ped and repeat',function(r)
    r.api.buildConfiguredPreviews({},1,{H.copy(place)})
    r.entities[101]=nil
    r.api.clearConfiguredPreviews();r.api.clearConfiguredPreviews()
end)
check('preset identity reused within one renderer',function(r)
    r.api.createSlotPreviewPed(nil,H.copy(place));r.api.randomPed()
    local skins={};for _,e in ipairs(r.trace) do if e.kind=='setPedAppearance' then skins[#skins+1]=e.args[2] end end
    H.same(skins[1],skins[2])
end)
for _,boundary in ipairs({'preview','streaming'}) do
    check('inherited cleanup while '..boundary..' is pending',function(r)
        local co=coroutine.create(function()
            return r.api.buildConfiguredPreviews({[1]={citizenid='A'}},1,{H.copy(place)})
        end)
        local ok,pending=coroutine.resume(co);assert(ok,pending)
        assert(pending==(boundary=='preview' and 'preview pending' or 'streaming pending'))
        r.api.destroyPreviewCam()
        ok=coroutine.resume(co);assert(ok and coroutine.status(co)=='dead')
        -- Original lacks a generation guard across these awaits. Record, do not fix here.
        assert(r.entities[101] and r.api.IsConfigured() and r.api.configuredOverview()==nil)
        r.api.clearConfiguredPreviews();assert(not r.entities[101])
    end,function(r)
        r.previewYield=boundary=='preview';r.streamingYield=boundary=='streaming'
    end)
end
check('streaming false return remains ignored by installed renderer',function(r)
    assert(r.api.createSlotPreviewPed(nil,H.copy(place))==101)
end,function(r) r.streamingResult=false end)
check('appearance false return remains ignored by installed renderer',function(r)
    assert(r.api.createSlotPreviewPed(nil,H.copy(place))==101)
end,function(r) r.appearanceResult=false end)
print('PASS character renderer models: '..count..' differential cases; complete presets, first-payload reference, saved/random appearance, protected failures, model/cache refresh, animation precedence, slot cleanup and retained late-await behavior; no real entities')
