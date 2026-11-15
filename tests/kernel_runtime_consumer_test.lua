local T=dofile('tests/kernel_native_bindings_harness.lua');local H=T.H
local function loadPR(path)
 local file='../pr_bridge/'..path..'.lua';local f=io.open(file,'rb')
 if f then f:close()else file='../../../../.planning/migration/staging/160/pr_bridge/'..path..'.lua'end
 return H.load(file,H.environment())
end
for _,side in ipairs({'server','client'})do
 local r=T.new(side,false);local n=r.bindingPorts.native;local e={};for k,v in pairs(n)do e[k]=v end
 local ep=r.adapterFixture.ports.events
 e.AddEventHandler=ep.listen;e.RemoveEventHandler=ep.remove;e.RegisterNetEvent=ep.markNetwork
 e.GetInvokingResource=function()return'forge-core'end;e.coroutine=coroutine;e.json={decode=function()end};e.debug=debug
 local public={inventory=r.services.inventory,banking=r.services.banking,cache=r.services.cache or{},callback={register=function()end},
 activeBridges={inventories='ox',banking='renewed',vehicle_key='pr_carkeys'}}
 local profile=loadPR('bridge/frameworks/forge/activation_profile')({authority='forge-core',generation='g275',qbEnabled=true,
 consumers={{name=r.boundResource,[side]={instance='i275',inventory=false}}}})
 local published={};e.exports={['forge-core']={}}
 local owner=loadPR('bridge/frameworks/forge/runtime_consumer')({environment=e,prCore=r.pr,public=public,config={compatFramework='forge'},profile=profile,
 load=loadPR,isCurrent=function()return true end,readDeclarations=function()return{'forge','qbx','qb'}end,
 registration={available=function(_,name)return published[name]==nil end,publishExport=function(name,fn)published[name]=fn end}})
 local facade=r.pr.forgeNormalizedFacade;assert(facade and not owner.IsReady())
 assert(owner.Complete(public)and owner.IsReady()and r.pr.forgeNormalizedFacade==facade)
 assert(owner.Close()and owner.Progress().complete and r.pr.forgeRuntimeConsumer==nil)
 r.finish()
end
print('PASS275 installed host/config/bindings prepared on both sides;public completion releases providers without replacing facade;owned cleanup')
