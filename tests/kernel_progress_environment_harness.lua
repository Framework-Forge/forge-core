local P=dofile('tests/kernel_progress_harness.lua');local E=dofile('tests/kernel_native_execution_harness.lua');local T={P=P,E=E,H=P.H}
T.factory=T.H.load('../pr_bridge/bridge/delivery/forge_progress_environment.lua',T.H.environment())
function T.new()
    local r=P.new(false);local e=E.new('client');r.executionFixture=e
    for _,name in ipairs(T.factory.Names())do e.native[name]=r.environment[name]end;e.allocate()
    r.ui={Streaming={}};r.bindings={execution=e.api,localPlayer=r.environment.LocalPlayer,settings=r.settings,environment=r.environment,getUI=function()return r.ui end}
    function r.build()r.built=T.factory.Build(r.bindings);return r.built end
    return r
end
return T
