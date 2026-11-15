local A=dofile('tests/kernel_automedic_harness.lua')
local n=0
local function case(label,fn,opt)A.case(label,fn,opt);n=n+1 end
for _,name in ipairs({'playerDropped','QBCore:Server:OnPlayerUnload','pr_bridge:server:OnPlayerUnloaded'})do
    case('cleanup '..name,function(r)
        r.start();local token=r.approve();assert(r.api.recoverHospital(1,token,'unreachable'))
        r.event(name,1);assert(r.api.recoveries[1]==nil and r.api.deaths[1]==nil and r.api.treatments[1]==nil)
        return true
    end)
end
case('metadata dead/time/clear',function(r)
    r.start();r.players[1].PlayerData.metadata.deathTimeStamp=r.now-25
    r.event('qbx_core:server:onSetMetaData','isdead',false,true,1)
    assert(r.api.deaths[1].at==r.now-25)
    r.event('qbx_core:server:onSetMetaData','isdead',true,false,1)
    assert(r.api.deaths[1]==nil);return true
end)
case('unrelated/invalid metadata event',function(r)
    r.start();r.event('qbx_core:server:onSetMetaData','other',nil,true,1)
    r.event('qbx_core:server:onSetMetaData','isdead',nil,true,0)
    return r.api.deaths
end)
case('report network source',function(r)r.start();r.event(r.config.Events.reportDeath,{timestamp=r.now});return true end)
case('invalid network source',function(r)r.start();r.source=0;r.event(r.config.Events.reportDeath,{});return true end)
case('leave hospital event guards',function(r)
    r.start();local token=r.approve();assert(r.api.recoverHospital(1,token,'unreachable'))
    r.event(r.config.Events.leaveHospital,{});assert(r.api.recoveries[1])
    r.event(r.config.Events.leaveHospital,'fake');assert(r.api.recoveries[1])
    r.event(r.config.Events.leaveHospital,token);assert(not r.api.recoveries[1]);return true
end)
case('all callback bodies and quotas',function(r)
    r.start();local c={};for _,e in ipairs(r.callbacks)do c[e.name]=e.handler end
    assert(c[r.config.Callbacks.getSettings](0));assert(c[r.config.Callbacks.saveSettings](0,r.api.getSettings()))
    assert(c[r.config.Callbacks.saveBed](0,A.bed('third',4)))
    assert(c[r.config.Callbacks.deleteBed](0,'third'));assert(c[r.config.Callbacks.getStatus](1))
    local ok,p=c[r.config.Callbacks.requestTreatment](1,'collapse');assert(ok)
    assert(c[r.config.Callbacks.cancelTreatment](1,'wrong'))
    return c[r.config.Callbacks.recoverHospital](1,p.token,'unreachable')
end)
case('callback completion excludes hospital argument',function(r)
    r.start();local token=r.approve();r.now=r.now+10
    for _,e in ipairs(r.callbacks)do if e.name==r.config.Callbacks.completeTreatment then return e.handler(1,token,{bed={}})end end
end)
case('admin guard remains in bed service',function(r)
    r.start();r.manage=false
    for _,e in ipairs(r.callbacks)do if e.name==r.config.Callbacks.saveBed then return e.handler(1,A.bed('no',0))end end
end)
-- Same exact Security policy, not a silently strengthened transport.
local r=A.new(true)
assert(#r.callbacks==9 and #r.boundary.Events==6 and #r.sessionBoundary.Events==4)
for _,e in ipairs(r.callbacks)do
    assert(e.options.access==((e.name==r.config.Callbacks.getSettings or e.name==r.config.Callbacks.saveSettings)and'admin'or'player'))
end
print('PASS AutoMedic event/callback differentials '..n..'; exact 2 admin/7 player classifications')

