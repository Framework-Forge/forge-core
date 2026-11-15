local E=dofile('tests/kernel_engine_profile_harness.lua');local P=dofile('tests/kernel_progress_harness.lua');local T={E=E,P=P,H=E.H}
function T.new(side)
    local r=E.new(side);r.progressFixture=P.new(false)
    if side=='client'then
        local env=T.H.load('../pr_bridge/bridge/delivery/forge_progress_environment.lua',T.H.environment())
        local n=r.seedUnit.seedPorts.native;for _,name in ipairs(env.Names())do if n[name]==nil then n[name]=r.progressFixture.environment[name]end end
        r.profilePorts.progress={localPlayer=r.progressFixture.environment.LocalPlayer,settings=r.progressFixture.settings}
    end
    r.factory154=T.H.load('kernel/entry/progress_native_profile.lua',T.H.environment())
    function r.allocate154()r.profile=r.factory154(side=='server'and r.fixture.base or r.fixture.state,r.profilePorts);r.api=side=='server'and r.profile or r.profile.Bootstrap;return r.profile end
    return r
end
return T
