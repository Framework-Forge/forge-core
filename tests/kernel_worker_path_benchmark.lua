-- Local Lua benchmark, not a FiveM resmon measurement.
local T=dofile('tests/kernel_worker_harness.lua');local old=T.H.load
for _,before in ipairs({true,false})do
 T.H.load=function(path,env,...)
  if before and path=='kernel/client/worker_context.lua'then
   path='../../../../[NOVO BACK-UP]/painel-interface-20261030/forge-core/kernel/client/worker_context.lua'
  end
  return old(path,env,...)
 end
 local r=T.new();r.prepare();local check
 for i=1,30 do local name,value=debug.getupvalue(r.api.Start,i);if name=='canonical'then check=value;break end end
 assert(check and check())
 local t=os.clock();for i=1,10000 do assert(check())end
 print(before and 'BEFORE' or 'AFTER',os.clock()-t)
 local prior=r.graph.Parts.World.World.Threads[1];r.graph.Parts.World.World.Threads[1]=function()end
 assert(not check(),'changed worker accepted')
 r.graph.Parts.World.World.Threads[1]=prior;assert(check());r.api.Close();assert(not check(),'closed scope accepted')
end
T.H.load=old
