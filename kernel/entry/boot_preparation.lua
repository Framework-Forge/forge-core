-- Construction is explicit;missing/native-test inputs are refused before raw/seed/publication.
return function(ports)
 local contract,info=assert(ports.contract),assert(ports.inspectFunction);local side=assert(ports.side)
 local providers=ports.providers or{};local phase,pending='allocated',0;local options,report,raw,entry;local api={OperationalReady=false}
 local function refusal(reason,detail)return{accepted=false,operationalReady=false,semanticReadinessProven=false,issues={{path='providers.buildInput',reason=reason,detail=detail}},side=side}end
 local function snapshot(value)if type(value)~='table'then return value end;local out={};for k,v in pairs(value)do out[k]=snapshot(v)end;return out end
 function api.Inspect()
  if report then return snapshot(report)end
  if type(providers.buildInput)~='function'then report=refusal('native_builder_missing');return snapshot(report)end
  local ok,origin=pcall(info,providers.buildInput)
  local source=ok and type(origin)=='table'and origin.source
  if type(source)~='string'then report=refusal('builder_origin_unknown');return snapshot(report)end
  source=source:gsub('\\','/'):gsub('^@+','')
  if source:sub(1,6)=='tests/'or source:find('/tests/',1,true)or source:find('harness',1,true)then report=refusal('test_builder');return snapshot(report)end
  local out=table.pack(pcall(providers.buildInput,side))
  if not out[1]then report=refusal('builder_failed',tostring(out[2]));return snapshot(report)end
  options=out[2];report=contract.Inspect(options,side,info);return snapshot(report)
 end
 function api.Stop()
  if phase=='closed'then return true end;phase='closing'
  if entry then local ok,done=pcall(entry.Stop);if not ok or done~=true then return false end end
  if pending~=0 then return false end
  if raw then local ok,done=pcall(raw.Close);if not ok or done~=true then return false end end
  phase='closed';return true
 end
 function api.Poll()
  if phase=='closed'then return true end;if phase~='closing'then return false,'candidate_not_stopping'end
  if entry then local ok,done=pcall(entry.Poll);if not ok or done~=true then return false end end;return api.Stop()
 end
 function api.Prepare()
  if phase~='allocated'then return false,'candidate_prepare_unavailable'end
  local r=api.Inspect();if not r.accepted then return false,r end
  if providers.constructionApproved~=true then return false,'candidate_construction_not_approved'end
  phase='preparing';pending=pending+1
  local ok,err=pcall(function()
   raw=assert(ports.createRaw)({isCurrent=options.isCurrent,namespaceAvailable=options.bootstrap.registration.available,
    beforeClose=function()return not entry or entry.Stop()end})
   local ready,why=raw.Prepare();assert(ready,why or'candidate raw preparation refused')
   entry=assert(ports.createEntry)(raw,options)
   ready,why=entry.Prepare(providers.localeKey);assert(ready,why or'candidate profile preparation refused')
  end);pending=pending-1
  if not ok or phase~='preparing'then api.Stop();return false,ok and'candidate_prepare_cancelled'or err end
  phase='prepared';return true
 end
 local function run(name,expected,nextPhase,approval)
  if phase~=expected or providers[approval]~=true then return false,'candidate_'..name:lower()..'_not_approved_or_unavailable'end
  phase=name:lower()..'ing';local working=phase;pending=pending+1
  local out=table.pack(pcall(entry[name]));pending=pending-1
  if not out[1]or out[2]~=true or phase~=working then api.Stop();return false,out[1]and(out[3]or'candidate_operation_cancelled')or out[2]end
  phase=nextPhase;return table.unpack(out,2,out.n)
 end
 function api.Install()return run('Install','prepared','installed','installApproved')end
 function api.Start()return run('Start','installed','running','startApproved')end
 function api.Progress()return{phase=phase,pending=pending,entry=entry and entry.Progress(),complete=phase=='closed'and pending==0,inputs=snapshot(report),operationalReady=false}end
 return api
end
