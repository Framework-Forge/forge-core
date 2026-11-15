local B=dofile('tests/kernel_native_bootstrap_harness.lua');local C=dofile('tests/kernel_client_locale_harness.lua')
local M={B=B,C=C,H=B.H}
function M.new()
    local r=B.attach(C.new(),'client')
    local remove=r.scope.ports.native.RemoveEventHandler
    r.scope.ports.native.RemoveEventHandler=function(token)if r.refuseNativeToken==token then return false end;return remove(token)end
    local env=B.environment(C.L.R.C.C.M.S.W.D.A.E.env());env.type=r.fixture.modules.Stores.environment().type;env.print=function()end
    r.bootstrapFactory=M.H.load('kernel/entry/client_bootstrap.lua',env)
    function r.allocateBootstrap()r.api=r.bootstrapFactory(r.fixture.state,r.bootstrapPorts);return r.api end
    function r.prepareBootstrap()if not r.api then r.allocateBootstrap()end;assert(r.api.Prepare());r.graph=r.api.Graph;return r.api end
    function r.installBootstrap()if not r.nativeProvidersOpened then r.wire.Initialize();r.surface.Open();r.nativeProvidersOpened=true end;return r.api.Install()end
    function r.startBootstrap()assert(r.installBootstrap());r.runtimeImports.pollNative();assert(r.api.Start())end
    function r.drain()r.api.Stop();r.clock.advance(120000);return r.api.Poll()end
    return r
end
return M
