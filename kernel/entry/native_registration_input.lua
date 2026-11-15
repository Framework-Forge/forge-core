-- Physical registration inputs and deferred event references. Boundary99 owns every registration.
return function(ports)
 local side,n,current=assert(ports.side),assert(ports.native),assert(ports.isCurrent)
 assert(side=='server'or side=='client','registration input side required')
 assert(n.GetCurrentResourceName()=='forge-core'and (not not n.IsDuplicityVersion())==(side=='server'),'physical registration input mismatch')
 local closed,transport=false
 local function live()local ok,v=pcall(current);return not closed and ok and v==true end
 local function guard(fn)return function(...)assert(live(),'registration input closed');return fn(...)end end
 local input={native={},running=assert(ports.running),available=guard(assert(ports.available)),
  prCommand=guard(assert(ports.prCommand)),oxCommand=guard(assert(ports.oxCommand))}
 for _,name in ipairs({'GetCurrentResourceName','IsDuplicityVersion','AddEventHandler','RemoveEventHandler','RegisterNetEvent'})do
  input.native[name]=guard(assert(n[name],'physical registration function required:'..name))
 end
 local registerCommand=assert(n.RegisterCommand,'physical registration function required:RegisterCommand')
 assert(type(registerCommand)=='function','physical RegisterCommand function required')
 input.native.RegisterCommand=guard(function(...)
  -- Cfx REGISTER_COMMAND is void: its native invocation result is not a success/rejection flag.
  registerCommand(...)
  return true
 end)
 input.native.source=guard(assert(ports.getSource))
 input.native.publishExport=guard(assert(ports.publishExport))
 local function bound()assert(live(),'registration input closed');return assert(transport,'event transport not bound')end
 local api={Input=input,OperationalReady=false}
 api.Events={
  listen=function(...)return bound().Events.listen(...)end,
  remove=function(...)return bound().Events.remove(...)end,
  markNetwork=function(...)return bound().Events.markNetwork(...)end,
  source=function()if transport then return bound().Events.source()end;return input.native.source()end}
 function api.Bind(value)
  assert(live()and transport==nil,'registration transport already bound or closed')
  assert(value.Side==side and type(value.Events)=='table'and type(value.Progress)=='function','matching native transport required')
  for _,name in ipairs({'listen','remove','markNetwork','source'})do assert(type(value.Events[name])=='function','transport event function required')end
  transport=value;return true
 end
 function api.IsBound()return transport~=nil end
 function api.IsCurrent()return live()end
 function api.Close()
  if transport and not transport.Progress().complete then return false,'registration_transport_not_drained'end
  closed=true;return true
 end
 return api
end
