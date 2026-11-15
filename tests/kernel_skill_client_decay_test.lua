local R=dofile('tests/kernel_skill_client_harness.lua')
local n=0
local function case(label,fn)R.case(label,fn);n=n+1 end
case('worker initializes while missing token',function(r)r.tick(1000);r.tick(2000);return true end)
case('worker skips when unloaded',function(r)
    r.event('QBCore:Client:OnPlayerUnload');r.tick(1000);r.tick(2000);return true
end)
case('decay exact deadline no catchup burst',function(r)
    r.sync(R.packet());r.tick(1000);assert(r.exports.getCurrentSkill('a')==10)
    r.tick(10999);assert(r.exports.getCurrentSkill('a')==10)
    r.tick(11000);assert(r.exports.getCurrentSkill('a')==8 and r.exports.getCurrentSkill('free')==7)
    r.tick(100000);assert(r.exports.getCurrentSkill('a')==6);return r.collect()
end)
case('pending counters retry until ack',function(r)
    r.sync(R.packet());assert(r.exports.updateSkill('a',2));r.tick(1000);r.tick(2000)
    r.sync({token='session:1',revision=2,values={a=12,rep=5,free=10},ack={a={gain=2,loss=0}}})
    r.tick(3000);return true
end)
case('zero awards do not dirty',function(r)r.sync(R.packet());assert(r.exports.updateSkill('a',0));r.tick(1000);return true end)
case('clamped zero at floor',function(r)
    local p=R.packet();p.values.a=0;r.sync(p);r.tick(1000);r.tick(11000)
    assert(r.exports.getCurrentSkill('a')==0);return true
end)
case('disabled still schedules but cannot change',function(r)
    local p=R.packet();p.definitions.settings.enabled=false;r.sync(p);r.tick(1000);r.tick(11000)
    assert(r.exports.getCurrentSkill('a')==10);return true
end)
case('sum never decays independently',function(r)
    local p=R.packet();p.definitions.skills[2].decay={enabled=true,amount=2,intervalMs=1000};r.sync(p)
    r.tick(1000);r.tick(11000);assert(r.exports.getCurrentSkill('sum')==5);return true
end)
case('definition interval change retains prior deadline',function(r)
    r.sync(R.packet());r.tick(1000)
    local p=R.packet();p.revision=2;p.definitions.skills[1].decay.intervalMs=50000;r.sync(p)
    r.tick(11000);assert(r.exports.getCurrentSkill('a')==8)
    r.tick(21000);assert(r.exports.getCurrentSkill('a')==8);return true
end)
case('disable clears deadline then reenable',function(r)
    r.sync(R.packet());r.tick(1000)
    local p=R.packet();p.revision=2;p.definitions.skills[1].decay.enabled=false;r.sync(p);r.tick(9000)
    p.revision=3;p.definitions.skills[1].decay.enabled=true;r.sync(p);r.tick(10000)
    r.tick(11000);assert(r.exports.getCurrentSkill('a')==10)
    r.tick(20000);assert(r.exports.getCurrentSkill('a')==8);return true
end)
case('unload load resets deadlines',function(r)
    r.sync(R.packet());r.tick(1000);r.event('QBCore:Client:OnPlayerUnload');r.event('QBCore:Client:OnPlayerLoaded')
    r.sync(R.packet());r.tick(11000);assert(r.exports.getCurrentSkill('a')==10)
    r.tick(21000);assert(r.exports.getCurrentSkill('a')==8);return true
end)
case('dirty survives unload sends empty counters',function(r)
    r.sync(R.packet());assert(r.exports.updateSkill('a',1))
    r.event('QBCore:Client:OnPlayerUnload');r.event('QBCore:Client:OnPlayerLoaded');r.sync(R.packet());r.tick(1000)
    return r.collect()
end)
for _,interval in ipairs({0,-1,10000,50000})do
    case('configured interval '..interval,function(r)
        local p=R.packet();p.definitions.skills[1].decay.intervalMs=interval;r.sync(p);r.tick(1000);r.tick(1001)
        return r.exports.getCurrentSkill('a')
    end)
end
print('PASS skill client decay/mirror differentials '..n)

