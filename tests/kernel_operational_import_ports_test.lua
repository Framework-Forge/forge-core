local source=assert(io.open('../pr_bridge/bridge/frameworks/forge/operational_import_ports.lua','rb')):read('*a')
for _,side in ipairs({'server','client'})do
 local captured,installed;local consumer={Generation='g277',IsReady=function()return true end}
 local public={table={freeze=function(t)return t end},string={random=function()return'abc'end},waitFor=function()end,
 print={warn=function()end},cache={},inventory={Search=function()return 0 end}}
 local hits=0;local sound=setmetatable({},{__index=function(_,name)return function(self,...)hits=hits+1;return name,...end end})
 local native=setmetatable({},{__index=_G});native.string={strsplit=function()end};native.exports={pr_3dsound=sound,qbx_core={},
 ['forge-core']={ForgeRuntimeStatus=function()return{generation='g277',stage=4}end}}
 native.GetCurrentResourceName=function()return'consumer'end;native.IsDuplicityVersion=function()return side=='server'end
 native.GetGameTimer=function()return 0 end;native.GetConvarInt=function()return 1000 end;native.GetConvar=function()return'discord'end
 native.AddEventHandler=function()end;native.RemoveEventHandler=function()end;native.RegisterNetEvent=function()end
 local pr={forgeRuntimeConsumer=consumer};native.PRCore=pr
 local resolver=function()end;local package={loaded={},searchers={}}
 public.ox_lib=setmetatable({},{__index=function(_,key)assert(key=='require');native.require=resolver;native.package=package;return resolver end});native.lib=public.ox_lib
 pr.load=function(path)
  assert(path=='@pr_bridge/bridge/frameworks/forge/import_ports_factory')
  return function(p)captured=p;return{Install=function()installed=true;return true end}end
 end
 assert(load(source,'@@pr_bridge/operational_import_ports.lua','t',_G))()({environment=native,prCore=pr,public=public})
 assert(native.require==resolver and native.package==package)
 assert(installed and captured.events.markNetwork==native.RegisterNetEvent and captured.native.GetGameTimer==native.GetGameTimer)
 local method=side=='server'and'PlayNativeSound'or'PlayLocalNativeSound'
 local name,value=captured.audio[method](42);assert(name==method and value==42 and hits==1)
 local private=captured.moduleEnvironment(function()end);assert(type(private.require)=='function'and private.GetGameTimer==native.GetGameTimer)
end
print('PASS277 operational import composition uses consumer PR helpers/events/cache and exact sound receiver;Cfx/export environment virtual')
