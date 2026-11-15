local N=dofile('tests/kernel_native_foundation_harness.lua');local req=N.loader()
local f=assert(io.open('../../../../.planning/migration/staging/boot-1807-20261028/CLIENT-NATIVES.json','rb'))
local inventory=test_decode_json(f:read('*a'));f:close()
local function setup(server)
 local e=N.H.environment();setmetatable(e,nil)
 for _,name in ipairs(inventory.names)do e[name]=function()error('unexercised client native: '..name)end end
 e.GetCurrentResourceName=function()return'forge-core'end;e.IsDuplicityVersion=function()return server end
 e._G=e;e.os=os;e.math=math;e.coroutine=coroutine;e.exports={};e.json={}
 e.promise={new=function()end};e.Citizen={Await=function()end};e.LocalPlayer={}
 local yes=function()return true end
 local p={environment=e,prCore={load=function()error('capture must not load modules')end},public={settings={}},
  registration={available=yes,prCommand=yes,oxCommand=yes,publishExport=yes},barrier={WrapIngress=yes,IsIngressOpen=yes},
  isCurrent=yes,isReady=yes,inventoryBridgeProbe=yes,pullLocale=yes,onError=error,targetSelection='native',originOwner={Bind=function(x)return x end}}
 return e,p
end
local e,p=setup(false);assert(e.SaveResourceFile==nil and e.TriggerClientEvent==nil and e.GetPlayerIdentifiers==nil)
assert(e.SetTrafficLightsState==nil and e.SetTrafficLightsState2==nil,'optional custom functions must really be absent')
local options=req('kernel.entry.physical_boot_options_v5')(p)('client')
assert(options.foundation.native.SaveResourceFile==nil,'do not fabricate client writes')
for name,fn in pairs(options.foundation.native)do assert(type(fn)=='function'and e[name]==fn,'captured only actual client capability: '..name)end
local count=0;for _ in pairs(options.foundation.native)do count=count+1 end;assert(count>150)
e.Wait=nil;local ok,why=pcall(req('kernel.entry.physical_boot_options_v5')(p),'client');assert(not ok and tostring(why):find('Wait',1,true))
local server,sp=setup(true);local ok,why=pcall(req('kernel.entry.physical_boot_options_v5')(sp),'server')
assert(not ok and tostring(why):find('SaveResourceFile',1,true),'server persistence remains mandatory')
print('PASS selected physical client capture against installed client function inventory; '..count..' ports, no server write stubs; missing Wait/server SaveResourceFile refused')
