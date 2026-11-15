-- Installed PR adapters/engine/namespace registry; virtual network/time/natives/providers only.
local T=dofile('tests/kernel_client_domains_harness.lua')
local R={T=T,H=T.H,P=T.P,env=T.A.E.env}
function R.wire()
    local r={events={server={},client={}},trace={},timers={},clock=0,playerSource=2}
    local H=R.H
    local function endpoint(side)
        local e={side=side,owners={},api={},claims={}}
        local function listen(name,fn)
            local list=r.events[side];local record={name=name,handler=fn};list[#list+1]=record;return record
        end
        local env=H.environment({coroutine=coroutine,source=side=='server'and 0 or'net:server',
            GetCurrentResourceName=function()return'forge-core'end,GetInvokingResource=function()return e.caller end,
            GetGameTimer=function()return r.clock end,GetConvarInt=function(_,default)return default end,
            DoesPlayerExist=function(source)return type(source)=='number'and source>0 end,
            RegisterNetEvent=function(name,fn)if fn then return listen(name,fn)end end,AddEventHandler=listen,
            RemoveEventHandler=function(token)
                if e.failRemove==token then error('virtual removal failure',0)end
                if e.removing then e.removing(token)end
                token.removed=true
            end,
            SetTimeout=function(ms,fn)r.timers[#r.timers+1]={ms=ms,fn=fn}end,
            print=function(...)r.trace[#r.trace+1]={'print',...}end,
            promise={new=function()
                local p={};function p:resolve(v)self.value=v end;function p:reject(v)self.error=v end;return p
            end},Citizen={Await=function(p)
                while p.value==nil and p.error==nil do coroutine.yield('await-rpc')end
                if p.error then error(p.error,0)end;return p.value
            end}})
        function e.dispatch(name,source,...)
            local old=env.source;env.source=source
            local list={};for _,record in ipairs(r.events[side])do list[#list+1]=record end
            local args=table.pack(...)
            local ok,problem=pcall(function()
                for _,record in ipairs(list)do if not record.removed and record.name==name then record.handler(table.unpack(args,1,args.n))end end
            end)
            env.source=old;if not ok then error(problem,0)end
        end
        local function send(name,target,...)
            r.trace[#r.trace+1]={side=side,name=name,target=target,args=H.copy(table.pack(...))}
            if e.hold then return end
            local peer=side=='server'and r.client or r.server
            peer.dispatch(name,side=='server'and'net:server'or r.playerSource,...)
        end
        env.TriggerClientEvent=function(name,target,...)send(name,target,...)end
        env.TriggerServerEvent=function(name,...)send(name,nil,...)end
        local rawFactory=H.load('../pr_bridge/bridge/callback/transport.lua',env)
        local function create(options)
            local before=#r.events[side]
            local engine=rawFactory(options)
            local register=engine.register
            engine.register=function(name,fn)
                e.binds=(e.binds or 0)+1
                if e.failBind==e.binds then error('virtual bind failure',0)end
                return register(name,fn)
            end
            e.baseListeners=(e.baseListeners or 0)+#r.events[side]-before
            return engine
        end
        local ownedFactory=H.load('../pr_bridge/bridge/callback/owned_registration.lua',env)
        for _,protocol in ipairs({'native','ox'})do e.owners[protocol]=ownedFactory({side=side,protocol=protocol,createTransport=create})end
        function e.Initialize()
            e.registry=H.load('../pr_bridge/bridge/callback/registry.lua',env)
            local ownership={available=function(name,wire)
                if e.registry.exists(name)then return false end
                for _,record in ipairs(r.events[side])do if not record.removed and record.name==wire then return false end end
                return true
            end,releaseClaim=function(name)
                assert(not e.registry.exists(name)or e.registry.valid(name),'foreign callback claim')
                if e.registry.valid(name)then e.registry.set(name,false)end;return true
            end}
            env.PRCore={load=function(path)
                assert(path=='@pr_bridge/bridge/callback/transport','only installed transport is injected')
                return function(options)
                    local protocol=options.claim and'ox'or'native'
                    return e.owners[protocol].Open(options,ownership)
                end
            end}
            e.api.native=H.load('../pr_bridge/bridge/callback/native.lua',env)(side=='server')
            env.lib={context=side,setValidCallback=e.registry.set};env.cache={resource='forge-core'}
            e.api.ox=H.load('../pr_bridge/bridge/compat/ox_lib/ox_callback.lua',env)
        end
        e.env=env;e.listen=listen
        function e.active()local n=0;for _,record in ipairs(r.events[side])do if not record.removed then n=n+1 end end;return n end
        function e.find(name)for _,record in ipairs(r.events[side])do if not record.removed and record.name==name then return record end end end
        return e
    end
    r.server=endpoint('server');r.client=endpoint('client')
    function r.Initialize()r.server.Initialize();r.client.Initialize()end
    function r.expire()local timers=r.timers;r.timers={};for _,timer in ipairs(timers)do timer.fn()end end
    return r
end
function R.new()
    local r=T.new();r.transport=R.wire();local w=r.transport
    -- Dedicated capture delivered BEFORE the actual Security48 constructor, not patched afterward.
    r.server.central.library.callback.register=w.server.owners.native.CaptureRegister
    w.server.owners.securityLibrary=r.server.central.library
    r.clientGraph=r.mount();r.serverGraph=r.server.mount()
    r.serverFactory=R.H.load('kernel/server/callback_registration.lua',R.env())
    r.clientFactory=R.H.load('kernel/client/callback_registration.lua',R.env())
    function r.prepare()
        r.serverRegistration=r.serverFactory(r.serverGraph,w.server.owners)
        r.clientRegistration=r.clientFactory(r.clientGraph,w.client.owners)
        return r.serverRegistration,r.clientRegistration
    end
    function r.install()
        w.Initialize();assert(r.serverRegistration.Install());assert(r.clientRegistration.Install())
    end
    function r.rpc(group,key,...)
        local cfg=r.config[group];return w.client.api.native.await((cfg.Callbacks or cfg.callbacks)[key],10000,...)
    end
    return r
end
return R
