local B=dofile('tests/kernel_adapter_binding_harness.lua');local K=dofile('tests/kernel_framework_backend_harness.lua');local H=B.H
local core=K.new();core.start();local pc=core.graph.PlayerCore
pc.Players.CheckPlayerData(2,{citizenid='HOST86',license='license:test',userId=101,money={cash=4,bank=0}})
local consumer=B.new('server');consumer.ports.adapter.core=core.backend.Core;consumer.mount();consumer.api.Install()
local normal=H.load('../pr_bridge/bridge/frameworks/forge/normalization_factory.lua',H.environment())({side='server',framework=consumer.target.framework,
    resourceName='forge-core',core={},native={},isCurrent=function()return consumer.current end})
local routing=H.load('../pr_bridge/bridge/frameworks/forge/routing_factory.lua',H.environment())({active={frameworks='forge'},config={},contracts={qb=true},
    isCurrent=function()return consumer.current end,readDeclarations=function()return{'forge'}end})
-- Getter is an explicit supplied test contract, not a claim that the full native QB bridge has been ported.
local supplied={Functions={GetPlayer=normal.Framework.GetPlayer},Shared={}}
local host=H.load('../pr_bridge/bridge/frameworks/forge/native_host_factory.lua',H.environment())({resourceName='forge-core',
    isCurrent=function()return consumer.current end,isReady=function()return true end,getNativeOwner=function()return'forge-core'end,
    getBridgeSetting=function()return'true'end,contracts={qb=true},routing=routing,getCoreObject=function(filters)
        if filters then return{Functions=supplied.Functions}end;return supplied
    end})
assert(host.GetCoreObject()==supplied and host.GetCoreObject({'Functions'}).Functions.GetPlayer(2)==pc.Lookup.GetPlayer(2))
assert(normal.Framework.GetPhoneProfile(2).identifier=='HOST86')
host.Close();routing.Close();normal.Close();consumer.api.Close();core.close()
assert(host.Progress().complete and routing.Progress().complete and normal.Progress().complete and consumer.api.Progress().complete and core.api.Progress().complete)
print('PASS lot86 supplied-getter integration84/85/83/82/74:host filters resolve same canonical Player/phone profile,owned Close;full native QB bridge/public aliases still pending,all effects virtual')
