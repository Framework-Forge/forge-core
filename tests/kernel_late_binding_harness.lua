local O=dofile('tests/kernel_inventory_bridge_harness.lua');local A=dofile('tests/kernel_adapter_binding_harness.lua');local H=O.H;local T={O=O,A=A,H=H}
function T.new()
    local r=O.C.new();r.graph.PlayerCore.Players.CheckPlayerData(2,{citizenid='LATE114',license='license:test',userId=101,money={cash=20,bank=30}})
    r.ox=O.fixture(true,r);r.adapterFixture=A.new('server');r.adapterFixture.ports.adapter.core=H.load('kernel/server/framework_backend.lua',H.environment())(r.graph,{
        isCurrent=function()return r.api.IsCurrent()end,isReady=function()return r.nativeReady end}).Core
    local fw=r.adapterFixture.source.api.Framework;local names={};for n in pairs(fw)do names[#names+1]=n end;table.sort(names)
    local aliases,seen={},{};for _,n in ipairs(names)do local fn=fw[n];seen[fn]=seen[fn]or n;aliases[n]=seen[fn]end
    r.ready=true;r.constructed=0;r.latePorts={side='server',frameworkMethods=aliases,inventoryServer=r.ox.server,
        isCurrent=function()return r.api.IsCurrent()end,isReady=function()return r.ready end,
        createSelection=function()r.constructed=r.constructed+1;return H.load('../pr_bridge/bridge/runtime/forge/selection_factory.lua',H.environment())({side='server',identity=r.identity,isCurrent=function()return r.api.IsCurrent()end})end,
        createContract=function()r.contract=r.contractFactory(r.contractPorts);return r.contract end,
        createAdapter=function()local a=r.adapterFixture.mount();r.preparedAdapter=a;return a end,
        createInventory=function(contract)r.ox.ports.contract=contract;r.ox.api=H.load(O.path,H.environment())(r.ox.ports);return r.ox.api end}
    r.lateFactory=H.load('../pr_bridge/bridge/runtime/forge/late_binding_factory.lua',H.environment())
    r.late=r.lateFactory(r.latePorts);local finish=r.finish
    function r.finish()r.late.Close();return finish()end
    return r
end
return T
