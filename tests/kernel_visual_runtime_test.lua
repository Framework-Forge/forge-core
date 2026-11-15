local create=dofile('kernel/pr_integration/core_activation_runtime.lua')
local tasks=dofile('../pr_bridge/bridge/runtime/owned_tasks.lua')
for _,broken in ipairs({false,true})do
 local threads,events,trace={},{},{}
 local rpc={};local running=false
 local e={PRCore={forgeOwnedCallbacks=rpc},coroutine=coroutine,IsDuplicityVersion=function()return false end,
  GetGameTimer=function()return 0 end,print=function()end,CreateThread=function(fn)threads[#threads+1]=fn end,
  Wait=function()error('unexpected wait')end,AddEventHandler=function(_,fn)events[#events+1]=fn;return #events end,RemoveEventHandler=function()end}
 e.PRCore.load=function()return function()return{Call=function()error('no consumers')end}end end
 local candidate={GetPreparedEntry=function()return{Bootstrap={Progress=function()return{phase='running'}end}}end,
  Activation={Barrier={Progress=function()return{stage=6,ingressOpen=true}end}},
  Activate=function()trace[#trace+1]='activate';running=true;return true end,
  Stop=function()trace[#trace+1]='stop';running=false;return true end,Poll=function()return true end}
 local api=create({environment=e,candidate=candidate,profile={Generation='test',Consumers=function()return{}end},
  configuration={IsCurrent=function()return true end,Ready=function()return true end,Close=function()return true end,
   PhysicalOptions={registration={publishExport=function()return true end}}},timeout=1000,interval=1,createTasks=tasks,
  createVisualDelivery=function(env,owned)
   assert(env==e and owned==rpc and running,'delivery started before core')
   return{Start=function()trace[#trace+1]='visual';if broken then error('visual failed')end;return true end,
    Close=function()trace[#trace+1]='visual-close';return true end}
  end})
 assert(api.Run());threads[1]()
 assert(trace[1]=='activate'and trace[2]=='visual')
 if broken then assert(api.Status().phase=='failed'and trace[3]=='visual-close'and trace[4]=='stop')
 else assert(api.Status().phase=='running');assert(api.Close());assert(trace[3]=='visual-close'and trace[4]=='stop')end
end
print('PASS visual delivery wired after activation; delivery cleanup precedes core shutdown on success and failure')
