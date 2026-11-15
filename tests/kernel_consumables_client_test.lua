local C=dofile('tests/kernel_consumables_harness.lua')
local total=0
local function scenario(options,fn)local p=C.pair('client',options);fn(p);total=total+p.count;return p end
scenario(nil,function(p)
    p.run('invalid interaction',function(r)return r.interact(false),r.interact({enabled=false})end)
    for _,category in ipairs({'food','drink','alcohol','narco','unknown'})do
        p.run(category..' defaults',function(r)return r.interact({enabled=true,category=category})end)
    end
    p.run('configured animation/props',function(r)return r.interact({enabled=true,duration='1500',label='Usando item',canCancel=false,
        animation={dict='dict',anim='clip',mode='full',props={{model='test',bone='12',pos={1,2,3},rotationOrder='1'}}}})end)
    p.run('cancel notification',function(r)r.progress=false;return r.interact({enabled=true,duration=50})end)
    p.run('truthy progress is not true return',function(r)r.progress=1;return r.interact({enabled=true,duration=50})end)
end)
scenario(nil,function(p)
    local data={enabled=true,duration=0,animation={props={{model='prop',bone='5',pos={1,2,3},rot={4,5,6},rotOrder=1},{model=''}}}}
    p.run('persistent start',function(r)return r.interact(data,'BURGER')end)
    p.run('reapply loop waits',function(r)return r.step(1)end)
    p.run('reapply when interrupted',function(r)r.playing=false;return r.step(1)end)
    p.run('same item toggles off',function(r)return r.interact(data,'burger')end)
    p.run('idle loop',function(r)return r.step(1)end)
    p.run('restart',function(r)return r.interact(data)end)
    p.run('cancel key',function(r)r.keybinds[1].onPressed()end)
    p.run('start cannot cancel',function(r)local d=C.H.copy(data);d.canCancel=false;return r.interact(d)end)
    p.run('ignored cancel',function(r)r.keybinds[1].onPressed()end)
    p.run('timed use cleans props',function(r)return r.interact({enabled=true,duration=50})end)
    p.run('resource stop cleanup',function(r)r.interact(data);r.dispatch('onResourceStop',0,'other');r.dispatch('onResourceStop',0,'forge-core')end)
end)
for _,case in ipairs({'dead','zero-ped','animation-false','animation-truthy','model-false','object-false','different-item','ped-change','ped-dead','no-entity','minimum-interval'})do
    scenario(function(r)
        if case=='dead'then r.dead=true elseif case=='zero-ped'then r.ped=0
        elseif case=='animation-false'then r.anim=false elseif case=='animation-truthy'then r.anim=1
        elseif case=='model-false'then r.modelLoaded=false elseif case=='object-false'then r.objectFail=true
        elseif case=='minimum-interval'then r.config.PersistentInteraction.reapplyInterval=1 end
    end,function(p)
        p.run(case..' start',function(r)return r.interact({enabled=true,duration=-1})end)
        p.run(case..' transition',function(r)
            if case=='different-item'then return r.interact({enabled=true,duration=0,category='narco'},'other')end
            local delay=r.step(1)
            if case=='ped-change'then r.ped=20;r.entities[20]=true
            elseif case=='ped-dead'then r.dead=true
            elseif case=='no-entity'then r.entities[10]=nil end
            return delay,r.step(1)
        end)
    end)
end
scenario(nil,function(p)
    p.run('pending prop load resumes after stop retained',function(r)
        r.modelHook=function()coroutine.yield('model');return true,25 end
        local co,delay=r.resume(function()return r.interact({enabled=true,duration=0})end);assert(delay=='model')
        r.dispatch('onResourceStop',0,'forge-core')
        assert(coroutine.resume(co));assert(r.entities[101],'baseline creates late prop after stop')
    end)
end)
print('PASS '..total..' client interaction differential cases; complete defaults/progress/persistent props/rotation/reapply/keybind/cleanup and retained post-stop resume')
