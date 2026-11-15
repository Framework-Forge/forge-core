-- Installed client50/server48 factories, World35/cache and PR RPC; only native/IO/time/network are virtual.
local D=dofile('tests/kernel_client_domains_harness.lua')
local T={D=D,H=D.H}
function T.unit()
    local r={registered={},calls={},attempts=0}
    r.spec={owner={},entries={
        {owner='First',key='one',handler=function(...)r.calls[#r.calls+1]=table.pack(...);return nil,7,nil end},
        {owner='Second',key='two',handler=function(...)r.calls[#r.calls+1]=table.pack(...)end}},
        isCurrent=function()if r.yieldGuard then coroutine.yield('guard')end;return not r.replaced end,
        subscribe=function(key,fn)
            r.attempts=r.attempts+1;r.registered[#r.registered+1]={key=key,handler=fn}
            if r.onSubscribe then r.onSubscribe(key,fn)end
            if r.failAt==r.attempts then error('subscription failure',0)end
        end}
    r.factory=D.H.load('kernel/shared/subscription_registration.lua',D.H.environment())
    function r.prepare()r.api=r.factory(r.spec);return r.api end
    function r.emit(key,...)
        local out
        for _,d in ipairs(r.registered)do if d.key==key then out=table.pack(d.handler(...))end end
        return out
    end
    return r
end
function T.new()
    local r={fixture=D.new(),logs={}};local f=r.fixture
    local graphEnv=D.A.E.env()
    graphEnv.print=function(...)r.logs[#r.logs+1]=table.pack(...)end
    graphEnv.type=f.modules.Stores.environment().type -- Same Cfx-aware vector3 double as installed Stores parity tests.
    -- The installed Stores body logs after a nonempty first payload. Bind that actual diagnostic port explicitly.
    f.factory=D.H.load('kernel/client/domain_assembly.lua',graphEnv)
    r.graph=f.mount();r.world=r.graph.Parts.World.WorldState;r.clock=f.fixtures.World
    r.factory=D.H.load('kernel/client/subscription_registration.lua',D.A.E.env())
    function r.prepare()r.api=r.factory(r.graph);return r.api end
    function r.apply(key,value,generation,revision)
        assert(r.world.apply({generation=generation or 1,states={[key]={generation=generation or 1,revision=revision or 1,data=value}},ready=false}))
    end
    function r.drain(ms)r.clock.advance(ms or 0)end
    function r.connect()
        r.server=f.connect();r.serverWorld=r.server.Parts.World
        -- Only explicit virtual initialization; the production registry never calls these.
        r.serverWorld.World.Initialize();r.graph.Parts.World.World.Initialize()
        return r.server
    end
    return r
end
return T
