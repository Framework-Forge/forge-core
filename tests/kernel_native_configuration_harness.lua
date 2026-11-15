local N=dofile('tests/kernel_native_execution_harness.lua');local S=dofile('tests/kernel_configuration_harness.lua');local C=dofile('tests/kernel_client_configuration_harness.lua')
local T={N=N,S=S,C=C,H=N.H,path='../pr_bridge/bridge/delivery/forge_native_configuration.lua'}
function T.new(side)
    local r=N.new(side);r.allocate();local fixture=side=='server'and S.new()or C.provider();r.fixture=fixture
    local p=fixture.ports
    r.native.GetResourceState=p.getResourceState;r.native.GetVehicleNumberPlateText=p.getVehicleNumberPlateText
    r.native.SetVehicleDoorsLocked=p.setVehicleDoorsLocked;r.native.vec4=p.vec4 or function(...)return S.P.vector(...)end;r.native.joaat=p.joaat
    r.external={qbx_vehiclekeys=fixture.qbx,pr_carkeys=fixture.raw};if side=='server'then r.external.qbx_vehiclekeys=fixture.qbx end
    local env=T.H.environment({GetGameTimer=function()return r.clock.now end,Wait=function(ms)r.clock.advance(ms or 0)end})
    r.configurationFactory=T.H.load(T.path,T.H.environment())
    r.configurationPorts={execution=r.api,external=r.external,side=side,isCurrent=function()return r.current end,keys={Pr=p.pr},random=p.random,
        running=coroutine.running,load=function(path)return T.H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',env)end}
    function r.mount()r.config=r.configurationFactory(r.configurationPorts);r.boundary=r.config.CreateConfiguration(r.config.Configuration);assert(r.boundary.Open());return r.config end
    function r.finish()if r.boundary then r.boundary.Close()end;if r.config then r.config.Close()end;r.api.Close()end
    return r
end
return T
