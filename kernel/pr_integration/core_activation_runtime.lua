--276: the actual resource boot waits for dependencies/consumer declarations before running A-F.
return function(p)
 local e,candidate,profile=assert(p.environment),assert(p.candidate),assert(p.profile)
 local control=assert(e.PRCore).load('@pr_bridge/bridge/runtime/forge/control_client',e)({external=e.exports})
 local config=assert(p.configuration);local maximum,interval=assert(p.timeout),assert(p.interval)
 assert(maximum>=1000 and maximum<=600000 and interval>=1 and interval<=1000,'bounded boot timing required')
 local phase,attempts,problem='allocated',0;local tasks;local token;local waitingFor;local visual;local posture;local api={OperationalReady=false}
 local publishState=p.publishState or function()end
 local function current()return phase~='closed'and config.IsCurrent()end
 local function fail(reason)
  if phase=='failed'then return end
  problem=tostring(reason);phase='failed'
  local progress=candidate.Coordinator and candidate.Coordinator.Progress()
  local step=progress and progress.steps and progress.steps[(progress.stage or 0)+1]
  e.print(('[forge-core] Falha na inicializaÃ§Ã£o%s: %s'):format(step and(' ['..step.name..']')or'',problem))
  publishState(api.Status())
  if posture then pcall(posture.Close);posture=nil end
  if visual then pcall(visual.Close);visual=nil end
  local ok,err=pcall(candidate.Stop)
  if not ok then e.print('[forge-core] Falha adicional na limpeza: '..tostring(err))end
 end
 tasks=assert(p.createTasks)({running=e.coroutine.running,isCurrent=function()return phase=='waiting'or phase=='activating'end,
 onError=fail})
 local scheduler=tasks.WrapNative({CreateThread=e.CreateThread,Wait=e.Wait})
 local function declarations()
  waitingFor=nil
  if not config.Ready()then waitingFor='core dependencies';return false end
  for _,spec in ipairs(profile.Consumers(e.IsDuplicityVersion()and'server'or'client'))do
   local ok,d=pcall(function()return control.Call(spec.name,'Describe',profile.Generation,spec.instance)end)
   if not ok or type(d)~='table'or d.current~=true or d.generation~=profile.Generation or d.instance~=spec.instance
    or d.providersReady~=true or d.phase~='prepared'then
     local reason=not ok and'Describe failed'or type(d)~='table'and'no descriptor'or d.current~=true and'not current'
      or d.generation~=profile.Generation and'generation mismatch'or d.instance~=spec.instance and'instance mismatch'
      or d.providersReady~=true and'providers not ready'or('phase '..tostring(d.phase))
     waitingFor='consumer '..spec.name..' ('..reason..')';return false
    end
  end
  return true
 end
 function api.Status()
  local barrier=candidate.Activation and candidate.Activation.Barrier.Progress()
  local entry=candidate.GetPreparedEntry();local started=entry and entry.Bootstrap.Progress().phase=='running'or false
  return{generation=profile.Generation,phase=phase,stage=barrier and barrier.stage or 0,ingressOpen=barrier and barrier.ingressOpen==true or false,
   coreStarted=started,attempts=attempts,error=problem,waitingFor=waitingFor}
 end
 function api.Run()
  if phase~='allocated'or not current()then return false end;phase='waiting';assert(tasks.Open())
  token=e.AddEventHandler(e.IsDuplicityVersion()and'onResourceStop'or'onClientResourceStop',function(name)if name=='forge-core'then api.Close()end end)
  assert(token~=nil and token~=false)
  local published=config.PhysicalOptions.registration.publishExport('ForgeRuntimeStatus',api.Status)
  assert(published~=false,'runtime status publication refused')
  local launched=tasks.Launch(scheduler,function()
   local begin=e.GetGameTimer()
   while phase=='waiting'and current()and not declarations()do
    assert(e.GetGameTimer()-begin<maximum,'Forge dependencies/consumer preparation timed out'..(waitingFor and': '..waitingFor or''));scheduler.Wait(interval)
   end
   if phase~='waiting'or not current()then return end;phase='activating'
   while phase=='activating'and current()do
    attempts=attempts+1;local ok,why=candidate.Activate()
    if ok then
     if p.createVisualDelivery then
      visual=p.createVisualDelivery(e,assert(e.PRCore.forgeOwnedCallbacks));assert(visual.Start())
     end
     if p.createPosture then
      posture=p.createPosture(e,assert(e.PRCore.forgeOwnedCallbacks),assert(candidate.GetPreparedEntry()));assert(posture.Start())
     end
     phase='running';publishState(api.Status());e.print(('[forge-core] InicializaÃ§Ã£o concluÃ­da (%s).'):format(profile.Generation));return
    end
    local co=candidate.Coordinator
    if type(why)=='table'and why.accepted==false then
     local issues={};for _,v in ipairs(why.issues or{})do issues[#issues+1]=tostring(v.path)..':'..tostring(v.reason)..(v.detail and' ('..tostring(v.detail)..')'or'')end
     fail('boot input refused: '..table.concat(issues,', '));return
    end
    if not co or co.Progress().closing or candidate.Progress().phase=='closed'or candidate.Progress().phase=='closing'then
     fail(type(why)=='string'and why or(co and co.Progress().lastError)or'activation refused');return
    end
    assert(e.GetGameTimer()-begin<maximum,'Forge activation timed out');scheduler.Wait(interval)
   end
  end)
  return launched~=nil and launched~=false
 end
 function api.Close()
  if posture then assert(posture.Close());posture=nil end
  if visual then assert(visual.Close());visual=nil end
  phase='closing';publishState({generation=profile.Generation,phase=phase,ingressOpen=false});tasks.Close()
  local done=candidate.Stop()or candidate.Poll()
  if not done or not tasks.Snapshot().quiescent then return false end
  if token then local result=e.RemoveEventHandler(token);if result==false then return false end;token=nil end
  if not config.Close()then return false end;phase='closed';return true
 end
 function api.Poll()if phase=='closed'then return true end;if phase~='closing'then return false end;candidate.Poll();return api.Close()end
 function api.Progress()return{phase=phase,error=problem,tasks=tasks.Snapshot(),complete=phase=='closed'and token==nil,operationalReady=false}end
 return api
end
