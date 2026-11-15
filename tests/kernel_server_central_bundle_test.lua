local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local marker=function(...)return ...end;local tbl=setmetatable({},{__index=function()return marker end})
local f={Side='server',IsCurrent=function()return true end,Locale=marker,Seed={IO={Codec={}},Execution={Native={GetConvar=function(_,d)return d end,GetConvarInt=function(_,d)return d end}}},Base={}}
local raw={Operations={Raw=tbl,IsReady=marker},Inventory=tbl,Keys={VehicleKey=tbl}}
local s={Cache={Ports={getResourceState=marker,accessCacheState=marker,emit=marker}},Logging={DeliveryPorts={httpRequest=marker}},Sound={Ports={sendClient=marker}}}
local lib={print={warn=marker},notify={NotifyPlayer=marker}}
local v={Clock={time=marker,date=marker},Platform={Player=function()return{}end,Select=function()return{GetPlayerIdentifiers=marker}end},
 Server={player={status={}}},Shared={defaultSpawn={},starterItems={},serverName='Server',notifyPosition='left'},Database={Database={query={await=marker}}},
 Counters={},Settings={},GetBucket=marker,NewPromise=marker,AwaitPromise=marker,Random=marker,Compile=marker}
local a=req('kernel.entry.server_central_bundle')(f,s,v,lib,{Documents={},Consumption={}},{services=raw,rpc={Ox={await=marker}},config={Job={},Vip={},Inventory={},Weapons={}},translate=marker,environment={os={clock=marker}}})
local count=0;for _,part in pairs(a.parts)do assert(type(part)=='table');count=count+1 end
assert(count==13 and a.parts.session.player.counters==v.Counters and a.parts.session.player.inventory==raw.Operations.Raw)
assert(a.parts.jobs.dependencies and next(a.parts.jobs.dependencies)==nil and a.platform.getIdentifiers==marker)
assert(not pcall(a.parts.session.player.triggerHook,'test'))
f.Base.ServerSupportContext={Hooks={Hooks={trigger=function()return 'local-hook'end}},Logger={log=function()return'local-log'end}}
assert(a.parts.session.player.triggerHook()=='local-hook'and a.parts.runtime.logger.log()=='local-log')
print('PASS204 all13 central inputs,raw provider identity,one counter/DB/platform and deferred local hooks/logger;no QBX forwarding')
