--229 links the prepared core and explicit physical A-F actions,never bypassing118 for Start.
local create=require 'kernel.entry.owned_boot_preparation_v2'
local actions=require 'kernel.entry.activation_actions_v2'
return function(p)
 local candidate=create(p);local stop,poll,start=candidate.Stop,candidate.Poll,candidate.Start
 local providers=p.providers or{};local coordinator,barrier,stopping,closeRequested
 function candidate.ClosePreparedCore()closeRequested=true;return stop()end -- Explicit stage-A cleanup capability for the trusted action plan.
 function candidate.Activate()
  if providers.constructionApproved~=true or providers.installApproved~=true or providers.startApproved~=true then return false,'activation_not_approved'end
  local report=candidate.Inspect();if not report.accepted then return false,report end
  local plan=providers.activation
  if type(plan)~='table'or type(plan.steps)~='table'or type(plan.barrier)~='table'then return false,'physical_activation_plan_missing'end
  if not coordinator then
   barrier=plan.barrier;local steps={}
   for i=1,6 do local input=assert(plan.steps[i],'activation action missing');local run=assert(input.run)
    -- Inspect the actual supplied body before replacing it by a canonical-identity check.
    local origin=p.inspectFunction(run);local source=assert(origin and origin.source):gsub('\\','/'):gsub('^@+','')
    assert(not source:find('/tests/',1,true)and source:sub(1,6)~='tests/'and not source:find('harness',1,true),'test activation body refused')
    steps[i]={name=input.name,close=input.close,before=input.before,run=function(b,g)
     local ok,why=run(b,g,candidate);if ok~=true then return false,why end
     local entry,raw=candidate.GetPreparedEntry(),candidate.GetPreparedRaw()
     assert(entry and raw and candidate.GetPreparedBarrier()==b,'activation/core barrier identity mismatch')
     if i==1 then assert(entry.Foundation and entry.Profile.Seed==entry.Foundation.Seed,'activation foundation identity mismatch')end
     if i==2 then assert(raw.Services.Progress().phase=='open','raw providers not open')end
     if i==3 then local phase=entry.Bootstrap.Progress().phase;assert(phase=='installed'or phase=='running','bootstrap not installed')end
     if i==6 and entry.Capabilities then assert(entry.Capabilities.IsReady(),'physical client capabilities not ready')end
     return true
    end}
   end
   coordinator=actions({generation=plan.generation,barrier=barrier,steps=steps,inspectFunction=p.inspectFunction})
   candidate.Coordinator=coordinator
  end
  local ok,why=coordinator.Run();if not ok then return false,why end
  return candidate.Start()
 end
 function candidate.StartPreparedCore()
  if not coordinator or providers.startApproved~=true then return false,'prestart_not_approved'end
  local progress=coordinator.Progress()
  if progress.closing or progress.stage~=5 or not progress.busy or not progress.steps[6].started
   or progress.steps[6].accepted or candidate.GetPreparedBarrier()~=barrier then return false,'prestart_outside_owned_phase'end
  if candidate.Progress().phase=='running'then return true end
  return start()
 end
 function candidate.Start()
  if not coordinator or not barrier.IsIngressOpen()then return false,'activation_barrier_not_open'end
  if candidate.GetPreparedBarrier()~=barrier then return false,'activation_barrier_identity_mismatch'end
  if candidate.Progress().phase=='running'then return true end
  return start()
 end
 function candidate.Stop()
  closeRequested=true
  if stopping then return false,'activation_cleanup_in_progress'end
  stopping=true
  local ok,result=pcall(function()if coordinator and not coordinator.Close()then return false end;if candidate.Progress().phase=='closed'then return true end;return stop()end)
  stopping=false;if not ok then return false,result end;return result
 end
 function candidate.Poll()
  local phase=candidate.Progress().phase
  if phase=='closed'then return true end
  local failed=coordinator and coordinator.Progress().closing==true
  if not closeRequested and phase~='closing'and not failed then return false,'candidate_not_stopping'end
  closeRequested=true
  if coordinator and not coordinator.Close()then return false end
  if candidate.Progress().phase=='closed'then return true end
  if candidate.Progress().phase~='closing'then return candidate.Stop()end
  return poll()
 end
 return candidate
end
