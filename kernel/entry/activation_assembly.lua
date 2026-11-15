--238: compose operations/probes with one barrier. No implicit physical controls or approvals.
local createBarrier=require 'kernel.entry.activation_barrier'
local createReadiness=require 'kernel.entry.activation_readiness'
local createConsumers=require 'kernel.entry.activation_consumers'
local createPublication=require 'kernel.entry.activation_publication'
local createPlan=require 'kernel.entry.owned_activation_plan_v2'
return function(p)
 local generation,side=assert(p.generation),assert(p.side)
 local names={};for i,item in ipairs(assert(p.consumers))do names[i]=assert(item.name)end
 local readiness
 local probes={}
 for _,name in ipairs({'allocations','rawProviders','bootstrap','nativeAPI','compatIdentity','consumerBindings',
  'oxHooks','catalogs','banking','keys','decisions','environment'})do
  probes[name]=function(g)return readiness~=nil and readiness.Probes[name](g)or false end
 end
 local barrier=createBarrier({generation=generation,isCurrent=assert(p.isCurrent),consumers=names,probes=probes})
 local consumers=createConsumers({side=side,generation=generation,barrier=barrier,isCurrent=p.isCurrent,consumers=p.consumers})
 local publication=createPublication({side=side,generation=generation,barrier=barrier,consumers=names,
  describeConsumer=consumers.Describe,loadPR=assert(p.loadPR),createCompatibility=assert(p.createCompatibility),
  getInvokingResource=assert(p.getInvokingResource)})
 readiness=createReadiness({generation=generation,getCandidate=assert(p.getCandidate),publication=publication,consumers=consumers,external=assert(p.external)})
 local plan=createPlan({generation=generation,barrier=barrier,publication=publication,consumers=consumers,readiness=readiness})
 return{Plan=plan,Barrier=barrier,Consumers=consumers,Publication=publication,Readiness=readiness,OperationalReady=false}
end
