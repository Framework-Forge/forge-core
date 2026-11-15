local Q=dofile('tests/kernel_skill_harness.lua')
local H=Q.H
local count=0
local function case(name,fn,options)Q.case(name,fn,options);count=count+1 end
case('whole config',function(r)
    local seed={custom=true}
    local private=H.load('kernel/config/forge_skills.lua',Q.env())(seed)
    local env=H.environment({PR={Skills={custom=true}}});H.load('shared/skills.lua',env)
    H.same(Q.P.snapshot(private),Q.P.snapshot(env.PR.Skills));assert(private==seed)
    return r.config
end)
for _,value in ipairs({{}, {resource=' forge-gym ',export='updateSkill',multiplier=2},
    {resource='bad/path',export='x'},{resource='valid',export='bad:name'},{resource='v',export='x',multiplier=-1},
    {resource='v',export='x',multiplier=10001},{resource='v',export='x',multiplier=0/0,gains=false,losses=false}})do
    case('normalize integration',function(r)return r.config.normalizeIntegration(value)end)
end
for _,value in ipairs({{}, {enabled=true,amount=3,intervalMs=10000},{enabled=true,amount=-1,intervalMs=1},
    {enabled=true,amount=0/0,intervalMs=math.huge}})do
    case('normalize decay',function(r)return r.config.normalizeDecay(value)end)
end
for _,value in ipairs({{},'invalid',{settings={enabled=false,defaultLevels={{from=20,to=10},{from=-1,to=5}}}},
    {skills={A={label='A',maxLevel=20},bad=false},reputations={r={skill='missing'},free={skill=''}}}})do
    case('setAll shapes',function(r)r.registry.setAll(value);return r.registry.payload()end)
end
case('clone and aliases',function(r)
    local s=r.registry.getSkill(' A ');s.label='modified'
    assert(r.registry.getDefinition('a').label~='modified')
    assert(r.registry.getReputation('r').linkedSkill=='total')
    return r.registry.getLinkedReputations('TOTAL'),r.registry.getLevels({}),r.registry.getLevels({levels={{from=4,to=7}}})
end)
case('registry upserts/removes',function(r)
    assert(r.registry.upsertSkill({name=' New Skill ',label=' New ',maxXp=123}))
    assert(r.registry.upsertReputation({name='new_rep',parentSkill='new_skill'}))
    local ok,err=r.registry.removeSkill('new_skill');assert(not ok and err=='skill_has_reputations')
    assert(r.registry.removeReputation('new_rep'));assert(r.registry.removeSkill('new_skill'))
    return r.registry.payload()
end)
for _,fn in ipairs({'upsertSkill','upsertReputation'})do
    case(fn..' invalid',function(r)return r.registry[fn](false)end)
    case(fn..' invalid integration',function(r)return r.registry[fn]({name='x',integration={resource='x'}})end)
end
case('codes collide',function(r)
    return table.pack(r.registry.upsertSkill({name='r'})),table.pack(r.registry.upsertReputation({name='a'}))
end)
case('draft parent resolved against live registry',function(r)
    local draft=r.library.jsonDraft(r.registry,{settings=true,skills=true,reputations=true})
    assert(r.registry.upsertSkill({name='new_parent'},draft))
    local ok,err=r.registry.upsertReputation({name='x',skill='new_parent'},draft)
    assert(not ok and err=='skill_not_found');return draft
end)
case('storage real PR lock/write/load',function(r)
    local draft=r.registry.export();assert(r.storage.save(draft))
    return r.storage.load()
end)
case('storage missing',function(r)r.m.files={};return r.storage.load()end)
case('storage corrupt',function(r)r.m.files[r.config.Storage.file]='broken';return r.storage.load()end)
case('storage refused',function(r)r.m.onWrite=function()return false end;return r.storage.save({})end)
print('PASS skill registry/config/storage differentials '..count)

