local T=dofile('tests/kernel_native_context_harness.lua');local H=T.H
local M={T=T,H=H,path='kernel/entry/native_profile.lua'};M.factory=H.load(M.path,H.environment())
function M.server()
    local r=T.server();r.configAssembly.Close();r.databaseAssembly.Close()
    r.profilePorts={side='server',seed=r.seed,services=r.servicesFixture.api,prCore=r.servicesFixture.wire.prs.server,external=r.external,
        random=r.configuration.ports.random,running=coroutine.running,loadPR=r.seedPorts.loadPR,barrier=r.barrier,
        bootstrap={context=r.originalContext,registration=r.bootstrapPorts.registration,isCurrent=r.bootstrapPorts.isCurrent,isReady=r.bootstrapPorts.isReady}}
    function r.allocateProfile()r.profile=M.factory(r.fixture.base,r.profilePorts);r.api=r.profile;return r.profile end
    function r.finishProfile()
        if r.profile then r.profile.Stop();r.clock.advance(1200000);r.profile.Poll()end
        r.seed.Close();r.servicesFixture.api.Close();r.servicesFixture.wire.close()
    end
    return r
end
function M.client()
    local r=T.C.new();local unit=T.S.unit('client');r.seedUnit=unit;r.nativeCurrent=true
    local ui=T.U.new();ui.scope.api.Close();r.uiFixture=ui
    local env=ui.ports.environment;env.type=r.fixture.modules.Stores.environment().type
    env.require=function()error('profile fixture has no external framework require')end
    -- Seed130 captures this explicit client-native test environment before creating its registry.
    unit.seedPorts.environment=env;unit.seedPorts.loadPR=function(path,target)
        return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)
    end
    local n=unit.seedPorts.native;local config=r.configuration.ports
    n.GetResourceState=config.getResourceState;n.GetVehicleNumberPlateText=config.getVehicleNumberPlateText;n.vec4=config.vec4;n.joaat=config.joaat
    r.seed=unit.allocateSeed();assert(r.seed.Prepare())
    r.profilePorts={side='client',seed=r.seed,services={Public={}},prCore=unit.ioFixture.core,external={pr_carkeys=r.configuration.raw,qbx_vehiclekeys=r.configuration.qbx},
        running=coroutine.running,loadPR=unit.seedPorts.loadPR,public=unit.public,environment=env,onError=error,bootstrap=r.bootstrapPorts}
    function r.allocateProfile()r.profile=M.factory(r.fixture.state,r.profilePorts);r.api=r.profile.Bootstrap;return r.profile end
    function r.finishProfile()
        if r.profile then r.profile.Stop();r.clock.advance(120000);r.profile.Poll()end
        r.seed.Close();unit.finishSeed();ui.finish()
    end
    return r
end
return M
