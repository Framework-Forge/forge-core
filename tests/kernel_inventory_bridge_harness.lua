local C=dofile('tests/kernel_inventory_contract_harness.lua');local H=C.H;local T={C=C,H=H,path='../pr_bridge/bridge/inventories/ox/forge_bridge_factory.lua'}
function T.fixture(ported,canonical)
    local r={events={},timers={},trace={},current=true,source=2,records={},accounts={money=30},stock=100,entityState={vehicleid=73},plate=' ABC '}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=H.copy(table.pack(...))}end
    r.player={PlayerData={source=2,citizenid='OX113',charinfo={firstname='Ana',lastname='Forge',gender=0,birthdate='2000-01-01'},money={cash=30,bank=0},metadata={licences={}}},Functions={}}
    r.player.Functions.SetPlayerData=function(k,v)r.player.PlayerData[k]=v;r.record('playerData',k,v)end
    r.player.Functions.GetMoney=function(k)return r.player.PlayerData.money[k]end
    r.player.Functions.SetMoney=function(k,v,reason)r.player.PlayerData.money[k]=v;r.record('setMoney',k,v,reason)end
    r.player.Functions.SetMetaData=function(k,v)r.player.PlayerData.metadata[k]=v;r.record('metadata',k,v)end
    local core={GetPlayer=function(_,src)r.record('getPlayer',src);return src==2 and r.player or nil end,
        GetPlayersData=function()r.record('playersData');return{r.player.PlayerData}end,
        GetGroups=function(_,src)r.record('groups',src);return{police=1}end,
        IsGradeBoss=function(_,group,grade)r.record('boss',group,grade);return grade==4 end,
        CanUseItem=function(_,name)r.record('usable',name);if name=='food'then return function(src,data)r.record('use',src,data);return true,nil,'tail'end end end}
    r.contract=canonical and canonical.contract or{Protocol='forge-inventory-core/1',Authority='forge-core',Core=core,Check=function()return r.current end}
    if canonical then r.player=assert(canonical.contract.Core:GetPlayer(2))end
    local inventory=setmetatable({},{__call=function(_,src)return r.records[src]end});r.Inventory=inventory
    inventory.GetAccountItemCounts=function(inv)r.record('accounts',type(inv)=='table'and inv.id or inv);return r.accounts end
    inventory.SetItem=function(src,name,count)r.record('item',src,name,count)end
    inventory.GetItem=function(inv,name,metadata,count)r.record('getItem',inv.id,name,metadata,count);return r.stock end
    inventory.RemoveItem=function(inv,name,count)r.record('removeItem',inv.id,name,count);r.stock=r.stock-count;return r.removeResult end
    r.server={playerDropped=function(...)r.record('dropped',...)end,setPlayerInventory=function(data,_,isCurrent)
        r.record('setup',data.source,data.citizenid);if r.setupHook then r.setupHook(data,isCurrent)end
        if r.rejectSetup then return false end;r.records[data.source]={id=data.source,owner=data.citizenid,player={groups={}}};return true end}
    r.native={DoesEntityExist=function(entity)return entity>0 end,Entity=function()return{state=r.entityState}end,GetVehicleNumberPlateText=function()return r.plate end}
    r.ports={contract=r.contract,server=r.server,native=r.native,Inventory=inventory,traceback=debug.traceback,isCurrent=function()return r.current end,
        source=function()return r.source end,clearState=function(src)r.record('clear',src)end,
        database={scalar=function(sql,params)r.record('db',sql,params);return 91 end},events={
            listen=function(name,fn)local t={name=name,fn=fn};r.events[#r.events+1]=t;if r.listenHook then r.listenHook(t)end;return t end,
            remove=function(t)if r.refuseRemove then return false end;t.removed=true end},
        schedule=function(ms,fn)r.timers[#r.timers+1]={ms=ms,fn=fn};if r.scheduleHook then return r.scheduleHook(ms,fn)end end}
    if ported then r.api=H.load(T.path,H.environment())(r.ports)
    else
        local env=H.environment({server=r.server,debug=debug,pr_lib={checkDependency=function()return true end,database=r.ports.database},exports={qbx_core=core},source=2,
            AddEventHandler=r.ports.events.listen,SetTimeout=r.ports.schedule,DoesEntityExist=r.native.DoesEntityExist,Entity=r.native.Entity,
            GetVehicleNumberPlateText=r.native.GetVehicleNumberPlateText,require=function(name)if name=='modules.inventory.server'then return inventory end;assert(name=='modules.state.server');return{clear=r.ports.clearState}end})
        H.load('../../../[ox]/ox_inventory/modules/bridge/qbx/server.lua',env)
    end
    function r.fire(name,...)for _,e in ipairs(r.events)do if not e.removed and e.name==name then e.fn(...)end end end
    function r.runTimers()for _,t in ipairs(r.timers)do assert(t.ms==500);t.fn()end end
    function r.active()local n=0;for _,e in ipairs(r.events)do if not e.removed then n=n+1 end end;return n end
    return r
end
return T
