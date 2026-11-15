--235: one publication owner over the prepared graph; compatibility is an explicit owned factory.
local nativeAPI=require 'kernel.compat.qbx.pr_native_api'
local admissionBinding=require 'kernel.entry.consumer_admission_binding'
return function(p)
 local side,generation,barrier=assert(p.side),assert(p.generation),assert(p.barrier)
 assert(side=='server'or side=='client');assert(barrier.Progress().generation==generation)
 local phase,pending='allocated',0;local entry,graph,compat,admission,native,control
 local children={};local api={OperationalReady=false}
 local function current()return phase~='closing'and phase~='closed'and entry and entry.IsCurrent()==true end
 local function track(fn,...)
  pending=pending+1;local out=table.pack(pcall(fn,...));pending=pending-1
  if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
 end
 local function own(child)
  assert(type(child)=='table'and type(child.Close)=='function'and type(child.Progress)=='function','owned publication child required')
  children[#children+1]=child;return child
 end
 function api.Prepare(candidate)
  if phase~='allocated'then return false,'publication_not_allocated'end;phase='preparing'
  local ok,why=pcall(track,function()
   assert(candidate.GetPreparedBarrier()==barrier,'publication barrier mismatch')
   entry=assert(candidate.GetPreparedEntry());graph=assert(entry.Bootstrap.Graph)
   assert(current(),'prepared graph not current')
   -- Must return the existing graph's origin; a second origin scope would lose caller identity.
   compat=own(assert(p.createCompatibility)(graph,side,entry))
   assert(compat.Graph==graph and compat.IsCurrent()and type(compat.Install)=='function'
    and type(compat.IsReady)=='function','compatibility graph mismatch')
   local origin=assert(compat.Origin);assert(origin.IsCurrent(),'canonical origin required')
   local factory=assert(p.loadPR)('@forge-core/kernel/pr_integration/consumer_admission_factory.lua')
   admission=own(factory(barrier,{generation=generation,side=side,consumers=p.consumers,
    isCurrent=current,describe=assert(p.describeConsumer),getInvokingResource=assert(p.getInvokingResource),
    invalidate=barrier.Close}))
   native=own(nativeAPI(graph,side,origin,{generation=generation,isCurrent=current,isReady=barrier.CanServe,
    getInvokingResource=p.getInvokingResource,isConsumerAllowed=admission.IsAllowed,
    getCoreObject=compat.GetCoreObject,public=entry.Bootstrap.Transport.Public}))
   control=own(admissionBinding(admission,{side=side,isCurrent=current,public=entry.Bootstrap.Transport.Public}))
   assert(current()and phase=='preparing','publication closed during preparation')
  end)
  if not ok then api.Close();return false,why end;phase='prepared';return true
 end
 function api.ObservePrepared()
  if phase~='prepared'or not current()then return false end
  local ok,value=pcall(track,admission.ObservePrepared)
  if not ok or value~=true then api.Close();return false,value end;return true
 end
 function api.Install()
  if phase~='prepared'or not current()then return false,'publication_not_prepared'end;phase='installing'
  local ok,why=pcall(track,function()
   assert(compat.Install());assert(current()and phase=='installing')
   assert(native.Install());assert(current()and phase=='installing')
   assert(control.Install());assert(current()and phase=='installing')
  end)
  if not ok then api.Close();return false,why end;phase='installed';return true
 end
 function api.IsInstalled()
  return phase=='installed'and current()and compat.IsCurrent()
   and compat.Progress().phase=='installed'and native.Progress().phase=='installed'and control.Progress().phase=='installed'
 end
 function api.CompatibilityReady()return api.IsInstalled()and compat.IsReady()==true end
 function api.Close()
  phase='closing';local clean=true
  for i=#children,1,-1 do local ok,value=pcall(children[i].Close);if not ok or value~=true then clean=false end end
  if pending==0 and clean then phase='closed'end
  return api.Progress().complete
 end
 function api.Progress()
  local total,clean=pending,true;local snapshots={}
  for i,c in ipairs(children)do local s=c.Progress();snapshots[i]=s;total=total+(s.pending or 0);clean=clean and s.complete==true end
  return{phase=phase,pending=total,children=snapshots,complete=phase=='closed'and total==0 and clean,operationalReady=false}
 end
 return api
end
