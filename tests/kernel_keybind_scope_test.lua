local T=dofile('tests/kernel_keybind_harness.lua');local cases=0
do local r=T.new(true);assert(not pcall(r.factory,r.ports));assert(r.api.Close());cases=cases+1 end
do local r=T.new(true);local a,b=r.lib(nil);assert(a==false and b=='invalid_data');assert(r.api.Close());cases=cases+1 end
do local r=T.new(true);local pressed=0;r.lib({name='x',defaultKey='e',onPressed=function()pressed=pressed+1 end});r.api.Close()
r.fire('+x');r.flush();assert(pressed==0 and #r.trace==0 and not pcall(r.lib,{name='z',defaultKey='f'}));cases=cases+1 end
do local r=T.new(true);local old=r.lib({name='x',defaultKey='e'});local called=0;local new=r.lib({name='x',defaultKey='f',onPressed=function()called=called+1 end})
assert(r.api.Progress().commands==2);r.fire('+x');assert(called==1);assert(r.api.Close()and old.disabled and new.disabled);cases=cases+1 end
do local r=T.new(true);r.foreign=true;assert(not pcall(r.lib,{name='foreign',defaultKey='e'}));assert(r.api.Progress().uncertain and not r.api.Close());cases=cases+1 end
do local r=T.new(true);r.mappingError=true;assert(not pcall(r.lib,{name='x',defaultKey='e'}));assert(not r.api.Close());cases=cases+1 end
do local r=T.new(true);local result;r.lib({name='x',defaultKey='e',onPressed=function()coroutine.yield('callback');result=true end})
local co=coroutine.create(function()r.fire('+x')end);assert(coroutine.resume(co));assert(not r.api.Close()and r.api.Progress().pending==1)
assert(coroutine.resume(co));assert(result and r.api.Close()and r.core.forgeKeybindScope==nil);cases=cases+1 end
assert(cases==7);print('PASS164 seven ownership/error/closed/replace/pending checks;mapping/command physical removal not claimed')
