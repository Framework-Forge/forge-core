-- Whole installed Forge client sources vs private descriptors. No real scheduler/network/UI or data writes.
local J=dofile('tests/kernel_job_catalog_harness.lua')
local H,P=J.H,J.P
local C={H=H,P=P,J=J}
function C.new(ported,options)
    local r={trace={},events={},callbacks={},threads={},client={},config=J.config(true).config,
        response={jobs={{name='police',stashes={{password='fixture-secret'}}}},gangs={},payments={enabled=true},revision=3},
        canManage=true}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    r.translate=function(key,params)r.record('translate',key,params);return key end
    r.library={debug={info=function(...)r.record('info',...)end,setEnabled=function(...)r.record('debug-enabled',...)end}}
    r.library.callback={await=function(...)
        r.record('await',...)
        if r.awaitHook then return r.awaitHook(...)end
        if r.awaitError then error('fixture-await',0)end
        return r.response,r.canManage
    end}
    r.client.Menu={openMain=function(...)r.record('open-main',...);if r.openHook then return r.openHook(...)end;return r.openResult end}
    r.client.JobPoints={refresh=function(payload)r.record('points',payload);if r.pointsHook then return r.pointsHook(payload)end end}
    r.client.JobBusiness={refresh=function(payload)r.record('business',payload);if r.businessHook then return r.businessHook(payload)end end}
    r.wait=function(ms)return coroutine.yield(ms)end
    if options then options(r)end
    local env=H.environment()
    if ported then
        r.replica=H.load('kernel/client/job/state.lua',env)({library=r.library,client=r.client,translate=r.translate,config=r.config})
        r.state=r.replica.State;r.events=r.replica.Events
        r.main=H.load('kernel/client/job/main.lua',env)({client=r.client,config=r.config})
        r.bootstrap=H.load('kernel/client/job/bootstrap.lua',env)({client=r.client,library=r.library,translate=r.translate,
            wait=r.wait,debugEnabled=r.debugEnabled})
        r.callbacks,r.threads=r.main.Callbacks,r.bootstrap.Threads
        assert(#r.trace==0,'constructors cannot request, refresh, log, register or start threads')
        r.client.JobState=r.state
    else
        env.ForgeCore={Client=r.client,t=r.translate};env.pr_lib=r.library;env.PR={Job=r.config,Debug=r.debugEnabled}
        env.RegisterNetEvent=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=true}end
        r.library.callback=r.library.callback or {}
        r.library.callback.register=function(name,fn)r.callbacks[name]=fn end
        env.CreateThread=function(fn)r.threads[#r.threads+1]=fn end;env.Wait=r.wait
        for _,name in ipairs({'client/job/state.lua','client/job/main.lua','client/main.lua'})do H.load(name,env)end
        r.state=r.client.JobState
    end
    r.env=env
    function r.dispatch(name,...)
        for _,event in ipairs(r.events)do if event.name==name then event.handler(...)end end
    end
    function r.open()return assert(r.callbacks[r.config.Callbacks.openMenu])()end
    function r.step()
        r.co=r.co or coroutine.create(r.threads[1])
        local out=table.pack(coroutine.resume(r.co));assert(out[1],out[2]);return table.unpack(out,2,out.n)
    end
    return r
end
function C.pair(options)
    local a,b=C.new(false,options),C.new(true,options);local p={a=a,b=b,count=0}
    function p.run(label,fn)
        local function run(r)local out=table.pack(pcall(fn,r));assert(out[1],label..': unexpected test error '..tostring(out[2]));return P.snapshot(out)end
        H.same(run(b),run(a),label..': returns')
        H.same(b.trace,a.trace,label..': requests/refreshes/logs/UI')
        H.same(P.snapshot(b.state),P.snapshot(a.state),label..': replica state')
        p.count=p.count+1
    end
    return p
end
function C.compose(state,ports)
    local env=H.environment()
    env.require=function(name)
        assert(name=='kernel.client.job.state'or name=='kernel.client.job.main'or name=='kernel.client.job.bootstrap')
        return H.load(name:gsub('%.','/')..'.lua',env)
    end
    return H.load('kernel/client/job/job_core.lua',env)(state,ports)
end
-- Exact installed PR callback transport on two simulated endpoints. No Cfx bus or real promises.
function C.wire()
    local r={events={server={},client={}},timers={},pending={},trace={},clock=0}
    local function endpoint(side)
        local e={source=side=='server'and 1 or'fixture-server',side=side}
        local function listen(name,fn)
            local list=r.events[side];list[#list+1]={name=name,handler=fn};return #list
        end
        local env=H.environment({source=e.source,GetCurrentResourceName=function()return'forge-core'end,
            GetGameTimer=function()return r.clock end,RegisterNetEvent=function(name,fn)if fn then return listen(name,fn)end end,
            AddEventHandler=listen,RemoveEventHandler=function(id)r.events[side][id].removed=true end,
            SetTimeout=function(ms,fn)r.timers[#r.timers+1]={ms=ms,fn=fn}end,
            promise={new=function()
                local p={};function p:resolve(value)self.value=value end;function p:reject(reason)self.error=reason end;return p
            end},
            Citizen={Await=function(p)
                while p.value==nil and p.error==nil do coroutine.yield('await-rpc')end
                if p.error then error(p.error,0)end;return p.value
            end}})
        function e.dispatch(name,source,...)
            e.source=source;env.source=source
            local list={};for _,event in ipairs(r.events[side])do list[#list+1]=event end
            for _,event in ipairs(list)do if not event.removed and event.name==name then event.handler(...)end end
        end
        e.api=H.load('../pr_bridge/bridge/callback/transport.lua',env)({server=side=='server',timeout=10000,rejectErrors=false,
            responseEvent='fixture:response',requestEvent=function(name)return'fixture:request:'..name end,
            acceptResponse=function(source,target)return side=='server'and tonumber(source)==tonumber(target)or side=='client'and source=='fixture-server'end,
            parseRequest=function(owner,key,...)return owner,key,table.pack(...)end,
            acceptRequest=function(source,owner,key)return type(key)=='string'and(owner=='fixture-client'or owner=='fixture-server')end,
            send=function(name,target,key,...)
                r.trace[#r.trace+1]={kind='request',side=side,name=name,target=target}
                local peer=side=='server'and r.client or r.server
                local args=H.copy(table.pack(...))
                peer.dispatch('fixture:request:'..name,side=='server'and'fixture-server'or r.playerSource,side=='server'and'fixture-server'or'fixture-client',key,table.unpack(args,1,args.n))
            end,
            reply=function(source,owner,key,...)
                r.trace[#r.trace+1]={kind='reply',side=side,key=key}
                local peer=side=='server'and r.client or r.server
                local args=H.copy(table.pack(...))
                peer.dispatch('fixture:response',side=='server'and'fixture-server'or r.playerSource,key,table.unpack(args,1,args.n))
            end})
        return e
    end
    r.playerSource=1
    r.server=endpoint('server');r.client=endpoint('client')
    return r
end
return C
