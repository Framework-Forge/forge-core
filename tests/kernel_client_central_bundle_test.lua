local T=dofile('tests/kernel_client_assembly_harness.lua');local N=dofile('tests/kernel_native_foundation_harness.lua')
local r=T.new();local req=N.loader();local old=r.ports;local u={Random=old.character.random,Strsplit=old.character.strsplit,Groupdigits=old.character.groupdigits}
local f={Side='client',IsCurrent=function()return true end,Base=r.state,Seed={Registry={Require=req},IO={Codec=old.character.json},
 Execution={Bind=function()return{vec4=function(...)return{...}end}end}},NativeCache={Cache=old.cache},Locale=old.runtime.locale,
 EngineInputs={Describe=function()return{}end,Select=function()return old.native end}}
local s={Utilities=u,Cache={Ports={getResourceState=old.producers.delivery.getResourceState,
 accessCacheState=old.producers.delivery.writeCache,emit=old.producers.delivery.emit}}}
local lib=old.library;lib.table.type=T.H.tableType;lib.print={warn=old.membership.warn};lib.Notify=old.legacy.notify
lib.requestModel=old.character.streaming.requestModel;lib.requestAnimDict=old.character.streaming.requestAnimDict
local int={SetPedAppearance=old.character.setPedAppearance,Character=old.character.integrations,Consumption=old.consumption.integrations}
local rpc={Side='client',Ox={await=function()return{jobs={},gangs={}}end}}
local p={rpc=rpc,config=old.config,services={Public={inventory={Search=old.legacy.searchInventory}}},environment={GlobalState=old.runtime.globalState},ui=old.character.ui}
local out=req('kernel.entry.client_central_bundle')(f,s,lib,int,p)
local input=req('kernel.entry.native_client_central_ports')(f,out);input.config.Client=old.config.Client
local graph=r.factory(r.state,input);assert(graph.IsCanonical()and graph.Core==r.state)
assert(input.cache==old.cache and out.characterIntegrations==int.Character and out.config.Client==old.config.Client)
assert(out.defaultSpawn[1]==-540.58 and out.defaultSpawn[4]==208.88)
print('PASS214 concrete central inputs construct real49; same PlayerData/cache; local shared spawn; PR inventory and character boundaries')
