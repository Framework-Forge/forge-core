-- Explicit graph library view. Callback ownership is always122;no lazy legacy callback bootstrap.
return function(ports)
 local source,current=assert(ports.library),assert(ports.isCurrent)
 local callback=assert(ports.callback);assert(type(callback.await)=='function','owned graph callback required')
 local closed=false;local api={OperationalReady=false};local view={callback=callback}
 local forbidden={framework=true,module=true,originalRequire=true,require=true,package=true}
 local function live()local ok,v=pcall(current);return not closed and ok and v==true end
 local function guarded(value,seen)
  if type(value)=='function'then return function(...)assert(live(),'native graph library closed');return value(...)end end
  if type(value)~='table'then return value end
  seen=seen or{};if seen[value]then return seen[value]end
  local out={};seen[value]=out
  for k,v in pairs(value)do out[k]=guarded(v,seen)end
  local mt=getmetatable(value)
  if type(mt)=='table'and(type(mt.__index)=='table'or type(mt.__index)=='function')then
   setmetatable(out,{__index=function(_,k)assert(live(),'native graph library closed');return guarded(value[k],seen)end})
  end
  if type(mt)=='table'and type(mt.__call)=='function'then
   local own=getmetatable(out)or{};own.__call=function(_,...)assert(live(),'native graph library closed');return value(...)end;setmetatable(out,own)
  end
  return out
 end
 for name,value in pairs(assert(ports.extensions))do
  assert(not forbidden[name]and name~='callback','forbidden graph library field:'..name);view[name]=guarded(value)
 end
 for _,name in ipairs(assert(ports.fields))do
  assert(type(name)=='string'and not forbidden[name]and name~='callback','forbidden graph library field:'..tostring(name))
  if view[name]==nil then local value=assert(source[name],'installed graph library field missing:'..name);view[name]=guarded(value)end
 end
 for _,path in ipairs(ports.required or{})do
  local value=view;for part in path:gmatch('[^.]+')do value=type(value)=='table'and value[part]or nil end
  assert(type(value)=='function','graph library function missing:'..path)
 end
 api.Library=view
 function api.IsCurrent()return live()end
 function api.Close()closed=true;return true end
 return api
end
