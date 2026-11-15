local R=dofile('tests/kernel_support_context_harness.lua')
local cases=0
for _,duration in ipairs({10,100001})do for _,kind in ipairs({'false','true','nil','error'})do
    local a=R.S.hooks(false);a.trace={};local b=R.hooks();a.duration=duration;b.duration=duration
    local response;if kind=='false'then response=false elseif kind=='true'then response=true end
    if kind=='error'then response='virtual hook error'end
    local ca=a.callback('probe',response,kind=='error'and'error'or nil)
    local cb=b.callback('probe',response,kind=='error'and'error'or nil)
    assert(a.exported.registerHook('probe',ca)==b.scope.Hooks.registerHook('probe',cb))
    R.H.same(table.pack(a.api.trigger('probe',{})),table.pack(b.scope.Hooks.trigger('probe',{})),'hooks67 response '..kind)
    R.H.same(a.trace,b.trace,'hooks67 trace '..kind);cases=cases+1
end end
assert(cases==8)
local r=R.hooks();local h=r.scope.Hooks
local called=0;local cb=r.callback('veto',false);local id=h.registerHook('money',cb)
assert(id==1 and cb.resource=='A'and cb.hookId==1 and getmetatable(cb).__index==nil and getmetatable(cb).__newindex==nil)
assert(h.trigger('money',{})==false,'false veto preserved');r.caller='B';h.removeHooks(id)
assert(h.trigger('money',{})==false,'foreign resource cannot remove internal hook')
r.caller='A';assert(table.pack(h.removeHooks(id)).n==0 and h.trigger('money',{})==true)
local err=r.callback('error','virtual hook error','error');h.registerHook('money',err)
assert(h.trigger('money',{})==true,'installed hook exception remains fail-open')
local alias=r.callback('alias',false);local first=h.registerHook('alias',alias);local second=h.registerHook('alias',alias)
assert(second==first+1 and alias.hookId==second);h.removeHooks(first)
assert(h.trigger('alias',{})==false,'same callback alias keeps installed mutable-id behavior')
r.scope.ResourceStopped('A');assert(h.trigger('alias',{})==true)
r.caller=nil;h.registerHook('nil-owner',r.callback('nil',false));r.scope.Close()
assert(r.scope.Progress().complete and h.trigger('nil-owner',{})==nil)
local lookup=R.S.hooks(true);local active=true
lookup.ports.getInvokingResource=function()coroutine.yield();return'A'end
local env=R.C.V.B.O.P.T.T.W.D.R.env()
local requireModule=env.require;local raw
env.require=function(name)local ctor=requireModule(name);if name=='kernel.modules.hooks'then
    return function(p)raw=ctor(p);return raw end end;return ctor end
local scope=R.H.load('kernel/modules/owned_hooks.lua',env)({hooks=lookup.ports,isCurrent=function()return active end});assert(scope.Open())
local callback=lookup.callback('late',false);local returned
local co=coroutine.create(function()returned=scope.Hooks.registerHook('late',callback)end)
assert(coroutine.resume(co));scope.Close();assert(scope.Progress().pending==1)
assert(coroutine.resume(co));assert(returned==1 and scope.Progress().complete and raw.trigger('late',{})==true,'late register is drained and cleaned after Close')
local fresh=R.hooks();fresh.current=false;assert(fresh.scope.Hooks.registerHook('old',fresh.callback('old',false))==nil)
fresh.scope.Close();assert(not fresh.scope.Open())
print('PASS lot67 hooks:callable metadata/veto/caller cleanup,nil owner,exception fail-open,mutable alias,late registration close,stale owner;no OX hooks touched')
