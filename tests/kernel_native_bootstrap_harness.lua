local N=dofile('tests/kernel_native_registration_harness.lua');local H=N.H;local M={N=N,H=H}
function M.environment(base)
    local env=base or H.environment();local prior=env.require;local cache={}
    env.require=function(name)
        if name:sub(1,13)=='kernel.entry.'then
            if not cache[name]then cache[name]=H.load(name:gsub('%.','/')..'.lua',env)end;return cache[name]
        end
        if prior then return prior(name)end;error('unsupported import '..name)
    end
    return env
end
function M.attach(r,side)
    r.scope=N.new(side);local p=r.scope.ports;local n=p.native
    n.AddEventHandler,n.RemoveEventHandler,n.RegisterNetEvent,n.source=r.events.listen,r.events.remove,r.events.markNetwork,r.events.source
    n.RegisterCommand,n.publishExport=r.surface.ports.nativeCommand,r.surface.ports.publishExport
    p.available,p.prCommand,p.oxCommand=r.surface.ports.available,r.surface.ports.prCommand,r.surface.ports.oxCommand
    r.nativeCurrent=true;r.nativeReady=true
    r.bootstrapPorts={context=side=='server'and r.importPorts or r.localePorts,registration=p,
        isCurrent=function()return r.nativeCurrent end,isReady=function()if r.bootstrapReadyHook then r.bootstrapReadyHook()end;return r.nativeReady end}
    return r
end
function M.server()
    local T=dofile('tests/kernel_locale_runtime_harness.lua');local r=M.attach(T.server(),'server');r.T=T
    local env=M.environment(T.S.M.R.C.V.B.O.P.T.T.W.D.R.env());env.print=function()end
    r.bootstrapFactory=H.load('kernel/entry/server_bootstrap.lua',env)
    function r.allocateBootstrap()r.api=r.bootstrapFactory(r.fixture.base,r.bootstrapPorts);return r.api end
    function r.prepareBootstrap()if not r.api then r.allocateBootstrap()end;assert(r.api.Prepare('en'));r.graph=r.api.Graph
        r.keys.api=r.fixture.base.ServerVehicleContext.Vehicles;r.configuration.api=r.fixture.base.ServerConfigurationContext.Boundary;return r.api end
    function r.installBootstrap()if not r.nativeProvidersOpened then r.wire.Initialize();r.surface.Open();r.nativeProvidersOpened=true end;return r.api.Install()end
    function r.startBootstrap()assert(r.installBootstrap());r.emit('onResourceStart','forge-core');r.begin();r.resume();assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[2]))end
    function r.drain()r.api.Stop();r.clock.advance(1200000);return r.api.Poll()end
    return r
end
return M
