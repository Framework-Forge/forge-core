local A=dofile('tests/kernel_work_menu_harness.lua')
local total=0
local function scenario(options,body)local p=A.pair(options);body(p);total=total+p.count end
scenario(nil,function(p)
    p.run('boss panel',function(r)return r.menu.openBossPanel('job',r.job)end)
    p.run('employees empty',function(r)r.reply(r.config.Job.Callbacks.getEmployees,true,{});return r.menu.openBossEmployees('job',r.job)end)
    p.run('employees list',function(r)r.reply(r.config.Job.Callbacks.getEmployees,true,{{citizenid='A',name='Ana',grade=2}});return r.menu.openBossEmployees('job',r.job)end)
    p.run('hire',function(r)r.inputs={{'A',2}};r.menu.openBossEmployees('job',r.job);return r.select(1)end)
    p.run('employee actions',function(r)return r.menu.openBossEmployeeActions('job',r.job,{citizenid='A',name='Ana',grade=2})end)
    p.run('grade change',function(r)r.inputs={{4}};r.menu.openBossEmployeeActions('job',r.job,{citizenid='A',grade=2});return r.select(1)end)
    p.run('fire',function(r)r.menu.openBossEmployeeActions('job',r.job,{citizenid='A'});return r.select(2)end)
    p.run('boss applications empty',function(r)r.reply(r.config.Job.Callbacks.getApplications,true,{});return r.menu.openBossApplications('job',r.job)end)
    p.run('boss applications rows',function(r)r.reply(r.config.Job.Callbacks.getApplications,true,{{id='app',stationId='main',submissions={1},label='App'}});return r.menu.openBossApplications('job',r.job)end)
    p.run('candidate list',function(r)r.reply(r.config.Job.Callbacks.getApplications,true,{{id='A_1',citizenid='A',passed=true}});return r.menu.openStationCandidates('job',r.job,r.point,r.application)end)
    for _,i in ipairs({1,2})do p.run('review candidate '..i,function(r)r.menu.openStationCandidateActions('job',r.job,r.point,r.application,{id='A_1',citizenid='A'});return r.select(i)end)end
end)
for _,key in ipairs({'shops','registers','alarms','bossMenus','applications'})do
    scenario(nil,function(p)
        p.run(key..' list',function(r)return r.menu.openStationBusinessList('job',r.job,r.point,key)end)
        p.run(key..' details',function(r)return r.menu.openStationBusinessPointDetails('job',r.job,r.point,key,r.point[key][1])end)
        p.run(key..' edit cancel',function(r)return r.menu.openStationBusinessPointEditor('job',r.job,r.point,key,r.point[key][1])end)
        p.run(key..' edit payload',function(r)
            local result=key=='shops'and{'Shop','true','ShopTarget','true',1,4}
                or key=='registers'and{'Cash','true',2,'Target',123,'password','pw','true','hard',50,70}
                or key=='applications'and{'App','true',2,'Target',80,'true'}
                or key=='alarms'and{'Alarm','true',2,'Target','Help'}
                or {'Boss','true',4,'Target'}
            r.inputs={result};r.menu.openStationBusinessPointEditor('job',r.job,r.point,key,r.point[key][1]);return r.lastRequest()
        end)
        p.run(key..' create raycast',function(r)
            r.controls[38]=true
            r.inputs={key=='shops'and{'New','true','','false',1,2}or{'New','true',1,'',0,'grade','','false','medium',0,0}}
            r.menu.openStationBusinessPointEditor('job',r.job,r.point,key);return r.lastRequest()
        end)
        p.run(key..' toggle',function(r)r.menu.openStationBusinessPointDetails('job',r.job,r.point,key,r.point[key][1]);return r.select(2)end)
        p.run(key..' capture cancel',function(r)r.controls[178]=true;r.menu.openStationBusinessPointDetails('job',r.job,r.point,key,r.point[key][1]);return r.select(3)end)
        p.run(key..' delete confirm',function(r)r.alerts={'confirm'};r.menu.openStationBusinessPointDetails('job',r.job,r.point,key,r.point[key][1]);return r.select(#r.last.options)end)
    end)
end
scenario(nil,function(p)
    p.run('shop items list',function(r)return r.menu.openStationShopItems('job',r.job,r.point,r.shop)end)
    p.run('shop item cancel',function(r)return r.menu.openStationShopItemEditor('job',r.job,r.point,r.shop,r.shop.items[1],1)end)
    p.run('shop item rebuild loses metadata',function(r)
        r.inputs={{'newburger','New Burger',25}}
        r.menu.openStationShopItemEditor('job',r.job,r.point,r.shop,r.shop.items[1],1)
        local args=r.lastRequest();local item=args[3].stashes[1].shops[1].items[1]
        assert(item.metadata==nil and item.name=='newburger')
        return args
    end)
    p.run('shop add item',function(r)r.inputs={{'water','Water',10}};r.menu.openStationShopItemEditor('job',r.job,r.point,r.shop);return r.lastRequest()end)
    p.run('questions list',function(r)return r.menu.openStationApplicationQuestions('job',r.job,r.point,r.application)end)
    p.run('question edit cancel',function(r)return r.menu.openStationQuestionEditor('job',r.job,r.point,r.application)end)
    p.run('question sparse answer index retained',function(r)
        r.inputs={{'Why?','A','','C','',3}}
        r.menu.openStationQuestionEditor('job',r.job,r.point,r.application,r.application.questions[1],1)
        local args=r.lastRequest();local q=args[3].stashes[1].applications[1].questions[1]
        assert(#q.options==2 and q.correct==3);return args
    end)
    p.run('question create',function(r)r.inputs={{'Question','A','B','C','D',1}};r.menu.openStationQuestionEditor('job',r.job,r.point,r.application);return r.lastRequest()end)
end)
for _,key in ipairs({'getEmployees','hirePlayer','setEmployeeGrade','fireEmployee','getApplications','reviewApplication','saveGroup'})do
    scenario(function(r)r.reply(r.config.Job.Callbacks[key],false,'refused')end,function(p)
        p.run('refusal '..key,function(r)
            if key=='getEmployees'then return r.menu.openBossEmployees('job',r.job)
            elseif key=='getApplications'then return r.menu.openBossApplications('job',r.job)
            elseif key=='reviewApplication'then r.menu.openStationCandidateActions('job',r.job,r.point,r.application,{id='A'});return r.select(1)
            elseif key=='hirePlayer'then r.inputs={{'A',1}};r.reply(r.config.Job.Callbacks.getEmployees,true,{});r.menu.openBossEmployees('job',r.job);return r.select(1)
            elseif key=='setEmployeeGrade'then r.inputs={{1}};r.menu.openBossEmployeeActions('job',r.job,{citizenid='A'});return r.select(1)
            elseif key=='fireEmployee'then r.menu.openBossEmployeeActions('job',r.job,{citizenid='A'});return r.select(2)
            else r.inputs={{'new','New',5}};return r.menu.openStationShopItemEditor('job',r.job,r.point,r.shop)end
        end)
    end)
end
print('PASS '..total..' business administration menu differential cases; all 13 APIs, five categories, employees/reviews/editors/field loss/sparse question semantics')

