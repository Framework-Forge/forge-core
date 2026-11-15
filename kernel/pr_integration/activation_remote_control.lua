--247: Forge-side local Cfx export proxy;never access another resource's PRCore.
return function(p)
 local n=assert(p.native);assert(n.GetCurrentResourceName()=='forge-core','control proxy belongs to Forge')
 local side=n.IsDuplicityVersion()and'server'or'client'
 local resource,generation,instance=assert(p.resource),assert(p.generation),assert(p.instance)
 assert(type(resource)=='string'and resource~=''and resource~='forge-core'and resource~='qbx_core')
 assert(type(generation)=='string'and generation~=''and type(instance)=='string'and instance~='')
 local control=assert(PRCore).load('@pr_bridge/bridge/runtime/forge/control_client',_ENV)({external=p.external})
 local phase,pending,busy='allocated',0,false;local remote;local api={OperationalReady=false}
 local function current(cleanup)return phase~='closed'and(phase~='closing'or cleanup==true)and p.isCurrent()==true and n.GetCurrentResourceName()=='forge-core'end
 local function call(op)
  assert(current(op=='Close'or op=='Progress'),'consumer control proxy closed')
  return control.Call(resource,op,generation,instance)
 end
 local function progress()
  local ok,value=pcall(call,'Progress')
  if ok and type(value)=='table'and type(value.pending)=='number'and value.pending>=0
   and type(value.phase)=='string'and type(value.complete)=='boolean'then remote=value
  else remote={phase='unobservable',pending=0,complete=false}end
  return remote
 end
 local function describe()
  local d=call('Describe')
  assert(type(d)=='table'and d.protocol=='forge-pr-consumer/1'and d.generation==generation
   and d.resource==resource and d.instance==instance and d.side==side and d.current==true,'remote consumer identity mismatch')
  return d
 end
 function api.Describe()if not current()then return end;return describe()end
 function api.Close()
  if phase=='closed'then return true end
  phase='closing';if busy then return false end;busy=true
  local ok,v=pcall(call,'Close');local status=progress();busy=false
  if ok and v==true and status.complete==true and status.phase=='closed'and pending==0 then phase='closed'end
  return api.Progress().complete
 end
 function api.Progress()
  local s=phase=='closed'and remote or progress()
  return{phase=phase,pending=pending+(s and s.pending or 0),remote=s,busy=busy,
   complete=phase=='closed'and pending==0 and not busy and s and s.complete==true,operationalReady=false}
 end
 local function action(name,from,active,to)
  if phase~=from or not current()then return false end;phase=active;pending=pending+1
  local ok,why=pcall(function()
   local before=describe()
   -- The operational PR entry prepares its host while answering the first Describe.
   -- Adopt only that exact prepared instance; never replay its allocations.
   local prepared=name=='Prepare'and before.phase=='prepared'
   assert(before.phase==from or prepared,('remote consumer phase mismatch: %s %s expected %s%s, got %s'):format(
    resource,name,from,name=='Prepare'and' or prepared'or'',tostring(before.phase)))
   if not prepared then
    local accepted,why=call(name);assert(accepted==true,why or'remote control operation refused')
   end
   assert(current()and phase==active)
   local d=describe();assert(d.phase==to and(to~='attached'or d.proxyReady==true),'remote commit not observed')
  end);pending=pending-1
  if not ok then api.Close();return false,why end
  phase=to;return true
 end
 function api.Prepare()return action('Prepare','allocated','preparing','prepared')end
 function api.Attach()return action('Attach','prepared','attaching','attached')end
 return api
end
