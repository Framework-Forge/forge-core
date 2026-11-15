local C=dofile('tests/kernel_client_jobs_harness.lua')
local total=0
local function scenario(options,fn)local p=C.pair(options);fn(p);total=total+p.count;return p end
scenario(nil,function(p)
    p.run('initial replica',function(r)return r.state.getGroups('job'),r.state.getGroups('gang'),r.state.getGroups('other')end)
    for _,payload in ipairs({false,1,'bad'})do p.run('invalid payload',function(r)return r.state.set(payload,true)end)end
    p.run('default set',function(r)return r.state.set({})end)
    p.run('full payload',function(r)return r.state.set(r.response,true)end)
    p.run('references shared with input',function(r)
        local payload={jobs={{name='shared'}},gangs={},payments={amount=100},revision='9'}
        assert(r.state.set(payload,true));assert(r.state.jobs==payload.jobs and r.state.payments==payload.payments)
        payload.jobs[1].label='live reference';return r.state
    end)
    p.run('missing payments/revision/admin retained',function(r)
        local payments=r.state.payments;r.state.set({jobs=false,gangs=1})
        assert(r.state.payments==payments and r.state.revision==9 and r.state.canManage);return r.state
    end)
    for _,flag in ipairs({true,false,1,'true',0,{}})do p.run('permission boolean',function(r)return r.state.set({},flag),r.state.canManage end)end
    p.run('getGroups exact gang only',function(r)r.state.set(r.response);return r.state.getGroups('GANG'),r.state.getGroups('gang'),r.state.getGroups(nil)end)
    p.run('network sync preserves flag',function(r)
        r.state.set(r.response,true);r.dispatch(r.config.Events.sync,{jobs={},revision=1,canManage=false})
        assert(r.state.canManage and r.state.revision==1,'installed sync retains privilege flag and accepts older revision')
    end)
    p.run('unload and stop do not clear admin replica',function(r)
        r.dispatch('QBCore:Client:OnPlayerUnload');r.dispatch('onResourceStop','forge-core');assert(r.state.canManage)
    end)
end)
for _,case in ipairs({'points-absent','business-absent','debug-absent','info-absent','refresh-false','points-error','business-error','debug-error','callable-debug'})do
    scenario(function(r)
        if case=='points-absent'then r.client.JobPoints=nil
        elseif case=='business-absent'then r.client.JobBusiness=nil
        elseif case=='debug-absent'then r.library.debug=nil
        elseif case=='info-absent'then r.library.debug={}
        elseif case=='refresh-false'then r.pointsHook=function()return false end;r.businessHook=function()return false end
        elseif case=='points-error'then r.pointsHook=function()error('points-error',0)end
        elseif case=='business-error'then r.businessHook=function()error('business-error',0)end
        elseif case=='debug-error'then r.library.debug.info=function()error('debug-error',0)end
        elseif case=='callable-debug'then r.library.debug=function()end end
    end,function(p)
        p.run(case,function(r)
            local ok,result=pcall(r.state.set,r.response,true)
            if case:find('error')or case=='callable-debug'then assert(not ok and r.state.revision==3)
            else assert(ok and result)end
            return ok
        end)
    end)
end
scenario(nil,function(p)
    p.run('refresh receives replica references',function(r)
        r.pointsHook=function(payload)
            assert(payload.jobs==r.state.jobs and payload.gangs==r.state.gangs);payload.jobs[1].touched=true
        end
        r.businessHook=function(payload)assert(payload.jobs[1].touched)end
        assert(r.state.set(r.response))
    end)
    p.run('nested refresh retained',function(r)
        local entered=false
        r.pointsHook=function()if not entered then entered=true;r.state.set({jobs={{name='nested'}},revision=4})end end
        r.businessHook=nil;r.state.set({jobs={{name='outer'}},revision=5})
        assert(r.state.revision==4 and r.state.jobs[1].name=='nested')
    end)
end)
scenario(nil,function(p)
    p.run('request returns state and admin',function(r)local state=r.state.request();assert(state==r.state and state.canManage);return state end)
    p.run('failed request retains current replica',function(r)r.response=false;r.canManage=false;local state=r.state.request();assert(state.canManage);return state end)
    p.run('callback missing no request',function(r)r.library.callback.await=nil;return r.state.request()end)
    p.run('library callback missing',function(r)r.library.callback=nil;return r.state.request()end)
end)
scenario(nil,function(p)
    p.run('late request overwrites newer sync retained',function(r)
        r.awaitHook=function()return coroutine.yield('pending')end
        local co=coroutine.create(r.state.request);local ok,delay=coroutine.resume(co);assert(ok and delay=='pending')
        r.dispatch(r.config.Events.sync,{jobs={{name='newer'}},revision=20})
        assert(coroutine.resume(co,{jobs={{name='old'}},revision=2},true))
        assert(r.state.revision==2 and r.state.jobs[1].name=='old'and r.state.canManage)
    end)
    p.run('transport exception propagates',function(r)r.awaitHook=nil;r.awaitError=true;local ok=pcall(r.state.request);assert(not ok);return ok end)
end)
print('PASS '..total..' client job replica differential cases; complete set/request/groups/sync/reference semantics, refresh order/failures and retained late revision/admin/session behavior')
