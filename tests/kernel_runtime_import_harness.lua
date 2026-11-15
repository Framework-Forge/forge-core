-- Whole installed ox init/native-cache/locale/table bodies; IO, Cfx exports/events/scheduler/JSON codec virtual.
local C=dofile('tests/kernel_cache_delivery_harness.lua');local H,P=C.H,C.P
local T={C=C,H=H,P=P,ox='../../../[ox]/ox_lib/'}
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
function T.provider()
    local r={current=true,ped=10,playerId=1,serverId=2,vehicle=0,seat=-1,weapon=0,handlers={},threads={},exported={},trace={},lang='en'}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    local function listen(name,fn)r.handlers[name]=r.handlers[name]or{};table.insert(r.handlers[name],fn)end
    function r.fire(name,...)for _,fn in ipairs(r.handlers[name]or{})do fn(...)end end
    r.host={game='fivem'}
    local hostEnv=H.environment({cache=r.host,PlayerId=function()return r.playerId end,GetPlayerServerId=function()return r.serverId end,
        PlayerPedId=function()return r.ped end,GetVehiclePedIsIn=function()return r.vehicle end,
        GetPedInVehicleSeat=function(_,seat)return seat==r.seat and r.ped or 0 end,GetVehicleMaxNumberOfPassengers=function()return 4 end,
        GetMount=false,IsPedOnMount=false,GetCurrentPedWeapon=function()return r.weapon~=0,r.weapon end,
        TriggerEvent=function(...)r.fire(...)end,CreateThread=function(fn)r.threads[#r.threads+1]=fn end,Wait=function()coroutine.yield()end,lib={}})
    H.load(T.ox..'resource/cache/client.lua',hostEnv)
    local exported=setmetatable({ox_lib={hasLoaded=function()return true end,cache=function(receiver,key)
        assert(receiver==nil);r.record('native-export',key);if r.readHook then r.readHook(key)end;return r.host[key]
    end}}, {__call=function(_,name,fn)r.exported[name]=fn end})
    local env=H.environment({_VERSION=_VERSION,msgpack={setoption=function()end},exports=exported,
        GetCurrentResourceName=function()return'forge-core'end,GetResourceState=function()return'started'end,
        IsDuplicityVersion=function()return false end,GetGameName=function()return'fivem'end,
        PlayerId=function()return r.playerId end,GetPlayerServerId=function()return r.serverId end,
        RegisterNetEvent=listen,AddEventHandler=listen,GetNumResourceMetadata=function()return 0 end,
        GetResourceMetadata=function()return nil end,Citizen={CreateThreadNow=function(fn)fn()end},
        SetTimeout=function()error('no callable cache timeout requested')end,
        warn=function(...)r.record('warn',...)end,json={decode=function(raw)return raw and test_decode_json(raw)or nil end}})
    local prior=getmetatable(env).__index
    setmetatable(env,{__index=function(t,k)if k=='lib'or k=='locale'then return nil end;return prior(t,k)end})
    env._ENV=env
    env.LoadResourceFile=function(resource,path)
        -- The public require loader is outside this fixture/lot; init gets its uncalled export fallback.
        if resource=='ox_lib'and path:match('^imports/require/')then return nil end
        assert(resource=='forge-core','locale fixture never reads another runtime resource')
        local key=assert(path:match('^locales/([^/]+)%.json$'),'unexpected import read '..path)
        r.record('file',resource,path)
        local ok,value=pcall(read,H.qbx..'locales/'..key..'.json');return ok and value or nil
    end
    H.load(T.ox..'init.lua',env)
    env.table.wipe=function(t)for k in pairs(t)do t[k]=nil end end
    H.load(T.ox..'imports/table/shared.lua',env)
    env.lib.getLocaleKey=function()return r.lang end
    H.load(T.ox..'imports/locale/shared.lua',env)()
    r.env,r.nativeCache=env,env.cache
    r.ports={nativeCache=env.cache,locale=function(...)if r.translateHook then r.translateHook(...)end;return env.locale(...)end,
        isCurrent=function()return r.current end,running=coroutine.running}
    r.factory=H.load('../pr_bridge/bridge/delivery/forge_runtime_imports.lua',H.environment())
    function r.mount()r.api=r.factory(r.ports);return r.api end
    function r.pollNative()
        r.nativeCo=r.nativeCo or coroutine.create(assert(r.threads[1]));local ok,err=coroutine.resume(r.nativeCo);assert(ok,err)
    end
    function r.setLanguage(lang)r.lang=lang;r.fire('ox_lib:setLocale',lang)end
    return r
end
function T.context()
    local r=C.context();r.runtimeImports=T.provider();r.importCaptures={}
    local env=C.C.M.S.W.D.A.E.env();local req=env.require
    env.type=r.fixture.modules.Stores.environment().type;env.print=function()end
    env.require=function(name)local ctor=req(name);if type(ctor)~='function'then return ctor end
        return function(...)local args=table.pack(...);local p=args[2]or args[1]
            if type(p)=='table'and(p.cache or p.locale)then r.importCaptures[name]=p end
            if name=='kernel.config.client'then r.configConstructions=r.configConstructions+1 end
            return ctor(table.unpack(args,1,args.n))
        end
    end
    r.importPorts={deliveryContext=r.deliveryPorts,imports=r.runtimeImports.ports,createImports=r.runtimeImports.factory}
    r.importFactory=H.load('kernel/client/runtime_import_context.lua',env)
    function r.prepareImports()r.api=r.importFactory(r.fixture.state,r.importPorts);r.graph=r.api.Graph;return r.api end
    function r.installImports()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return T
