local R=dofile('tests/kernel_server_settings_harness.lua')
local count=0
local function case(n,fn)R.case(n,fn);count=count+1 end
case('disabled',function(r)local co=r.connect();r.step(co);assert(coroutine.status(co)=='dead')end)
case('empty enabled stored',function(r)r.p.settings={enabled=true,password=''};r.step(r.connect());assert(not r.card)end)
for _,answer in ipairs({'fixture-pass','wrong',''})do
    case('answer '..answer,function(r)
        r.p.load();local co=r.connect();assert(r.step(co)==0);assert(r.step(co)==1000);r.step(co)
        assert(coroutine.status(co)=='dead'and r.card:find('AdaptiveCard',1,true));r.cardResponse({password=answer})
    end)
end
case('nil response',function(r)r.p.load();local co=r.connect();r.step(co);r.step(co);r.step(co);r.cardResponse(nil)end)
case('non table response',function(r)r.p.load();local co=r.connect();r.step(co);r.step(co);r.step(co);r.cardResponse('fixture-pass')end)
case('number password',function(r)r.p.settings={enabled=true,password='123'};local co=r.connect();r.step(co);r.step(co);r.step(co);r.cardResponse({password=123})end)
case('escape card',function(r)
    r.p.settings={enabled=true,password='fixture-pass',cardTitle='Title "quoted"\\',cardDescription='A\r\nB',placeholder='?',submitText='Go'}
    local co=r.connect();r.step(co);r.step(co);r.step(co);assert(r.card:find('\\n',1,true));r.cardResponse({})
end)
case('changed during wait retains old password',function(r)
    r.p.load();local co=r.connect();r.step(co);r.p.settings={enabled=true,password='fixture-new',cardTitle='New title'}
    r.step(co);r.step(co);assert(r.card:find('New title',1,true));r.cardResponse({password='fixture-pass'})
end)
case('no support fallback',function(r)r.p.settings={enabled=true,password='fixture-pass'};local co=r.connect();r.step(co);r.step(co);r.step(co);r.cardResponse({})end)
case('repeated response inherited',function(r)r.p.load();local co=r.connect();r.step(co);r.step(co);r.step(co);r.cardResponse({password='fixture-pass'});r.cardResponse({password='bad'})end)
case('two simultaneous cards',function(r)r.p.load();local a,b=r.connect(),r.connect();r.step(a);r.step(b);r.step(a);r.step(b);r.step(a);r.step(b)end)
print('PASS password deferral differentials '..count)
