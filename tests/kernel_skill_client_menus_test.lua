local R=dofile('tests/kernel_skill_client_harness.lua')
local n=0
local function case(label,fn,opts)R.menuCase(label,fn,opts);n=n+1 end
case('root categories',function(u)u.menu.openMain();u.menu.openSkillsMenu();u.select(1);u.menu.openSkillsMenu();u.select(2)end)
case('admin callback',function(u)return u.skillCallbacks[u.config.Skills.Callbacks.openAdmin]()end)
for _,parent in ipairs({false,'a'})do
    case('reputation list '..tostring(parent),function(u)u.menu.openReputationList(parent or nil)end)
end
case('skill list details all actions',function(u)
    u.menu.openSkillList();u.select(2)
    u.menu.openSkillDetails(u.skill);u.select(2)
    u.menu.openSkillDetails(u.skill);u.select(3)
    u.menu.openSkillDetails(u.skill);u.alerts={'cancel'};u.select(4);u.runTimers(500)
end)
case('skill deletion confirmed failure',function(u)
    u.reply(u.config.Skills.Callbacks.deleteSkill,false,'blocked');u.menu.openSkillDetails(u.skill)
    u.alerts={'confirm'};u.select(4);u.runTimers()
end)
case('rep details levels/delete',function(u)
    u.menu.openReputationDetails(u.rep,'a');u.select(2)
    u.menu.openReputationDetails(u.rep,'a');u.alerts={'confirm'};u.select(3);u.runTimers()
end)
for _,kind in ipairs({'skill','rep'})do
    for _,fresh in ipairs({true,false})do
        case(kind..' form '..tostring(fresh),function(u)
            u.inputs={u.form(fresh,kind)}
            if kind=='rep'then u.menu.openReputationEditor(u.rep,fresh,'a')else u.menu.openSkillEditor(u.skill,fresh)end
            u.runTimers(500);u.runTimers(1000)
        end)
        case(kind..' cancel '..tostring(fresh),function(u)
            if kind=='rep'then u.menu.openReputationEditor(u.rep,fresh,'a')else u.menu.openSkillEditor(u.skill,fresh)end
        end)
    end
    case(kind..' form preserves extras and defaults',function(u)
        u.inputs={{'Changed','book',kind=='rep'and'a'or'direct',45}}
        if kind=='rep'then u.menu.openReputationEditor(u.rep,false,'a')else u.menu.openSkillEditor(u.skill,false)end
        return u.lastRequest()
    end)
    case(kind..' failed save still timer',function(u)
        u.reply(kind=='rep'and u.config.Skills.Callbacks.saveReputation or u.config.Skills.Callbacks.saveSkill,false,'save_failed')
        u.inputs={u.form(false,kind)}
        if kind=='rep'then u.menu.openReputationEditor(u.rep,false,'a')else u.menu.openSkillEditor(u.skill,false)end
        u.runTimers()
    end)
    case(kind..' levels empty',function(u)
        u.menu.openSkillLevelList(kind,{name='empty'});assert(u.last.options[2].disabled)
    end)
    case(kind..' levels details/edit/delete',function(u)
        local item=kind=='rep'and u.rep or u.skill
        u.menu.openSkillLevelList(kind,item,'a');u.select(2);u.select(1)
        u.menu.openSkillLevelDetails(kind,item,1,item.levels[1],'a');u.select(2);u.runTimers()
    end)
    for _,fresh in ipairs({true,false})do
        case(kind..' level editor '..tostring(fresh),function(u)
            local item=kind=='rep'and u.rep or u.skill
            u.inputs={{'New level',10,20}}
            u.menu.openSkillLevelEditor(kind,item,1,item.levels[1],fresh,'a');u.runTimers()
        end)
        case(kind..' level cancel '..tostring(fresh),function(u)
            local item=kind=='rep'and u.rep or u.skill
            u.menu.openSkillLevelEditor(kind,item,1,item.levels[1],fresh,'a')
        end)
    end
end
case('create rep from parent loses return parent',function(u)
    u.menu.openReputationList('a');u.select(1)
    -- Initial definition has parent, but parentSkill parameter is not passed by the installed caller.
    assert(u.last.id=='forge_core_reputation_list_all')
end)
case('player cache preferred',function(u)
    u.cache['forge-core:skills']={skills={},reputations={}}
    assert(u.menu.openPlayerSkillsMenu('custom'));assert(u.last.menu=='custom'and u.last.options[1].disabled)
end)
case('player fallback RPC and details',function(u)
    assert(u.menu.openPlayerSkillsMenu('custom'));u.select(1);u.select(2)
    assert(u.last.menu=='forge_core_player_skill_details_a')
end)
case('player no payload returns false',function(u)
    u.reply('skills-player',false,'database_unavailable')
    return u.menu.openPlayerSkillsMenu(),u.menu.openPlayerReputationsMenu()
end)
case('player cache reputation filter',function(u)
    u.cache['forge-core:skills']={skills={},reputations={{name='x',skill='a',xp=50,level={from=0,to=0}}}}
    return u.menu.openPlayerReputationsMenu('a')
end)
case('player linkedSkill alias not used by player filter',function(u)
    u.cache['forge-core:skills']={skills={},reputations={{name='x',linkedSkill='a'}}}
    u.menu.openPlayerReputationsMenu('a');assert(u.last.options[1].disabled)
end)
for _,native in ipairs({false,true})do
    case('two client commands '..tostring(native),function(u)
        assert(#u.commands==2)
        u.commands[1].handler();u.commands[2].handler()
    end,{nativeCommand=native})
end
print('PASS skill menus differentials '..n)

