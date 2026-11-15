-- Real client49/50 and PR task factory; virtual scheduler/platform/IO only.
local D=dofile('tests/kernel_client_domains_harness.lua')
local H=D.H
local T={D=D,H=H}
T.create=H.load('../pr_bridge/bridge/runtime/owned_tasks.lua',H.environment())
function T.clock()
    local r={now=0,queue={},errors={},waits={}}
    local function put(ms,fn)
        local co=coroutine.create(fn);r.queue[#r.queue+1]={at=r.now+ms,co=co};return'provider',nil,42
    end
    r.native={CreateThread=function(fn)return put(0,fn)end,SetTimeout=function(ms,fn)return put(ms,fn)end,
        Wait=function(ms)r.waits[#r.waits+1]=ms;coroutine.yield(ms);return nil,false,7 end}
    r.native.createThread,r.native.setTimeout,r.native.wait=r.native.CreateThread,r.native.SetTimeout,r.native.Wait
    function r.step(index)
        local task=table.remove(r.queue,index);r.now=task.at
        local ok,delay=coroutine.resume(task.co);assert(ok,tostring(delay))
        if coroutine.status(task.co)~='dead'then task.at=r.now+math.max(1,tonumber(delay)or 0);r.queue[#r.queue+1]=task end
    end
    function r.advance(ms)
        local target=r.now+ms;local steps=0
        while true do
            table.sort(r.queue,function(a,b)return a.at<b.at end)
            local task=r.queue[1];if not task or task.at>target then break end
            steps=steps+1;assert(steps<10000,'virtual scheduler runaway');r.step(1)
        end
        r.now=target
    end
    function r.scope()
        local s=T.create({isCurrent=function()return not r.stale end,running=coroutine.running,
            onError=function(err,id)r.errors[#r.errors+1]={err=err,id=id}end})
        return s,s.WrapNative(r.native)
    end
    return r
end
function T.new()
    local old=D.A.new
    -- Let the established fixture prepare its ports/config, but defer assembly49 until wrapping.
    D.A.new=function(...)local c=old(...);c.mount=function()end;return c end
    local ok,f=pcall(D.new);D.A.new=old;assert(ok,f)
    local r={fixture=f,clock=T.clock(),errors={},ready=true,readyCalls=0,logs={}}
    local function sched(native)
        local n={};for k,v in pairs(native)do n[k]=v end
        for k,v in pairs(r.clock.native)do n[k]=v end
        return n
    end
    f.central.ports.native=sched(f.central.ports.native)
    for _,p in pairs(f.ports.domains)do p.native=sched(p.native)end
    f.ports.domains.Jobs.wait=r.clock.native.Wait
    local env=D.A.E.env();env.print=function(...)r.logs[#r.logs+1]=table.pack(...)end
    env.type=f.modules.Stores.environment().type
    r.ports={central=f.central.ports,domains=f.ports,createTasks=T.create,running=coroutine.running,
        onError=function(err,id)r.errors[#r.errors+1]={err=err,id=id}end,
        isReady=function()r.readyCalls=r.readyCalls+1;if r.readyHook then r.readyHook()end;return r.ready end}
    r.factory=H.load('kernel/client/worker_context.lua',env)
    function r.prepare()r.api=r.factory(f.state,r.ports);r.graph=r.api.Graph;return r.api end
    return r
end
return T
