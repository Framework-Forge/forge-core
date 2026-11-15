-- Whole installed PR shared/state/resources/central caches, virtual exports/event bus only.
local C=dofile('tests/kernel_client_configuration_harness.lua');local H,P=C.H,C.P
local T={C=C,H=H,P=P}
function T.provider()
    local r={trace={},now=1000,state='started',current=true,events={}}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    local function cache(resource)
        local api={};local env=H.environment({GetGameTimer=function()return r.now end,
            GetCurrentResourceName=function()return resource end,IsDuplicityVersion=function()return false end,
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
        if ported then return H.load('kernel/shared/bridge_cache.lua',H.environment())(r.api.Delivery,'qbx_core:client:cacheChanged')end
        return H.load(H.qbx..'modules/bridge-cache.lua',H.environment({GetResourceState=r.ports.getResourceState,
            TriggerEvent=r.emit,exports={pr_bridge={accessCacheState=function(_,...)return r.access(...)end}}}))('qbx_core:client:cacheChanged')
    end
    function r.snapshot()
        local a,b={},{};for k,v in pairs(r.host.state)do a[k]=P.snapshot(v)end
        for k,v in pairs(r.localCache.state)do b[k]=P.snapshot(v)end;return{host=a,private=b}
    end
    return r
end
function T.context()
    local r=C.context();r.cacheDelivery=T.provider()
    r.cacheDelivery.eventHook=function(name,...)return r.emit(name,...)end
    local env=C.M.S.W.D.A.E.env();local req=env.require
    env.type=r.fixture.modules.Stores.environment().type;env.print=function()end;r.boundLibraries={}
    env.require=function(name)local ctor=req(name)
        if type(ctor)~='function'then return ctor end
        return function(...)
            local args=table.pack(...);local p=args[2]or args[1]
            if name=='kernel.config.client'then r.configConstructions=r.configConstructions+1 end
            if type(p)=='table'and p.library then r.boundLibraries[name]=p.library end
            return ctor(table.unpack(args,1,args.n))
        end
    end
    r.deliveryPorts={delivery=r.cacheDelivery.ports,createDelivery=r.cacheDelivery.factory,configurationContext=r.configurationPorts}
    r.deliveryFactory=H.load('kernel/client/delivery_context.lua',env)
    function r.prepareDelivery()r.api=r.deliveryFactory(r.fixture.state,r.deliveryPorts);r.graph=r.api.Graph;return r.api end
    function r.installDelivery()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return T
