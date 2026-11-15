local P=dofile('tests/kernel_player_harness.lua')
local H,count=P.H,0
local function runtime(ported)
    local r={events={},trace={},jobs={seed={label='seed'}},gangs={seed={label='seed'}}}
    r.response={jobs={taxi={label='Taxi'}},gangs={none={label='None'}}}
    function r.await(name)
        r.trace[#r.trace+1]=name
        if r.beforeAwait then r.beforeAwait() end
        if r.failure then error('simulated group failure',0) end
        return r.response
    end
    local env=H.environment()
    if ported then
        r.api=H.load('kernel/client/groups.lua',env)({jobs=r.jobs,gangs=r.gangs,awaitGroups=r.await})
        for _,event in ipairs(r.api.Events) do r.events[event.name]=event.handler end
        assert(#r.trace==0 and r.api.GetJobs()==r.jobs and r.api.GetGangs()==r.gangs)
        r.load=function() return r.api.Initialize() end
    else
        r.api={}
        env.require=function(name) if name=='shared.jobs' then return r.jobs elseif name=='shared.gangs' then return r.gangs end;error(name) end
        env.exports=function(name,fn) r.api[name]=fn end
        env.RegisterNetEvent=function(name,fn) r.events[name]=fn end
        env.lib={callback={await=r.await}}
        r.load=function() return P.loadOrigin('client/groups.lua',env) end
    end
    return r
end
local function test(name,action)
    local a,b=runtime(false),runtime(true)
    H.same(P.snapshot(table.pack(action(b))),P.snapshot(table.pack(action(a))),name)
    H.same(b.trace,a.trace,name..': calls');count=count+1
end
test('initial full refs',function(r)
    r.load();assert(r.api.GetJobs()==r.response.jobs and r.api.GetGangs()==r.response.gangs)
    return r.api.GetJobs(),r.api.GetGangs()
end)
for _,method in ipairs({'GetJob','GetGang'}) do
    for _,key in ipairs({'taxi','none','missing'}) do test(method..key,function(r) r.load();return r.api[method](key) end) end
end
for _,kind in ipairs({'Job','Gang'}) do
    for _,action in ipairs({'update','delete'}) do test(kind..action,function(r)
        r.load();local value=action=='update' and {label='New'} or nil
        local key=kind=='Job' and 'taxi' or 'none'
        r.events['qbx_core:client:on'..kind..'Update'](key,value)
        return r.api.GetJobs(),r.api.GetGangs()
    end) end
end
test('seeds exposed before await and replaced',function(r)
    r.beforeAwait=function()
        assert(r.api.GetJobs()==r.jobs and r.api.GetGangs()==r.gangs)
        r.events['qbx_core:client:onJobUpdate']('late',{label='Event'})
    end
    r.load();return r.api.GetJob('late'),r.api.GetJobs()
end)
test('nil reply errors',function(r) r.response=nil;return pcall(r.load) and true or false end)
test('missing fields retained',function(r) r.response={};r.load();return r.api.GetJobs(),r.api.GetGangs() end)
test('callback error',function(r) r.failure=true;return pcall(r.load) and true or false end)
-- Guard only the newly explicit initializer; no new merge, retries or polling.
local r=runtime(true)
r.beforeAwait=function() coroutine.yield('waiting') end
local co=coroutine.create(r.load)
assert(coroutine.resume(co));assert(not r.api.Initialize() and #r.trace==1)
assert(coroutine.resume(co) and coroutine.status(co)=='dead')
assert(not r.api.Initialize() and #r.trace==1)
assert(count==15,'Unexpected group count: '..count)
print('PASS client group registry: '..count..' differential cases plus explicit-init concurrency guard; reference replacement, seeds, events and errors preserved')
