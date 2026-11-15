local H=dofile('tests/kernel_harness.lua')
local create=H.load('kernel/pr_integration/core_activation_runtime.lua',H.environment())
local tasks=H.load('../pr_bridge/bridge/runtime/owned_tasks.lua',H.environment())
for _,case in ipairs({'throw','declined','inputs','timeout','cleanup','retry'})do
 local now,attempts,stops=0,0,0;local threads,logs,states={},{},{}
 local failed,open=false,false
 local candidate={GetPreparedEntry=function()end,Progress=function()return{phase=failed and'closing'or'allocated'}end,
  Coordinator={Progress=function()return{stage=2,closing=failed,steps={{name='A'},{name='B'},{name='C'}}}end},
  Activation={Barrier={Progress=function()return{stage=open and 6 or 2,ingressOpen=open}end}},
  Stop=function()stops=stops+1;if case=='cleanup'then error('cleanup-specific')end;return true end,Poll=function()return true end}
 candidate.Activate=function()
  attempts=attempts+1
  if case=='throw'or case=='cleanup'then error('provider-specific')end
  if case=='inputs'then return false,{accepted=false,issues={{path='builder',reason='refused',detail='input-specific'}}}end
  if case=='declined'then failed=true;return false,'prepare-specific'end
  if case=='retry'and attempts==2 then open=true;return true end
  return false,{'catalogs'}
 end
 local env=H.environment({IsDuplicityVersion=function()return 1 end,coroutine=coroutine,
  GetGameTimer=function()return now end,print=function(s)logs[#logs+1]=s end,
  CreateThread=function(fn)threads[#threads+1]=coroutine.create(fn)end,Wait=function()coroutine.yield()end,
  AddEventHandler=function()return 1 end,RemoveEventHandler=function()return true end,
  exports={consumer={ForgePrActivationControl=function()return{current=true,generation='diagnostic',instance='one',providersReady=true,phase='prepared'}end}}})
 env.PRCore={load=function(path,e)
  assert(path=='@pr_bridge/bridge/runtime/forge/control_client')
  return H.load('../pr_bridge/bridge/runtime/forge/control_client.lua',e)
 end}
 local config={IsCurrent=function()return true end,Ready=function()return true end,Close=function()return true end,
  PhysicalOptions={registration={publishExport=function(name,fn)assert(name=='ForgeRuntimeStatus');return true end}}}
 local owner=create({environment=env,candidate=candidate,configuration=config,profile={Generation='diagnostic',Consumers=function()return{{name='consumer',instance='one'}}end},
  timeout=1000,interval=1,createTasks=tasks,publishState=function(s)states[#states+1]=s end})
 assert(#threads==0 and attempts==0)
 assert(owner.Run());assert(coroutine.resume(threads[1]))
 if coroutine.status(threads[1])~='dead'then now=case=='timeout'and 1001 or 1;assert(coroutine.resume(threads[1]))end
 assert(coroutine.status(threads[1])=='dead')
 if case=='retry'then
  assert(owner.Status().phase=='running'and open and stops==0 and attempts==2)
 else
  local expected=({throw='provider-specific',cleanup='provider-specific',declined='prepare-specific',inputs='input-specific',timeout='activation timed out'})[case]
  assert(owner.Status().phase=='failed'and not owner.Status().ingressOpen and stops==1)
  assert(owner.Status().error:find(expected,1,true)and states[#states].error==owner.Status().error)
  assert(logs[1]:find(expected,1,true)and logs[1]:find('[C]',1,true),'console must show the original failure and stage')
  assert(#logs==(case=='cleanup'and 2 or 1),'root failure must be printed once')
  if case=='cleanup'then assert(logs[2]:find('cleanup-specific',1,true))end
 end
end
local prepare=H.load('kernel/entry/boot_preparation.lua',H.environment())
for _,failure in ipairs({'raw','profile','Install','Start'})do
 local providers={constructionApproved=true,installApproved=true,startApproved=true,
  buildInput=function()return{isCurrent=function()return true end,bootstrap={registration={available=function()return true end}}}end}
 local function result(name)if failure==name then return false,'specific-'..name end;return true end
 local entry={Prepare=function()return result('profile')end,Install=function()return result('Install')end,Start=function()return result('Start')end,
  Stop=function()return true end,Poll=function()return true end,Progress=function()return{}end}
 local owner=prepare({side='server',contract={Inspect=function()return{accepted=true}end},providers=providers,
  inspectFunction=function()return{source='@@forge-core/entry.lua'}end,
  createRaw=function()return{Prepare=function()return result('raw')end,Close=function()return true end}end,createEntry=function()return entry end})
 local ok,why=owner.Prepare()
 if failure=='Install'or failure=='Start'then assert(ok);ok,why=owner.Install()end
 if failure=='Start'then assert(ok);ok,why=owner.Start()end
 assert(ok==false and why:find('specific-'..failure,1,true),'original refusal must survive '..failure)
 assert(owner.Progress().complete)
end
print('PASS boot failures: original errors, stage logging, cleanup failure isolation, timeout, pending retry and four preparation/lifecycle refusals')
