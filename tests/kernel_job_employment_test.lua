local B=dofile('tests/kernel_business_harness.lua')
local n=0
local function case(label,action)n=n+1;B.case('business',label,action)end
local function submissions(r)return r.registry.get('job','police').stashes[1].applications[1].submissions end
for _,answers in ipairs({{'yes','2'},{'no',2},{'no','no'},{}})do
    case('application answers',function(r)local ok,result=r.api.submitApplication(1,'job','police','main_desk','join',answers);assert(ok and result.score~=nil and #submissions(r)==1)end)
end
for _,variant in ipairs({'no-player','no-questions','disabled','missing','save-failed','phone-throw','phone-false','no-phone','no-charinfo'})do
    case('application '..variant,function(r)
        local point='join'
        if variant=='no-player'then r.players[1]=nil elseif variant=='no-questions'then B.edit(r,function(g,p)p.applications[1].questions={}end)
        elseif variant=='disabled'then B.edit(r,function(g,p)p.applications[1].enabled=false end)
        elseif variant=='missing'then point='none'elseif variant=='save-failed'then r.saveResult=false
        elseif variant=='phone-throw'then r.results.Phone='throw'elseif variant=='phone-false'then r.results.Phone=table.pack(false)
        elseif variant=='no-phone'then r.library.phone=nil elseif variant=='no-charinfo'then r.players[1].charinfo=nil end
        local ok=r.api.submitApplication(1,'job','police','main_desk',point,{'yes',2})
        assert(ok==(variant=='phone-throw'or variant=='phone-false'or variant=='no-phone'or variant=='no-charinfo'))
    end)
end
case('replace pending preserve reviewed',function(r)
    assert(r.api.submitApplication(1,'job','police','main_desk','join',{'yes',2}))
    B.edit(r,function(g,p)p.applications[1].submissions[2]={id='old',citizenid='A',status='rejected'}end)
    assert(r.api.submitApplication(1,'job','police','main_desk','join',{}));assert(#submissions(r)==2 and submissions(r)[1].id=='old')
end)
for _,role in ipairs({'boss','recruiter','member','admin','outsider'})do
    case('permissions '..role,function(r)
        r.players[1].job.grade=role=='boss'and 4 or role=='recruiter'and 2 or 0
        if role=='admin'then r.allowed=true elseif role=='outsider'then r.players[1].job.name='taxi'end
        local manages=role=='boss'or role=='recruiter'or role=='admin';local bosses=role=='boss'or role=='admin'
        local ok=r.api.getApplications(1,'job','police');assert(ok==manages)
        ok=r.api.hirePlayer(1,'job','police','C',2);assert(ok==manages)
        ok=r.api.fireEmployee(1,'job','police','C');assert(ok==bosses)
        ok=r.api.setEmployeeGrade(1,'job','police','C',2);assert(ok==bosses)
    end)
end
for _,status in ipairs({'accepted','rejected','invalid','notfound','save-failed','hire-failed'})do
    case('review '..status,function(r)
        assert(r.api.submitApplication(1,'job','police','main_desk','join',{'yes',2}));local id=submissions(r)[1].id
        local selected=status
        if status=='notfound'then id='none';selected='rejected'elseif status=='save-failed'then r.saveResult=false;selected='accepted'
        elseif status=='hire-failed'then r.results.AddPlayerToJob=table.pack(false,{code='denied'});selected='accepted'end
        local ok=r.api.reviewApplication(1,'job','police','main_desk','join',id,selected);assert(ok==(status=='accepted'or status=='rejected'))
    end)
end
case('application list and absent point',function(r)local ok,list=r.api.getApplications(1,'job','police');assert(ok and #list==1 and list[1].stationId=='Main Desk');ok,list=r.api.getApplications(1,'job','police','main_desk','missing');assert(ok and #list==0)end)
for _,variant in ipairs({'normal','not-ready','member-throw','members-nil','members-false','bad-rows','no-database','denied'})do
    case('employee listing '..variant,function(r)
        r.rows={{citizenid='A',grade='4'},{citizenid='C',grade='bad'}}
        if variant=='not-ready'then r.coreReady=false elseif variant=='member-throw'then r.results.GetGroupMembers='throw'
        elseif variant=='members-nil'then r.results.GetGroupMembers=table.pack(nil)elseif variant=='members-false'then r.results.GetGroupMembers=table.pack(false)
        elseif variant=='bad-rows'then r.results.GetGroupMembers=table.pack('invalid')
        elseif variant=='no-database'then r.coreReady=false;r.library.database=nil
        elseif variant=='denied'then r.players[1].job.grade=0 end
        local ok,list=r.api.getEmployees(1,'job','police')
        assert(ok~=(variant=='bad-rows'or variant=='no-database'or variant=='denied'))
        if ok then assert(#list==2)end
    end)
end
for _,kind in ipairs({'job','gang'})do
    for _,action in ipairs({'hire','fire','grade'})do
        case(kind..' '..action,function(r)
            local name=kind=='gang'and'ballas'or'police';if kind=='gang'then B.edit(r,function()end,'gang')end
            if action=='hire'then assert(r.api.hirePlayer(0,kind,name,'C','2'))
            elseif action=='fire'then assert(r.api.fireEmployee(1,kind,name,'C'))
            else assert(r.api.setEmployeeGrade(1,kind,name,'C',2))end
        end)
    end
end
case('structured membership error',function(r)r.results.AddPlayerToJob=table.pack(false,{message='denied'});local ok,err=r.api.hirePlayer(0,'job','police','C',0);B.expect(ok,err,'denied')end)
print('PASS '..n..' Business application/employment differential cases; scoring, pending replacement, roles, member lookup and local-adapter contracts')
