local T=dofile('tests/kernel_owned_rpc_harness.lua');local H=T.H
local w=T.new();w.open()
local noop=function()end
local ioPorts={JSON={}}
for _,n in ipairs({'loadJsonRecovery','saveJsonRecovery','saveJsonBatch','withJsonLock','jsonDraft','wrapJsonMutations','recordJsonIncident'})do ioPorts.JSON[n]=noop end
local db={};for _,n in ipairs({'query','execute','insert','update','scalar','single','transaction','prepare','rawExecute'})do db[n]={await=noop}end
local lib=H.load('../pr_bridge/bridge/delivery/forge_server_library_ports_v2.lua',H.environment())({
 foundation={Side='server',IsCurrent=function()return true end,Seed={IO=ioPorts,Library={Cache={}}},Public={settings={}},RegistrationInput={prCommand=noop}},
 support={IsCurrent=function()return true end,Utilities={Library={}},Logging={DeliveryPorts={httpRequest=noop,setTimeout=noop}},Dependencies={CheckDependency=noop}},
 values={IsCurrent=function()return true end,Database={IsReady=noop,Database=db}},environment={},config={},rpc=w.scopes.server,
 native={TriggerClientEvent=noop,GetPlayerIdentifierByType=noop,GetCurrentResourceName=noop,GetInvokingResource=noop,GetResourceMetadata=noop,GetResourceState=noop},
 services={Public={inventory={},banking={},vehicle_key={}}},loadPR=function()return{versionCheck=noop}end
}).Library
local ok,err=pcall(w.scopes.server.Ox.await,2,'forge-core:client:menu:open',5000)
assert(not ok and tostring(err):find('Expected callback event',1,true),'old misrouting must reproduce')
local allowed=true;local calls=0
local service={canManage=function()return allowed end,sendTo=noop}
for _,spec in ipairs({{'jobs','forgecore','forge-core:client:menu:open'}, {'skill','skills','forge-core:client:skills:open'}, {'staff','staff','forge-core:client:staff:open'}})do
 local config={Callbacks={openMenu=spec[3],openAdmin=spec[3]},Commands={open=spec[2],jobs='jobs',testMei='mei',admin=spec[2],menu=spec[2],direct='staffdirect'}}
 local p={config=spec[1]=='jobs'and{Job=config}or config,library=lib,services={JobService=service},service=service,translate=function(k)return k end,time={},native={}}
 local command=H.load('kernel/server/'..spec[1]..'/commands.lua',H.environment())(p).Commands[1]
 local owner=w.scopes.client.Owners.native;local lease=owner.Reserve(spec[3])
 assert(owner.Bind(lease,function()calls=calls+1;return nil,false end))
 allowed=false;command.handler(2);assert(calls==0)
 allowed=true;command.handler(0);assert(calls==0)
 command.handler(2);assert(calls==1);calls=0;assert(owner.Release(lease))
end
local factory=dofile('kernel/pr_integration/visual_config_delivery.lua')
local record={epoch='server',revision=1,data={target={color='#123456'},interact={color='#abcdef'}}}
local applied={};local threads={}
for _,side in ipairs({'server','client'})do
 local e=w[side].env
 e.IsDuplicityVersion=function()return side=='server'end
 e.GetResourceState=function()return 'started'end
 e.CreateThread=function(fn)threads[#threads+1]=fn end
 e.exports.pr_bridge.GetCachedState=function(_,domain)assert(domain=='interface');return record end
 e.exports.pr_bridge.ApplyVisualConfig=function(_,r)applied[#applied+1]=r;return true end
end
local server=factory(w.server.env,w.scopes.server);assert(server.Start())
local client=factory(w.client.env,w.scopes.client);assert(client.Start());threads[1]()
assert(applied[1]==record and applied[1].data.interact.color=='#abcdef')
w.client.dispatch('pr_bridge:ui:ready','');assert(#threads==1,'ready must not poll after delivery')
w.client.dispatch('forge-core:config:interface','local',{data={}});assert(#applied==1,'local injection accepted')
local nextRecord={epoch='server',revision=2,data={target={color='#654321'}}}
w.client.dispatch('forge-core:config:interface',65535,nextRecord);assert(applied[2]==nextRecord)
local sent=#w.trace;w.server.dispatch('pr_bridge:ui:configCommitted','',nextRecord);assert(#w.trace==sent+1)
assert(client.Close());w.client.dispatch('forge-core:config:interface',65535,record);assert(#applied==2)
assert(server.Close());assert(server.Close());w.close()
print('PASS old panel error reproduced; 3 real command bodies/native RPC, ACL/console, initial visual snapshot, update, injection refusal, no polling, cleanup')
