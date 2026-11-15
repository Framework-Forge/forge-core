-- Explicit native central49 input. Assemblies own state/membership/helpers/runtime/renderer/status links.
local jobs=require 'kernel.shared.jobs'
local gangs=require 'kernel.shared.gangs'
local function clone(value)if type(value)~='table'then return value end;local out={};for k,v in pairs(value)do out[k]=clone(v)end;return out end
return function(foundation,ports)
 assert(foundation.Side=='client'and foundation.IsCurrent(),'client central foundation required')
 local function need(name,kind)local v=assert(ports[name],'client central provider required:'..name);assert(type(v)==kind,'client central provider type:'..name);return v end
 local library=need('library','table');local rpc=need('rpc','table')
 assert(rpc.Side=='client'and type(rpc.Ox.await)=='function','client RPC122 required')
 local names={};for _,entry in ipairs(foundation.EngineInputs.Describe())do names[#names+1]=entry.name end
 local n=foundation.EngineInputs.Select(names)
 local config=need('config','table');assert(type(config.Inventory)=='table','local Inventory config required')
 local random,strsplit=need('random','function'),need('strsplit','function')
 return{native=n,library=library,cache=foundation.NativeCache.Cache,config=config,
  membership={tableType=assert(library.table.type),warn=assert(library.print.warn)},
  helpers={audio=need('audio','table'),warn=library.print.warn},
  producers={delivery=need('delivery','table')},
  legacy={jobs=clone(jobs),gangs=clone(gangs),notify=need('notify','function'),notifyPosition=ports.notifyPosition,
   random=random,strsplit=strsplit,searchInventory=need('searchInventory','function'),
   awaitGroups=function()assert(foundation.IsCurrent(),'client foundation unavailable');return rpc.Ox.await('qbx_core:server:getGroups',false)end},
  runtime={globalState=need('globalState','table'),locale=foundation.Locale,random=random},
  character={streaming=need('streaming','table'),json=foundation.Seed.IO.Codec,random=random,
   setPedAppearance=need('setPedAppearance','function'),defaultSpawn=assert(ports.defaultSpawn),
   ui=need('ui','table'),callbacks=rpc.Ox,integrations=need('characterIntegrations','table'),locale=foundation.Locale,
   groupdigits=need('groupdigits','function'),strsplit=strsplit},
  consumption={integrations=need('consumptionIntegrations','table')}}
end
