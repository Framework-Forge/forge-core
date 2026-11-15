local A=dofile('tests/kernel_work_menu_harness.lua')
local total=0
local function scenario(options,body)local p=A.pair(options);body(p);total=total+p.count end
scenario(nil,function(p)
    p.run('main counts and hierarchy',function(r)r.menu.openMain();assert(#r.last.options==13 and r.last.id=='forge_core_main')end)
    for _,i in ipairs({1,2,3,4,5,6,7,8,9,10,11,12,13})do p.run('root action '..i,function(r)r.menu.openMain();return r.select(i)end)end
    p.run('local admin event',function(r)r.dispatch('forge-core:client:openAdminMenu')end)
    for _,name in ipairs({'openJob','openGang'})do p.run('Creator '..name,function(r)return r.creator[name]()end)end
    p.run('scalar and boolean helpers',function(r)return r.shared.boolValue('yes'),r.shared.boolValue('sim'),r.shared.boolValue(1),r.shared.boolDefault(0),r.shared.boolLabel(false),r.shared.accountLabel('unknown'),r.shared.jobTypeDefault(false)end)
    p.run('grades clone/order/next',function(r)
        local grades={['4']={name='Chief'},['0']={name='Member'}}
        return r.shared.listGrades(grades),r.shared.nextGradeLevel(grades),r.shared.countGrades(grades),r.shared.clone(r.job)
    end)
    p.run('options and descriptions',function(r)
        return r.shared.boolOptions(),r.shared.accountOptions(),r.shared.buildJobTypeOptions(),r.shared.staffRoleOptions(),
            r.shared.skillCalculationOptions(),r.shared.calculationLabel('sum'),r.shared.groupTitle(r.job),
            r.shared.gradeTitle(4,{name='Chief'}),r.shared.gradeDescription('job',{payment=100,isboss=true,bankAuth=false})
    end)
    for _,level in ipairs({{}, {from=10,to=20,progress=5},{from=10,to=20,progress=30},{from=10,to=20,progress=15},{from=1,to=1}})do
        p.run('level progress '..tostring(level.progress),function(r)return r.shared.levelProgress(level)end)
    end
    p.run('level/xp/linked helpers',function(r)
        local payload={reputations={{skill='police'},{linkedSkill='police'},{skill='other'}}}
        return r.shared.levelCount({levels={1,2}}),r.shared.levelXpText({xp=10,level={to=100}}),r.shared.playerSkillDescription({xp=100}),
            r.shared.countLinkedReputations(payload,'police'),r.shared.linkedPlayerReputations(payload,'police'),
            r.shared.skillSelectOptions({skills={{name='police',label='Police'}}})
    end)
    p.run('skills fetch and save',function(r)
        r.reply('skills-get',{skills=false,reputations={{skill='police'}}})
        r.reply('skills-player',true,{skills={},reputations=false})
        r.reply('skills-save',true,{name='new'})
        return r.shared.fetchSkillsPayload(),r.shared.fetchPlayerSkillsPayload(),r.shared.saveSkillDefinition('skill',{name='new'})
    end)
    p.run('skill errors and malformed',function(r)
        r.reply('skills-get',false);r.reply('skills-player',false,'blocked');r.reply('reps-save',false,'save')
        return r.shared.fetchSkillsPayload(),r.shared.fetchPlayerSkillsPayload(),r.shared.saveSkillDefinition('rep',{})
    end)
    p.run('nearby excludes self/missing/far',function(r)return r.shared.nearbyServerIds(5),r.shared.nearbyServerIds(4)end)
    p.run('build grades job',function(r)r.inputs={{'Junior',10},{'Chief',100}};return r.shared.buildGrades('job',2)end)
    p.run('build grades gang cancel',function(r)r.inputs={{'Member'}};return r.shared.buildGrades('gang',2)end)
    p.run('empty grades limit',function(r)return r.shared.buildGrades('job',0)end)
end)
for _,index in ipairs({5,6,8,9,10,11})do
    scenario(function(r)
        for _,name in ipairs({'forge-garage','forge-rental','forge-loadscreen','forge-pause','Syn_Sit','forge-dk'})do r.resources[name]='stopped'end
    end,function(p)p.run('external stopped '..index,function(r)r.menu.openMain();return r.select(index,nil,true)end)end)
end
for _,kind in ipairs({'documents-false','documents-throw','documents-bad','seat-false','seat-throw','interface-missing','garage-disabled','rental-custom','no-replica','no-ui','false-ui'})do
    scenario(function(r)
        if kind=='documents-false'then r.documents={ok=false}
        elseif kind=='documents-throw'then r.documentsError=true
        elseif kind=='documents-bad'then r.documents=true
        elseif kind=='seat-false'then r.seat=false
        elseif kind=='seat-throw'then r.seatError=true
        elseif kind=='interface-missing'then r.library.openVisualAdminMenu=nil
        elseif kind=='garage-disabled'then r.config.Garage.AdminMenu.enabled=false
        elseif kind=='rental-custom'then r.config.Rental.AdminMenu={resource='custom',event='custom:open'}
        elseif kind=='no-replica'then r.client.JobState=nil
        elseif kind=='no-ui'then r.library.menus=nil
        elseif kind=='false-ui'then r.uiReturn=false end
    end,function(p)p.run(kind,function(r)
        r.menu.openMain()
        if kind:find('documents',1,true)then return r.select(11,nil,true)
        elseif kind:find('seat',1,true)then return r.select(10,nil,true)
        elseif kind=='interface-missing'then return r.select(7)
        elseif kind=='garage-disabled'then return r.select(5,nil,true)
        elseif kind=='rental-custom'then return r.select(6,nil,true)end
    end)end)
end
scenario(nil,function(p)
    p.run('missing input notifies',function(r)r.library.menus.InputDialog=nil;return r.shared.inputDialog('title',{})end)
    p.run('missing alert is nil',function(r)r.library.menus.AlertDialog=nil;return r.shared.alertDialog({})end)
    p.run('callback absent',function(r)r.library.callback=nil;return r.shared.awaitServer('test')end)
    p.run('missing debug/notify harmless',function(r)r.library.debug=nil;r.library.Notify=nil;r.shared.debug('info','message');r.shared.notify({})end)
end)
print('PASS '..total..' central menu/helper/panel differential cases; full hierarchy/PR boundaries, pure helpers, Creator, error/default/parent semantics')

