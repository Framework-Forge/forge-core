local R=dofile('tests/kernel_event_registration_harness.lua');local H,n=R.H,0
local function check(v,label)n=n+1;assert(v,label)end
local function new(entries)
 local b=R.bus();local spec={owner={},side='server',entries=entries or{},isCurrent=function()if b.currentError then error('current check failed')end;return b.valid~=false end}
 local a=H.load('kernel/shared/event_registration.lua',R.env())(spec,b.ports);return a,b,spec
end
local calls={};local function receive(...)calls[#calls+1]=table.pack(...);return false,nil,4 end
local a,b,spec=new({{owner='old',name='shared',handler=receive,network=true,sourceFirst=true},
 {owner='new',name='shared',handler=function(...)calls[#calls+1]=table.pack(...)end,network=true,sourceFirst=false},
 {owner='other-event',name='local',handler=receive,network=false,sourceFirst=false}})
check(#b.trace==0 and a.State=='prepared-inactive','constructor inert')
local copied=a.Describe();copied[1].name='foreign'
check(a.Describe()[1].name=='shared','descriptor copy isolated')
spec.entries[1].handler=function()error('caller mutation')end
check(a.Install()and b.active()==3 and a.State=='installed','explicit install')
check(b.marks.shared==1 and b.marks['local']==nil,'network marking once and only network names')
b.emit('shared',17,'a',nil,'z')
H.same(calls[1],table.pack(17,'a',nil,'z'),'origin injected only for old body')
H.same(calls[2],table.pack('a',nil,'z'),'payload-only body no injection')
check(not a.Install()and b.active()==3,'install never duplicated')
local token,fn;for t,v in pairs(b.records)do if t.id==1 then token,fn=t,v.handler end end
b.origin=27;H.same(table.pack(fn('x')),table.pack(false,nil,4),'multi-return preserved')
local before=#calls;b.valid=false;fn('blocked');check(#calls==before,'foreign graph not dispatched');b.valid=true
spec.owner.EventRegistration={};fn('blocked');check(#calls==before,'foreign owner not dispatched');spec.owner.EventRegistration=a
b.onRemove=function()check(not a.Dispose(),'disposal reentry refused');fn('disabled')end
check(a.Dispose()and b.active()==0 and #calls==before,'disabled before removal')
H.same(b.removals,{3,2,1},'reverse removal order')
a.State='installed';fn('stale');check(#calls==before,'public state cannot resurrect disposed wrapper')
check(not a.Install()and not a.Dispose(),'disposed holder never installed again')
local q,qb=new({{owner='error',name='error',network=false,sourceFirst=false,handler=function()error('preserved error')end}})
q.Install();local errFn;for _,v in pairs(qb.records)do errFn=v.handler end
check(not pcall(errFn),'handler error propagated');q.Dispose()
local yielded,yb=new({{owner='yield',name='yield',network=false,sourceFirst=true,handler=function(origin,...)
 local payload=table.pack(...);coroutine.yield('waiting');return origin,table.unpack(payload,1,payload.n)
end}})
yielded.Install();local yf;for _,v in pairs(yb.records)do yf=v.handler end
yb.origin=71;local co=coroutine.create(function()return yf(nil,5)end)
local ok,wait=coroutine.resume(co);check(ok and wait=='waiting','yield preserved')
yielded.Dispose();yb.origin=99;local result=table.pack(coroutine.resume(co))
H.same(result,table.pack(true,71,nil,5),'inflight handler not cancelled or origin replaced after yield')
for _,field in ipairs({'listen','remove','markNetwork','source'})do
 local bus=R.bus();bus.ports[field]=nil;local spec={owner={},side='server',entries={},isCurrent=function()return true end}
 check(not pcall(H.load('kernel/shared/event_registration.lua',R.env()),spec,bus.ports),'missing port '..field)
 check(spec.owner.EventRegistration==nil and #bus.trace==0,'preflight before ownership/effects')
end
for _,bad in ipairs({{owner='x',name='',handler=receive,network=false,sourceFirst=false},
 {owner='x',name='a',handler=receive,network=1,sourceFirst=false},
 {owner='x',name='a',handler=receive,network=false,sourceFirst=1}})do check(not pcall(new,{bad}),'bad descriptor refused')end
local d={owner='x',name='alias',handler=receive,network=false,sourceFirst=false}
check(not pcall(new,{d,d}),'same name-handler alias refused')
local f,fb=new({d,{owner='two',name='second',handler=receive,network=true,sourceFirst=false}});fb.failAt=2
check(not f.Install()and f.State=='install-failed'and fb.active()==0,'partial install cleanup')
check(not f.Install(),'failed install not replayed')
local g,gb=new({d,{owner='two',name='second',handler=receive,network=true,sourceFirst=false}})
gb.failAt=2;gb.failRemove=1;check(not g.Install()and g.State=='dispose-failed'and gb.active()==1,'failed cleanup reported')
local stale;for _,v in pairs(gb.records)do stale=v.handler end;before=#calls;stale('blocked')
check(#calls==before,'failed cleanup wrapper disabled');gb.failRemove=nil
check(g.Dispose()and gb.active()==0,'retry only failed removals')
local z,zb=new({d});zb.onListen=function(_,dispatch)
 before=#calls;dispatch('during install');check(#calls==before,'dispatch blocked before commit')
 check(not z.Install()and not z.Dispose(),'install reentry refused')
 zb.valid=false
end
check(not z.Install()and zb.active()==0,'graph replacement during install cleans known tokens')
local change,cb=new({d});cb.valid=false;check(not change.Install()and #cb.trace==0,'replaced graph refused before side effects')
local m,mb=new({d});mb.markError=true -- Local-only event never marks a network name.
check(m.Install()and mb.marks.alias==nil,'local-only installation independent of network port');m.Dispose()
local x,xb=new({{owner='net',name='net',handler=receive,network=true,sourceFirst=false}});xb.markError=true
check(not x.Install()and xb.active()==0,'mark failure leaves no listeners')
local nilToken,nb=new({d});nb.ports.listen=function()end -- Captured function is already fixed, changing caller ports cannot replace it.
check(nilToken.Install()and nb.active()==1,'caller port mutation cannot replace captured functions');nilToken.Dispose()
local ports=R.bus();ports.ports.listen=function()return nil end
local spec={owner={},side='server',entries={d},isCurrent=function()return true end}
local invalid=H.load('kernel/shared/event_registration.lua',R.env())(spec,ports.ports)
check(not invalid.Install()and invalid.State=='install-failed','nil token rejected')
local locked,lb=new({d});locked.Install();local lf;for _,v in pairs(lb.records)do lf=v.handler end
before=#calls;lb.currentError=true;lf('current error');check(#calls==before,'current checker error fails closed');locked.Dispose()
local empty,eb=new();check(empty.Install()and empty.Dispose()and #eb.trace==0,'empty plan has no runtime effects')
local foreign=R.bus();foreign.ports.listen('foreign',function()end)
local keep=H.load('kernel/shared/event_registration.lua',R.env())({owner={},side='client',entries={d},isCurrent=function()return true end},foreign.ports)
keep.Install();check(keep.Dispose()and foreign.active()==1,'cleanup never removes foreign listener')
print('PASS lot51 registry: '..n..' checks; construction, alias/network policy, immutable descriptors, origin/returns/errors/yields, one install, rollback of known listeners/retry cleanup, no inflight cancellation claim')
