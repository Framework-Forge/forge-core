-- Installed shop/PR adapter/garage handler; virtual SQL, inventory, entities and transport only.
local B=dofile('tests/kernel_banking_harness.lua');local H=B.H
local V={B=B,H=H,shop='../../../[vehicle_system]/pr_carkeys/server/sv_shop.lua',garageFile='../forge-garage/client/persist.lua'}
function V.new()
    local r={calls={},sql={},items={},cache={},notifications={},messages={},exported={},modes={},states={pr_carkeys='started',['forge-garage']='started'},
        selected='pr_carkeys',current=true,serial=0,insertResult=31,itemResult=true,identifier=function(src)return'C'..src end}
    local pc={Cache={GetKey=function(k)return r.cache[k]end,SetKey=function(k,v)r.cache[k]=v end},
        GenerateBarcode=function()r.serial=r.serial+1;return'KEY'..r.serial end,
        SanitizePlate=function(v)if type(v)~='string'then return nil end;v=v:upper():gsub('%s+','');return v~=''and v or nil end,
        ResolveKeyItem=function()return r.itemName or'carkey_original'end}
    local env=H.environment({PRCarkeys=pc,Config={Sound={soundDefault='beep'},Default={UseKeyAnim={DefaultDistance=20}}},
        Bridge={framework={GetIdentifier=function(src)return r.identifier(src)end},inventory={AddItem=function(...)
            r.items[#r.items+1]=table.pack(...);if r.itemHook then r.itemHook(...)end
            if r.itemError then error('virtual item error')end;return r.itemResult end},
            notify={Notify=function(...)r.notifications[#r.notifications+1]=table.pack(...)end}},
        ExecuteSQLInsert=function(sql,args)r.sql[#r.sql+1]={sql=sql,args=H.copy(args)};if r.sqlHook then r.sqlHook()end
            if r.sqlError then error('virtual key SQL error')end;return r.insertResult end,
        exports=function(name,fn)r.exported[name]=fn end,Debug=function()end,os={time=function()return 1000 end}})
    H.load(V.shop,env)
    r.raw={}
    for _,name in ipairs({'BuyOriginalKey','GiveTempKey','RemoveTempKey','CreateTempKeyItem','RemoveTempKeyItem','HasVehicleAccess','SetLockState'})do
        local method=name
        r.raw[name]=function(self,...)
            assert(self==r.raw,'raw key receiver preserved');local args=table.pack(...)
            r.calls[#r.calls+1]={name=method,args=args};if r.callHook then r.callHook(method,args)end
            local mode=r.modes[method];if mode=='error'then error('virtual key export error')end
            if type(mode)=='table'then return table.unpack(mode,1,mode.n)end
            if method=='BuyOriginalKey'then return r.exported[method](...)end
            if method=='GiveTempKey'or method=='RemoveTempKey'or method=='SetLockState'then return end
            if method=='CreateTempKeyItem'then return'TEMP'end;return true
        end
    end
    r.public=H.load('../pr_bridge/bridge/vehicle_key/pr_carkeys/server.lua',H.environment({ActiveBridges={vehicle_key='pr_carkeys'},
        exports={pr_carkeys=r.raw},Debug=function()end,Lang={t=function()return''end}}))
    r.factory=H.load('../pr_bridge/bridge/vehicle_key/forge_provider.lua',H.environment())
    r.ports={vehicleKey=r.public,prCarkeys=r.raw,resourceState=function(name)return r.states[name]or'stopped'end,
        selected=function()return r.selected end,isCurrent=function()return r.current end,
        sendClient=function(...)r.messages[#r.messages+1]=table.pack(...);if r.sendHook then return r.sendHook(...)end end}
    function r.mount()r.api=r.factory(r.ports);return r.api end
    return r
end
function V.garage()
    local f=assert(io.open(V.garageFile,'rb'));local s=f:read('*a');f:close()
    local first=assert(s:find("RegisterNetEvent('forge_garage:client:registerExistingPersistentVehicle'",1,true))
    local last=assert(s:find('\nend)',first,true))
    local r={exists=true,spawnedVehs={},spawnedPlates={},cache={},state={},net=501,entity=101}
    local state={set=function(_,name,value,replicated)assert(replicated==true);r.state[name]=value end}
    local env=H.environment({spawnedVehs=r.spawnedVehs,spawnedPlates=r.spawnedPlates,
        NetworkGetEntityFromNetworkId=function(id)return id==r.net and r.entity or 0 end,
        DoesEntityExist=function(entity)return r.exists and entity==r.entity end,Entity=function()return{state=state}end,
        pr_lib={cache={set=function(k,v)r.cache[k]=v end}},RegisterNetEvent=function(name,fn)
            assert(name=='forge_garage:client:registerExistingPersistentVehicle');r.receive=fn end})
    assert(load(s:sub(first,last+4),'@installed_garage_existing_handler','t',env))()
    return r
end
function V.context()
    local r=B.context();r.keys=V.new()
    r.vehicleContextPorts={bankingContext=r.bankContextPorts,vehicles=r.keys.ports,createVehicles=r.keys.factory}
    local env=B.O.P.T.T.W.D.R.env();env.print=function(...)r.fixture.central.record('print',...)end
    r.vehicleFactory=H.load('kernel/server/vehicle_integration_context.lua',env)
    function r.prepareVehicles()r.api=r.vehicleFactory(r.fixture.base,r.vehicleContextPorts);r.graph=r.api.Graph;r.keys.api=r.api.Vehicles;return r.api end
    function r.vehicleInstall()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return V
