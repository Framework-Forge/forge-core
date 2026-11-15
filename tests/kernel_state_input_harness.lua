-- Real PR provider and real client50 graph; only platform/time/network/IO are virtual.
local D=dofile('tests/kernel_client_domains_harness.lua')
local H=D.H
local T={D=D,H=H}
function T.ports()
    local r={commands={},mappings={},timers={},bags={},removed={},effects={},nextCookie=0,adds=0,now=0,errors={}}
    local env=H.environment({Bridge={},
        RegisterCommand=function(name,fn)
            assert(not r.commands[name],'virtual native command collision '..name)
            r.commands[name]=fn
            if r.commandHook then r.commandHook(name)end
            if r.commandFailure==name then error('partial native command failure',0)end
        end,
        RegisterKeyMapping=function(name,description,mapper,key)r.mappings[#r.mappings+1]={name,description,mapper,key}end,
        SetTimeout=function(ms,fn)r.timers[#r.timers+1]={ms=ms,fn=fn}end,
        TriggerEvent=function(...)r.effects[#r.effects+1]=table.pack(...)end,
        IsPauseMenuActive=function()return r.paused==true end,
        GetControlInstructionalButton=function(_,hash)return't_'..hash end,
        joaat=function(s)local n=0;for i=1,#s do n=(n*31+s:byte(i))&0xffffffff end;return n end,
        print=function(...)r.errors[#r.errors+1]=table.pack(...)end})
    r.provider=H.load('../pr_bridge/bridge/addKeybind/client.lua',env)
    local remove=r.provider.remove
    r.provider.remove=function(name)if r.failKeyRemove==name then return false end;return remove(name)end
    r.ports={keybind=r.provider,
        availableKey=function(name)
            if r.preflight then r.preflight(name)end
            return not r.commands['+'..name]and not r.commands['-'..name]and not r.occupied
        end,
        addBag=function(key,filter,handler)
            r.adds=r.adds+1;if r.failAdd==r.adds then error('bag install failure',0)end
            r.nextCookie=r.nextCookie+1;local cookie=r.nextCookie
            r.bags[cookie]={key=key,filter=filter,handler=handler}
            if r.onAdd then r.onAdd(cookie)end;return cookie
        end,
        removeBag=function(cookie)
            if r.removeHook then r.removeHook(cookie)end
            if r.failRemove==cookie then return false end
            assert(r.bags[cookie],'remove only owned live cookie');r.bags[cookie]=nil;r.removed[#r.removed+1]=cookie
        end,
        resolveEntity=function(name)return 20,tonumber(name:match('%d+'))end}
    function r.emit(key,bag,value,...)
        local out
        for _,d in pairs(r.bags)do
            if d.key==key and(d.filter==nil or d.filter==''or d.filter==bag)then out=table.pack(d.handler(bag,key,value,...))end
        end
        return out
    end
    function r.key(name,down)return assert(r.commands[(down==false and'-'or'+')..name])()end
    function r.common(spec)
        r.spec=spec or{owner={},bags={},keys={},isCurrent=function()return not r.replaced end}
        r.api=H.load('kernel/shared/state_input_registration.lua',H.environment())(r.spec,r.ports);return r.api
    end
    return r
end
function T.new(options)
    local r=T.ports();r.graphFixture=D.new();local g=r.graphFixture
    -- The fixture builds central49 before50. Optional Discord variant uses its actual factory.
    if options=='no-discord'then
        local p=g.central
        p.config.discord.enabled=false
        p.api.Parts.Runtime.Discord=H.load('kernel/client/discord.lua',D.A.E.env())({core=g.state,native=p.native,
            cache=p.ports.cache,config=p.config,globalState=p.runtime.globalState})
    end
    r.graph=g.mount();r.central=g.central
    r.ports.resolveEntity=r.graph.Central.Parts.Helpers.Lib.getEntityAndNetIdFromBagName
    local waitEnv=H.environment({GetGameTimer=function()return r.now end,Wait=function()r.now=r.now+1000;if r.yieldWait then coroutine.yield('waiting')end end})
    r.central.library.waitFor=H.load('../pr_bridge/bridge/utils/waitFor.lua',waitEnv)
    r.net={};r.central.native.NetworkDoesEntityExistWithNetworkId=function(id)return r.net[id]~=nil end
    r.central.native.NetworkGetEntityFromNetworkId=function(id)return r.net[id]end
    function r.prepare()
        r.api=H.load('kernel/client/state_input_registration.lua',D.A.E.env())(r.graph,r.ports);return r.api
    end
    return r
end
return T
