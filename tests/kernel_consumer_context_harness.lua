local I=dofile('tests/kernel_import_registry_harness.lua');local H,P=I.H,I.P
local T={I=I,H=H,P=P}
function T.new(side)
    local r=I.new(side);r.gets=0;r.tokens={};r.marked={};r.data={citizenid='A',job={name='police',onduty=true},gang={name='none'},charinfo={firstname='Ana',lastname='Forge'}}
    r.oldQBX={foreign=true};r.target.QBX=r.oldQBX
    r.ports.getPlayerData=function()r.gets=r.gets+1;if r.getHook then r.getHook()end;return r.data end
    r.ports.events={listen=function(name,fn)
        if r.listenHook then r.listenHook(name,fn)end
        local token={name=name,handler=fn,active=true};r.tokens[#r.tokens+1]=token;return token
    end,markNetwork=function(name)
        r.marked[#r.marked+1]=name;if r.markHook then r.markHook(name)end;return true
    end,remove=function(token)
        assert(token.active,'only active consumer token may be removed')
        if r.refuseRemove then return false end;token.active=false;return true
    end}
    local registry=r.factory;local constructors={['kernel.imports.legacy_registry']=registry,
        ['kernel.modules.playerdata']=H.load('kernel/modules/playerdata.lua',H.environment()),
        ['kernel.shared.event_registration']=H.load('kernel/shared/event_registration.lua',H.environment())}
    local factory=H.load('kernel/imports/consumer_context.lua',H.environment({require=function(name)return assert(constructors[name],name)end}))
    function r.mount()r.api=factory(r.ports);return r.api end
    function r.emit(name,...)
        for _,token in ipairs(r.tokens)do if token.active and token.name==name then token.handler(...)end end
    end
    function r.active()local n=0;for _,token in ipairs(r.tokens)do if token.active then n=n+1 end end;return n end
    return r
end
function T.original(side,data)
    local r={gets=0,events={},target={}};local env=H.environment()
    env.IsDuplicityVersion=function()return side=='server'end
    env.exports={qbx_core={GetPlayerData=function()r.gets=r.gets+1;return data end}}
    env.RegisterNetEvent=function(name,fn)r.events[name]=fn end
    P.loadOrigin('modules/playerdata.lua',env);r.target.QBX=rawget(env,'QBX')
    function r.emit(name,...)return r.events[name](...)end
    return r
end
return T
