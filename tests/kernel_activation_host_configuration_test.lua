local T=dofile('tests/kernel_native_bindings_harness.lua');local H=T.H
local function loadPR(path)return H.load('../pr_bridge/'..path..'.lua',H.environment())end
local create=loadPR('bridge/frameworks/forge/activation_host_configuration')
for _,side in ipairs({'server','client'})do
 local r=T.new(side,side=='server');local n=r.bindingPorts.native;n.GetInvokingResource=function()return 'forge-core'end
 local spec={instance='host267'..side,inventory=side=='server'}
 local profile=loadPR('bridge/frameworks/forge/activation_profile')({authority='forge-core',generation='g267',qbEnabled=true,
 consumers={{name=r.boundResource,[side]=spec}}})
 local ports={};for k,v in pairs(r.bindingPorts)do ports[k]=v end;ports.api=nil
 local exports={};local registration={available=function(kind,name)return kind=='export'and exports[name]==nil end,
 publishExport=function(name,fn)exports[name]=fn end}
 local p={native=n,profile=profile,bindingPorts=ports,prCore=r.pr,external={['forge-core']={}},
 isCurrent=function()return true end,load=loadPR,registration=registration,installApproved=false}
 local configured=create(p)
 assert(configured.Generation=='g267'and configured.Instance==spec.instance and configured.Side==side)
 assert(not configured.Install()and next(exports)==nil)
 p.installApproved=true;assert(configured.Install()and type(exports.ForgePrActivationControl)=='function')
 assert(not pcall(create,p));assert(configured.Close()and configured.Progress().complete and r.pr.forgeActivationHost==nil)
 ports.inventory=not spec.inventory;assert(not pcall(create,p));ports.inventory=spec.inventory
 ports.contracts={qbx=true,qb=side~='server'};assert(not pcall(create,p))
 r.finish()
end
print('PASS267 profile/side/instance/expected configured through actual host;publication explicit;ownership and contract mismatches denied')
