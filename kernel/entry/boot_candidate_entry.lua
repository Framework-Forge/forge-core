-- Operational definition276:one foundation/origin,concrete compatibility and guarded prestart.No automatic approvals.
assert(GetCurrentResourceName()=='forge-core','candidate must execute inside Forge')
assert(type(PRCore)=='table'and PRCore.forgeBootCandidate==nil,'fresh local PR candidate required')
local function module(path)
 local source=assert(LoadResourceFile('forge-core',path),'missing candidate module:'..path)
 local env=setmetatable({},{__index=_ENV})
 env.require=function(name)return module(name:gsub('%.','/')..'.lua')end
 return assert(load(source,'@@forge-core/'..path,'t',env))()
end
local server=IsDuplicityVersion();local side=server and'server'or'client'
local providers=rawget(PRCore,'forgeBootProviders')
local candidate,assembly,activationProfile
if providers and providers.activationProfile~=nil then
 activationProfile=PRCore.load('@forge-core/kernel/pr_integration/activation_profile',_ENV)(providers.activationProfile)
end
local function physicalCurrent()
 local q=providers and providers.physicalOptions
 return q and type(q.isCurrent)=='function'and q.isCurrent()==true or false
end
local origin=module('kernel/entry/activation_origin.lua')({running=coroutine.running,
 getInvokingResource=GetInvokingResource,isCurrent=physicalCurrent})
local p={side=side,originOwner=origin,providers=providers,inspectFunction=function(fn)return debug.getinfo(fn,'S')end,
 createRaw=function(options)return PRCore.load('@forge-core/kernel/pr_integration/raw_entry',_ENV)(options)end}
if providers and rawget(providers,'activationAssembly')~=nil then
 assert(providers.activation==nil,'ambiguous activation plans')
 local physical={};for k,v in pairs(assert(providers.physicalOptions,'physical options required'))do physical[k]=v end
 assert(physical.barrier==nil,'assembly owns the only activation barrier')
 local input={};for k,v in pairs(providers.activationAssembly)do input[k]=v end
 if activationProfile then
  assert(input.consumerSpecs==nil and input.consumers==nil,'profile owns consumer selection')
  assert(input.generation==nil or input.generation==activationProfile.Generation,'profile generation mismatch')
  input.generation=activationProfile.Generation;input.consumerSpecs=activationProfile.Consumers(side)
 end
 if input.effectProofs then
  assert(input.external==nil,'ambiguous external readiness proofs')
  input.external=module('kernel/entry/physical_readiness_evidence.lua')({side=side,generation=input.generation,proofs=input.effectProofs})
 end
 input.side=side;input.getCandidate=function()return candidate end
 input.getInvokingResource=GetInvokingResource
 input.loadPR=function(path)if path:sub(1,1)~='@'then path='@pr_bridge/'..path end;return PRCore.load(path,_ENV)end
 if input.consumerSpecs then
  assert(input.consumers==nil,'ambiguous consumer controls');input.consumers={}
  local create=PRCore.load('@forge-core/kernel/pr_integration/activation_remote_control',_ENV)
  for i,spec in ipairs(input.consumerSpecs)do input.consumers[i]={name=spec.name,control=create({
   native={GetCurrentResourceName=GetCurrentResourceName,IsDuplicityVersion=IsDuplicityVersion},external=exports,
   resource=spec.name,generation=input.generation,instance=spec.instance,isCurrent=physicalCurrent})}end
 end
 if input.createCompatibility==nil then
  local makePorts=module('kernel/entry/compatibility_physical_ports_v5.lua')({environment=_ENV,isCurrent=physicalCurrent,
   getRaw=function()return candidate.GetPreparedRaw()end,sharedConfig=providers.compatibilitySharedConfig,
   legacyConversion=providers.legacyConversion})
  input.createCompatibility=function(graph,which,entry)
   return module('kernel/entry/activation_compatibility.lua')(graph,which,entry,{generation=input.generation,
    barrier=assembly.Barrier,makePorts=makePorts,getInvokingResource=GetInvokingResource,
    aliasAvailable=function(name)return physical.registration.available('event',name)end})
  end
 end
 assembly=module('kernel/entry/activation_assembly_v2.lua')(input)
 local selected={};for k,v in pairs(providers)do selected[k]=v end
 selected.activation=assembly.Plan;physical.barrier=assembly.Barrier;selected.physicalOptions=physical
 providers=selected;p.providers=selected
end
if providers and rawget(providers,'physicalOptions')~=nil then
 assert(rawget(providers,'buildInput')==nil,'ambiguous boot input builders')
 local controls={};for k,v in pairs(providers.physicalOptions)do controls[k]=v end
 controls.environment,controls.prCore,controls.originOwner=_ENV,PRCore,origin
 local selected={};for k,v in pairs(providers)do selected[k]=v end
 selected.buildInput=module('kernel/entry/physical_boot_options_v5.lua')(controls);p.providers=selected
end
candidate=module('kernel/entry/coordinated_boot_preparation_v8.lua')(p)
if assembly then candidate.Activation=assembly end
if activationProfile then candidate.ActivationProfile=activationProfile end
PRCore.forgeBootCandidate=candidate
-- Activation is owned by core_activation_runtime;construction of this definition does not start A-F.
