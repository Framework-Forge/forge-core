-- Actual server48/PR57; only platform, database, IO and readiness are virtual.
local D=dofile('tests/kernel_domains_harness.lua')
local W=dofile('tests/kernel_worker_harness.lua')
local T={D=D,H=D.H,W=W}
function T.new()
    local r={fixture=D.new(),clock=W.clock(),errors={},listeners={},ready=true};local f=r.fixture
    local function scheduled(n)
        local out={};for k,v in pairs(n)do out[k]=v end
        for k,v in pairs(r.clock.native)do out[k]=v end
        if n.listen then out.listen=function(name,fn)
            r.listeners[#r.listeners+1]={name=name,handler=fn};return #r.listeners
        end end
        out.spawn=r.clock.native.CreateThread;return out
    end
    for _,p in pairs(f.ports.central)do if p.native then p.native=scheduled(p.native)end end
    f.ports.central.session.player.platform=scheduled(f.ports.central.session.player.platform)
    f.ports.helpers.native=scheduled(f.ports.helpers.native)
    for _,p in pairs(f.ports.domains)do p.native=scheduled(p.native)end
    -- Explicit virtual information_schema result for the unmodified Storage boundary.
    local single=f.central.db.single.await
    f.central.db.single.await=function(sql,params)
        if sql:find('information_schema.TABLES',1,true)then return {['COUNT(*)']=1}end
        return single(sql,params)
    end
    r.ports={graph=f.ports,createTasks=W.create,running=coroutine.running,
        bootstrap={native=scheduled(f.central.native),library=f.central.library},
        onError=function(err,id)r.errors[#r.errors+1]={err=err,id=id}end,
        isReady=function()if r.readyHook then r.readyHook()end;return r.ready end}
    local environment=D.R.env();environment.print=function(...)f.central.record('print',...)end
    r.factory=T.H.load('kernel/server/worker_context.lua',environment)
    function r.prepare()r.api=r.factory(f.base,r.ports);r.graph=r.api.Graph;return r.api end
    function r.begin()
        r.co=coroutine.create(function()r.outcome=table.pack(pcall(r.api.Start))end)
        local ok,err=coroutine.resume(r.co);assert(ok,err);return r.co
    end
    function r.resume()local ok,err=coroutine.resume(r.co);assert(ok,err);return r.outcome end
    return r
end
return T
