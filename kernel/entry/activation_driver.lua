--266: one owned bounded retry worker;candidate retains authority over Start/Stop and barriers.
return function(p)
 local candidate,current=assert(p.candidate),assert(p.isCurrent)
 local maximum,interval=assert(p.maxAttempts),assert(p.interval)
 assert(type(maximum)=='number'and maximum%1==0 and maximum>=1 and maximum<=1000,'bounded activation attempts required')
 assert(type(interval)=='number'and interval>=1 and interval<=60000,'bounded retry interval required')
 local phase,attempts='allocated',0;local api={OperationalReady=false};local tasks
 local function progress()return tasks.Snapshot()end
 function api.Stop()
  if phase=='closed'then return true end;phase='closing';tasks.Close()
  local ok,value=pcall(candidate.Stop);if not ok then api.LastError=value;return false end
  if value==true and candidate.Progress().complete and progress().quiescent then phase='closed';return true end
  return false
 end
 function api.Poll()
  if phase=='closed'then return true end;if phase~='closing'then return false,'driver_not_stopping'end
  local ok,value=pcall(candidate.Poll)
  if not ok then api.LastError=value;return false end
  if value==true and candidate.Progress().complete and progress().quiescent then phase='closed';return true end
  return false
 end
 tasks=assert(p.createTasks)({running=assert(p.running),isCurrent=function()return phase=='running'and current()==true end,
 onError=function(err)api.LastError=err;api.Stop()end})
 local scheduler=tasks.WrapNative(assert(p.scheduler))
 function api.Run()
  if phase~='allocated'or current()~=true then return false,'activation_driver_not_allocated'end
  phase='running';assert(tasks.Open())
  local ok,why=tasks.Launch(scheduler,function()
   while phase=='running'and current()==true and attempts<maximum do
    attempts=attempts+1
    local accepted,reason=candidate.Activate();api.LastResult=reason
    if phase~='running'then return end
    if accepted==true then phase='committed';return end
    local state=candidate.Progress();local co=candidate.Coordinator
    if not co or state.phase=='closing'or state.phase=='closed'or co.Progress().closing then
     api.LastError=reason or'activation_refused';api.Stop();return
    end
    if attempts<maximum then scheduler.Wait(interval)end
   end
   if phase=='running'then api.LastError='activation_attempt_limit';api.Stop()end
  end)
  if ok==nil or ok==false then api.LastError=why;api.Stop();return false,why end;return true
 end
 function api.Progress()
  local s=progress()
  return{phase=phase,attempts=attempts,tasks=s,lastError=api.LastError,
   complete=phase=='closed'and s.quiescent and candidate.Progress().complete,operationalReady=false}
 end
 return api
end
