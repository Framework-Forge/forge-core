local P=dofile('tests/kernel_player_harness.lua');local H=P.H;local T={P=P,H=H}
T.path='../pr_bridge/bridge/frameworks/forge/client_factory.lua'
function T.new(ported)
    local r={view={PlayerData={}},current=true,events={},trace={},ready=false,dirty=0,pulls=0}
    local function record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    r.cache={GetResourceState=function(resource,key)
        assert(resource=='qbx_core'and key=='session');r.pulls=r.pulls+1
        if r.cacheHook then r.cacheHook()end;return r.session
    end,get=function(key)assert(key=='playerData');return r.cached end}
    r.inventory={GetItemCount=function(name)assert(name=='black_money');record('inventory',name);return r.dirty end}
    r.ports={view=r.view,cache=r.cache,cacheNamespace='qbx_core',inventory=r.inventory,isCurrent=function()return r.current end,
        readSessionReady=function()record('ready');if r.readyHook then r.readyHook()end;return r.ready end,
        triggerLocal=function(...)record('local',...);return 78 end,triggerServer=function(...)record('server',...);return 79 end}
    if ported then
        r.api=H.load(T.path,H.environment())(r.ports);r.framework=r.api.Framework
        for _,d in ipairs(r.api.Events)do r.events[d.name]={handler=d.handler,network=d.network}end
    else
        local env=H.environment({ActiveBridges={frameworks='qbx'},QBX=r.view,Bridge={cache=r.cache,inventory=r.inventory},
            exports={qbx_core={IsPlayerLoaded=function()return r.ports.readSessionReady()end}},
            TriggerEvent=r.ports.triggerLocal,TriggerServerEvent=r.ports.triggerServer,
            RegisterNetEvent=function(name,handler)r.events[name]={handler=handler,network=true}end,
            AddEventHandler=function(name,handler)r.events[name]={handler=handler,network=false}end})
        r.framework=H.load('../pr_bridge/bridge/frameworks/qbx/client.lua',env)
    end
    function r.emit(name,...)return assert(r.events[name],name).handler(...)end
    return r
end
function T.data()
    return{citizenid='A80',charinfo={firstname='Ana',lastname='Forge',birthdate='2000-01-02',gender=1},
        job={name='police',label='Police',grade={level=2,name='Sergeant'},onduty=true},gang={name='none'},money={cash=50,bank=500},metadata={hunger=70}}
end
return T
