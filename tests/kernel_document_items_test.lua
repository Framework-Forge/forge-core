local C=dofile('tests/kernel_character_harness.lua')
local count=0
local function test(name,fn) C.compare('documents',name,fn);count=count+1 end
test('live catalog',function(r) local value=r.api.get();assert(value.passport and value.id_card and not value.ignored);return value end)
for _,state in ipairs({'starting','stopped','missing'}) do test(state,function(r) r.state=state;return r.api.get() end) end
for _,ready in ipairs({false,1,'true'}) do test('strict ready '..tostring(ready),function(r) r.ready=ready;return r.api.get() end) end
test('api error fallback',function(r) r.apiError=true;r.files['data/config.json']='saved';r.codec.saved={types={a={item='custom'}}};return r.api.get() end)
test('invalid live payload fallback',function(r) r.items='wrong';return r.api.get() end)
test('primary bindings',function(r) r.state='stopped';r.files['data/config.json']='saved';r.codec.saved={types={a={item='custom'},b=false,c={item=3}}};return r.api.get() end)
test('bad primary backup',function(r) r.ready=false;r.files['data/config.json']='bad';r.files['data/config.json.bak']='backup';r.codec.backup={types={{item='backup_doc'}}};return r.api.get() end)
test('bad types then backup',function(r) r.ready=false;r.files['data/config.json']='wrong';r.codec.wrong={types='wrong'};r.files['data/config.json.bak']='backup';r.codec.backup={types={}};return r.api.get() end)
test('fresh result each call',function(r) local value=r.api.get();value.id_card=nil;return r.api.get() end)
print('PASS document classifier: '..count..' differential cases; legacy suppression, strict live readiness and saved primary/backup bindings via explicit PR ports; no document issuance')
