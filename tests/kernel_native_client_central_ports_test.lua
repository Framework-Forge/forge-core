local T=dofile('tests/kernel_client_assembly_harness.lua');local H=T.H;local r=T.new()
local e=T.E.env();local f=H.load('kernel/entry/native_client_central_ports.lua',e)
local old=r.ports;local calls=0;local rpc={Side='client',Ox={await=function(name,arg)assert(name=='qbx_core:server:getGroups'and arg==false);calls=calls+1;return{jobs={},gangs={}}end}}
local foundation={Side='client',IsCurrent=function()return true end,NativeCache={Cache=old.cache},Seed={IO={Codec=old.character.json}},
 Locale=old.runtime.locale,EngineInputs={Describe=function()return{}end,Select=function()return old.native end}}
local p={library=old.library,rpc=rpc,config=old.config,random=old.character.random,strsplit=old.character.strsplit,
 audio=old.helpers.audio,delivery=old.producers.delivery,notify=old.legacy.notify,notifyPosition=old.legacy.notifyPosition,
 searchInventory=old.legacy.searchInventory,globalState=old.runtime.globalState,streaming=old.character.streaming,
 setPedAppearance=old.character.setPedAppearance,defaultSpawn=old.character.defaultSpawn,ui=old.character.ui,
 characterIntegrations=old.character.integrations,groupdigits=old.character.groupdigits,consumptionIntegrations=old.consumption.integrations}
p.library.table=p.library.table or{};p.library.table.type=H.tableType
p.library.print=p.library.print or{};p.library.print.warn=old.membership.warn
local out=f(foundation,p);assert(out.legacy.jobs.unemployed and out.legacy.gangs.none and calls==0)
assert(out.character.callbacks==rpc.Ox and out.cache==old.cache and out.character.json==old.character.json)
assert(out.legacy.awaitGroups()and calls==1)
local graph=r.factory(r.state,out);assert(graph.IsCanonical()and graph.Core==r.state)
for _,name in ipairs({'setPedAppearance','characterIntegrations','globalState','delivery','rpc','library','searchInventory'})do
 local bad={};for k,v in pairs(p)do bad[k]=v end;bad[name]=nil;assert(not pcall(f,foundation,bad),name)
end
print('PASS185 native central49 inputs construct actual canonical graph;local group seeds,owned RPC,unique PlayerData and missing-provider refusal')
