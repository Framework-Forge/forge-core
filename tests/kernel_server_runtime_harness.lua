-- Isolated test doubles; no resource/SQL/network/commands/chat/chaves reais.
local V = dofile('tests/kernel_legacy_harness.lua')
local H, P = V.H, V.P
local R = {H = H, P = P, V = V}
function R.new(ported, module)
    local r = {trace = {}, commands = {}, events = {}, exported = {}, globalState = {sentinel = true},
        resource = 'forge-core', convars = {['inventory:framework']='qbx',onesync_enableInfinity=1,sv_maxclients=48},
        dependencies = {}, entities = {}, players = {'1','2','3'}, optin = true, aces = {}, pedVehicle = 20,
        peds = {[1]=10,[2]=11,[3]=12}, coords = {[10]=V.vector(0,0,0),[11]=V.vector(5,0,0),[12]=V.vector(100,0,0)},
        keysState = 'started', plate = 'ABC', nearby = {120,130}, classResponse = {[101]=1,[102]=2},
        actionSuccess = true, randomIndex = 1}
    function r.record(kind,...) r.trace[#r.trace+1] = {kind=kind,args=P.snapshot(table.pack(...))} end
    local function effect(name) return function(...) r.record(name,...) end end
    local native = {}
    native.GetHashKey = function(name)
        r.record('hash',name); local hash=0; for i=1,#name do hash=(hash*31+name:byte(i))%1000000 end; return hash
    end
    native.GetConvar = function(key,default) r.record('convar',key,default); local value=r.convars[key]; if value==nil then return default end; return value end
    native.GetConvarInt = native.GetConvar
    native.ExecuteCommand = effect('execute-simulated')
    native.SetRoutingBucketEntityLockdownMode = effect('lockdown')
    native.GetInvokingResource = function() r.record('caller'); return r.caller end
    native.GetCurrentResourceName = function() r.record('resourceName'); return r.resource end
    native.TriggerClientEvent = effect('client')
    native.GetPlayers = function() r.record('players'); if r.playersHook then return r.playersHook() end; return r.players end
    native.Entity = function(entity)
        r.record('entity',entity); r.entities[entity] = r.entities[entity] or {}
        local state = r.entities[entity]
        state.set = state.set or function(_,key,value,replicated) r.record('entityState',entity,key,value,replicated); state[key]=value end
        return {state=state}
    end
    native.Player = function(source) r.record('playerState',source); return {state={set=function(_,...) r.record('state',source,...) end}} end
    native.GetResourceState = function(resource)
        r.record('resourceState',resource)
        if resource=='forge-chat'then return r.chatState or 'missing' end
        assert(resource=='pr_carkeys');return r.keysState
    end
    native.GetPlayerPed = function(source) r.record('ped',source); return r.peds[tonumber(source)] or 0 end
    native.GetEntityCoords = function(ped) r.record('coords',ped); return r.coords[ped] or V.vector(0,0,0) end
    native.GetPlayerRoutingBucket = function(source) r.record('bucket',source); return 4 end
    native.GetVehiclePedIsIn = function(...) r.record('inVehicle',...); return r.pedVehicle end
    native.NetworkGetNetworkIdFromEntity = function(entity) r.record('netId',entity); return entity+100 end
    native.NetworkGetEntityFromNetworkId = function(id) r.record('fromNet',id); return id-100 end
    native.DoesEntityExist = function(entity) r.record('exists',entity); return r.entityExists~=false end
    native.IsPlayerAceAllowed = function(source,ace) r.record('ace',source,ace); return (r.aces[tonumber(source)] or {})[ace] == true end
    native.DropPlayer = effect('drop')
    native.GetPlayerName = function(source) r.record('name',source); return 'Player '..tostring(source) end
    r.native = native
    local shared = H.load('kernel/shared/main.lua',H.environment())({weapons={[123]={name='weapon_old',label='Old'}},
        locations={shop=V.vector(1,2,3)},vehicles={}})
    shared.SetVehicles({car={model='car',hash=101,name='Car',category='cars'}})
    local core = {Shared=shared,Players={},Player_Buckets={},Entity_Buckets={},UsableItems={}}
    r.core = core
    local function makePlayer(id)
        local player = {PlayerData={source=id,citizenid='CID'..id,job={name='taxi',label='Taxi',grade={level=1,name='Driver'},onduty=false},
            gang={name='none',label='None',grade={level=0,name='None'}},money={cash=0,bank=0}},Functions={}}
        player.Functions.AddMoney=function(kind,amount) r.record('money-add',id,kind,amount); if type(amount)=='number' then player.PlayerData.money[kind]=(player.PlayerData.money[kind] or 0)+amount end end
        player.Functions.SetMoney=function(kind,amount) r.record('money-set',id,kind,amount); player.PlayerData.money[kind]=amount end
        player.Functions.SetJob=function(...) r.record('job-set',id,...); return r.actionSuccess,{reason='rejected'} end
        player.Functions.SetGang=function(...) r.record('gang-set',id,...); return r.actionSuccess,{reason='rejected'} end
        return player
    end
    if module~='main' then core.Players[1],core.Players[2],core.Players[3]=makePlayer(1),makePlayer(2),makePlayer(3) end
    local services = {}
    services.GetPlayer=function(source) r.record('lookup',source); return core.Players[tonumber(source)] end
    services.IsOptin=function(source) r.record('optin',source); if r.optins then return r.optins[tonumber(source)]==true end; return r.optin end
    services.Notify=effect('notify')
    for _,name in ipairs({'AddPermission','RemovePermission','DeleteVehicle','Logout','ForceDeleteCharacter'}) do services[name]=effect(name) end
    services.ToggleOptin=function(source) r.record('ToggleOptin',source); r.optin=not r.optin end
    for _,name in ipairs({'SetPlayerPrimaryJob','AddPlayerToJob','RemovePlayerFromJob'}) do
        services[name]=function(...) r.record(name,...); return r.actionSuccess,{reason='rejected'} end
    end
    r.services = services
    local helpers = {getVehiclePlate=function(vehicle) r.record('plate',vehicle); return r.plate end,
        spawnVehicle=function(options) r.record('spawn',options); return 121,21 end, table={mapBySubfield=function(items,key)
            local result={}; for _,item in pairs(items) do if item[key] then result[item[key]]=result[item[key]] or {}; table.insert(result[item[key]],item) end end; return result
        end}}
    local library = {print={error=effect('error')},callback={}}
    library.versionCheck=effect('versionCheck')
    library.checkDependency=function(...) r.record('dependency',...); return r.dependencies[(...)]~=false end
    library.callback.await=function(name,...)
        r.record('callback',name,...)
        if r.awaitHook then return r.awaitHook(name,...) end
        if name=='qbx_core:client:getVehiclesInRadius' then return H.copy(r.nearby) end
        assert(name=='qbx_core:client:getVehicleClasses'); return r.classResponse
    end
    local promises = {}
    local function newPromise()
        r.record('promise-new'); local p={state='pending'}
        function p:resolve(value) r.record('promise-resolve',value); self.state,self.value='resolved',value end
        function p:reject(value) r.record('promise-reject',value); self.state,self.value='rejected',value end
        promises[#promises+1]=p; return p
    end
    local function awaitPromise(p)
        r.record('promise-await')
        while p.state=='pending' do coroutine.yield('promise pending') end
        if p.state=='rejected' then error(p.value,0) end
        return p.value
    end
    local locale=function(key,...) if select('#',...)>0 then return key..':'..tostring((...)) end; return key end
    local removeKeyItem=function(...) r.record('removeKey',...); if r.keyError then error('simulated key error',0) end; return false end
    local chatMessage=function(...) r.record('chat',...); if r.chatError then error('simulated chat error',0) end end
    local logger={log=effect('log')}
    local config={server={pvp=true,closed=false,whitelistPermission='admin'},logging={role={'admin'}},
        giveVehicleKeys=function(...) r.record('giveKey',...) end}
    local random=function(...) r.record('random',...); return r.randomIndex end
    local json={encode=function(value) r.record('encode',value); return '<mock-error>' end}
    r.bindings={core=core,native=native,library=library,helpers=helpers,globalState=r.globalState,
        newPromise=newPromise,awaitPromise=awaitPromise,random=random,config=config,locale=locale,logger=logger,
        removeKeyItem=removeKeyItem,chatMessage=chatMessage,services=services,json=json}
    r.promises,r.config,r.library,r.helpers=promises,config,library,helpers
    local env=H.environment()
    if ported then
        r.api=H.load('kernel/server/'..module..'.lua',env)(r.bindings)
        r.initialize=r.api.Initialize or function() return false end
        for _,e in ipairs(r.api.Events) do r.events[e.name]=e.handler end
        for _,e in ipairs(r.api.Commands or {}) do r.commands[e.name]=e end
        assert(#r.trace==0,'No external/registration/native/promise/SQL effects in constructor')
    else
        for name,fn in pairs(native) do env[name]=fn end
        for name,fn in pairs(services) do env[name]=fn end
        env.QBX,env.GlobalState,env.qbx,env.lib,env.json,env.locale=core,r.globalState,helpers,library,json,locale
        env.require=function(name)
            if name=='shared.main' then return shared elseif name=='config.server' then return config elseif name=='modules.logger' then return logger end
            error('External import '..tostring(name))
        end
        env.math.random=random; env.promise={new=function() return newPromise() end}; env.Citizen={Await=awaitPromise}
        env.RegisterNetEvent=function(name,fn) r.events[name]=function(source,...) env.source=source; return fn(...) end end
        env.exports=setmetatable({pr_carkeys={RemoveTempKeyItem=function(_,...) return removeKeyItem(...) end},
            chat={addMessage=function(_,...) return chatMessage(...) end}},{__call=function(_,name,fn) r.exported[name]=fn end})
        library.addCommand=function(name,options,handler) r.commands[name]={name=name,options=options,handler=handler} end
        r.api=r.exported
        r.initialize=function()
            local text=P.source('server/'..module..'.lua')
            text=text:gsub('PlayerJob%?%.([%w_.]+)','(PlayerJob and PlayerJob.%1)')
                :gsub('PlayerGang%?%.([%w_.]+)','(PlayerGang and PlayerGang.%1)')
            P.loadOrigin('server/'..module..'.lua',env,text)
            if module=='main' then r.core=env.QBX end
        end
    end
    r.env=env
    function r.command(name,args,source) return assert(r.commands[name],name).handler(source or 1,args or {}) end
    return r
end
function R.args(command,values)
    local args={}; for key,value in pairs(values or {}) do args['command.'..command..'.params.'..key..'.name']=value end; return args
end
function R.compare(module,name,action)
    local a,b=R.new(false,module),R.new(true,module)
    a.initialize(); b.initialize()
    H.same(P.snapshot(table.pack(action(b))),P.snapshot(table.pack(action(a))),name..': returns')
    H.same(b.trace,a.trace,name..': effects')
    H.same(P.snapshot(b.core),P.snapshot(a.core),name..': state')
    H.same(b.globalState,a.globalState,name..': globals')
end
return R

