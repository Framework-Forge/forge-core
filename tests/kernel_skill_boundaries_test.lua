local Q=dofile('tests/kernel_skill_harness.lua')
local count=0
local function case(name,fn,options)Q.case(name,fn,options);count=count+1 end
case('all exports preserve signatures',function(r)
    assert(r.exports.updateSkill(1,'a',2))
    assert(r.exports.fetchSkills(1).values.a==12)
    return r.exports.getCurrentSkill(1,'a'),r.exports.getCurrentLevel(1,'a'),r.exports.getSkillInfo('r'),
        r.exports.getSkillDefinitions()
end)
case('seven full callback bodies',function(r)
    r.attachBoundaries()
    assert(#r.callbacks==7)
    local map={};for _,e in ipairs(r.callbacks)do map[e.name]=e.handler end
    local payload,manage=map[r.config.Callbacks.getAll](1);assert(manage and payload.skills)
    assert(map[r.config.Callbacks.fetchPlayer](1))
    assert(map[r.config.Callbacks.addXp](1,'a',2))
    assert(map[r.config.Callbacks.saveSkill](1,{name='x'}))
    assert(map[r.config.Callbacks.saveReputation](1,{name='y',skill='x'}))
    assert(map[r.config.Callbacks.deleteReputation](1,'y'))
    assert(map[r.config.Callbacks.deleteSkill](1,'x'));return true
end)
case('getAll nonadmin still public',function(r)
    r.attachBoundaries();r.manage=false
    return r.callbacks[1].handler(1)
end)
for _,native in ipairs({false,true})do
    for _,src in ipairs({0,1})do
        case('command '..tostring(native)..':'..src,function(r)
            r.attachBoundaries();local e=r.commands[1]
            if e.options then assert(e.options.canAccess(src))end
            return e.handler(src,{},'forgeskills')
        end,{nativeCommand=native})
    end
    case('command denied '..tostring(native),function(r)
        r.attachBoundaries();r.manage=false
        return r.commands[1].handler(1,{},'forgeskills')
    end,{nativeCommand=native})
end
-- Explicit callback classification must equal the installed Security policy.
local r=Q.new(true);r.attachBoundaries()
local admin={saveSkill=true,deleteSkill=true,saveReputation=true,deleteReputation=true,addXp=true}
local names={};for key,name in pairs(r.config.Callbacks)do names[name]=key end
for _,e in ipairs(r.callbacks)do assert(e.options.access==(admin[names[e.name]]and'admin'or'player'))end
assert(#r.boundary.Exports==6 and #r.boundary.NetEvents==2 and #r.boundary.Listeners==5)
print('PASS skill boundary differentials '..count..'; explicit 5 admin/2 player callback classifications, 6 exports/2 net events/5 listeners, no registrations')

