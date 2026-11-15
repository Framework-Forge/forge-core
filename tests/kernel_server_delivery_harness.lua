-- Whole installed PR server caches and real composed server68, virtual ports only.
local M=dofile('tests/kernel_media_harness.lua');local H,P=M.H,M.T.P
local T={M=M,H=H,P=P}
function T.provider()
    local r={trace={},now=1000,state='started',current=true,events={}}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    local function cache(resource)
        local api={};local env=H.environment({GetGameTimer=function()return r.now end,
            GetCurrentResourceName=function()return resource end,IsDuplicityVersion=function()return true end,
            AddEventHandler=function(name,fn)r.events[name]=fn end,
            exports={pr_bridge={accessCacheState=function(self,...)assert(self==r.exportProxy);return r.access(...)end}}})
        r.exportProxy=env.exports.pr_bridge
        local raw=H.load('../pr_bridge/bridge/cache/shared.lua',env)(api,{frameworks='qbx'})
        H.load('../pr_bridge/bridge/cache/state.lua',env)(api,raw)
        H.load('../pr_bridge/bridge/cache/resources.lua',env)(raw)
        H.load('../pr_bridge/bridge/cache/central.lua',env)(raw)
        return raw,api
    end
    r.host,r.hostApi=cache('pr_bridge')
    function r.access(mode,key,value,ttl)
        r.record('access',mode,key,value,ttl)
        if r.accessHook then r.accessHook(mode,key,value,ttl)end
        if r.failAccess then error('virtual cache failure',0)end
        if r.falseAccess then return false,'refused'end
        -- Virtual Cfx serialization boundary, not a proof of native msgpack/reference behavior.
        local result=H.copy(table.pack(r.host.accessStateCache(mode,key,H.copy(value),ttl)))
        return table.unpack(result,1,result.n)
    end
    r.localCache,r.localApi=cache('forge-core')
    function r.emit(...)r.record('event',...);if r.eventHook then return r.eventHook(...)end;return nil,false,17 end
    r.ports={cache=r.localCache,accessCacheState=r.access,emit=r.emit,
        getResourceState=function(name)r.record('resource',name);return r.state end,
        isCurrent=function()return r.current end,running=coroutine.running}
    r.factory=H.load('../pr_bridge/bridge/delivery/forge_cache.lua',H.environment())
    function r.mount()r.api=r.factory(r.ports);return r.api end
    function r.writer(ported)
        if ported then return H.load('kernel/shared/bridge_cache.lua',H.environment())(r.api.Delivery,'qbx_core:server:cacheChanged')end
        return H.load(H.qbx..'modules/bridge-cache.lua',H.environment({GetResourceState=r.ports.getResourceState,
            TriggerEvent=r.emit,exports={pr_bridge={accessCacheState=function(_,...)return r.access(...)end}}}))('qbx_core:server:cacheChanged')
    end
    function r.snapshot()
        local a,b={},{};for k,v in pairs(r.host.state)do a[k]=P.snapshot(v)end
        for k,v in pairs(r.localCache.state)do b[k]=P.snapshot(v)end;return{host=a,private=b}
    end
    return r
end
function T.producer(ported)
    local r=T.provider();r.core={Players={}};r.handlers={}
    for src=2,3 do r.core.Players[src]={PlayerData={source=src,citizenid='S72'..src,metadata={health=200,hunger=100},money={cash=src}}}end
    if ported then
        r.mount();assert(r.api.Open())
        local module=H.load('kernel/server/bridge_cache.lua',H.environment())({core=r.core,writer=r.writer(true),emit=r.api.EmitLocal})
        r.producer=module.Producer;r.core.BridgeCache=r.producer
        for _,entry in ipairs(module.Events)do r.handlers[entry.name]=function(...)return entry.handler(nil,...)end end
    else
        local env=H.environment({QBX=r.core,TriggerEvent=r.emit,AddEventHandler=function(name,fn)r.handlers[name]=fn end})
        env.require=function(name)assert(name=='modules.bridge-cache');return function()return r.writer(false)end end
        H.load(H.qbx..'server/bridge-cache.lua',env);r.producer=r.core.BridgeCache
    end
    function r.fire(name,...)return assert(r.handlers[name])(...)end
    return r
end
function T.context()
    local r=M.context();r.cacheDelivery=T.provider();r.boundLibraries={}
    -- Virtual network-origin test; production still checks GetInvokingResource before accepting status.
    r.fixture.ports.central.session.player.platform.getInvokingResource=function()return nil end
    r.cacheDelivery.eventHook=function(name,...)return r.emit(name,...)end
    local env=M.R.C.V.B.O.P.T.T.W.D.R.env();local req=env.require
    env.print=function(...)r.fixture.central.record('print',...)end
    env.require=function(name)local ctor=req(name)
        if type(ctor)~='function'then return ctor end
        return function(...)
            local args=table.pack(...);local p=args[3]or args[2]or args[1]
            if type(p)=='table'and p.library then r.boundLibraries[name]=p.library end
            if name=='kernel.config.shared'then r.configCounts.shared=r.configCounts.shared+1 end
            if name=='kernel.config.server'then r.configCounts.server=r.configCounts.server+1 end
            return ctor(table.unpack(args,1,args.n))
        end
    end
    r.deliveryPorts={mediaContext=r.mediaPorts,delivery=r.cacheDelivery.ports,createDelivery=r.cacheDelivery.factory}
    r.deliveryFactory=H.load('kernel/server/delivery_context.lua',env)
    function r.prepareDelivery()
        r.api=r.deliveryFactory(r.fixture.base,r.deliveryPorts);r.graph=r.api.Graph
        r.keys.api=r.fixture.base.ServerVehicleContext.Vehicles
        r.configuration.api=r.fixture.base.ServerConfigurationContext.Boundary
        return r.api
    end
    function r.deliveryInstall()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    function r.startDelivery()assert(r.deliveryInstall());r.emit('onResourceStart','forge-core');r.begin();r.resume();assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]))end
    return r
end
return T
