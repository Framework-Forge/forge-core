-- Independent descriptor walk and installed literal-export contracts; never executes source files.
local T=dofile('tests/kernel_public_registration_harness.lua');local r=T.new();r.preparePublic()
local function coverage(graph,entries)
 local seen,expected,actual={},{},{}
 local function add(kind,name,fn)
  local key=kind..':'..(kind=='command'and name:lower()or name)
  if name=='GetCachedState'and kind=='export'then expected[key]=true;return end
  assert(expected[key]==nil or expected[key]==fn,'unexpected reachable collision '..key);expected[key]=fn
 end
 local function walk(value)
  if type(value)~='table'or seen[value]then return end;seen[value]=true
  for key,d in pairs(value.Exports or{})do
   if type(key)=='string'and type(d)=='function'then add('export',key,d)
   elseif type(d)=='table'and type(d.name)=='string'and type(d.handler)=='function'then add('export',d.name,d.handler)end
  end
  for key,d in pairs(value.Commands or{})do if type(d)=='table'and type(d.handler)=='function'then
   local names=type(d.name)=='table'and d.name or{d.name or(type(key)=='string'and key)}
   for _,name in ipairs(names)do add('command',name,d.handler)end
  end end
  for key,child in pairs(value)do if type(child)=='table'and key~='Base'and key~='State'and key~='Config'then walk(child)end end
 end
 walk(graph)
 for _,d in ipairs(entries)do
  local key=d.kind..':'..(d.kind=='command'and d.name:lower()or d.name)
  assert(not actual[key],'duplicate selection '..key);actual[key]=d.handler
 end
 local count=0;for key,fn in pairs(expected)do assert(actual[key]and(fn==true or actual[key]==fn),'omitted/foreign reachable descriptor '..key);count=count+1 end
 return actual,count
end
local server,serverCount=coverage(r.serverGraph,r.serverEntries)
local client,clientCount=coverage(r.clientGraph,r.clientEntries)
local function original(file,selected,resolve)
 local stream=assert(io.open(file,'rb'));local source=stream:read('*a');stream:close();local count=0
 for name in source:gmatch('exports%s*%(%s*[\'"]([^\'"]+)[\'"]')do
  local fn=assert(selected['export:'..name],'unbound installed literal export '..file..':'..name)
  if resolve then assert(fn==resolve(name),'wrong installed export target '..name)end
  count=count+1
 end
 return count
end
local pc=r.serverGraph.PlayerCore;local count=0
for _,item in ipairs({{'main',pc.Runtime.Main.Exports},{'weapons',pc.Runtime.Weapons.Exports},{'groups',pc.Groups},
 {'vehicle-persistence-compat',r.serverGraph.Parts.Vehicles.Helpers.Persistence.Exports},{'status',pc.Producers.Status.Exports},
 {'character_slots',pc.Characters.Slots.Exports},{'player',pc.Players}})do
 count=count+original('../../../[qbx]/qbx_core/server/'..item[1]..'.lua',server,function(name)return item[2][name]end)
end
count=count+original('../../../[qbx]/qbx_core/server/functions.lua',server,function(name)return pc.Lookup[name]or pc.Lifecycle.Functions.Exports[name]end)
count=count+original('../../../[qbx]/qbx_core/server/session.lua',server)
local p=r.clientGraph.Central.Parts;local clientOriginal=0
for _,item in ipairs({{'main',p.Runtime.Main.Exports},{'bridge-cache',p.Producers.Cache.Exports},{'status',p.Producers.Status.Exports},
 {'groups',p.Legacy.Groups.Exports},{'functions',p.Legacy.Functions.Exports}})do
 clientOriginal=clientOriginal+original('../../../[qbx]/qbx_core/client/'..item[1]..'.lua',client,function(name)return item[2][name]end)
end
clientOriginal=clientOriginal+original('../../../[qbx]/qbx_core/client/session.lua',client)
assert(server['export:CheckPlayerData']==nil and server['export:PrepareSchema']==nil,'internal methods never exposed')
assert(#r.serverCallbacks==2,'two remaining raw core callbacks explicitly selected')
print('PASS public coverage: '..serverCount..' reachable server/'..clientCount..' client export-command contracts; '..count..' server/'..clientOriginal..' client installed QBX literal exports checked by name/target; hooks/imports/compat outside graph remain pending')
