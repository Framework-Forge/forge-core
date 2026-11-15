local C=dofile('tests/kernel_central_pr_entry_harness.lua');local I=dofile('tests/kernel_native_io_harness.lua')
local L=dofile('tests/kernel_native_library_harness.lua');local H=C.H
local T={C=C,I=I,L=L,H=H}
T.registry=H.load('kernel/entry/native_factory_registry.lua',H.environment())
T.seed=H.load('kernel/entry/native_seed.lua',H.environment())
function T.io(side)
    local r=I.new(side);local prior=r.native.LoadResourceFile
    r.native.LoadResourceFile=function(resource,path)
        if resource=='forge-core'and path:match('^kernel/')then
            local f=io.open(path,'rb');if f then local s=f:read('*a');f:close();return s end
        end
        return prior(resource,path)
    end
    return r
end
function T.registryFixture()
    local r=T.io();r.allocate();local p={readFile=r.api.Files.LoadResourceFile,compile=load,environment=H.environment(),isCurrent=function()return r.current end,
        inventoryBridgeProbe=function()return{}end};r.registryPorts=p;r.registry=T.registry(p);return r
end
function T.unit(side)
    local r=L.new(side);local ioFixture=T.io(r.side);r.ioFixture=ioFixture
    assert(r.wire.scopes[r.side].Close());r.wire.prs[r.side]=ioFixture.core;r.wire.ports[r.side].prCore=ioFixture.core
    r.wire.scopes[r.side]=H.load('kernel/pr_integration/callback_owner.lua',H.environment())(r.wire.ports[r.side]);assert(r.wire.scopes[r.side].Open())
    local clock=dofile('tests/kernel_worker_harness.lua').clock();r.clock=clock
    local n={};for k,v in pairs(ioFixture.native)do n[k]=v end;for k,v in pairs(clock.native)do n[k]=v end
    n.GetGameTimer=function()return clock.now end;n.GetConvar=function(_,fallback)return fallback end;n.GetConvarInt=function(_,fallback)return fallback end
    r.seedPorts={prCore=ioFixture.core,rpc=r.wire.scopes[r.side],native=n,json=ioFixture.codec,public=r.public,environment=r.ports.environment,
        nativeCache=r.nativeCache,events={},running=coroutine.running,getSource=function()return 0 end,isCurrent=function()return r.current end,
        compile=load,inventoryBridgeProbe=function()return{}end,createRegistry=T.registry,
        loadPR=function(path,target)if r.seedLoadHook then r.seedLoadHook(path)end;return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or r.ports.environment)end}
    function r.allocateSeed()r.seed=T.seed(r.seedPorts);return r.seed end
    function r.finishSeed()if r.seed then r.seed.Close()end;r.finish()end
    return r
end
function T.server()
    local ioFixture=T.io('server');local original=C.S.new
    -- Construct122 against the actual PRCore127 BEFORE services123 allocate;never adopt an open engine.
    C.S.new=function(...)
        local s=original(...);assert(s.wire.scopes.server.Close())
        s.wire.prs.server=ioFixture.core;s.wire.ports.server.prCore=ioFixture.core
        s.wire.scopes.server=H.load('kernel/pr_integration/callback_owner.lua',H.environment())(s.wire.ports.server)
        s.ports.prCore=ioFixture.core;s.ports.rpc=s.wire.scopes.server;return s
    end
    local ok,r=pcall(C.new);C.S.new=original;assert(ok,r);r.ioFixture=ioFixture
    local context=r.bootstrapPorts.context
    local runtime=context.deliveryContext.mediaContext.supportContext.configurationContext.vehicleContext.bankingContext.operationsContext.inventoryContext.startup.lifecycle.worker.graph.central.runtime
    local n={};for k,v in pairs(ioFixture.native)do n[k]=v end;for k,v in pairs(r.clock.native)do n[k]=v end
    local get,getInt=runtime.native.GetConvar,runtime.native.GetConvarInt
    n.GetConvar=function(key,...)if key=='inventory:framework'then return'forge'end;return get(key,...)end
    n.GetConvarInt=getInt;n.GetGameTimer=function()return r.clock.now end
    local env=r.T.S.M.R.C.V.B.O.P.T.T.W.D.R.env();env.print=function()end;env.debug=debug;env.os=os
    local nativeTable={};for k,v in pairs(table)do nativeTable[k]=v end
    nativeTable.clone=function(value)local out={};for k,v in pairs(value)do out[k]=v end;return out end
    env.table=nativeTable;env.GetGameTimer=n.GetGameTimer;env.GetConvar=n.GetConvar
    env.GetCurrentResourceName=n.GetCurrentResourceName;env.IsDuplicityVersion=n.IsDuplicityVersion
    r.cacheHost=L.C.provider();env.exports={pr_bridge={accessCacheState=function(_,...)return r.cacheHost.access(...)end}}
    r.public={};r.descriptor={protocol='forge-pr-consumer/1',resource='ox_inventory',side='server',instance='prepared130',current=true,phase='prepared'}
    r.seedPorts={prCore=ioFixture.core,rpc=r.servicesFixture.wire.scopes.server,native=n,json=ioFixture.codec,
        public=r.public,environment=env,nativeCache={resource='forge-core',game='fxserver'},events=r.events,running=coroutine.running,
        getSource=function()return r.events.source()end,isCurrent=function()return r.nativeCurrent end,compile=load,
        inventoryBridgeProbe=function()return r.descriptor end,createRegistry=T.registry,
        loadPR=function(path,target)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end}
    r.seed=T.seed(r.seedPorts);assert(r.seed.Prepare());r.registry=r.seed.Registry
    local execution=r.seed.Execution.Native;runtime.native.GetConvar,runtime.native.GetConvarInt=execution.GetConvar,execution.GetConvarInt
    -- Only clone the input locale branch. Other domain/platform/config seeds remain explicit fixtures.
    local p={};for k,v in pairs(context)do p[k]=v end;local locale={};for k,v in pairs(context.locale)do locale[k]=v end
    locale.readFile=r.seed.IO.Files.LoadResourceFile;locale.decode=r.seed.IO.Codec.decode;p.locale=locale
    r.bootstrapPorts.context=p;r.bootstrapFactory=r.registry.Require('kernel.entry.server_bootstrap')
    return r
end
return T
