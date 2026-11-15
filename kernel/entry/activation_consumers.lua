--237: trusted controls may be local owners or explicit local-export proxies. Never impersonate a consumer.
return function(p)
 local side,generation,barrier=assert(p.side),assert(p.generation),assert(p.barrier)
 assert(side=='client'or side=='server');assert(barrier.Progress().generation==generation)
 local list,seen={},{}
 for _,item in ipairs(assert(p.consumers))do
  local name,c=assert(item.name),assert(item.control)
  assert(type(name)=='string'and name~=''and name~='forge-core'and name~='qbx_core'and not seen[name],'unique external consumer required')
  for _,key in ipairs({'Prepare','Attach','Describe','Close','Progress'})do assert(type(c[key])=='function','consumer control missing:'..key)end
  list[#list+1]={name=name,control=c};seen[name]=true
 end
 assert(#list>0,'consumers required')
 local phase,pending='allocated',0;local api={OperationalReady=false}
 local function valid()return phase~='closing'and phase~='closed'and p.isCurrent()==true end
 local function descriptor(e)
  local d=e.control.Describe()
  assert(type(d)=='table'and d.protocol=='forge-pr-consumer/1'and d.resource==e.name and d.side==side
   and d.generation==generation and type(d.instance)=='string'and d.instance~=''and d.current==true,'consumer identity mismatch')
  assert(not e.instance or e.instance==d.instance,'consumer instance replaced');return d
 end
 local function work(fn)
  pending=pending+1;local ok,why=pcall(fn);pending=pending-1
  if not ok then api.Close();return false,why end;return true
 end
 function api.Prepare()
  if phase~='allocated'or not valid()then return false end;phase='preparing'
  local ok,why=work(function()for _,e in ipairs(list)do
   assert(e.control.Prepare());assert(valid()and phase=='preparing')
   local d=descriptor(e);assert(d.phase=='prepared');e.instance=d.instance
  end end)
  if ok then phase='prepared'end;return ok,why
 end
 function api.Describe(name)
  for _,e in ipairs(list)do if e.name==name and valid()then return descriptor(e)end end
 end
 function api.IsPrepared()
  if not valid()or(phase~='prepared'and phase~='attaching'and phase~='attached')then return false end
  for _,e in ipairs(list)do local ok,d=pcall(descriptor,e);if not ok or(d.phase~='prepared'and d.phase~='attaching'and d.phase~='attached')then return false end end
  return true
 end
 function api.IsAttached()
  if phase~='attached'or not api.IsPrepared()then return false end
  local states=barrier.Progress().consumers
  for _,e in ipairs(list)do local d=descriptor(e);if d.phase~='attached'or d.proxyReady~=true or states[e.name]~='committed'then return false end end
  return true
 end
 function api.Attach()
  if phase~='prepared'or not valid()then return false end;phase='attaching'
  local ok,why=work(function()for _,e in ipairs(list)do
   assert(e.control.Attach());assert(valid()and phase=='attaching')
   local d=descriptor(e);assert(d.phase=='attached'and d.proxyReady==true and barrier.Progress().consumers[e.name]=='committed','consumer not admitted')
  end end)
  if ok then phase='attached'end;return ok,why
 end
 function api.Close()
  phase='closing';local clean=true
  for i=#list,1,-1 do local ok,v=pcall(list[i].control.Close);if not ok or v~=true then clean=false end end
  if clean and pending==0 then phase='closed'end;return api.Progress().complete
 end
 function api.Progress()
  local total,clean=pending,true
  for _,e in ipairs(list)do local s=e.control.Progress();total=total+(s.pending or 0);clean=clean and s.complete==true end
  return{phase=phase,pending=total,consumers=#list,complete=phase=='closed'and total==0 and clean,operationalReady=false}
 end
 return api
end
