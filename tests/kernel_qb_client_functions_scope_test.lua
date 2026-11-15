local T=dofile('tests/kernel_qb_client_functions_harness.lua');local H=T.H;local n=0
for _,success in ipairs({false,true})do for _,props in ipairs({false,true})do for _,cancel in ipairs({false,true})do
    T.compare('progress',function(r)
        r.progress=success
        return r.api.Progressbar('ignored','Progress',1000,true,cancel,
            props and{disableMovement=true,disableCarMovement=false,disableCombat=true,disableMouse=true}or nil,
            props and{animDict='dict',anim='clip',flags=49}or nil,
            props and{model='p',bone=1,coords={1,2,3},rotation={4,5,6}}or nil,
            props and{model='q',bone=2}or nil,
            function()r.record('finish')end,function()r.record('cancel')end)
    end);n=n+1
end end end
T.compare('propTwo ignored without first prop',function(r)return r.api.Progressbar(nil,'x',0,false,false,nil,nil,nil,{model='q'})end);n=n+1
for _,ported in ipairs({false,true})do
    local r=T.new(ported);local original=r.state.PlayerData
    assert(r.api.GetPlayerData()==original)
    local returns=table.pack(r.api.GetPlayerData(function(data)assert(data==original);r.record('data-callback',data);return'ignored'end));assert(returns.n==0)
    r.state.PlayerData={citizenid='REPLACED'};assert(r.api.GetPlayerData()==r.state.PlayerData and original~=r.api.GetPlayerData())
    assert(r.api.RequestAnimDict==r.library.requestAnimDict and r.api.LoadModel==r.library.requestModel and r.api.LoadAnimSet==r.library.requestAnimSet)
    local result=table.pack(r.api.Notify('Text'));assert(result.n==0)
    local co=coroutine.create(function()r.progressHook=function()coroutine.yield('progress')end;r.api.Progressbar(nil,'x',10,false,true,nil,nil,nil,nil,function()r.record('late finish')end)end)
    assert(coroutine.resume(co));assert(coroutine.resume(co));assert(r.trace[#r.trace].kind=='late finish')
    n=n+1
end
local factory=H.load('kernel/compat/qb/client_functions.lua',T.V.T.env())
assert(not pcall(factory,{}));n=n+1
print('PASS lot90 scope:'..n..' checks;progress payload/finish/cancel,canonical getter reference/replacement,alias identity,ignored Notify return and accepted late progress characterized')
