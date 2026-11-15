local T=dofile('tests/kernel_qb_client_bridge_harness.lua');local H=T.H;local n=0
local function snapshot(v,seen)
    if type(v)=='function'then return'<function>'end
    if type(v)~='table'then return v end
    if getmetatable(v)==false then return'<blocked Items>'end
    seen=seen or{};if seen[v]then return'<cycle>'end;seen[v]=true
    local out={};for k,item in pairs(v)do out[k]=snapshot(item,seen)end;seen[v]=nil;return out
end
local a,b=T.new(false),T.new(true)
H.same(a.trace,b.trace,'construction metadata')
H.same(snapshot(a.object),snapshot(b.object),'complete installed object');n=n+1
local eventCount,exportCount=0,0
for name,d in pairs(a.events)do assert(b.events[name]and d.network==b.events[name].network,name);eventCount=eventCount+1 end
for name in pairs(b.events)do assert(a.events[name],name)end
for name in pairs(a.exported)do assert(b.exported[name],name);exportCount=exportCount+1 end
for name in pairs(b.exported)do assert(a.exported[name],name)end
assert(eventCount==10 and exportCount==5);n=n+1
for _,filters in ipairs({{}, {'Functions'}, {'PlayerData'}, {unknown=true}})do
    assert(a.api.GetCoreObject(filters)==a.object and b.api.GetCoreObject(filters)==b.object);n=n+1
end
for _,r in ipairs({a,b})do
    r.trace={}
    local f=r.object.Functions
    f.CreateClientCallback('echo',function(cb,...)r.record('client-callback',...);cb(nil,'tail')end)
    r.fire('QBCore:Client:TriggerClientCallback','echo',1,nil,3)
    r.fire('QBCore:Client:TriggerClientCallback','missing','ignored')
    f.TriggerCallback('server',function(...)r.record('server-callback',...)end,'request')
    r.fire('QBCore:Client:TriggerCallback','server',false,nil,'tail')
    r.fire('QBCore:Client:TriggerCallback','server','ignored')
    assert(r.object.ServerCallbacks.server==nil)
    r.fire('qbx_core:client:onJobUpdate','newjob',{label='New'})
    r.fire('qbx_core:client:onGangUpdate','newgang',{label='New'})
    assert(r.object.Shared.Jobs==r.jobs and r.object.Shared.Gangs==r.gangs)
    r.object.Debug('ignored',{value=1})
    r.exported.DrawText('Text','left');r.exported.ChangeText('Changed','top');r.exported.KeyPressed();r.runTask();r.exported.HideText()
end
H.same(a.trace,b.trace,'callbacks/groups/debug/TextUI');n=n+1
for _,r in ipairs({a,b})do
    r.trace={};local old=r.state.PlayerData
    assert(r.object.PlayerData==old and r.object.Functions.GetPlayerData()==old)
    r.state.PlayerData={citizenid='NEW92'}
    assert(r.object.PlayerData==old and r.object.Functions.GetPlayerData()==r.state.PlayerData,'installed snapshot versus dynamic getter')
    r.object.Functions.TriggerCallback('collision',function()r.record('old')end)
    r.object.Functions.TriggerCallback('collision',function()r.record('new')end)
    r.fire('QBCore:Client:TriggerCallback','collision')
    r.object.Functions.TriggerCallback('throw',function()error('fixture_reply_error')end)
    assert(not pcall(r.fire,'QBCore:Client:TriggerCallback','throw')and r.object.ServerCallbacks.throw~=nil)
end
H.same(a.trace,b.trace,'retained references/collisions/error');n=n+1
for _,setting in ipairs({'false','true','FALSE','0'})do
    local x,y=T.new(false,setting),T.new(true,setting)
    assert(x.api.Enabled==y.api.Enabled);if setting=='false'then assert(next(x.events)==nil and next(y.events)==nil and y.api.GetCoreObject==nil and #y.trace==0)end;n=n+1
end
print('PASS lot92 whole installed client main parity:'..n..' comparisons;10 events/5 exports,complete object/snapshot-dynamic data/filter ignore,callbacks/group/debug/TextUI and bridge convar')
