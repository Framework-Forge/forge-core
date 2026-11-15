local T=dofile('tests/kernel_native_bindings_harness.lua');local H=T.H
local function loadPR(path)return H.load('../pr_bridge/'..path..'.lua',H.environment())end
for _,side in ipairs({'server','client'})do
 local r=T.new(side,side=='server');local n=r.bindingPorts.native;n.GetInvokingResource=function()return'forge-core'end
 local profile=loadPR('bridge/frameworks/forge/activation_profile')({authority='forge-core',generation='g274',qbEnabled=true,
 consumers={{name=r.boundResource,[side]={instance='i274',inventory=side=='server'}}}})
 local ports={};for k,v in pairs(r.bindingPorts)do ports[k]=v end;ports.api=nil;ports.contracts={qbx=true,qb=true}
 local exports={};local host=loadPR('bridge/frameworks/forge/activation_host_configuration_v2')({native=n,profile=profile,prCore=r.pr,bindingPorts=ports,
 external={['forge-core']={}},load=loadPR,isCurrent=function()return true end,installApproved=true,
 registration={available=function()return next(exports)==nil end,publishExport=function(name,fn)exports[name]=fn end}})
 assert(host.Prepare());local facade=r.pr.forgeNormalizedFacade;local allocation=r.pr.forgeConsumerOwner
 assert(facade and allocation and host.Prepare()and r.pr.forgeNormalizedFacade==facade and r.pr.forgeConsumerOwner==allocation)
 assert(host.Install());assert(exports.ForgePrActivationControl('Prepare','g274','i274'))
 assert(r.pr.forgeConsumerOwner==allocation and r.providerReads==0)
 assert(host.Close()and host.Progress().complete)
 r.finish()
end
print('PASS274 facade prepared before PR selection;coordinator Prepare reuses same actual allocation;no proxy handshake/raw service reads before Attach')
