-- Installed PR wait/key bodies, actual69/57/58; all platform/cache/clock effects virtual.
local M=dofile('tests/kernel_client_media_harness.lua');local S=dofile('tests/kernel_support_harness.lua')
local H=M.H;local T={M=M,S=S,H=H,P=S.P}
function T.provider()
    local r={states={},trace={},now=0,current=true,raw={},qbx={},vectors=0,hashes=0}
    function r.record(name,...)r.trace[#r.trace+1]={kind=name,args=S.P.snapshot(table.pack(...))}end
    local env=H.environment({Config={Debug=false},pr_lib={activeBridges={frameworks='qbx',database='oxmysql',inventory='ox'}},
        GetResourceState=function()return'stopped'end,IsDuplicityVersion=function()return false end,print=function()end})
    local root='../../../[vehicle_system]/pr_carkeys/'
    H.load(root..'shared/main.lua',env)
    r.keyState=H.load(root..'client/modules/vehicle_state.lua',env)
    env.exports=function(name,fn)r.raw[name]=function(self,...)
        assert(self==r.raw,'Cfx PR receiver');r.record(name,...)
        if r.keyHook then r.keyHook(...)end;if r.keyError then error('virtual key error',0)end
        return fn(...)
    end end
    H.load(root..'client/modules/vehicle_exports.lua',env)
    r.qbx.HasKeys=function(self,...)assert(self==r.qbx,'Cfx QBX receiver');r.record('HasKeys',...)
        if r.keyError then error('virtual key error',0)end;return r.qbxResult,nil,17
    end
    r.waitFor=H.load('../pr_bridge/bridge/utils/waitFor.lua',H.environment({
        GetGameTimer=function()return r.now end,Wait=function(ms)
            r.record('wait',ms);r.now=r.now+1;if r.waitHook then r.waitHook(ms)end
        end}))
    r.ports={vec4=function(...)r.vectors=r.vectors+1;return S.P.vector(...)end,
        joaat=function(v)r.hashes=r.hashes+1;return'HASH_'..v end,
        getResourceState=function(name)r.record('state',name);return r.states[name]or'stopped'end,
        getVehicleNumberPlateText=function(vehicle)r.record('plate',vehicle);return r.plate end,
        prKeys=r.raw,qbxKeys=r.qbx,waitFor=r.waitFor,isCurrent=function()return r.current end,running=coroutine.running}
    r.factory=H.load('../pr_bridge/bridge/delivery/forge_client_configuration.lua',H.environment())
    function r.mount()r.api=r.factory(r.ports);return r.api end
    function r.config(ported)
        if ported then return H.load('kernel/config/client.lua',H.environment())(r.api.Ports)end
        return S.P.loadOrigin('config/client.lua',H.environment({vec4=r.ports.vec4,joaat=r.ports.joaat,
            GetResourceState=r.ports.getResourceState,GetVehicleNumberPlateText=r.ports.getVehicleNumberPlateText,
            exports={pr_carkeys=r.raw,qbx_vehiclekeys=r.qbx}}))
    end
    return r
end
function T.context()
    local r=M.context();r.configuration=T.provider()
    -- Fixture49 formerly constructed Client06;70 explicitly owns the new construction.
    r.mediaPorts.worker.central.config={Inventory=r.mediaPorts.worker.central.config.Inventory}
    local env=M.S.W.D.A.E.env();env.type=r.fixture.modules.Stores.environment().type;env.print=function()end
    local requireModule=env.require;r.captures={};r.configConstructions=0
    local targets={['kernel.helpers']=true,['kernel.client.session_core']=true,['kernel.client.runtime_core']=true,['kernel.client.character_core']=true}
    env.require=function(name)local ctor=requireModule(name)
        if name=='kernel.config.client'then return function(p)r.configConstructions=r.configConstructions+1;return ctor(p)end end
        if targets[name]then return function(a,b)r.captures[name]=b or a;return ctor(a,b)end end;return ctor
    end
    -- Match the installed fixture native hash representation at this graph boundary.
    r.configuration.ports.joaat=r.mediaPorts.worker.central.native.joaat
    r.configuration.ports.vec4=r.mediaPorts.worker.central.native.vec4
    r.configurationPorts={configuration=r.configuration.ports,createConfiguration=r.configuration.factory,mediaContext=r.mediaPorts}
    r.configurationFactory=H.load('kernel/client/configuration_context.lua',env)
    function r.prepareConfiguration()
        r.api=r.configurationFactory(r.fixture.state,r.configurationPorts);r.graph=r.api.Graph;r.worker=r.api.Context.Worker
        return r.api
    end
    function r.installConfiguration()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return T
