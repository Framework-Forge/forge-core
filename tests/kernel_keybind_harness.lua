local H=dofile('tests/kernel_harness.lua');local T={H=H,path='../pr_bridge/bridge/delivery/forge_client_keybinds.lua'}
function T.new(wrapped)
 local r={current=true,commands={},timers={},mappings={},trace={},pause=false,core={resource='forge-core',context='client'}}
 local function hash(s)local n=0;for i=1,#s do n=(n*31+s:byte(i))&0x7fffffff end;return n end
 local env=H.environment({GetCurrentResourceName=function()return'forge-core'end,joaat=hash,IsPauseMenuActive=function()return r.pause end,
 GetControlInstructionalButton=function(_,value)return't_'..value end,Wait=function()coroutine.yield('frame')end,
 SetTimeout=function(ms,fn)r.timers[#r.timers+1]=fn end,RegisterCommand=function(name,fn)r.commands[name]=fn end,
 RegisterKeyMapping=function(...)if r.mappingError then error('mapping failure')end;r.mappings[#r.mappings+1]=table.pack(...)end,
 TriggerEvent=function(...)r.trace[#r.trace+1]=table.pack(...)end,print=function()end});r.environment=env
 r.ports={prCore=r.core,environment=env,isCurrent=function()return r.current end,public={nativeCommand=function(name,fn)
 if r.foreign then return false end;r.commands[name]=fn end},running=coroutine.running,onError=error,
 createTasks=H.load('../pr_bridge/bridge/runtime/owned_tasks.lua',H.environment()),
 load=function(path,target)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target)end}
 if wrapped then r.factory=H.load(T.path,H.environment());r.api=r.factory(r.ports);assert(r.api.Open());r.lib=r.api.Keybind
 else r.lib=H.load('../pr_bridge/bridge/addKeybind/client.lua',env)end
 function r.fire(name)return assert(r.commands[name],name)()end
 function r.flush()for _,fn in ipairs(r.timers)do fn()end end
 return r
end
return T
