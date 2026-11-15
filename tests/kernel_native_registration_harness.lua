local T=dofile('tests/kernel_qb_binding_context_harness.lua');local H=T.H;local M={H=H,T=T}
function M.new(side)
    local r={side=side or'server',bus={},marked={},commands={},published={},foreign={},current=true,ready=true,origin=0,calls=0}
    r.native={GetCurrentResourceName=function()return r.resource or'forge-core'end,IsDuplicityVersion=function()return r.side=='server'end,source=function()return r.origin end}
    r.native.AddEventHandler=function(name,fn)
        r.calls=r.calls+1;local token={name=name,handler=fn};r.bus[#r.bus+1]=token
        if r.addHook then r.addHook(token)end;return token
    end
    r.native.RemoveEventHandler=function(token)
        if r.removeHook then local value=r.removeHook(token);if value==false then return false end end
        token.removed=true;r.calls=r.calls+1
    end
    r.native.RegisterNetEvent=function(name)r.calls=r.calls+1;r.marked[name]=true end
    r.native.RegisterCommand=function(name,fn,restricted)r.calls=r.calls+1;r.commands[name]={handler=fn,restricted=restricted}end
    r.native.publishExport=function(name,fn)r.calls=r.calls+1;r.published[name]=fn;if r.publishHook then return r.publishHook(name,fn)end end
    r.ports={native=r.native,running=coroutine.running,available=function(kind,name)if r.availableHook then r.availableHook(kind,name)end;return not r.foreign[kind..':'..name]end,
        prCommand=function(name,options,fn)r.commands[name]={handler=fn,options=options,mode='pr'}end,
        oxCommand=function(name,options,fn)r.commands[name]={handler=fn,options=options,mode='ox'}end}
    r.spec={side=r.side,isCurrent=function()return r.current end,isReady=function()if r.readyHook then r.readyHook()end;return r.ready end}
    r.factory=H.load('kernel/entry/native_registration.lua',H.environment())
    function r.allocate()r.api=r.factory(r.spec,r.ports);return r.api end
    function r.fire(name,source,...)
        r.origin=source;for _,t in ipairs(r.bus)do if t.name==name and not t.removed then t.handler(...)end end
    end
    return r
end
return M
