-- New assembly tests: real private factories, installed PR/OX adapters; virtual IO/SQL/platform only.
local A=dofile('tests/kernel_character_admin_harness.lua')
local L=dofile('tests/kernel_lifecycle_harness.lua')
local N=dofile('tests/kernel_server_runtime_harness.lua')
local I=dofile('tests/kernel_inventory_harness.lua')
local W=dofile('tests/kernel_weapon_harness.lua')
local T=dofile('tests/kernel_transport_harness.lua')
local H,P=A.H,A.P
local R={H=H,P=P,A=A,L=L,N=N,I=I,W=W,T=T}
function R.copy(t)local result={};for k,v in pairs(t)do result[k]=v end;return result end
function R.env()
    local env=T.B.environment();local loaded={}
    env.require=function(name)
        assert(name:match('^kernel%.[%w_.]+$'),'no external module import: '..tostring(name))
        if not loaded[name]then loaded[name]=H.load(name:gsub('%.','/')..'.lua',env)end;return loaded[name]
    end
    return env
end
function R.new()
    local r={p=P.new(true),l=L.new(true),n=N.new(true,'commands'),c=A.C.slots(true),character=A.C.character(true),documents=A.C.documents(true),
        trace={},timers={},workers={},handlers={},hooks={},hookCount=0,rows={},skins={},saved={},now=1000000,caller='pr_bridge',items={water=3,new_slot=2}}
    function r.record(k,...)r.trace[#r.trace+1]={kind=k,args=P.snapshot(table.pack(...))}end
    r.m=A.F.J.persistence();r.codec=r.m.codec
    r.db={}
    for _,name in ipairs({'query','single','scalar','insert','update','transaction'})do
        local function invoke(sql,params)
            r.record('db-'..name,sql,params)
            if name=='transaction'and type(sql)=='table'and sql[1]and sql[1].query:find('qbx_character_',1,true)then return r.c.bindings.db.transaction.await(sql)end
            if type(sql)=='string'and sql:find('qbx_character_',1,true)then return r.c.bindings.db[name].await(sql,params)end
            if name=='query'then
                if sql:find('FROM players WHERE license',1,true)then local rows={};for _,v in pairs(r.rows)do rows[#rows+1]=H.copy(v)end;return rows end
                if sql:find('FROM player_groups',1,true)then return{}end
                if sql:find('CREATE TABLE',1,true)then error('DDL forbidden in assembly tests',0)end
                return{}
            end
            if name=='scalar'then if sql:find('`users`',1,true)then return 101 end;return nil end
            if name=='single'then
                if sql:find('FROM playerskins',1,true)then return r.skins[params[1]]end
                if sql:find('FROM players WHERE citizenid',1,true)then return H.copy(r.rows[params[1]])end
                return{count=0}
            end
            if name=='insert'then r.saved[#r.saved+1]={sql=sql,params=H.copy(params)};return r.failSave and nil or 1 end
            if name=='transaction'then return true end
            return 1
        end
        r.db[name]=setmetatable({await=invoke},{__call=function(_,...)return invoke(...)end})
    end
    local shared={weapons={},locations={}}
    local e=R.env()
    r.base=H.load('kernel/init.lua',e)({shared=shared,membership={tableType=H.tableType,warn=function()error('unexpected warning')end},
        groups={jobs=r.p.groupData.jobs,gangs=r.p.groupData.gangs,emitServer=r.p.platform.emitServer,emitClient=r.p.platform.emitClient,
            saveGroups=function()error('No legacy Lua writes')end,logError=function()error('unexpected group error')end}})
    r.base.Shared.ForceJobDefaultDutyAtLogin=true
    local player=R.copy(r.p.bindings);player.core,player.storage,player.lookup,player.groups=nil,nil,nil,nil
    player.characterSlots=nil;player.config.characters={defaultNumberOfCharacters=3}
    player.db,player.json,player.date,player.warn=r.db,r.codec,os.date,function()error('unexpected warning')end
    local lifecycle=R.copy(r.l.bindings);lifecycle.config={server=r.l.serverConfig,logging=r.l.logging}
    lifecycle.queue={enabled=false,maxPlayers=48};lifecycle.serverName='Fixture'
    local runtime=R.copy(r.n.bindings);runtime.config=player.config;runtime.config.server=r.l.serverConfig
    runtime.config.giveVehicleKeys=r.n.config.giveVehicleKeys
    local slotPorts={db=r.db,json=r.c.bindings.json,calendar=r.c.bindings.calendar,native={GetPlayerIdentifierByType=function(_,kind)return kind=='license2'and'license2:test'or'license:test'end,
        DropPlayer=function(...)r.record('drop-slot',...)end}}
    local character=R.copy(r.character.bindings);character.slots,character.previewsReady,character.getPreviews=nil,nil,nil
    character.config=nil;character.documents=r.documents.bindings
    r.library={};for k,v in pairs(r.m.api)do r.library[k]=v end
    r.ox=I.oxItems();local proxy={}
    for name,fn in pairs(r.ox.exports)do proxy[name]=function(_,...)return fn(...)end end
    proxy.Items=function(_,name)if name then return r.ox.definitions[name]or r.ox.definitions[name:upper()]end;return r.ox.definitions end
    proxy.registerHook=function(_,name,fn,options)r.hookCount=r.hookCount+1;r.hooks[name]=r.hooks[name]or{};r.hooks[name][r.hookCount]=fn;return r.hookCount end
    proxy.AddItem=function(_,src,name,count)r.record('add-item',src,name,count);r.items[name]=(r.items[name]or 0)+count;return true end
    proxy.RemoveItem=function(_,src,name,count)r.record('remove-item',src,name,count);if(r.items[name]or 0)<count then return false end;r.items[name]=r.items[name]-count;return true end
    proxy.CanCarryItem=function()return true end
    proxy.GetInventory=function()return{items={}}end
    r.library.inventory=H.load('../pr_bridge/bridge/inventories/ox/server.lua',H.environment({exports={ox_inventory=proxy},ActiveBridges={inventory='ox'},
        Lang={t=function(_,key)return key end},Debug=function()end,Bridge={framework=setmetatable({},{__index=function()error('forbidden framework cycle')end})}}))
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    r.library.debug={};for _,level in ipairs({'warn','info','error','success'})do r.library.debug[level]=function(...)r.record('log-'..level,...)end end
    r.library.database={query=function()return{}end,single=function()return nil end,transaction=function()return true end}
    r.bank={government=0,taxi=10000}
    r.library.banking={EnsureJobAccount=function(name)r.bank[name]=r.bank[name]or 0;return true end,
        JobAccountExists=function(name)return r.bank[name]~=nil end,GetJobAccountBalance=function(name)return r.bank[name]end,
        AddJobAccountBalance=function(name,value)r.bank[name]=(r.bank[name]or 0)+value;return true end,
        RemoveJobAccountBalance=function(name,value)if(r.bank[name]or 0)<value then return false end;r.bank[name]=r.bank[name]-value;return true end}
    local helpers=T.helpers();r.library.load=function(name)assert(name=='@pr_bridge/bridge/frameworks/compat_helpers');return helpers end
    r.library.command=function()error('no command installation')end
    r.library.callback={register=function(name,fn)assert(not r.handlers[name],'duplicate RPC');r.handlers[name]=fn end}
    r.library.utils=H.load('../pr_bridge/bridge/utils/shared.lua',H.environment())
    r.library.table=H.load('../pr_bridge/bridge/utils/tables.lua',H.environment())
    r.library.math=H.load('../pr_bridge/bridge/utils/numbers.lua',T.B.environment())
    r.native={isAceAllowed=function(src)return src==2 end,isPlayerAceAllowed=function(src)return src==2 end,getInvokingResource=function()return r.caller end,
        isPrincipalAceAllowed=function()return false end,getPlayers=function()return{'1','2'}end,getPlayerName=function()return'Fixture'end,
        emitClient=r.p.platform.emitClient,emit=function(...)r.record('event',...)end,getSource=function()return 1 end,
        getIdentifier=function()return'license:test'end,getGameTimer=function()return r.now end,getPlayerPing=function()return 50 end,
        setTimeout=function(ms,fn)r.timers[#r.timers+1]={ms=ms,fn=fn}end,spawn=function(fn)r.workers[#r.workers+1]=fn end,
        wait=function()error('No worker scheduled for execution')end,execute=function(...)r.record('ace-command',...)end,print=function()end,
        getPed=function(src)return src end,getCoords=function()return T.B.vector(1,2,3)end,listen=function()error('no listener installation')end}
    r.translate=function(key)return key end;r.integrations={inventoryReady=function()return true end,inventoryState=function()return'started'end,
        applyPlayerInventoryBonus=function(...)r.record('inventory-bonus',...);return true end,
        inventoryItemsReady=function()return true end,awaitUse=function()return true end}
    for method,name in pairs({setItemDefinition='SetItemDefinition',disableItemDefinition='DisableItemDefinition',removeItemDefinition='RemoveItemDefinition',
        SetWeaponItem='SetWeaponItem',DisableWeaponItem='DisableWeaponItem',RemoveWeaponItem='RemoveWeaponItem',HasWeaponItem='HasWeaponItem'})do
        r.integrations[method]=function(...)return assert(r.ox.exports[name])(...)end
    end
    r.jobConfig=A.F.J.config(true).config;r.inventoryConfig=I.config(true);r.weaponConfig=W.config(true)
    r.ports={session={player=player,delivery={getResourceState=function()return'stopped'end,writeCache=function()r.record('cache-delivery')end,emit=r.p.platform.emitServer},
            getBucket=function(src)return r.base.PlayerCore and r.base.PlayerCore.State.Player_Buckets[src]or 0 end,
            status={config={checkpointMinutes=1},awaitSnapshot=function()return{hunger=50}end}},
        slots=slotPorts,lifecycle=lifecycle,runtime=runtime,character=character,
        catalog={config=r.jobConfig,library=r.library,translate=r.translate},
        jobs={library=r.library,native=r.native,translate=r.translate,time=function()return r.now end,dependencies={}},
        finance={library=r.library,native=r.native,translate=r.translate,time=function()return r.now end,integrations=r.integrations,resource='forge-core'},
        business={library=r.library,native=r.native,translate=r.translate,time=function()return r.now end,integrations=r.integrations,json=r.codec},
        inventory={config=r.inventoryConfig,library=r.library,native=r.native,integrations=r.integrations,translate=r.translate,compile=load,resource='forge-core'},
        consumption={library=r.library,native=r.native,integrations=r.integrations},
        weapons={config=r.weaponConfig,library=r.library,native=r.native,integrations=r.integrations,translate=r.translate,resource='forge-core'},
        transport={config={AdminAce='forge-core.admin',NotifyPos='top-right'},library=r.library,native=r.native,json=r.codec,translate=r.translate,time=function()return r.now end}}
    r.factory=H.load('kernel/server/assembly_core.lua',e)
    function r.mount()r.api=r.factory(r.base,r.ports);return r.api end
    function r.characterRow(cid,slot)
        local value={userId=101,citizenid=cid,license='license:test',name='Fixture',lastLoggedOutUnix=0}
        for k,v in pairs({charinfo={cid=slot,firstname='First',lastname='Last',birthdate='2000-01-01'},money={cash=10,bank=100},metadata={},position={x=1,y=2,z=3,w=4},job={name='taxi',grade={level=0}},gang={name='none',grade={level=0}}})do value[k]=r.codec.encode(v)end
        r.rows[cid]=value;return value
    end
    return r
end
return R
