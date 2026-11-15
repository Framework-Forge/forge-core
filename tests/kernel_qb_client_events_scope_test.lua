local D=dofile('tests/kernel_qb_client_events_harness.lua');local H=D.H;local n=0
for _,ported in ipairs({false,true})do
    local r=D.new(ported)
    r.exported.KeyPressed();r.yielding=true
    local state,delay=r.runTask();assert(state=='suspended'and delay==500)
    r.exported.DrawText('new provider text','right')
    assert(r.trace[#r.trace].kind=='show')
    r.yielding=false;assert(r.runTask()=='dead');assert(r.trace[#r.trace].kind=='hide');n=n+1
    -- Chave aguardada e evento final: nenhum ack/cancelamento real e inferido.
    local co=coroutine.create(function()r.keyHook=function()coroutine.yield('keys')end;return r.fire('QBCore:Client:VehicleInfo',{netId=1,seat=0,event='Entered',name='server-name'})end)
    assert(coroutine.resume(co));assert(coroutine.resume(co))
    local last=r.trace[#r.trace];assert(last.kind=='event'and last.args[2].name==nil and last.args[2].vehicle==101);n=n+1
end
local env=H.environment();local factory=H.load('kernel/compat/qb/client_drawtext.lua',env)
for _,ports in ipairs({{}, {library={}}, {library={showTextUI=function()end,hideTextUI=function()end},scheduler={}}})do assert(not pcall(factory,ports));n=n+1 end
assert(not pcall(H.load('kernel/compat/qb/client_events.lua',env),{config={hasKeys=false},native={},helpers={}}));n=n+1
print('PASS lot91 scope:'..n..' checks;accepted timer can hide later shared text,keys await/payload nil preserved,missing PR/config ports refused;no runtime registrations')
