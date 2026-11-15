local R=dofile('tests/kernel_access_client_harness.lua')
local count=0
local function case(n,fn)R.menuCase(n,fn);count=count+1 end
case('main parent',function(r)assert(r.menu.openWhitelistMenu());assert(r.last.menu=='forge_core_server_settings'and #r.last.options==6)end)
for _,bad in ipairs({false,'bad'})do
    case('fetch failure '..tostring(bad),function(r)r.awaitHook=function()return bad,'fixture-error'end;assert(not r.menu.openWhitelistMenu())end)
end
case('players empty',function(r)r.menu.openWhitelistPlayers();assert(r.last.options[1].disabled)end)
for _,allowed in ipairs({false,true})do
    case('player details '..tostring(allowed),function(r)
        r.list={players={{citizenid='C1',name='One',whitelisted=allowed,online=true,source=1}},whitelisted=1,pending=0}
        r.menu.openWhitelistPlayers();r.select(1);assert(r.last.menu=='forge_core_whitelist_players');r.select(1);r.runTimers()
    end)
end
case('ban cancel',function(r)r.menu.openWhitelistBanDialog({citizenid='C1'})end)
case('ban payload',function(r)r.inputs={{'Reason','2','3','4'}};r.menu.openWhitelistBanDialog({citizenid='C1',source=1});r.runTimers()end)
for _,action in ipairs({'add','remove'})do
    case('action '..action,function(r)r.inputs={{'0123'}};r.menu.openWhitelistPlayerAction(action);local req=r.lastRequest();assert(req[3]==123);r.runTimers()end)
end
case('action failure and lock',function(r)
    r.inputs={{'C1'},{'C2'}};r.awaitHook=function()return false,'fixture-refused'end
    r.menu.openWhitelistPlayerAction('add');r.menu.openWhitelistPlayerAction('add')
    assert(r.count('await')==1);r.runTimers(1000);r.inputs={{'C3'}};r.menu.openWhitelistPlayerAction('add');assert(r.count('await')==2)
end)
case('settings cancel',function(r)r.menu.openWhitelistSettingsEditor(r.cfg)end)
case('settings save',function(r)
    r.inputs={{'true','85','both','true','false','Load','Escape','Start'}}
    r.menu.openWhitelistSettingsEditor(r.cfg);r.runTimers()
end)
for _,point in ipairs({'spawn','exam','completion','bad'})do
    case('point '..point,function(r)r.menu.openWhitelistLocationPoint(r.cfg,point);assert(r.last)end)
end
case('capture current',function(r)
    r.menu.openWhitelistLocationPoint(r.cfg,'spawn');r.select(1);r.select(1)
    assert(r.saved.spawnCoords.x==1.235 and r.saved.spawnCoords.w==89.57);r.runTimers()
end)
case('zone center current',function(r)
    r.menu.openWhitelistZoneMenu(r.cfg);r.select(1);r.select(1);assert(r.saved.citizenZone.coords.x==1.235);r.runTimers()
end)
case('zone save',function(r)r.inputs={{'1','2','3','4','5','6'}};r.menu.openWhitelistZoneEditor(r.cfg);r.runTimers()end)
case('zone cancel',function(r)r.menu.openWhitelistZoneEditor(r.cfg)end)
case('blip save',function(r)r.inputs={{'true',525,3,0.8,'Exam'}};r.menu.openWhitelistBlipEditor(r.cfg);r.runTimers()end)
case('blip cancel',function(r)r.menu.openWhitelistBlipEditor(r.cfg)end)
case('question create',function(r)r.inputs={{'New question'}};r.menu.openWhitelistQuestionEditor(r.cfg,nil);assert(#r.saved.questions==2);r.runTimers()end)
case('question edit',function(r)r.inputs={{'Changed'}};r.menu.openWhitelistQuestionEditor(r.cfg,1);assert(r.saved.questions[1].question=='Changed');r.runTimers()end)
case('question remove',function(r)r.menu.openWhitelistQuestionDetails(r.cfg,1);r.alerts={'confirm'};r.select(3);assert(#r.saved.questions==0);r.runTimers()end)
case('question remove cancel',function(r)r.menu.openWhitelistQuestionDetails(r.cfg,1);r.alerts={'cancel'};r.select(3);assert(not r.saved)end)
case('question navigation',function(r)r.menu.openWhitelistQuestions(r.cfg);r.select(2);r.select(2);assert(r.last.menu=='forge_core_whitelist_question_1')end)
case('question missing',function(r)r.menu.openWhitelistQuestionDetails(r.cfg,999);r.menu.openWhitelistOptions(r.cfg,999)end)
case('question cancel new',function(r)r.menu.openWhitelistQuestionEditor(r.cfg,nil)end)
case('question cancel edit',function(r)r.menu.openWhitelistQuestionEditor(r.cfg,1)end)
case('option create',function(r)r.inputs={{'Maybe','false'}};r.menu.openWhitelistOptionEditor(r.cfg,1,nil);assert(#r.saved.questions[1].options==2);r.runTimers()end)
case('option edit',function(r)r.inputs={{'No','false'}};r.menu.openWhitelistOptionEditor(r.cfg,1,1);assert(r.saved.questions[1].options[1].label=='No');r.runTimers()end)
case('option cancel',function(r)r.menu.openWhitelistOptionEditor(r.cfg,1,1)end)
case('laser absent',function(r)r.library.devlaser=nil;r.menu.openWhitelistLocationPoint(r.cfg,'exam');r.select(1);r.select(2)end)
for _,action in ipairs({'capture','cancel','stop','invalid'})do
    case('laser '..action,function(r)
        r.menu.openWhitelistLocationPoint(r.cfg,'exam');r.select(1);r.select(2);r.tick()
        if action=='stop'then r.laser.opts.onStop()
        else
            r.controls={[action=='cancel'and 177 or 201]=true}
            if action=='capture'then r.laser.target={coords=R.vector(4,5,6)}end
            r.tick()
        end
        if action=='capture'then assert(r.saved.examCoords.x==4)end
    end)
end
print('PASS access client menu differentials '..count)
