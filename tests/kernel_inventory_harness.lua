-- Installed InventoryService vs inactive port; custom mutation/persistence/world boundaries are simulated.
local J=dofile('tests/kernel_job_catalog_harness.lua')
local H,P=J.H,J.P
local I={H=H,P=P,J=J,compile=load}
function I.config(ported,seed)
    if ported then return H.load('kernel/config/forge_inventory.lua',H.environment())(H.copy(seed))end
    local env=H.environment({PR={Inventory=H.copy(seed)}});H.load('shared/inventory.lua',env);return env.PR.Inventory
end
function I.new(ported,options)
    local r={ported=ported,trace={},results={},definitions={},events={},exported={},timers={},ready=true,
        players={[1]={source=1,citizenid='A',job={name='police',grade={level=4}},gang={name='ballas',grade={level=2}}}},
        vip={},aces={[1]={['forge-core.admin']=true}},weapons={weapon_pistol={name='weapon_pistol',oxName='WEAPON_PISTOL',label='Pistol',active=true}}}
    function r.record(kind,...)r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))}end
    function r.result(name,...)
        local v=r.results[name];if v=='throw'then error('fixture-'..name,0)end
        if v then return table.unpack(v,1,v.n)end;return ...
    end
    r.config=I.config(true);r.memory=J.persistence();r.library={}
    for k,v in pairs(r.memory.api)do r.library[k]=v end
    r.memory.seed(r.config.Storage.items,{burger={name='burger',label='Burger',weight=100,stack=true,active=true}})
    r.memory.seed(r.config.Storage.weaponInventory,{ammo={},components={},tints={}})
    r.library.notify={NotifyPlayer=function(...)r.record('notify',...)end}
    r.library.inventory={
        Items=function(name)r.record('items',name);if name~=nil then return r.result('Items',r.definitions[name])end;return r.result('Items',r.definitions)end,
        CanCarryItem=function(...)r.record('carry',...);return r.result('CanCarryItem',true)end,
        AddItem=function(...)r.record('add',...);return r.result('AddItem',true,'added')end}
    local wrap=r.library.wrapJsonMutations
    r.library.wrapJsonMutations=function(path,service,names)r.record('wrap',path,names);return wrap(path,service,names)end
    r.services={VipService={get=function(src)r.record('vip',src);return r.vip[src]end},
        WeaponRegistry={getWeapons=function()r.record('weapons');return r.weapons end},
        ConsumableService={refreshItem=function(...)r.record('refresh-item',...)end},
        WeaponOxSync={syncAll=function(...)r.record('weapon-sync',...)end}}
    r.playerAccess={GetPlayerData=function(src)r.record('player-data',src);return r.players[src]end}
    r.native={isAceAllowed=function(src,ace)r.record('ace',src,ace);return r.result('ace',(r.aces[src]or{})[ace]or false)end,
        getPlayerName=function(src)r.record('player-name',src);return r.result('GetPlayerName',r.players[src]and'Player '..src or nil)end,
        emit=function(...)r.record('emit',...)end,print=function(...)r.record('print',...)end,
        setTimeout=function(ms,fn)r.record('timer',ms);r.timers[#r.timers+1]={ms=ms,fn=fn}end}
    r.integrations={inventoryReady=function()r.record('ready');return r.ready end}
    for _,method in ipairs({'setItemDefinition','disableItemDefinition','removeItemDefinition'})do
        r.integrations[method]=function(name,data,active)
            r.record(method,name,data,active)
            local result=r.result(method,true)
            if result then
                if method=='removeItemDefinition'then r.definitions[name]=nil
                else r.definitions[name]=H.copy(data);r.definitions[name].disabled=method=='disableItemDefinition'or nil end
            end
            return result
        end
    end
    r.translate=function(key,args)r.record('translate',key,args);return key end
    r.compile=I.compile
    if options then options(r)end
    local env=H.environment()
    if ported then
        r.api=H.load('kernel/server/inventory/service.lua',env)({config=r.config,services=r.services,library=r.library,native=r.native,
            playerAccess=r.playerAccess,integrations=r.integrations,translate=r.translate,compile=r.compile,resource='forge-core',notifyPosition='top-right'})
        r.events,r.exported=r.api.Events,r.api.Exports
        assert(#r.trace==0 and #r.memory.trace==0,'constructor must not load/sync/register/write')
        if not r.noInit then assert(r.api.Initialize())end
    else
        env.ForgeCore=r.services;env.PR={Inventory=r.config,NotifyPos='top-right'};r.services.t=r.translate
        env.pr_lib=r.library;r.library.framework=r.playerAccess
        env.GetCurrentResourceName=function()return'forge-core'end
        env.GetResourceState=function(name)assert(name=='ox_inventory');return r.integrations.inventoryReady()and'started'or'stopped'end
        env.IsPlayerAceAllowed=r.native.isAceAllowed;env.GetPlayerName=r.native.getPlayerName;env.TriggerEvent=r.native.emit
        env.SetTimeout=r.native.setTimeout;env.print=r.native.print;env.load=r.compile
        env.AddEventHandler=function(name,handler)r.events[#r.events+1]={name=name,handler=handler,network=false}end
        env.exports=setmetatable({ox_inventory={
            SetItemDefinition=function(_,...)return r.integrations.setItemDefinition(...)end,
            DisableItemDefinition=function(_,...)return r.integrations.disableItemDefinition(...)end,
            RemoveItemDefinition=function(_,...)return r.integrations.removeItemDefinition(...)end,
            Items=function(_,...)return r.library.inventory.Items(...)end}},
            {__call=function(_,name,fn)r.exported[name]=fn end})
        H.load('server/inventory/service.lua',env);r.api=r.services.InventoryService
    end
    r.env=env
    function r.dispatch(name,... )for _,e in ipairs(r.events)do if e.name==name then e.handler(...)end end end
    function r.runTimers()local list=r.timers;r.timers={};for _,v in ipairs(list)do v.fn()end end
    function r.seedItems(items)r.memory.seed(r.config.Storage.items,items)end
    function r.seedEquipment(data)r.memory.seed(r.config.Storage.weaponInventory,data)end
    return r
end
function I.case(label,action,options)
    local a,b=I.new(false,options),I.new(true,options)
    local function run(r)local out=table.pack(pcall(action,r));assert(out[1],label..': unexpected test error: '..tostring(out[2]));return P.snapshot(out)end
    H.same(run(b),run(a),label..': returns');H.same(b.trace,a.trace,label..': effects');H.same(b.memory.trace,a.memory.trace,label..': persistence effects')
    local function state(r)return P.snapshot({items=r.api.items,inventory=r.api.weaponInventory,revision=r.api.revision,live=r.definitions,
        files=r.memory.files,events=r.events,exported=r.exported,timers=r.timers})end
    H.same(state(b),state(a),label..': state')
end
function I.compose(base,ports)
    return H.load('kernel/server/inventory/inventory_core.lua',H.environment({require=function(name)
        assert(name=='kernel.config.forge_inventory'or name=='kernel.server.inventory.service'or name=='kernel.server.inventory.callbacks')
        return H.load(name:gsub('%.','/')..'.lua',H.environment())
    end}))(base,ports)
end
function I.oxItems()
    local r={definitions={},exports={},events={},workers={}}
    local stream=assert(io.open('../../../[ox]/ox_inventory/modules/items/server.lua','rb'))
    local text=stream:read('a');stream:close()
    -- Only Cfx syntax adaptation in a test loader; installed production source is never edited.
    text=P.lua54(text):gsub('data%?%.name','(data and data.name)'):gsub('item%?%.weapon','(item and item.weapon)')
        :gsub('inv%?%.player%?%.name','(inv and inv.player and inv.player.name)')
        :gsub('Items%.containers%[name%]%?%.size','(Items.containers[name] and Items.containers[name].size)')
        :gsub('`([^`]+)`',function(name)return tostring(#name)end)
    local env=H.environment({pr_lib={},shared={framework='qbx'},
        require=function(name)
            if name=='modules.items.shared'then return r.definitions end
            if name=='modules.items.containers'or name=='modules.utils.server'then return {}end
            if name=='modules.hooks.server'then return function()error('Metadata generation outside this test scope')end end
            error('Unexpected OX import '..name)
        end,
        exports=setmetatable({},{__call=function(_,name,fn)r.exports[name]=fn end}),
        TriggerEvent=function(name,...)r.events[#r.events+1]={name=name,args=P.snapshot(table.pack(...))}end,
        TriggerClientEvent=function(name,...)r.events[#r.events+1]={name=name,args=P.snapshot(table.pack(...))}end,
        CreateThread=function(fn)r.workers[#r.workers+1]=fn end,joaat=function(name)return #name end})
    r.api=assert(I.compile(text,'@installed_ox_items','t',env))()
    assert(#r.workers==1,'OX startup worker captured, never executed')
    return r
end
return I
