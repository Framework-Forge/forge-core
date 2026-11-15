local T=dofile('tests/kernel_owned_rpc_harness.lua');local H=T.H
local makeHost=dofile('tests/kernel_callback_public_host_fixture.lua')
local oldOwner='../../../../[NOVO BACK-UP]/callback-host-20261030/callback_owner.lua'
for _,backupPR in ipairs({true,false})do
 for _,mode in ipairs({'original-qbx','migrated-before','migrated-after'})do
  local w=T.new();local hosts={};local adapters={};local data=H.groupsFixture()
  for _,side in ipairs({'server','client'})do
   hosts[side]=makeHost(H,w[side],side,backupPR)
   w.ports[side].environment.exports={pr_bridge=hosts[side].proxy}
  end
  if mode=='original-qbx'then
   for _,side in ipairs({'server','client'})do
    local env=setmetatable({GetCurrentResourceName=function()return'qbx_core'end,
     cache={resource='qbx_core'},lib={context=side,setValidCallback=function(name,value)
      return hosts[side].Service('qbx_core','setValidCallback',name,value)
     end}}, {__index=w[side].env})
    env.PRCore={load=function(path,scope)
     assert(path=='@pr_bridge/bridge/callback/transport')
     return H.load('../../[backup]/pr_bridge/bridge/callback/transport.lua',scope)
    end}
    adapters[side]=H.load('../../[backup]/pr_bridge/bridge/compat/ox_lib/ox_callback.lua',env)
   end
   local env=setmetatable({require=function(name)return assert(({['shared.jobs']=data.jobs,['shared.gangs']=data.gangs})[name])end,
    exports=function()end,lib={callback=adapters.server,print={error=function()end}},
    SaveResourceFile=function()error('no file writes allowed')end,TriggerEvent=function()end}, {__index=w.server.env})
   H.load('../../[backup]/qbx_core/server/groups.lua',env)
  else
   if mode=='migrated-before'then
    for _,side in ipairs({'server','client'})do
     w.prs[side].forgeOwnedCallbacks=nil
     w.scopes[side]=H.load(oldOwner,H.environment())(w.ports[side])
    end
   end
   w.open()
   local group=H.load('kernel/server/groups.lua',H.environment())({jobs=data.jobs,gangs=data.gangs,
    logError=function()end,emitServer=function()end,emitClient=function()end,saveGroups=function()error('no file writes allowed')end})
   local owner=w.scopes.server.Owners.ox;local lease=owner.Reserve('qbx_core:server:getGroups')
   assert(owner.Bind(lease,group.Callbacks['qbx_core:server:getGroups']))
   adapters.client=w.scopes.client.Ox
  end
  local ok,groups=pcall(adapters.client.await,'qbx_core:server:getGroups',false)
  if mode=='migrated-before'then
   assert(not ok and tostring(groups):find("callback 'qbx_core:server:getGroups' does not exist",1,true),tostring(groups))
  else
   assert(ok,tostring(groups));H.same(groups,{jobs=data.jobs,gangs=data.gangs},'backup original/ported payload')
   if mode=='migrated-after'then
    local client=H.load('kernel/client/groups.lua',H.environment())({jobs={},gangs={},awaitGroups=adapters.client.await})
    assert(client.Initialize());H.same(client.GetJobs(),data.jobs,'client initialized jobs');H.same(client.GetGangs(),data.gangs,'client initialized gangs')
   end
  end
  if mode~='original-qbx'then assert(w.scopes.server.Close());assert(w.scopes.client.Close())end
 end
end
print('PASS 6 backup comparisons: original QBX succeeds; pre-fix Forge reproduces literal getGroups failure; corrected Forge initializes groups, against both backup and installed PR hosts')
