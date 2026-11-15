-- Server composition over immutable canonical assembly; only virtual SQL/IO/HTTP/buckets/drop.
local A=dofile('tests/kernel_access_harness.lua')
local H=A.H
local file=assert(io.open('tests/kernel_automedic_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('wire.playerSource=1\np.api.CheckPlayerData',1,true))
local server=assert(load(source:sub(1,cut-1)..[[
return {base=base,p=p,wire=wire,library=library,core=core}
]],'@canonical-server30','t',_ENV))()
local base,p,wire=server.base,server.p,server.wire
wire.playerSource=1
p.api.CheckPlayerData(1,{citizenid='PATIENT',license='license:patient',userId=101})
p.api.CheckPlayerData(2,{citizenid='ADMIN',license='license:admin',userId=102})
local r=A.new(true)
r.library.cache=server.library.cache
r.library.framework=setmetatable({},{__index=function()error('forbidden PR framework cycle')end})
r.native.source=function()return wire.server.source end
r.native.GetPlayers=function()return {'1','2'}end
r.library.callback.await=function(target,name,timeout,...)
    local oldPlayer,oldSource=wire.playerSource,wire.server.source
    wire.playerSource=target
    local result=table.pack(pcall(wire.server.api.request,name,target,nil,timeout,...))
    wire.playerSource,wire.server.source=oldPlayer,oldSource
    assert(result[1],result[2]);return table.unpack(result,2,result.n)
end
local clientCalls={}
for _,key in ipairs({'clientAdded','clientRemoved','clientConfigUpdated'})do
    wire.client.api.register(r.config.Whitelist.Callbacks[key],function(...)
        clientCalls[#clientCalls+1]={key,A.P.snapshot(table.pack(...))};return true
    end)
end
local ports={config=r.config,library=r.library,native=r.native,json=r.m.codec,translate=r.translate,webhookIntegration=r.webhookIntegration}
local core=H.load('kernel/server/access_core.lua',A.env())(base,ports)
assert(core.PlayerCore==base.PlayerCore and core.Security==base.Callbacks and core.Session==base.ForgeSession)
assert(base.ForgeSession==server.core.Session and core.Session.Session~=p.core.Session,'Forge view policy not producer readiness')
assert(base.JobCatalog.Dependencies.WhitelistService==core.Whitelist.Service and base.JobCatalog.Dependencies.AfkService==core.Afk.Service)
assert(not core.Whitelist.Service.started and not core.Afk.Service.started and #r.workers==0 and #r.m.trace==0,'no automatic start/schema/worker')
assert(not pcall(H.load('kernel/server/access_core.lua',A.env()),base,ports),'duplicate attachment refused')
for _,entry in ipairs(core.Callbacks)do base.Callbacks.register(entry.name,entry.handler,entry.options)end
for _,entry in ipairs(core.Afk.Events)do p.platform.on(entry.name,entry.handler)end
local w,a=core.Whitelist.Service,core.Afk.Service
assert(w.start());assert(w.start())
local function rpc(name,...)return wire.client.api.request(name,nil,nil,10000,...)end
local c=r.config.Whitelist.Callbacks
local ok,why=rpc(c.saveConfig,{enabled=false})
assert(not ok and why=='no_permission','actual Security refuses patient administration')
ok,why=rpc(c.add)
assert(not ok and why=='no_permission','transport refuses internal self-grant path')
local allowed,cfg=rpc(c.check)
assert(not allowed and p.core.Player_Buckets[1]==1001,'same local Functions owns refusal bucket')
assert(cfg.questions[1].options[1].value==true,'installed full config payload retained for later policy decision')
wire.playerSource=2
local added,addError=rpc(c.add,1)
assert(added,addError);assert(r.records.PATIENT and p.core.Player_Buckets[1]==0)
assert(clientCalls[#clientCalls][1]=='clientAdded','actual PR server-to-client RPC with explicit future-client fixture')
wire.playerSource=1
assert(rpc(c.check));assert(p.core.Player_Buckets[1]==0)
assert(not p.core.Session.isLoaded(1)and core.Session.Session.isLoaded(1),'AFK uses exact Forge Session policy')
assert(rpc(c.submitPreExam,{Email={kind='email',value='fixture@example.invalid'}}))
assert(r.answers.PATIENT and not r.answers.C1,'pre-exam uses canonical local identity')
wire.playerSource=2
r.listRows={{citizenid='PATIENT',name='Patient',whitelisted='PATIENT'},{citizenid='ADMIN',name='Administrator'}}
local listed,rows=rpc(c.listPlayers);assert(listed and rows.whitelisted==1 and rows.pending==1)
assert(rpc(c.remove,1));assert(not r.records.PATIENT and p.core.Player_Buckets[1]==1001)
assert(clientCalls[#clientCalls][1]=='clientRemoved')
local config=w.getConfig();config.percent=88
assert(rpc(c.saveConfig,config));local configWorker=r.workers[#r.workers];configWorker()
assert(clientCalls[#clientCalls][1]=='clientConfigUpdated')
local saved=r.m.codec.decode(r.m.files[r.config.Whitelist.Storage.configFile])
assert(saved.percent==88,'PR persistence only virtual JSON')
-- AFK timers share the local authoritative Session view, not library.framework.
local afk=r.config.Afk.Callbacks
assert(rpc(afk.saveSettings,{enabled=true,minutes=1}))
assert(a.start());assert(a.start());local index=#r.workers
local co=r.runWorker(index);r.tick(co);assert(a.remainingSeconds[1]==60 and a.remainingSeconds[2]==60)
r.tick(co);assert(a.remainingSeconds[1]==59)
wire.server.source=1
p.platform.emitServer('pr_bridge:server:OnPlayerUnloaded',1)
r.tick(co);assert(a.remainingSeconds[1]==nil and a.remainingSeconds[2]==58)
p.platform.emitServer('pr_bridge:server:OnPlayerLoaded',1)
r.tick(co);assert(a.remainingSeconds[1]==60)
-- The kick implementation runs only against a recorder, never a real connection.
a.remainingSeconds[1]=0;r.tick(co);assert(r.drops[#r.drops][1]==1 and a.remainingSeconds[1]==nil)
-- New character after source reuse starts a fresh timer when lifecycle delivery arrives.
p.core.Players[1].PlayerData.citizenid='NEW'
p.platform.emitServer('pr_bridge:server:OnPlayerLoaded',1)
r.tick(co);assert(a.remainingSeconds[1]==60)
a.started=false;r.tick(co);assert(coroutine.status(co)=='dead')
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil)
print('PASS access composition: canonical Player/Lookup/Functions buckets/Forge Session/JobService/Security, actual PR RPC/persistence/DB adapter/identifiers with virtual driver; deny/add/check/remove/preexam/config broadcast/AFK unload/reload/source reuse/drop; client exam/menus/webhook PR binder and real SQL/runtime remain pending')
