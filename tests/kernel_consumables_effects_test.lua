local C=dofile('tests/kernel_consumables_harness.lua')
local total=0
local function scenario(options,fn)local p=C.pair('client',options);fn(p);total=total+p.count end
scenario(nil,function(p)
    p.run('nil data',function(r)r.effects(nil)end)
    p.run('statuses direct local',function(r)r.effects({statuses={hunger=5,health=10}})end)
    p.run('fallback after status error',function(r)r.statusError=true;r.effects({statuses={hunger=3}})end)
    p.run('alcohol light',function(r)r.effects({alcohol=1})end)
    p.run('alcohol heavy',function(r)r.effects({alcohol='3'})end)
    p.run('alcohol decay wait',function(r)return r.step(2)end)
    p.run('alcohol decayed',function(r)r.now=900000;return r.step(2)end)
    p.run('heavy threshold after decay',function(r)r.effects({alcohol=0.1})end)
end)
for _,effect in ipairs({'adrenaline','meth','coke','crack','ecstasy','weed','unknown'})do
    scenario(function(r)r.running=true end,function(p)
        p.run(effect..' schedules',function(r)r.effects({effect=effect,effectDuration=1000,effectStrength=2})end)
        p.run(effect..' starts',function(r)return r.step(1,true)end)
        p.run(effect..' tick',function(r)r.now=1000;if coroutine.status(r.cos.w1)=='suspended'then return r.step(1,true)end end)
    end)
end
scenario(nil,function(p)
    p.run('oxy no worker/evidence',function(r)r.effects({effect='oxy'});assert(#r.workers==0)end)
    p.run('first worker',function(r)r.effects({effect='meth',effectDuration=2000});return r.step(1,true)end)
    p.run('replacement token',function(r)r.effects({effect='weed',effectDuration=1000});return r.step(2,true)end)
    p.run('old token stops without cleanup of replacement',function(r)return r.step(1,true)end)
    p.run('replacement cleanup',function(r)r.now=1000;return r.step(2,true)end)
    p.run('idle alcohol',function(r)return r.step(2)end)
end)
for _,case in ipairs({'lower-bound','upper-bound','string-case','stop-no-cleanup'})do
    scenario(nil,function(p)
        p.run(case,function(r)
            r.effects({effect=case=='string-case'and'METH'or'adrenaline',effectDuration=case=='upper-bound'and 999999 or -1,effectStrength=-1})
            local delay=r.step(1,true);r.dispatch('onResourceStop',0,'forge-core');return delay
        end)
    end)
end
print('PASS '..total..' interaction-effect differential cases; local status/fallback, alcohol threshold/decay, every special effect, timers/token/clamps and retained cleanup limitations')
