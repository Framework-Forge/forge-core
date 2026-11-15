local P=dofile('tests/kernel_player_harness.lua');local H=P.H;local T={H=H,P=P,path='../pr_bridge/bridge/frameworks/forge/server_factory.lua'}
function T.new(ported,mode)
    local r={trace={},current=true,result=true,mode=mode or'normal'}
    local function record(name,...)r.trace[#r.trace+1]={name=name,args=P.snapshot(table.pack(...))}end
    local data={source=1,citizenid='C81',license='L81',charinfo={firstname='Ana',lastname='Forge',birthdate='2000',gender=0},
        metadata={hunger=50},money={cash=50,bank=100},job={name='police',label='Police',grade={level=2,name='Sergeant'}},jobs={police=2}}
    local pf={};for _,name in ipairs({'GetItemByName','SetMetaData','AddItem','RemoveItem'})do pf[name]=function(...)
        record('player.'..name,...);if name=='GetItemByName'then return{name='item',amount=3}end;return r.result,'player-result'
    end end
    r.player={PlayerData=data,Functions=pf};r.core={}
    for _,name in ipairs({'GetPlayer','GetPlayerByCitizenId','GetOfflinePlayer','GetStatus','SetStatus','AddStatus','HasPermission',
        'CreateUseableItem','SetJob','SetJobDuty','AddPlayerToJob','RemovePlayerFromJob','SetPlayerPrimaryJob','AddPlayerToGang',
        'RemovePlayerFromGang','SetPlayerPrimaryGang','GetMoney','AddMoney','RemoveMoney'})do r.core[name]=function(...)
        record(name,...);if r.hook then r.hook(name,...)end
        if r.mode=='error'then error('backend failed '..name,0)end
        if name=='GetPlayer'or name=='GetPlayerByCitizenId'or name=='GetOfflinePlayer'then
            if r.mode=='missing'then return nil end;return r.player
        end
        if name=='GetMoney'then local _,kind=...;return data.money[kind]or 0 end
        if name=='GetStatus'then return 50,'ignored' end
        if r.mode=='nil'then return nil,'detail'elseif r.mode=='false'then return false,'detail'end
        return r.result,'detail'
    end end
    local inventory={};for _,name in ipairs({'GetWeapon','GetItem','CreateWeaponData','RemoveWeapon','AddWeapon'})do
        inventory[name]=function(...)record('inventory.'..name,...);return false,'inventory-detail'end
    end
    local banking={};for _,name in ipairs({'addAccountMoney','removeAccountMoney'})do banking[name]=function(...)record('bank.'..name,...);return false end end
    r.ports={core=r.core,isCurrent=function()return r.current end,inventory=r.mode=='inventory'and inventory or nil,
        banking=r.mode~='absent'and banking or nil,callback=r.mode~='absent'and{register=function(...)record('callback',...)end}or nil,
        native={GetPlayerPed=function(source)record('ped',source);return 10 end,GetEntityCoords=function()return{x=1,y=2,z=3}end,
            GetEntityHeading=function()return 90 end,vec4=function(x,y,z,w)return{x=x,y=y,z=z,w=w}end},
        decode=function(raw)record('decode',raw);if raw=='vehicle'then return{plate='P81',model=7}elseif raw=='char'then return{firstname='Off',lastname='Line'}end;return{plate='P81'}end}
    if r.mode~='absent'then r.ports.db={single=function(sql,params)
        record('db.single',sql,params);if sql:find('charinfo',1,true)then return{charinfo='char'}end
        return{citizenid='OWNER81',mods='vehicle'}
    end,execute=function(...)record('db.execute',...);return false end}end
    if ported then r.api=H.load(T.path,H.environment())(r.ports);r.framework=r.api.Framework
    else
        local provider={};for name,fn in pairs(r.core)do provider[name]=function(receiver,...)assert(receiver==provider);return fn(...)end end
        local bankProvider;if r.ports.banking then bankProvider={};for name,fn in pairs(banking)do bankProvider[name]=function(receiver,...)assert(receiver==bankProvider);return fn(...)end end end
        local env=H.environment({ActiveBridges={frameworks='qbx'},Debug=function()end,Lang={t=function()return'detected'end},
            exports={qbx_core=provider,['Renewed-Banking']=bankProvider},PRCore={callback=r.ports.callback},
            Bridge={inventory=r.ports.inventory,db=r.ports.db},json={decode=r.ports.decode}})
        for name,fn in pairs(r.ports.native)do env[name]=fn end
        r.framework=H.load('../pr_bridge/bridge/frameworks/qbx/server.lua',env)
    end
    return r
end
return T
