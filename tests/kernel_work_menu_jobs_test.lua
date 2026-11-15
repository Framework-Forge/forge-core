local A=dofile('tests/kernel_work_menu_harness.lua')
local total=0
local function scenario(options,body)local p=A.pair(options);body(p);total=total+p.count end
scenario(nil,function(p)
    for _,name in ipairs({'openJobsMenu','openPaymentSettings'})do p.run(name,function(r)return r.menu[name]()end)end
    for _,kind in ipairs({'job','gang'})do
        for _,name in ipairs({'openGroupList','openGroupDetails','openGroupPointList','openGradeList'})do
            p.run(name..kind,function(r)return r.menu[name](kind,kind=='job'and r.job or r.gang)end)
        end
        p.run('point details '..kind,function(r)return r.menu.openGroupPointDetails(kind,r.job,r.point)end)
        p.run('grade details '..kind,function(r)return r.menu.openGradeDetails(kind,r.job,4,'4',r.job.grades['4'])end)
    end
    p.run('group new job',function(r)r.inputs={{'New','new_job',2,'police'},{'Member',10},{'Chief',100}};r.menu.openGroupCreator('job');return r.lastRequest()end)
    p.run('group gang',function(r)r.inputs={{'Gang','new_gang',1},{'Boss'}};r.menu.openGroupCreator('gang');return r.lastRequest()end)
    p.run('group cancel',function(r)return r.menu.openGroupCreator('job')end)
    p.run('grade cancel cancels create',function(r)r.inputs={{'New','new_job',2,'none'},{'Member',10}};return r.menu.openGroupCreator('job')end)
    p.run('group edit preserves extra fields',function(r)r.inputs={{'Changed','none','false','true'}};r.menu.openGroupEditor('job',r.job);return r.lastRequest()end)
    p.run('group edit gang',function(r)r.inputs={{'Changed'}};r.menu.openGroupEditor('gang',r.gang);return r.lastRequest()end)
    p.run('group edit cancel',function(r)return r.menu.openGroupEditor('job',r.job)end)
    p.run('point create',function(r)r.inputs={{'  Dock @@ ','true'}};r.menu.openGroupPointEditor('job',r.job,nil,true);return r.lastRequest()end)
    p.run('point edit',function(r)r.inputs={{'Changed','false'}};r.menu.openGroupPointEditor('job',r.job,r.point,false);return r.lastRequest()end)
    p.run('point cancel',function(r)return r.menu.openGroupPointEditor('job',r.job,nil,true)end)
    p.run('point delete cancelled',function(r)return r.menu.removeGroupPoint('job',r.job,r.point)end)
    p.run('point delete confirmed',function(r)r.alerts={'confirm'};r.menu.removeGroupPoint('job',r.job,r.point);return r.lastRequest()end)
    for _,kind in ipairs({'job','gang'})do
        p.run('grade create '..kind,function(r)
            r.inputs={kind=='job'and{5,'New',250,'true','false'}or{5,'New','true','false'}}
            r.menu.openGradeEditor(kind,r.job,5,nil,true);return r.lastRequest()
        end)
        p.run('grade edit '..kind,function(r)
            r.inputs={kind=='job'and{4,'Changed',250,'false','true'}or{4,'Changed','false','true'}}
            r.menu.openGradeEditor(kind,r.job,4,'4',false);return r.lastRequest()
        end)
    end
    p.run('grade cancel',function(r)return r.menu.openGradeEditor('job',r.job,4,'4',false)end)
    p.run('remove grade confirmed',function(r)r.alerts={'confirm'};r.menu.removeGrade('job',r.job,'4');return r.lastRequest()end)
    p.run('remove grade cancelled',function(r)return r.menu.removeGrade('job',r.job,'4')end)
    p.run('last grade protected',function(r)return r.menu.removeGrade('job',{name='last',grades={['0']={name='Member'}}},'0')end)
end)
for _,kind in ipairs({'stash','duty'})do
    for _,variant in ipairs({'cancel','save','capture','capture-cancel','ray-missing','capture-no-hit','error'})do
        scenario(function(r)
            r.controls[38]=true
            if variant=='capture-cancel'then r.controls[38]=false;r.controls[178]=true
            elseif variant=='ray-missing'then r.library.raycast=nil
            elseif variant=='capture-no-hit'then r.ray=nil end
            if variant=='error'then r.reply(r.config.Job.Callbacks.saveGroup,false,'refused')end
        end,function(p)
            p.run(kind..variant,function(r)
                if variant~='cancel'then
                    if kind=='stash'then r.inputs={{'true',2,20,12,'key',1,'pw','Target','webhook',variant=='save'and'false'or'true'}}
                    else r.inputs={{'true',1,'Target',variant=='save'and'false'or'true'}}end
                end
                r.menu[kind=='stash'and'openGroupStashEditor'or'openGroupDutyEditor']('job',r.job,r.point)
                return r.lastRequest()
            end)
        end)
    end
end
scenario(nil,function(p)
    p.run('point enable/disable action',function(r)r.menu.openGroupPointDetails('job',r.job,r.point);return r.select(#r.last.options-1)end)
    p.run('group delete action',function(r)r.alerts={'confirm'};r.menu.openGroupDetails('job',r.job);return r.select(4)end)
    p.run('grade list create callback',function(r)r.menu.openGradeList('job',r.job);return r.select(1)end)
    p.run('invalid title fallback timer id',function(r)r.inputs={{'@@','true'}};r.menu.openGroupPointEditor('job',r.job,nil,true);return r.lastRequest()end)
    p.run('old group after await and timer retained',function(r)
        r.inputs={{'Old','none','true','false'}};r.menu.openGroupEditor('job',r.job)
        r.dispatch('onResourceStop','forge-core');r.runTimers(500)
    end)
end)
scenario(nil,function(p)
    p.run('raycast yields, then confirms',function(r)
        r.inputs={{'true',0,'Duty','true'}}
        local co=coroutine.create(function()r.menu.openGroupDutyEditor('job',r.job,r.point)end)
        local ok,delay=coroutine.resume(co);assert(ok and delay==0)
        r.controls[38]=true;assert(coroutine.resume(co))
        return r.lastRequest()
    end)
end)
print('PASS '..total..' jobs menu differential cases; 17 APIs, groups/grades/policy/payloads/points/stash/duty/raycast and retained timers')

