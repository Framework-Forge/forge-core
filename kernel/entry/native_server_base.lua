-- Construct the one server state from local seeds; no adopted QBX/PR framework state.
local createBase=require 'kernel.init'
local jobs=require 'kernel.shared.jobs'
local gangs=require 'kernel.shared.gangs'
local weapons=require 'kernel.shared.weapons'
local locations=require 'kernel.shared.locations'
local function clone(value)
 if type(value)~='table'then return value end
 local out={};for k,v in pairs(value)do out[k]=clone(v)end;return out
end
return function(ports)
 local current=assert(ports.isCurrent);local n=assert(ports.native)
 local io=assert(ports.io);local library=assert(ports.library)
 assert(n.GetCurrentResourceName()=='forge-core'and (not not n.IsDuplicityVersion())==true,'native server base required')
 local closed=false
 local function live()local ok,v=pcall(current);return not closed and ok and v==true end
 local function guard(fn)return function(...)assert(live(),'native server base closed');return fn(...)end end
 assert(live(),'native server base unavailable')
 local base=createBase({
  shared={locations=clone(locations),weapons=clone(weapons)},
  membership={tableType=guard(assert(library.table.type)),warn=guard(assert(library.print.warn))},
  groups={jobs=clone(jobs),gangs=clone(gangs),emitServer=guard(assert(n.TriggerEvent)),emitClient=guard(assert(n.TriggerClientEvent)),
   logError=guard(assert(library.print.error)),saveGroups=guard(function(kind,source)
    local paths={job='kernel/shared/jobs.lua',gang='kernel/shared/gangs.lua'}
    return assert(io.Files.SaveResourceFile)('forge-core',assert(paths[kind],'unknown group kind'),source,-1)
   end)}
 })
 local api={Base=base,OperationalReady=false}
 function api.IsCurrent()return live()end
 function api.Close()closed=true;return true end
 return api
end
