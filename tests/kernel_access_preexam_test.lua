local A=dofile('tests/kernel_access_harness.lua')
local n=0
local function case(name,fn)A.case(name,fn);n=n+1 end
case('answers-store',function(r)assert(r.w.submitPreExam(1,{Email={value='fixture',kind='email'}}));assert(r.answers.C1)end)
case('answers-merge',function(r)r.answers.C1={answers=r.m.codec.encode({Old={value='old'}})}
    assert(r.w.submitPreExam(1,{New={value='new'}}));local v=r.m.codec.decode(r.answers.C1.answers);assert(v.Old and v.New)end)
case('malformed-prior',function(r)r.answers.C1={answers='bad'};assert(r.w.submitPreExam(1,{}))end)
case('invalid-player',function(r)r.players[1]=nil;local ok,e=r.w.submitPreExam(1,{});assert(not ok and e=='invalid_player')end)
case('db-missing-no-webhook-success',function(r)r.ready=false;assert(r.w.submitPreExam(1,{})and not r.answers.C1)end)
case('db-write-failure-ignored',function(r)r.noApply=true;r.updateResult=0;assert(r.w.submitPreExam(1,{})and not r.answers.C1)end)
case('non-table-input',function(r)assert(r.w.submitPreExam(1,'wrong'))end)
case('arbitrary-answer-key',function(r)assert(r.w.submitPreExam(1,{NotConfigured={value='accepted'}}));assert(r.m.codec.decode(r.answers.C1.answers).NotConfigured)end)
local function hook(r,format)
    local c=A.H.copy(r.config.Whitelist.Defaults);c.preExam={webhook='https://fixture.invalid/test',formatPhone=format};r.m.seed(r.config.Whitelist.Storage.configFile,c)
end
case('webhook-phone',function(r)hook(r,true);assert(r.w.submitPreExam(1,{Phone={kind='phone',value='000'}}))
    local trace=r.trace[#r.trace];assert(trace.kind=='http');local payload=r.m.codec.decode(trace.args[4]);assert(payload.embeds[1].fields[4].value=='https://wa.me/55000')end)
case('webhook-no-format',function(r)hook(r,false);assert(r.w.submitPreExam(1,{Phone={kind='phone',value='000'}}))end)
case('webhook-return-false-ignored',function(r)hook(r,false);r.httpResult=false;assert(r.w.submitPreExam(1,{}))end)
case('webhook-error-after-store',function(r)hook(r,false);r.httpError=true;assert(not pcall(r.w.submitPreExam,1,{}));assert(r.answers.C1)end)
case('webhook-without-db',function(r)hook(r,false);r.ready=false;assert(r.w.submitPreExam(1,{})and not r.answers.C1)end)
case('malformed-answer-after-write',function(r)hook(r,false);assert(not pcall(r.w.submitPreExam,1,{Bad=9}));assert(r.answers.C1)end)
case('late-query-new-character',function(r)
    r.queryHook=function()r.players[1]={PlayerData={source=1,citizenid='NEW',metadata={}}};return table.pack({})end
    assert(r.w.submitPreExam(1,{})and r.answers.C1 and not r.answers.NEW)
end)
print('PASS whitelist pre-exam differentials '..n)
