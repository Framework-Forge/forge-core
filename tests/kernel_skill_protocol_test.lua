local Q=dofile('tests/kernel_skill_harness.lua')
local count=0
local function case(name,fn,options)Q.case(name,fn,options);count=count+1 end
local init='forge-core:server:skills:initialize'
local mirror='forge-core:server:skills:mirror'
local function integration(r,name,value)
    local d=r.registry.getDefinition(name);d.integration=value;d.name=name
    if d.skill then assert(r.registry.upsertReputation(d))else assert(r.registry.upsertSkill(d))end
end
local function route(extra)
    local d={resource='forge-gym',export='updateSkill',identifier='',multiplier=2,gains=true,losses=true}
    for k,v in pairs(extra or {})do d[k]=v end;return d
end
case('initialize throttle',function(r)
    r.event(init);assert(#r.packets==1);r.event(init);assert(#r.packets==1)
    r.time=2000;r.event(init);assert(#r.packets==2);return true
end)
case('mirror replay/ack/rate/direction',function(r)
    r.event(init);r.time=2000
    local packet=r.packet({a={gain=5,loss=0}});r.event(mirror,packet);assert(r.api.getCurrentSkill(1,'a')==15)
    r.time=2250;r.event(mirror,packet);assert(r.api.getCurrentSkill(1,'a')==15)
    r.time=2500;r.event(mirror,r.packet({a={gain=100,loss=0}}));assert(r.api.getCurrentSkill(1,'a')==15)
    r.time=2750;r.event(mirror,r.packet({a={gain=5,loss=3}}));assert(r.api.getCurrentSkill(1,'a')==12)
    return r.packets[#r.packets]
end)
case('invalid/stale packet and throttle',function(r)
    r.event(mirror,{});r.time=2000;r.event(init);r.time=3000
    r.event(mirror,{token='stale',counters={a={gain=1,loss=0}}})
    r.event(mirror,r.packet({a={gain=2,loss=0}}));assert(r.api.getCurrentSkill(1,'a')==10)
    return true
end)
case('status extension same ledger',function(r)
    r.event(init);r.event('qbx_core:server:statusExtensions',1,{forgeSkills=r.packet({a={gain=3,loss=1}})})
    assert(r.api.getCurrentSkill(1,'a')==12)
    r.event('qbx_core:server:progressionCheckpoint',1,'cid1');return true
end)
case('status extension does not recheck current citizenid',function(r)
    r.event(init);local packet=r.packet({a={gain=3,loss=0}});r.cid='different'
    r.event('qbx_core:server:statusExtensions',1,{forgeSkills=packet})
    assert(r.cache['forge-core:skills:1'].a==13)
    return r.api.flush(1,'cid1')
end)
case('same citizenid reconnect reuses old token',function(r)
    r.event(init);local packet=r.packet({a={gain=3,loss=0}})
    -- Source/citizenid match is inherited; there is no owner-generation check here.
    r.time=3000;r.event(init)
    r.event(mirror,packet);assert(r.cache['forge-core:skills:1'].a==13)
    return true
end)
case('old unload does not delete new session but clears its cache',function(r)
    assert(r.api.addXp(1,'a',2))
    local switched=false
    r.updateHook=function()
        if switched then return end;switched=true;r.cid='cid2'
        r.stored.cid2=r.m.codec.encode({a=30})
        assert(r.api.addXp(1,'a',1))
    end
    r.event('QBCore:Server:OnPlayerUnload',1)
    assert(r.api.getCurrentSkill(1,'a')==31 and r.cache['forge-core:skills:1']==nil)
    return r.api.flush(1,'cid2')
end)
case('parent sum and forward two routes',function(r)
    integration(r,'r',route());integration(r,'total',route({identifier='overall'}))
    assert(r.api.addXp(1,'r',7));assert(r.api.getCurrentSkill(1,'total')==12)
    return true
end)
case('mirror aggregates parent delta',function(r)
    integration(r,'total',route());r.event(init)
    r.event('qbx_core:server:statusExtensions',1,{forgeSkills=r.packet({r={gain=2,loss=0}})})
    assert(r.api.getCurrentSkill(1,'total')==7);return true
end)
for _,opts in ipairs({{gains=false},{losses=false},{identifier='strength'},{multiplier=0},{multiplier=0.5}})do
    case('integration options',function(r)
        integration(r,'a',route(opts));assert(r.api.addXp(1,'a',2));return r.api.addXp(1,'a',-3)
    end)
end
case('resource stopped',function(r)integration(r,'a',route());r.externalState='stopped';return r.api.addXp(1,'a',2)end)
case('export throws local award remains',function(r)
    integration(r,'a',route());r.integrationError='external-failed'
    assert(r.api.addXp(1,'a',2));assert(r.api.getCurrentSkill(1,'a')==12);return true
end)
case('export false no rollback',function(r)
    integration(r,'a',route());r.integrationResult=table.pack(false)
    return r.api.addXp(1,'a',2)
end)
case('visited local/target routes',function(r)
    integration(r,'a',route())
    assert(r.api.addXp(1,'a',2,{visited={['forge-core:a']=true}}))
    return r.api.addXp(1,'a',2,{visited={['forge-gym:a']=true}})
end)
case('forward reentry guard',function(r)
    integration(r,'a',route())
    local count=0
    r.integrationHook=function()count=count+1;return r.api.addXp(1,'a',1)end
    assert(r.api.addXp(1,'a',2));assert(count==1 and r.api.getCurrentSkill(1,'a')==13);return true
end)
for _,event in ipairs({'QBCore:Server:OnPlayerUnload','playerDropped'})do
    case(event..' success clears/reloads',function(r)
        assert(r.api.addXp(1,'a',2));r.event(event,1)
        assert(r.cache['forge-core:skills:1']==nil)
        return r.api.fetchPlayer(1)
    end)
    case(event..' failed flush keeps session but clears cache',function(r)
        assert(r.api.addXp(1,'a',2));r.updateResult=table.pack(false);r.event(event,1)
        assert(r.cache['forge-core:skills:1']==nil)
        assert(r.api.getCurrentSkill(1,'a')==12);return true
    end)
end
case('checkpoint wrong citizenid no save',function(r)
    assert(r.api.addXp(1,'a',2));r.event('qbx_core:server:progressionCheckpoint',1,'wrong')
    return r.api.flush(1)
end)
case('resource stop only own',function(r)
    assert(r.api.addXp(1,'a',2));r.event('onResourceStop','other');r.event('onResourceStop','forge-core');return true
end)
print('PASS skill protocol/integration/lifecycle differentials '..count)

