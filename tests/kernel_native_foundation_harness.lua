local H=dofile('tests/kernel_harness.lua')
local T={H=H}
function T.loader(extra)
 local cache,env={}
 env=H.environment(extra)
 env.require=function(name)
  assert(name:sub(1,7)=='kernel.')
  if cache[name]==nil then cache[name]=H.load(name:gsub('%.','/')..'.lua',env)end
  return cache[name]
 end
 return env.require,env
end
function T.basePorts(server)
 local r={current=true,events={},writes={},errors={}}
 r.native={GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return server end,
 TriggerEvent=function(...)r.events[#r.events+1]=table.pack(...)end,TriggerClientEvent=function(...)r.events[#r.events+1]=table.pack(...)end}
 r.io={Files={SaveResourceFile=function(...)r.writes[#r.writes+1]=table.pack(...);return true end}}
 r.library={table={type=H.tableType},print={warn=function()end,error=function(...)r.errors[#r.errors+1]=table.pack(...)end}}
 r.ports={native=r.native,io=r.io,library=r.library,isCurrent=function()return r.current end}
 return r
end
return T
