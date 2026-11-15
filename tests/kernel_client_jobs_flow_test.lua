local C=dofile('tests/kernel_client_jobs_harness.lua')
local total=0
local function scenario(options,fn)local p=C.pair(options);fn(p);total=total+p.count end
scenario(nil,function(p)
    p.run('open main callback',function(r)return r.open()end)
    p.run('open result false ignored retained',function(r)r.openResult=false;assert(r.open()==true)end)
    p.run('late controller absent',function(r)r.client.Menu=nil;return r.open()end)
    p.run('late controller attached',function(r)r.client.Menu={openMain=function()r.record('new-main')end};return r.open()end)
    p.run('bad controller raises',function(r)r.client.Menu={};local ok=pcall(r.open);assert(not ok);return ok end)
end)
for _,value in ipairs({true,false,1,'true'})do
    scenario(function(r)r.debugEnabled=value end,function(p)
        p.run('bootstrap waits 1500 first',function(r)assert(r.step()==1500 and #r.trace==0)end)
        p.run('bootstrap publishes after wait',function(r)r.step();assert(r.state.revision==3);return coroutine.status(r.co)end)
    end)
end
for _,case in ipairs({'no-debug','no-setEnabled','no-info','no-state','no-callback','setEnabled-error','await-error','function-debug'})do
    scenario(function(r)
        if case=='no-debug'then r.library.debug=nil
        elseif case=='no-setEnabled'then r.library.debug.setEnabled=nil
        elseif case=='no-info'then r.library.debug.info=nil
        elseif case=='no-callback'then r.library.callback.await=nil
        elseif case=='setEnabled-error'then r.library.debug.setEnabled=function()error('debug-enable-error',0)end
        elseif case=='await-error'then r.awaitError=true
        elseif case=='function-debug'then r.library.debug=function()end end
    end,function(p)
        p.run(case..' delay',function(r)return r.step()end)
        p.run(case..' resume',function(r)
            if case=='no-state'then r.client.JobState=nil end
            local ok=pcall(r.step)
            if case=='setEnabled-error'or case=='await-error'or case=='function-debug'then assert(not ok)else assert(ok)end
            return ok
        end)
    end)
end
scenario(nil,function(p)
    p.run('bootstrap does not own unload',function(r)return r.step()end)
    p.run('unload before delay completion does not cancel request',function(r)
        r.dispatch('QBCore:Client:OnPlayerUnload');r.step();assert(r.state.canManage and r.state.revision==3)
    end)
end)
print('PASS '..total..' client job flow differential cases; open-menu descriptor, complete 1500ms bootstrap/debug/request/log order and inherited error/unload behavior')
