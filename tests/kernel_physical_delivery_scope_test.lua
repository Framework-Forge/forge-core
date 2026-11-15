local T=dofile('tests/kernel_physical_delivery_harness.lua');local count=0
local function one(fn)local r=T.new('server');fn(r);r.finish();count=count+1 end
one(function(r)r.physicalName='foreign';assert(not pcall(r.loadPhysical)and #r.physicalReads==0)end)
one(function(r)r.forgeState='stopped';assert(not pcall(r.loadPhysical)and #r.physicalReads==0)end)
one(function(r)r.extensionReady=false;assert(not pcall(r.loadPhysical));for _,fn in pairs(r.published)do assert(not pcall(fn))end;assert(r.qbBinding.IsCurrent())end)
one(function(r)r.extensionDescribe=function()return{protocol='bad',side='server',generation='old107',setField=true}end
    assert(not pcall(r.loadPhysical));for _,fn in pairs(r.published)do assert(not pcall(fn))end end)
one(function(r)r.physicalPublishHook=function(name)if name=='SetField'then r.stopPhysical()end end
    assert(not pcall(r.loadPhysical));for _,fn in pairs(r.published)do assert(not pcall(fn))end;assert(r.api.IsCurrent())end)
one(function(r)r.physicalReadHook=function(path)if path=='compat/qb.lua'then return true,nil end end
    assert(not pcall(r.loadPhysical)and next(r.published)==nil)end)
one(function(r)r.loadPhysical();local c=r.consumer();c.target[T.key]='foreign'
    assert(not pcall(c.loadEntry,'modules/lib.lua')and c.target[T.key]=='foreign');c.target[T.key]=nil end)
one(function(r)r.loadPhysical();local c=r.consumer();c.target.ForgeQbxConsumerPorts=nil
    assert(not pcall(c.loadEntry,'modules/lib.lua')and rawget(c.target,T.key)==nil and #c.physicalEvents==0)end)
one(function(r)r.loadPhysical();local c=r.consumer();c.deliveryPorts.consumer.isServer=false
    assert(not pcall(c.loadEntry,'modules/lib.lua')and rawget(c.target,T.key)==nil)end)
one(function(r)r.loadPhysical();local c=r.consumer();local before=#c.target.package.searchers
    c.physicalReadHook=function(path)if path=='kernel/modules/utils.lua'then return true,nil end end
    assert(not pcall(c.loadEntry,'modules/lib.lua')and rawget(c.target,T.key)==nil and #c.target.package.searchers==before)end)
one(function(r)r.loadPhysical();local c=r.consumer();c.compileHook=function()error('compile refusal107')end
    assert(not pcall(c.loadEntry,'modules/lib.lua')and rawget(c.target,T.key)==nil)end)
one(function(r)r.loadPhysical();local c=r.consumer();c.physicalListenHook=function(t)t.fn('consumer107')end
    assert(not pcall(c.loadEntry,'modules/lib.lua')and rawget(c.target,T.key)==nil);for _,t in ipairs(c.physicalEvents)do assert(t.removed)end end)
one(function(r)r.loadPhysical();local c=r.consumer();assert(c.loadEntry('modules/lib.lua'));local scope=c.target[T.key]
    c.refusePhysicalRemove=true;assert(not scope.Close()and c.target[T.key]==scope and scope.Progress().stopRemaining)
    c.refusePhysicalRemove=false;assert(scope.Close()and rawget(c.target,T.key)==nil and scope.Progress().complete)end)
one(function(r)r.loadPhysical();local c=r.consumer();c.physicalReadHook=function(path)if path=='kernel/modules/lib.lua'then
        assert(not pcall(c.loadEntry,'modules/lib.lua'),'partial import cannot reenter')end end
    assert(c.loadEntry('modules/lib.lua'));local scope=c.target[T.key];local foreign={foreign107=true};c.target.qbx=foreign
    assert(scope.Close()and c.target.qbx==foreign,'preserve foreign replacement')end)
one(function(r)r.loadPhysical();local c=r.consumer();assert(c.loadEntry('modules/lib.lua'));local scope=c.target[T.key]
    c.physicalReadHook=function(path)if path=='kernel/imports/entries/utils.lua'then c.stopPhysical()end end
    assert(not pcall(c.loadEntry,'modules/utils.lua')and rawget(c.target,T.key)==nil and scope.Progress().complete)end)
one(function(r)r.loadPhysical();local c=r.consumer();c.physicalListenHook=function()error('uncertain registration107')end
    assert(not pcall(c.loadEntry,'modules/lib.lua'));local scope=assert(c.target[T.key])
    assert(scope.Progress().registrationUncertain and not scope.Progress().complete and not scope.Close())
    for _,t in ipairs(c.physicalEvents)do t.fn('consumer107');t.removed=true end
    assert(not scope.Close(),'unknown native registration cannot be claimed removed');c.target[T.key]=nil end)
local client=T.new('client');client.loadPhysical();local c=client.consumer();assert(c.loadEntry('modules/playerdata.lua'))
local scope=c.target[T.key];c.refuseRemove=true;assert(not scope.Close()and not scope.Progress().complete)
c.refuseRemove=false;assert(scope.Close()and scope.Progress().complete and c.active()==0);client.finish();count=count+1
assert(count==17)
print('PASS lot107 seventeen physical refusal/cleanup cases,including stop in-flight,unknown registration diagnosis and retry of client PlayerData listener removal')
