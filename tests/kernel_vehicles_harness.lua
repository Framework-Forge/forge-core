-- Whole installed vehicle sources vs private ports; only memory/virtual SQL/native/key/UI effects.
local W=dofile('tests/kernel_world_harness.lua')
local J=dofile('tests/kernel_job_catalog_harness.lua')
local H,P=W.H,W.P
local R={H=H,P=P,env=W.env,J=J}
function R.hash(v)
    local s=tostring(v):lower();local n=0;for i=1,#s do n=(n*31+s:byte(i))%100000000 end;return n
end
function R.vector(x,y,z)
    return setmetatable({x=x,y=y,z=z},{__sub=function(a,b)return R.vector(a.x-b.x,a.y-b.y,a.z-b.z)end,
        __len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end})
end
function R.config(ported)
    if ported then return{Vehicles=H.load('kernel/config/forge_vehicles.lua',R.env())(),AdminAce='forge-core.admin',NotifyPos='top-right'}end
    local e=H.environment({PR={}});H.load('shared/vehicles.lua',e)
    e.PR.AdminAce='forge-core.admin';e.PR.NotifyPos='top-right';return e.PR
end
function R.new(ported,uninitialized)
    local r={trace={},events={},callbacks={},exports={},timers={},files={},now=1000,jobResult=true,aces={},coreState='started',
        resources={pr_carkeys='started',['forge-garage']='started'},saved=true,syncCount=0,tempResult=true,keyItemResult=true,
        originalKeyResult={success=true,barcode='K1'},insertResult=77,duplicate=0,entities={[101]=true},netId=501,
        vehicle=101,model=R.hash('sultan'),plate=' TEST01 ',positions={[11]=R.vector(0,0,0),[12]=R.vector(1,0,0),[101]=R.vector(5,0,0)},
        players={[1]={PlayerData={citizenid='C1',license='L1'}},[2]={PlayerData={citizenid='C2',license='L2'}}}}
    r.config=R.config(ported);r.codec=J.persistence().codec
    function r.record(k,...)r.trace[#r.trace+1]={kind=k,args=P.snapshot(table.pack(...))}end
    r.json={encode=function(v)if r.encodeError then error('fixture-encode',0)end
        if r.largeProps then return string.rep('x',r.largeProps)end;return r.codec.encode(v)end,
        decode=function(v)if r.decodeError then error('fixture-decode',0)end;return r.codec.decode(v)end}
    r.initial={sultan={model='sultan',name='Sultan',brand='Karin',hash='sultan',class='B',category='sports',price=100,stock=5},
        disabled={model='disabled',name='Disabled',hash=20,active=false,class='C'}}
    r.files[r.config.Vehicles.Storage]=r.codec.encode(r.initial)
    r.catalogFile={read=function(resource,path)assert(resource=='forge-core');r.record('file-read',path)
            if r.readError then error('fixture-read',0)end;return r.files[path]end,
        write=function(resource,path,bytes,len)assert(resource=='forge-core'and len==-1);r.record('file-write',path,bytes,len)
            if r.writeError then error('fixture-write',0)end
            if r.saved~=false and r.saved~=nil then r.files[path]=bytes end;return r.saved end}
    r.native={GetCurrentResourceName=function()return'forge-core'end,
        IsPlayerAceAllowed=function(src,ace)r.record('ace',src,ace);return r.aces[ace]==true end,
        joaat=R.hash,print=function(...)r.record('print',...)end,
        SetTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]={ms=ms,fn=fn}end,
        GetPlayerName=function(src)return r.players[tonumber(src)]and'Player'..src end,
        NetworkGetEntityFromNetworkId=function(id)if r.networkHook then return r.networkHook(id)end;return id==r.netId and r.vehicle or 0 end,
        GetGameTimer=function()return r.now end,
        DoesEntityExist=function(v)return r.entities[v]==true end,
        Wait=function(ms)r.record('wait',ms);r.now=r.now+math.max(ms,1);if r.waitHook then r.waitHook(ms)end end,
        GetEntityType=function()return r.entityType or 2 end,
        GetPlayerPed=function(src)return r.players[src]and 10+src or 0 end,
        GetVehiclePedIsIn=function(ped)return r.occupant==false and 0 or r.vehicle end,
        GetEntityCoords=function(v)return r.positions[v]or R.vector(0,0,0)end,
        GetEntityModel=function()return r.model end,
        GetVehicleNumberPlateText=function()return r.plate end,
        SetVehicleNumberPlateText=function(v,plate)r.record('set-plate',v,plate);r.plate=plate end}
    r.kernel={getPlayer=function(src)r.record('lookup',src);if r.lookupHook then return r.lookupHook(src)end;return r.players[src]end,
        setVehicleCatalog=function(data)r.record('project',data);r.syncCount=r.syncCount+1
            if r.syncHook then return r.syncHook(data)end
            local n=0;for _ in pairs(data)do n=n+1 end;r.projected=H.copy(data);return true,n end,
        enablePersistence=function(v)r.record('persisted',v);if r.persistenceError then error('fixture-persistence',0)end;return true end,
        resourceState=function()r.record('core-state');return r.coreState end,
        resourceName=function()return'forge-core'end}
    r.integration={resourceState=function(resource)r.record('resource-state',resource);return r.resources[resource]or'stopped'end,
        buyOriginalKey=function(src,plate)r.record('original-key',src,plate)
            if r.originalKeyHook then return r.originalKeyHook(src,plate)end;return r.originalKeyResult end,
        registerExistingPersistentVehicle=function(...)r.record('garage',...);if r.garageError then error('fixture-garage',0)end end}
    r.services={JobService={canManage=function(src)r.record('job-access',src);if r.jobError then error('fixture-job',0)end;return r.jobResult end}}
    r.translate=function(k,p)r.record('translate',k,p);return k end
    r.library={notify={NotifyPlayer=function(...)r.record('notify',...)end}}
    local keyProxy={GiveTempKey=function(_,...)r.record('temp-key',...);if r.tempError then error('fixture-temp',0)end;return r.tempResult end,
        CreateTempKeyItem=function(_,...)r.record('key-item',...);if r.itemError then error('fixture-item',0)end;return r.keyItemResult end,
        RemoveTempKey=function(_,...)r.record('temp-remove',...);if r.removeError then error('fixture-key-remove',0)end;return true end}
    r.library.vehicle_key=H.load('../pr_bridge/bridge/vehicle_key/pr_carkeys/server.lua',H.environment({
        ActiveBridges={vehicle_key='pr_carkeys'},exports={pr_carkeys=keyProxy},Debug=function()end,Lang={t=function()return''end}}))
    local function driver(kind,sql,params,cb)
        r.record('db-'..kind,sql,params)
        if r.dbHook then local custom,value=r.dbHook(kind,sql,params);if custom then return cb(value)end end
        if r.dbError==kind then error('fixture-db-'..kind,0)end
        if kind=='scalar'then cb(r.duplicate)elseif kind=='insert'then cb(r.insertResult)else cb(1)end
    end
    r.library.database=H.load('../pr_bridge/bridge/database/oxmysql/server.lua',H.environment({
        ActiveBridges={database='oxmysql'},GetResourceState=function()return'started'end,
        exports={oxmysql=setmetatable({},{__index=function(_,kind)return function(_,...)return driver(kind,...)end end})},
        promise={new=function()return{resolve=function(self,v)self.value=v;self.resolved=true end}end},
        Citizen={Await=function(p)assert(p.resolved);return p.value end},Debug=function()end}))
    r.clientSnapshot={netId=r.netId,modelName='sultan',props={color1=2}}
    r.library.callback={awaitClient=function(target,name,timeout)
        assert(timeout==7000 and name==r.config.Vehicles.Callbacks.getCurrentVehicle);r.record('client-snapshot',target,name,timeout)
        if r.snapshotHook then return r.snapshotHook(target)end;return H.copy(r.clientSnapshot)end}
    local e=H.environment({PR=r.config,ForgeCore=r.services,pr_lib=r.library,json=r.json,load=load,print=r.native.print})
    r.services.t=r.translate;r.services.Callbacks={register=function(n,fn)r.callbacks[n]=fn end}
    for n,fn in pairs(r.native)do e[n]=fn end
    e.GetResourceState=function(name)if name=='qbx_core'then return r.kernel.resourceState()end;return r.integration.resourceState(name)end
    e.LoadResourceFile=r.catalogFile.read;e.SaveResourceFile=r.catalogFile.write
    e.AddEventHandler=function(n,fn)r.events[#r.events+1]={name=n,handler=fn,network=false}end
    e.SetTimeout=r.native.SetTimeout;e.exports=setmetatable({qbx_core={
        SetVehicleCatalog=function(_,...)return r.kernel.setVehicleCatalog(...)end,GetPlayer=function(_,...)return r.kernel.getPlayer(...)end,
        EnablePersistence=function(_,...)return r.kernel.enablePersistence(...)end},
        pr_carkeys={BuyOriginalKey=function(_,...)return r.integration.buyOriginalKey(...)end}},
        {__call=function(_,n,fn)r.exports[n]=fn end})
    e.TriggerClientEvent=function(name,...)assert(name=='forge_garage:client:registerExistingPersistentVehicle');return r.integration.registerExistingPersistentVehicle(...)end
    local ports={config=r.config,library=r.library,native=r.native,services=r.services,translate=r.translate,
        kernel=r.kernel,catalogFile=r.catalogFile,json=r.json,compile=load,vehicleIntegration=r.integration}
    r.ports=ports
    if ported then
        r.api=H.load('kernel/server/vehicle_catalog.lua',R.env())(ports)
        assert(#r.trace==0 and #r.timers==0 and r.api.Service.revision==0,'inactive catalog constructor')
        r.d=r.api.Service;ports.service=r.d
        r.transport=H.load('kernel/server/vehicle_callbacks.lua',R.env())(ports)
        r.events=r.api.Events;r.exports=r.api.Exports
        for _,d in ipairs(r.transport.Callbacks)do assert(d.options.access=='admin');r.callbacks[d.name]=d.handler end
        if not uninitialized then assert(r.api.Initialize());assert(not r.api.Initialize())end
    else
        H.load('server/vehicle/service.lua',e);r.d=e.ForgeCore.VehicleService
        H.load('server/vehicle/callbacks.lua',e)
    end
    r.env=e;r.initTrace=H.copy(r.trace)
    function r.runTimers(ms)local list=r.timers;r.timers={};for _,v in ipairs(list)do if not ms or ms==v.ms then v.fn()else r.timers[#r.timers+1]=v end end end
    function r.fireCoreStarted()for _,d in ipairs(r.events)do d.handler(ported and'forge-core'or'qbx_core')end end
    function r.cb(key,...)return assert(r.callbacks[r.config.Vehicles.Callbacks[key]])(...)end
    function r.state()return P.snapshot({r.d,r.files,r.projected,r.plate})end
    r.trace={};return r
end
function R.outcome(fn,r)return W.outcome(fn,r)end
function R.case(name,fn)
    local a,b=R.new(false),R.new(true)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return');H.same(b.trace,a.trace,name..' effects');H.same(b.state(),a.state(),name..' state')
end
function R.menu(ported,options)
    local r=W.menu(ported);r.config.Vehicles=R.config(ported).Vehicles
    r.vehicle={model='sultan',name='Sultan',brand='Karin',category='sports',class='B',type='automobile',price=100,stock=5,active=true,hash='sultan'}
    r.payload={vehicles={r.vehicle},revision=1};r.entities={[100]=true};r.networked=true;r.netId=500;r.spawnResult=100;r.ped=11;r.now=1000;r.saved={}
    r.snapshotProps={model=R.hash('sultan'),plate='ABC'}
    local await=r.library.callback.await
    r.library.callback.await=function(name,timeout,...)
        local vehicle=false;for k,n in pairs(r.config.Vehicles.Callbacks)do if name==n then vehicle=true end end
        if not vehicle then return await(name,timeout,...)end
        assert(timeout==10000);r.record('vehicle-await',name,timeout,...)
        if r.vehicleHook then return r.vehicleHook(name,...)end
        if name==r.config.Vehicles.Callbacks.getAll then return true,H.copy(r.payload)end
        r.saved[#r.saved+1]={name=name,args=H.copy(table.pack(...))};return true,{}
    end
    r.callbacks={}
    r.library.callback.register=function(n,fn)r.callbacks[n]=fn end
    local native=r.native
    native.PlayerPedId=function()return r.ped end
    native.GetVehiclePedIsIn=function()return r.inVehicle==false and 0 or 100 end
    native.DoesEntityExist=function(v)return r.entities[v]==true end
    native.NetworkGetEntityIsNetworked=function()return r.networked end
    native.NetworkRegisterEntityAsNetworked=function(v)r.record('network-register',v);if not r.networkFail then r.networked=true end end
    native.NetworkGetNetworkIdFromEntity=function()return r.netId end
    native.GetGameTimer=function()return r.now end
    native.Wait=function(ms)r.record('wait',ms);r.now=r.now+1000;if r.waitHook then r.waitHook()end end
    native.GetOffsetFromEntityInWorldCoords=function(...)r.record('offset',...);return R.vector(0,6,30.5)end
    native.GetGroundZFor_3dCoord=function()return not r.noGround,30 end
    native.GetEntityHeading=function()return 90 end
    native.GetEntityArchetypeName=function()return'sultan'end
    native.vector3=R.vector
    for _,n in ipairs({'SetVehicleNumberPlateText','SetVehicleDoorsLocked','SetVehicleEngineOn','SetVehicleOnGroundProperly'})do
        native[n]=function(...)r.record(n,...)end
    end
    native.DeleteEntity=function(v)r.record('delete-vehicle',v);r.entities[v]=nil end
    r.random=function()return 42 end
    r.library.fivem={blips=H.load('../pr_bridge/bridge/fivem/blips/shared.lua',H.environment()),
        getVehicleProperties=function(v)r.record('properties',v);return H.copy(r.snapshotProps)end,
        streaming={createVehicle=function(...)r.record('create-vehicle',...);return r.spawnResult,'fixture-create'end}}
    if options then options(r)end
    if ported then
        r.api=H.load('kernel/client/menu/vehicles.lua',R.env())({menu=r.menu,shared=r.shared,config=r.config,
            library=r.library,native=native,random=r.random});r.callbacks=r.api.Callbacks
    else
        for n,fn in pairs(native)do r.env[n]=fn end
        r.env.math=H.copy(math);r.env.math.random=r.random
        H.load('client/menu/menu_vehicles.lua',r.env)
    end
    r.trace={};return r
end
function R.menuCase(name,fn,options)
    local a,b=R.menu(false,options),R.menu(true,options)
    H.same(R.outcome(fn,b),R.outcome(fn,a),name..' return');H.same(b.trace,a.trace,name..' effects')
    H.same(P.snapshot(b.contexts),P.snapshot(a.contexts),name..' context');H.same(b.saved,a.saved,name..' requests');H.same(b.entities,a.entities,name..' entities')
end
return R
