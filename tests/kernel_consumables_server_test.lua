local C=dofile('tests/kernel_consumables_harness.lua')
local total=0
local function scenario(options,fn)local p=C.pair('server',options);fn(p);total=total+p.count;return p end
local p=scenario(nil,function(p)
    p.run('deferred bootstrap',function(r)r.runTimers();return #r.registered end)
    p.run('successful consumption always vetoes vanilla',function(r)return r.use(1)end)
    p.run('repeat refresh idempotent',function(r)r.api.refreshAll();r.api.refreshItem('BURGER');r.api.refreshItem('')end)
    p.run('missing item',function(r)r.api.refreshItem('missing');r.items.burger=nil;return r.use(1)end)
end)
for _,case in ipairs({'disabled','no-interaction','interaction-disabled','busy','bad-source','bad-item','nil','cancel','table-false','stopped','started','exception','remove-false','remove-nil','remove-error','remove-zero','remove-negative','fraction','duration-default','persistent','duration-floor','range-swap','effect-filter','clamps'})do
    scenario(function(r)
        local interaction=r.items.burger.interaction
        if case=='disabled'then r.items.burger.active=false
        elseif case=='no-interaction'then r.items.burger.interaction=nil
        elseif case=='interaction-disabled'then interaction.enabled=false
        elseif case=='nil'then r.response=nil
        elseif case=='cancel'then r.response=false
        elseif case=='table-false'then r.response={completed=false}
        elseif case=='stopped'then r.response={completed=true,action='stopped'}
        elseif case=='started'then r.response={completed=true,action='started'}
        elseif case=='exception'then r.awaitError=true
        elseif case=='remove-false'then r.removed=false
        elseif case=='remove-nil'then r.removed=nil
        elseif case=='remove-error'then r.removeError=true
        elseif case=='remove-zero'then interaction.remove=0
        elseif case=='remove-negative'then interaction.remove=-5
        elseif case=='fraction'then interaction.remove=2.9
        elseif case=='duration-default'then interaction.duration=nil
        elseif case=='persistent'then interaction.duration=0
        elseif case=='duration-floor'then interaction.duration=2500.9
        elseif case=='range-swap'then interaction.effects={health={min=10.9,max=-5.1},hunger={8.9,3.1},oxygen={min='2'}};r.randomMax=true
        elseif case=='effect-filter'then interaction.effect='unknown'
        elseif case=='clamps'then interaction.effect='meth';interaction.effectDuration=999999;interaction.effectStrength=999;interaction.alcohol='5'
        end
    end,function(p)
        p.run(case..' bootstrap',function(r)r.runTimers()
            -- Missing interaction prevents registration, so put it back just for the callback capture, then restore.
            if #r.registered==0 then r.items.burger.interaction={enabled=true};r.api.refreshItem('burger');r.items.burger.interaction=nil end
        end)
        p.run(case,function(r)
            if case=='busy'then r.api.busy[1]=true end
            local cb=r.registered[1].cb
            if case=='bad-item'then return cb(1,false)end
            return cb(case=='bad-source'and'bad'or 1,{name='burger',slot=7})
        end)
    end)
end
scenario(nil,function(p)
    for _,key in ipairs({'SetHunger','AddHunger','SetThirst','AddThirst','setHunger','addHunger','setThirst','addThirst'})do
        p.run(key,function(r)return r.exports[key]('1',150),r.exports[key]('bad',2),r.exports[key](1,-8)end)
    end
    for _,invoker in ipairs({'network','ox_inventory','other'})do
        for _,name in ipairs({'setHunger','addHunger','setThirst','addThirst'})do
            p.run(invoker..':'..name,function(r)r.invoker=invoker~='network'and invoker or nil;r.dispatch('consumables:server:'..name,1,120)end)
        end
    end
    p.run('drop',function(r)r.api.busy[1]=true;r.dispatch('playerDropped',1)end)
    p.run('reload only queues refresh',function(r)r.dispatch('forge-core:server:inventory:reloaded',0);r.runTimers()end)
end)
scenario(function(r)r.registerResult=false;r.items.lockpick={name='lockpick',active=false,interaction={enabled=false}};r.items.advancedlockpick={name='advancedlockpick'}end,function(p)
    p.run('failed registration plus specials',function(r)r.runTimers();return #r.registered end)
    p.run('retry refresh',function(r)r.registerResult=true;r.api.refreshItem('burger')end)
    p.run('disabled special bypass retained',function(r)assert(r.registered[3].name=='lockpick');return r.registered[3].cb(1)end)
    p.run('advanced special',function(r)assert(r.registered[4].name=='advancedlockpick');return r.registered[4].cb(1)end)
end)
-- Block during the await does NOT cancel the captured interaction in the installed implementation.
scenario(nil,function(p)
    p.run('block during await retained',function(r)
        r.runTimers();r.awaitHook=function()r.items.burger.active=false;return true end
        r.use(1);local removed,effect=false,false
        for _,entry in ipairs(r.trace)do removed=removed or entry.kind=='remove';effect=effect or entry.kind=='client'and entry.args[1]=='forge-core:client:inventory:applyInteractionEffects'end
        assert(removed and effect and r.items.burger.active==false)
    end)
end)
scenario(nil,function(p)
    p.run('old completion after drop clears replacement busy retained',function(r)
        r.runTimers();r.awaitHook=function()return coroutine.yield('await')end
        local old,delay=r.resume(function()return r.use(1)end);assert(delay=='await'and r.api.busy[1])
        r.dispatch('playerDropped',1)
        local fresh=r.resume(function()return r.use(1)end);assert(r.api.busy[1])
        assert(coroutine.resume(old,true));assert(r.api.busy[1]==nil,'old completion wrongly clears new busy, baseline retained')
        assert(coroutine.resume(fresh,false))
    end)
end)
print('PASS '..total..' server consumption differential cases; initialization/registration, removal/effects/cancel, aliases and exact inherited block/source-reuse races')
