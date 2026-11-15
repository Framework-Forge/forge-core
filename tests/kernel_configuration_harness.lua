-- Actual65/06/07 composition and PR config provider; external ports/platform/SQL remain virtual.
local V=dofile('tests/kernel_vehicle_integration_harness.lua');local S=dofile('tests/kernel_support_harness.lua')
local H=V.H;local C={V=V,S=S,H=H,P=S.P}
function C.parts(keys)
    local r={keys=keys,trace={},counter=0,plate='  NATIVE  ',current=true,qbx={},qbxCalls={}}
    local function record(kind,...)r.trace[#r.trace+1]={kind=kind,args=S.P.snapshot(table.pack(...))}end
    for _,name in ipairs({'GiveKeys','SetLockState'})do local method=name
        r.qbx[name]=function(self,...)
            assert(self==r.qbx);r.qbxCalls[#r.qbxCalls+1]={name=method,args=table.pack(...)};record('qbx-'..method,...)
            if r.qbxHook then r.qbxHook(method)end;return'ALT',nil,7
        end
    end
    r.ports={pr=keys.api and keys.api.Pr or{},qbxVehiclekeys=r.qbx,isCurrent=function()return r.current end,
        getResourceState=function(name)record('state',name);return keys.states[name]or'stopped'end,
        getVehicleNumberPlateText=function(entity)record('plate',entity);return r.plate end,
        setVehicleDoorsLocked=function(...)record('native-lock',...);if r.lockHook then r.lockHook(...)end end,
        random=function(a,b)record('random',a,b);r.counter=r.counter+1;return a+(r.counter%(b-a+1))end,
        randomString=function(pattern)record('randomString',pattern);r.counter=r.counter+1;return'ID'..r.counter..pattern end}
    r.factory=H.load('../pr_bridge/bridge/vehicle_key/forge_configuration.lua',H.environment())
    function r.mount()r.api=r.factory(r.ports);return r.api end
    function r.original()
        local env=H.environment({GetResourceState=r.ports.getResourceState,GetVehicleNumberPlateText=r.ports.getVehicleNumberPlateText,
            SetVehicleDoorsLocked=r.ports.setVehicleDoorsLocked,exports={pr_carkeys=keys.raw,qbx_vehiclekeys=r.qbx},
            lib={string={random=r.ports.randomString}}})
        env.math.random=r.ports.random
        return S.P.loadOrigin('config/server.lua',env)
    end
    return r
end
function C.new()
    local keys=V.new();keys.mount();assert(keys.api.Open())
    local r=C.parts(keys);r.mount();assert(r.api.Open());r.config=H.load('kernel/config/server.lua',H.environment())(r.api.Ports)
    return r
end
function C.context()
    local r=V.context();r.configuration=C.parts(r.keys);r.captures={};r.configCounts={shared=0,server=0};r.vectors=0
    local env=V.B.O.P.T.T.W.D.R.env();local requireModule=env.require
    local captured={['kernel.server.player']='Player',['kernel.server.storage']='Storage',['kernel.server.status']='Status',
        ['kernel.server.character_slots']='Slots',['kernel.server.character']='Character',['kernel.server.functions']='Functions',
        ['kernel.server.events']='Events',['kernel.server.commands']='Commands'}
    env.require=function(name)
        local ctor=requireModule(name)
        if name=='kernel.config.server'or name=='kernel.config.shared'then
            return function(p)local k=name:match('([^.]+)$');r.configCounts[k]=r.configCounts[k]+1;return ctor(p)end
        end
        if captured[name]then return function(p)r.captures[captured[name]]=p;return ctor(p)end end
        return ctor
    end
    env.print=function(...)r.fixture.central.record('print',...)end
    r.configurationPorts={vehicleContext=r.vehicleContextPorts,configuration=r.configuration.ports,createConfiguration=r.configuration.factory,
        shared={vec4=function(...)r.vectors=r.vectors+1;return S.P.vector(...)end}}
    r.configurationFactory=H.load('kernel/server/configuration_context.lua',env)
    function r.prepareConfiguration()
        r.api=r.configurationFactory(r.fixture.base,r.configurationPorts);r.graph=r.api.Graph;r.keys.api=r.api.Context.Vehicles
        r.configuration.api=r.api.Boundary;return r.api
    end
    function r.configurationInstall()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return C
