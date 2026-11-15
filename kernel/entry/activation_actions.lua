-- A-F action ownership around118. Real probes remain with the supplied barrier.
return function(p)
 local barrier,steps,info=assert(p.barrier),assert(p.steps),assert(p.inspectFunction)
 local generation=assert(p.generation);assert(barrier.Progress().generation==generation,'activation generation mismatch')
 assert(#steps==6,'six explicit activation actions required')
 local list={};for i=1,6 do local s=assert(steps[i]);assert(type(s.name)=='string'and s.name~='','activation name required')
  for _,key in ipairs({'run','close'})do
   assert(type(s[key])=='function','explicit activation action required')
   local origin=info(s[key]);local source=assert(origin and origin.source,'action origin required'):gsub('\\','/'):gsub('^@+','')
   assert(not source:find('/tests/',1,true)and source:sub(1,6)~='tests/'and not source:find('harness',1,true),'test activation action refused')
  end
  list[i]={name=s.name,run=s.run,close=s.close,started=false,accepted=false,closed=false}
 end
 local stage,pending,busy,closing=0,0,false,false;local api={OperationalReady=false}
 function api.Close()
  closing=true;barrier.Close() -- Revoke admissions before a yielding cleanup.
  if busy or pending~=0 then return false end
  local done=true
  for i=6,1,-1 do local s=list[i];if s.started and not s.closed then
   local ok,v=pcall(s.close);s.closed=ok and v==true;done=s.closed and done
  end end
  return done and barrier.Progress().complete
 end
 function api.Advance(nextStage)
  if closing or busy or nextStage~=stage+1 or nextStage>6 then return false,'activation_action_unavailable'end
  busy=true;pending=pending+1;local s=list[nextStage];local reason
  local ok,result=pcall(function()
   if not s.accepted then s.started=true;local accepted,why=s.run(barrier,generation)
    if accepted~=true then reason=why or'action_refused';return false end;s.accepted=true
   end
   if closing then return false end
   local passed,why=barrier.Advance(nextStage);reason=why;return passed==true
  end)
  pending=pending-1;busy=false
  if not ok or closing or not s.accepted then api.LastError=ok and reason or result;api.Close();return false,api.LastError end
  if result~=true then return false,reason end -- Probe pending:retry only probes,never repeat accepted work.
  stage=nextStage;return true
 end
 function api.Run()
  for i=stage+1,6 do local ok,why=api.Advance(i);if not ok then return false,why end end
  return barrier.IsIngressOpen()
 end
 function api.Progress()
  local states={};local complete=closing and not busy and pending==0 and barrier.Progress().complete
  for i,s in ipairs(list)do states[i]={name=s.name,started=s.started,accepted=s.accepted,closed=s.closed};complete=complete and(not s.started or s.closed)end
  return{stage=stage,pending=pending,busy=busy,closing=closing,steps=states,barrier=barrier.Progress(),complete=complete,lastError=api.LastError,operationalReady=false}
 end
 return api
end
