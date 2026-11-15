local W=dofile('tests/kernel_weapon_harness.lua')
local total=0
local function scenario(options,fn)local p=W.pair('service',options);fn(p);total=total+p.count;return p end
scenario(nil,function(p)
    p.run('start and normalized save',function(r)return r.api.start()end)
    p.run('idempotent start',function(r)return r.api.start()end)
    p.run('payload',function(r)return r.api.getPayload()end)
    p.run('denied',function(r)return r.api.upsert(1,{name='test'}),r.api.delete(1,'pistol'),r.api.setActive(1,'pistol',false)end)
    p.run('admin upsert',function(r)return r.api.upsert(2,{name='test',label='Test',ammotype='none',weight=5})end)
    p.run('console disable',function(r)return r.api.setActive(0,'test',false)end)
    p.run('enable',function(r)return r.api.setActive(2,'test',true)end)
    p.run('delete',function(r)return r.api.delete(2,'test')end)
    p.run('delete missing',function(r)return r.api.delete(2,'test')end)
    p.run('disable missing',function(r)return r.api.setActive(0,'test',false)end)
    p.run('invalid upsert',function(r)return r.api.upsert(0,false)end)
    p.run('reload',function(r)return r.api.reload()end)
    p.run('local core restart queues projection',function(r)r.dispatch('qbx_core');return #r.timers end)
    p.run('inventory restart queues external sync',function(r)r.dispatch('ox_inventory');r.runTimers()end)
    p.run('unrelated resource',function(r)r.dispatch('other');return #r.timers end)
end)
for _,mode in ipairs({'job-true','job-false-ace','console','admin','group.admin','forge-core.admin','no-job'})do
    scenario(function(r)
        r.manage=mode=='job-true'
        if mode=='admin'or mode=='group.admin'or mode=='forge-core.admin'then r.aces[1]={[mode]=true}end
        if mode=='no-job'then r.services.JobService=nil end
    end,function(p)p.run(mode,function(r)return r.api.canManage(mode=='console'and 0 or mode=='job-false-ace'and 2 or 1)end)end)
end
for _,action in ipairs({'upsert','delete','setActive'})do
    scenario(nil,function(p)
        p.run(action..' prepare',function(r)return r.api.start()end)
        p.run(action..' save fails without swapping live registry',function(r)
            local old=r.memory.files[r.config.Storage.file]
            r.memory.onWrite=function(path,bytes)if path==r.config.Storage.file and bytes~=old then return false end;return true end
            if action=='upsert'then return r.api.upsert(0,{name='other'})
            elseif action=='delete'then return r.api.delete(0,'pistol')
            else return r.api.setActive(0,'pistol',false)end
        end)
    end)
end
scenario(nil,function(p)
    p.run('reload ignores persistence failure retained',function(r)
        r.memory.onWrite=function()return false end
        assert(r.api.reload()==true and r.services.WeaponRegistry.weapons.weapon_pistol)
        return r.api.getPayload()
    end)
end)
for _,failure in ipairs({'project','ox-sync'})do
    scenario(function(r)r.results[failure]=table.pack(false)end,function(p)
        p.run(failure..' false ignored',function(r)return r.api.upsert(0,{name='other'})end)
    end)
    scenario(function(r)r.results[failure]='throw'end,function(p)
        p.run(failure..' throw after save retained',function(r)
            local ok=pcall(r.api.upsert,0,{name='other'})
            assert(not ok and r.services.WeaponRegistry.weapons.weapon_other);return ok
        end)
        p.run(failure..' start marked before failure retained',function(r)
            local ok=pcall(r.api.start);assert(not ok and r.api.started);return ok,r.api.start()
        end)
    end)
end
scenario(nil,function(p)p.run('events before start do nothing',function(r)r.dispatch('qbx_core');r.dispatch('ox_inventory');assert(#r.timers==0)end)end)
-- Explicit wrapper setup cannot run on construction and is one-shot across a yielding PR call.
local r=W.new(true,'service',function(r)r.noInit=true end)
assert(#r.trace==0 and #r.memory.trace==0)
local wrap=r.library.wrapJsonMutations;local calls=0
r.library.wrapJsonMutations=function(...)calls=calls+1;coroutine.yield('wrap');return wrap(...)end
local co=coroutine.create(r.api.Initialize);local ok,value=coroutine.resume(co)
assert(ok and value=='wrap'and not r.api.Initialize()and calls==1)
assert(coroutine.resume(co));assert(not r.api.Initialize())
print('PASS '..total..' weapon service differential cases plus explicit initialization/reentry; complete permissions/save/publish/notify, reload/start and inherited acknowledgement failures')
