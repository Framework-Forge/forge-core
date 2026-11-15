local R=dofile('tests/kernel_world_harness.lua')
local H,n=R.H,0
local function packet(g,v,revision,key)
    key=key or'density'
    return{generation=g,states={[key]={generation=g,revision=revision or 1,data={value=v}}}}
end
local function case(name,server,fn)
    local a,b=R.world(false,server),R.world(true,server)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' returns')
    H.same(b.trace,a.trace,name..' local events')
    H.same(b.out,a.out,name..' network effects')
    for _,key in ipairs(R.domains)do H.same(b.state.getRecord(key),a.state.getRecord(key),name..' '..key)end
    n=n+1
end
case('publication detached',true,function(r)
    local t={a={b=1}};assert(r.state.publish('density',t));t.a.b=9
    local c=r.state.get('density');c.a.b=4;assert(r.state.get('density').a.b==1)
    assert(not r.state.publish('density',{a={b=1}}));assert(not r.state.getRecord('unknown'))
end)
case('coalesce per tick',true,function(r)
    r.state.publish('density',{x=1});r.state.publish('density',{x=2});r.state.publish('stores',{x=3})
    r.advance(0);assert(#r.out==1 and r.out[1].args[1].states.density.data.x==2)
end)
case('invalid publication domain',true,function(r)assert(not pcall(r.state.publish,'unknown',{}))end)
case('invalid publication data',true,function(r)assert(not pcall(r.state.publish,'density',false))end)
case('full snapshot ready',true,function(r)
    for _,key in ipairs(R.domains)do r.state.publish(key,{value=key})end
    local p=r.callbacks['forge-core:cache:snapshot'](1);assert(p.ready and p.states.characterPreviews)
end)
case('partial snapshot unready',true,function(r)r.state.publish('density',{});assert(not r.callbacks['forge-core:cache:snapshot'](1).ready)end)
case('throttle and drop key',true,function(r)
    local cb=r.callbacks['forge-core:cache:snapshot'];assert(cb(1));assert(not cb(1))
    r.now=r.now+499;assert(not cb(1));r.now=r.now+1;assert(cb(1))
    r.fire('playerDropped',1);assert(cb(1))
end)
case('provider public export',true,function(r)
    r.state.publish('density',{value=5});local v=r.exported.GetCachedState('density');v.data.value=8;assert(r.state.get('density').value==5)
end)
case('pending stop no network',true,function(r)
    r.state.publish('density',{});r.fire('onResourceStop',nil,'other');assert(r.state.get('density'))
    r.fire('onResourceStop',nil,'forge-core');r.advance(0);assert(not r.state.get('density')and #r.out==0)
end)
case('invalid subscription',true,function(r)assert(not pcall(r.state.onChange,'unknown',function()end))end)
case('passive PR getter never pulls',true,function(r)
    r.state.publish('density',{value=5});assert(r.library.cache.GetResourceState('forge-core','density')==nil)
    r.library.cache.SetResourceState('forge-core','density',r.state.get('density'))
    local v=r.library.cache.GetResourceState('forge-core','density')
    assert(v.value==5);v.value=8;assert(r.state.get('density').value==5)
end)
case('spoof rejected authentic accepted',false,function(r)
    r.fire('forge-core:cache:world',4,packet(9,'bad'));assert(not r.state.get('density'))
    r.fire('forge-core:cache:world',65535,packet(9,'good'));assert(r.state.get('density').value=='good')
end)
case('old and equal revisions ignored',false,function(r)
    assert(r.state.apply(packet(9,'new',3)));assert(r.state.apply(packet(9,'old',1)))
    assert(r.state.apply(packet(9,'equal',3)));assert(r.state.get('density').value=='new')
end)
case('older generation rejected',false,function(r)r.state.apply(packet(9,'new'));assert(not r.state.apply(packet(8,'old')))end)
for _,kind in ipairs({'unknown','wrong-generation','bad-revision','bad-data','nan','negative'})do
    case('invalid batch '..kind,false,function(r)
        r.state.apply(packet(5,'old'))
        local p=packet(6,'new');p.states.stores={generation=6,revision=1,data={}}
        if kind=='unknown'then p.states.unknown=p.states.stores
        elseif kind=='wrong-generation'then p.states.stores.generation=5
        elseif kind=='bad-revision'then p.states.stores.revision='1'
        elseif kind=='bad-data'then p.states.stores.data=false
        elseif kind=='nan'then p.generation=0/0
        else p.states.stores.revision=-1 end
        assert(not r.state.apply(p));assert(r.state.get('density').value=='old','validate before resetting old generation')
    end)
end
case('rapid generation listener coalesces reset',false,function(r)
    local seen={};r.state.onChange('density',function(v)seen[#seen+1]=v and v.value or'clear'end)
    r.state.apply(packet(5,'old'));r.advance(0)
    r.state.apply(packet(6,'new'));r.advance(0)
    H.same(seen,{'old','new'})
end)
case('yielding listener serialized',false,function(r)
    local seen={};r.state.onChange('density',function(v)r.native.Wait(10);seen[#seen+1]=v.value end)
    r.state.apply(packet(5,'first'));r.advance(0);r.state.apply(packet(5,'second',2));r.advance(20)
    H.same(seen,{'first','second'})
end)
case('listener error propagated',false,function(r)
    r.state.onChange('density',function()error('fixture-listener',0)end)
    r.state.apply(packet(5,'value'));local ok,err=pcall(r.advance,0);assert(not ok and tostring(err):find('fixture-listener',1,true))
end)
case('refresh requires all ten domains',false,function(r)
    local p=packet(9,'value');p.ready=true
    r.library.callback.await=function()return p end
    assert(not r.state.refresh())
    for _,key in ipairs(R.domains)do p.states[key]={generation=9,revision=2,data={value=key}}end
    assert(r.state.refresh());assert(r.state.get('stores').value=='stores')
end)
case('refresh error returns false',false,function(r)r.library.callback.await=function()error('fixture-rpc',0)end;assert(not r.state.refresh())end)
case('hydrate backoff and stop',false,function(r)
    local count=0;r.library.callback.await=function()count=count+1;return nil end
    assert(#r.initial==1);r.initial[1]=coroutine.create(r.initial[1])
    assert(coroutine.resume(r.initial[1]));assert(coroutine.resume(r.initial[1]));r.advance(0);assert(count==1)
    r.advance(1000);assert(count==2);r.advance(2000);assert(count==3)
    r.fire('pr_bridge:client:OnPlayerLoaded');r.advance(0);assert(count==3,'no duplicate hydration')
    r.fire('onResourceStop',nil,'forge-core');r.advance(4000);assert(count==3)
end)
print('PASS world cache differentials '..n)
