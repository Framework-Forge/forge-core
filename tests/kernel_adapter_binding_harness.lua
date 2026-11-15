local C=dofile('tests/kernel_forge_adapter_harness.lua');local S=dofile('tests/kernel_forge_server_adapter_harness.lua')
local W=dofile('tests/kernel_callback_registration_harness.lua');local H=C.H;local T={C=C,S=S,W=W,H=H}
T.path='../pr_bridge/bridge/runtime/forge/consumer_binding.lua'
function T.new(side)
    local r={current=true,side=side or'client',tokens={},target={},aliases={}}
    r.source=r.side=='client'and C.new(true)or S.new(true)
    r.ports={side=r.side,isCurrent=function()return r.current end,adapter=r.source.ports,
        createAdapter=H.load(r.side=='client'and C.path or S.path,H.environment()),
        publications={{object=r.target,key='framework'},{object=r.aliases,key='framework'}},
        createEvents=H.load('kernel/shared/event_registration.lua',H.environment()),events={
            listen=function(name,handler)
                if r.listenHook then r.listenHook(name)end
                local token={name=name,handler=handler,active=true};r.tokens[#r.tokens+1]=token;return token
            end,remove=function(token)if r.refuseRemove then return false end;token.active=false;return true end,
            markNetwork=function(name)if r.markHook then r.markHook(name)end;return true end}}
    if r.side=='server'then r.wire=W.wire();r.wire.Initialize();r.ports.callbacks=r.wire.server.owners.native end
    function r.mount()r.api=H.load(T.path,H.environment())(r.ports);return r.api end
    function r.emit(name,...)for _,t in ipairs(r.tokens)do if t.active and t.name==name then t.handler(...)end end end
    function r.active()local n=0;for _,t in ipairs(r.tokens)do if t.active then n=n+1 end end;return n end
    return r
end
return T
