local R=dofile('tests/kernel_skill_client_harness.lua')
local n=0
local function case(label,fn)R.menuCase(label,fn);n=n+1 end
case('shared skill/rep lock',function(u)
    u.inputs={u.form(false,'skill'),u.form(false,'rep')};u.menu.openSkillEditor(u.skill,false)
    u.menu.openReputationEditor(u.rep,false,'a');assert(u.last.id=='forge_core_reputation_list_a')
    u.runTimers(1000);u.inputs={u.form(false,'rep')};u.menu.openReputationEditor(u.rep,false,'a')
end)
case('lock checked after dialog and can race',function(u)
    local nested=false
    u.inputHook=function()
        if not nested then
            nested=true;u.inputs={u.form(false,'rep')}
            local hook=u.inputHook;u.inputHook=nil;u.menu.openReputationEditor(u.rep,false,'a');u.inputHook=hook
        end
        return u.form(false,'skill')
    end
    u.menu.openSkillEditor(u.skill,false);assert(u.last.id=='forge_core_skill_list')
end)
case('await exception leaves editor locked',function(u)
    u.inputs={u.form(false,'skill')};u.awaitError=true
    local ok,err=pcall(u.menu.openSkillEditor,u.skill,false);assert(not ok and tostring(err):find('fixture%-await'))
    u.awaitError=false;u.inputs={u.form(false,'skill')};u.menu.openSkillEditor(u.skill,false)
    assert(u.last.id=='forge_core_skill_list'and #u.timers==0)
end)
case('deletion bypasses editor lock',function(u)
    u.inputs={u.form(false,'skill')};u.menu.openSkillEditor(u.skill,false)
    u.menu.openSkillDetails(u.skill);u.alerts={'confirm'};u.select(4)
end)
case('level edit bypasses editor lock',function(u)
    u.inputs={u.form(false,'skill'),{'Level',1,5}};u.menu.openSkillEditor(u.skill,false)
    u.menu.openSkillLevelEditor('skill',u.skill,1,u.skill.levels[1],false)
end)
case('timer reopens after navigation',function(u)
    u.inputs={u.form(false,'skill')};u.menu.openSkillEditor(u.skill,false)
    u.menu.openMain();u.runTimers(500);assert(u.last.id=='forge_core_skill_list')
end)
case('form clones provided definition after dialog',function(u)
    local original=u.skill
    u.inputs={u.form(false,'skill')}
    u.inputHook=function()original.levels={{title='Concurrent',from=40,to=50}};return u.form(false,'skill')end
    u.menu.openSkillEditor(original,false)
    return u.lastRequest()
end)
case('missing levels rep index removes inherited',function(u)
    u.menu.openSkillLevelDetails('rep',{name='empty'},1,{title='Missing'},'a')
    u.select(2);u.runTimers()
end)
for _,value in ipairs({false,'bad',{}, {skills=false,reputations='bad'}})do
    case('malformed admin payload',function(u)u.reply('skills-get',value);u.menu.openSkillsMenu();u.menu.openSkillList()end)
end
case('truthy malformed cache suppresses fallback inherited',function(u)
    u.cache['forge-core:skills']='bad';u.menu.openPlayerSkillsMenu()
end)
print('PASS skill menu lock/error differentials '..n)

