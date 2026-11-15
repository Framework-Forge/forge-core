local R=dofile('tests/kernel_access_client_harness.lua')
local count=0
local function case(n,fn)R.case(n,fn);count=count+1 end
local function exam(r)r.state.config=r.cfg;r.state.active=true;r.run(r.fn('beginExam'));r.advance(20)end
case('reentry',function(r)r.state.examRunning=true;exam(r);assert(#r.trace==0)end)
case('cancel preexam',function(r)r.cfg.preExam={enabled=true,questions={{label='Email',required=true,kind='email'}}};exam(r);assert(not r.state.examRunning)end)
case('preexam payload',function(r)
    r.cfg.preExam={enabled=true,questions={{label='Email',type='input',required=true,kind='email',min=2,max=80}}}
    r.inputs={{'fixture@example.invalid'}};r.alerts={'cancel'};exam(r);assert(not r.state.examRunning)
end)
case('preexam ignores refusal',function(r)
    r.cfg.preExam={enabled=true,questions={}};r.inputs={{}};r.alerts={'cancel'}
    r.awaitHook=function()return false,'rejected'end;exam(r);assert(not r.state.examRunning)
end)
for _,answer in ipairs({'confirm','cancel'})do
    case('confirm '..answer,function(r)r.alerts={answer};r.inputs={{'1'}};exam(r);assert(not r.state.examRunning)end)
end
case('failed answer',function(r)r.alerts={'confirm','confirm'};r.inputs={{'2'}};exam(r);assert(r.state.active)end)
case('cancel answer',function(r)r.alerts={'confirm','confirm'};exam(r);assert(r.state.active)end)
case('empty exam',function(r)r.cfg.questions={};r.alerts={'confirm','confirm'};exam(r);assert(r.state.active)end)
case('zero threshold passes empty',function(r)r.cfg.questions={};r.cfg.percent=0;r.alerts={'confirm','confirm'};r.addAllowed=true;exam(r);r.advance(600);assert(not r.state.active)end)
case('success refusal retained',function(r)r.alerts={'confirm','confirm'};r.inputs={{'1'}};exam(r);assert(r.state.active and not r.state.examRunning)end)
case('success completion',function(r)r.alerts={'confirm','confirm'};r.inputs={{'1'}};r.addAllowed=true;exam(r);r.advance(600);assert(not r.state.active and r.pos.x==9)end)
case('numeric correctness not true',function(r)r.cfg.questions[1].options[1].value=1;r.alerts={'confirm','confirm'};r.inputs={{'1'}};exam(r);assert(r.state.active)end)
case('invalid answer index',function(r)r.alerts={'confirm','confirm'};r.inputs={{'999'}};exam(r);assert(r.state.active)end)
case('all questions continue after cancel',function(r)
    r.cfg.questions[2]=R.H.copy(r.cfg.questions[1]);r.cfg.questions[2].question='Q2'
    r.alerts={'confirm','confirm'};exam(r);assert(r.state.active)
end)
case('late exam still acts inherited',function(r)
    r.alerts={'confirm','confirm'};r.inputs={{'1'}};r.addAllowed=true
    r.inputHook=function()r.fire('forge-core:session:changed',nil,nil);return {'1'}end
    exam(r);r.advance(600);assert(r.pos.x==9 and not r.state.active)
end)
print('PASS access client exam differentials '..count)
