--278: real Cfx composition;the definition allocates nothing until the owned runtime starts A-F.
assert(GetCurrentResourceName()=='forge-core','Forge authority required')
assert(GetConvar('forge:kernel','false')=='true','explicit Forge kernel profile required')
local pr=assert(PRCore);assert(pr.forgeCoreBootstrap and not pr.forgeOperationalRuntime,'fresh minimal PR bootstrap required')
local function loadPR(path)if path:sub(1,1)~='@'then path='@pr_bridge/'..path end;return pr.load(path,_ENV)end
local function module(path)
 local source=assert(LoadResourceFile('forge-core',path),'missing Forge module:'..path)
 local env=setmetatable({},{__index=_ENV})
 env.require=function(name)return module(name:gsub('%.','/')..'.lua')end
 return assert(load(source,'@@forge-core/'..path,'t',env))()
end
local profile=loadPR('@forge-core/kernel/pr_integration/operational_profile')(_ENV)
local config=loadPR('@forge-core/kernel/pr_integration/core_runtime_configuration')({
 environment=_ENV,profile=profile,getCandidate=function()return pr.forgeBootCandidate end})
local side=IsDuplicityVersion()and'server'or'client'
local decisions={sameBase=true,legacyCompat='pr_bridge',preserveData=true,legacyConversion='disabled-for-initial-test'}
local providers={constructionApproved=true,installApproved=true,startApproved=true,
 localeKey=GetConvar('pr_bridge:locale','pt-br'),physicalOptions=config.PhysicalOptions,
 compatibilitySharedConfig=module('kernel/config/shared.lua')({vec4=vec4}),
 legacyConversion={inventoryItems={},legacyItems={},convertItems=function()
  error('Legacy item file conversion is disabled for the initial migration test',0)
 end},
 activationAssembly={generation=profile.Generation,consumerSpecs=profile.Consumers(side),isCurrent=config.IsCurrent,
  effectProofs=loadPR('@forge-core/kernel/pr_integration/operational_effect_proofs')({
   environment=_ENV,profile=profile,isCurrent=config.IsCurrent,decisions=decisions})}}
assert(pr.forgeBootProviders==nil,'physical providers already owned');pr.forgeBootProviders=providers
assert(load(assert(LoadResourceFile('forge-core','kernel/entry/boot_candidate_entry.lua')),
 '@@forge-core/kernel/entry/boot_candidate_entry.lua','t',_ENV))()
local runtime=loadPR('@forge-core/kernel/pr_integration/core_activation_runtime')({
 environment=_ENV,candidate=assert(pr.forgeBootCandidate),profile=profile,configuration=config,
 timeout=GetConvarInt('forge:activationTimeout',120000),interval=25,
 createTasks=loadPR('bridge/runtime/owned_tasks'),
 createPosture=loadPR('@forge-core/kernel/pr_integration/posture_runtime'),
 createVisualDelivery=loadPR('@forge-core/kernel/pr_integration/visual_config_delivery'),
 publishState=function(s)if side=='server'then
  -- Forge: sem statebag. Publica o estado de ativacao por convar replicada,
  -- o mesmo meio ja usado pelo forge:bootGeneration.
  SetConvarReplicated('forge:coreActivation',json.encode({generation=s.generation,phase=s.phase,ingressOpen=s.ingressOpen==true}))
 end end})
pr.forgeOperationalRuntime=runtime
assert(runtime.Run(),'owned Forge activation task refused')
