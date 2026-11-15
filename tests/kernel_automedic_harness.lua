-- Test-only whole installed sources + PR persistence/money/cache facades, no real inventory/SQL/IO.
local Q=dofile('tests/kernel_skill_harness.lua')
local H,P,J=Q.H,Q.P,Q.J
local A={Q=Q,H=H,P=P,J=J}
A.env=Q.env
function A.config(ported)
    if ported then return H.load('kernel/config/forge_automedic.lua',H.environment())()end
    local e=H.environment({PR={}});H.load('shared/automedic.lua',e);return e.PR.AutoMedic
end
function A.bed(id,x,prison)
    return {id=id,label=id,model='v_med_bed1',coords={x=x or 0,y=0,z=1},heading=0,
        exit={x=x or 0,y=1,z=0},exitHeading=90,prison=prison==true}
end
function A.new(ported,options)
    local r={trace={},events={},callbacks={},now=1792320000,source=1,health=100,bucket=0,exists=true,
        inventoryState='started',clearResult=table.pack(true),manage=true,jailed=false,balances={cash=200,bank=500},
        removeResults={},addResult=true,settings={cooldown=0,treatmentPrice=100,beds={A.bed('near',0),A.bed('far',50)}},
        positions={[1]={x=1,y=0,z=0},[2]={x=2,y=0,z=0},[3]={x=3,y=0,z=0}}}
    function r.record(k,...)r.trace[#r.trace+1]={kind=k,args=P.snapshot(table.pack(...))}end
    r.config=A.config(ported);r.m=J.persistence();r.library=r.m.api;r.cache={}
    r.library.cache={get=function(k)return r.cache[k]end,set=function(k,v)r.cache[k]=H.copy(v)end}
    H.load('../pr_bridge/bridge/cache/resources.lua',H.environment())(r.library.cache)
    r.players={}
    for src=1,3 do r.players[src]={PlayerData={source=src,citizenid='C'..src,metadata={isdead=true,hunger=5,thirst=8}}}end
    r.native={resourceName=function()return'forge-core'end,time=function()return r.now end,source=function()return r.source end,
        isAceAllowed=function(src,ace)r.record('ace',src,ace);return r.manage end,
        ped=function(src)return r.pedMissing and 0 or tonumber(src)end,exists=function()return r.exists end,
        health=function()return r.health end,coords=function(src)return r.positions[src]end,
        bucket=function()return r.bucket end,emitClient=function(...)r.record('client',...)end}
    r.kernel={GetPlayer=function(src)r.record('player',src);return r.players[src]end,
        GetStatus=function(src,key)r.record('get-status',src,key);return r.statusOverride and r.statusOverride[key] or r.players[src].PlayerData.metadata[key]end,
        SetStatus=function(src,key,value)r.record('set-status',src,key,value);return r.setStatusResult end,
        SetMetadata=function(src,key,value)
            r.record('metadata',src,key,value);if r.metadataHook then r.metadataHook(src,key,value)end
            if r.metadataError then error('metadata-failed',0)end
            local p=r.players[src];if not p then return end
            local old=p.PlayerData.metadata[key];p.PlayerData.metadata[key]=value
            r.event('qbx_core:server:onSetMetaData',key,old,value,src)
            return r.setMetadataResult
        end}
    r.playerApi={GetMoney=function(src,account)r.record('money-get',src,account);return r.balances[account]end,
        RemoveMoney=function(src,account,amount,reason)
            r.record('money-remove',src,account,amount,reason)
            if r.moneyHook then r.moneyHook(src,account,amount)end
            if r.moneyError then error('money-failed',0)end
            local result=r.removeResults[account]
            if result==nil then result=true end
            if result==true then r.balances[account]=r.balances[account]-amount end
            return result
        end,
        AddMoney=function(src,account,amount,reason)
            r.record('money-refund',src,account,amount,reason)
            if r.refundError then error('refund-failed',0)end
            if r.addResult==true then r.balances[account]=r.balances[account]+amount end
            return r.addResult
        end}
    local function clear(src)
        r.record('inventory-clear',src)
        if r.clearHook then r.clearHook(src)end
        if r.clearError then error('clear-failed',0)end
        return table.unpack(r.clearResult,1,r.clearResult.n)
    end
    r.inventoryIntegration={isReady=function()r.record('inventory-ready');return r.inventoryState=='started'end,clearInventoryRaw=clear}
    r.services={JobService={canManage=function(src)r.record('manage',src);return r.manage end},
        PrisonService={canChangeJobs=function(src)r.record('prison',src);return not r.jailed end}}
    if options then options(r)end
    r.m.seed(r.config.Storage.file,r.settings)
    local e=H.environment({PR={AutoMedic=r.config,AdminAce='forge-core.admin'},pr_lib=r.library,
        os={time=r.native.time},ForgeCore={JobService=r.services.JobService,PrisonService=r.services.PrisonService},
        IsDuplicityVersion=function()return true end,GetCurrentResourceName=r.native.resourceName})
    e.math.random=function()return 123456 end
    e.AddEventHandler=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=false}end
    e.RegisterNetEvent=function(name,fn)r.events[#r.events+1]={name=name,handler=fn,network=true}end
    local qbx={};for name,fn in pairs(r.kernel)do qbx[name]=function(_,...)return fn(...)end end
    for name,fn in pairs(r.playerApi)do qbx[name]=function(_,...)return fn(...)end end
    local fe=H.environment({ActiveBridges={frameworks='qbx'},exports={qbx_core=qbx},Debug=function()end,Lang={t=function()return''end}})
    r.referenceMoney=H.load('../pr_bridge/bridge/frameworks/qbx/server.lua',fe)
    r.money=r.moneyMissing and nil or {getPlayerMoney=r.playerApi.GetMoney,removePlayerMoney=r.playerApi.RemoveMoney,addPlayerMoney=r.playerApi.AddMoney}
    if r.moneyMissing then r.money=nil end
    if ported then
        r.sessionBoundary=H.load('kernel/server/forge_session.lua',e)({kernel=r.kernel,cache=r.library.cache,native=r.native})
        r.services.Session=r.sessionBoundary.Session
        for _,d in ipairs(r.sessionBoundary.Events)do r.events[#r.events+1]=d end
        r.boundary=H.load('kernel/server/automedic/service.lua',e)({config=r.config,adminAce='forge-core.admin',services=r.services,
            kernel=r.kernel,native=r.native,library=r.library,money=r.money,inventoryIntegration=r.inventoryIntegration})
        r.api=r.boundary.Service
        for _,d in ipairs(r.boundary.Events)do r.events[#r.events+1]=d end
        r.callbacks=H.load('kernel/server/automedic/callbacks.lua',e)({config=r.config,service=r.api})
    else
        -- Installed cache is passive. Its GetPlayer fixture points to the same delivered local player records.
        r.library.cache.GetPlayer=function(src)return r.kernel.GetPlayer(src)end
        r.library.framework=r.moneyMissing and nil or r.referenceMoney
        if r.moneyMissing then r.library.framework=nil end
        e.GetResourceState=function(name)assert(name=='ox_inventory');r.record('inventory-ready');return r.inventoryState end
        e.GetPlayerPed=r.native.ped;e.DoesEntityExist=r.native.exists;e.GetEntityHealth=r.native.health
        e.GetEntityCoords=r.native.coords;e.GetPlayerRoutingBucket=r.native.bucket
        e.IsPlayerAceAllowed=r.native.isAceAllowed;e.TriggerClientEvent=r.native.emitClient;e.source=r.source
        e.exports={qbx_core=qbx,ox_inventory={ClearInventory=function(_,src)return clear(src)end}}
        e.ForgeCore.Callbacks={register=function(name,handler,options)r.callbacks[#r.callbacks+1]={name=name,handler=handler,options=options or {}}end}
        r.callbacks={}
        H.load('shared/session.lua',e);r.services.Session=e.ForgeCore.Session
        H.load('server/automedic/service.lua',e);r.api=e.ForgeCore.AutoMedicService
        H.load('server/automedic/callbacks.lua',e)
    end
    r.env=e
    function r.event(name,...)
        e.source=r.source
        for _,entry in ipairs(r.events)do if entry.name==name then entry.handler(...)end end
    end
    function r.start()r.api.start();return r.api end
    function r.approve(src,category)
        local ok,p=r.api.requestTreatment(src or 1,category or 'collapse');assert(ok,p);return p.token,p
    end
    return r
end
function A.case(label,fn,options)
    local a,b=A.new(false,options),A.new(true,options)
    H.same(Q.outcome(fn,b),Q.outcome(fn,a),label..': results/errors')
    H.same(b.trace,a.trace,label..': all effects')
    H.same(P.snapshot({b.api,b.players}),P.snapshot({a.api,a.players}),label..': complete service/player state')
    H.same(b.cache,a.cache,label..': passive cache')
    H.same(b.balances,a.balances,label..': balances')
    H.same(b.m.files,a.m.files,label..': files');H.same(b.m.trace,a.m.trace,label..': PR IO')
end
-- Whole installed OX Clear body; only Cfx += syntax is adapted in this read-only test loader.
function A.oxClear()
    local stream=assert(io.open('../../../[ox]/ox_inventory/modules/inventory/server.lua','rb'))
    local text=stream:read('a');stream:close()
    local start=assert(text:find('function Inventory.Clear(inv, keep)',1,true))
    local finish=assert(text:find("exports('ClearInventory', Inventory.Clear)",start,true))
    local body=text:sub(start,finish-1):gsub('newWeight %+= v.weight','newWeight = newWeight + v.weight'):gsub('inc %+= 1','inc = inc + 1')
    local r={records={},sync={}}
    local Inventory=setmetatable({},{__call=function(_,id)return type(id)=='table'and id or r.records[id]end})
    local e=H.environment({Inventory=Inventory,server={syncInventory=function(inv)r.sync[#r.sync+1]={id=inv.id,items=H.copy(inv.items)}end}})
    e.table.wipe=function(t)for k in pairs(t)do t[k]=nil end end
    assert(load(body,'installed-ox-clear','t',e))()
    r.clear=Inventory.Clear
    function r.seed(src)
        local inv={id=src,player=true,items={[1]={name='burger',count=2,weight=200,slot=1}},weight=200,weapon=1}
        function inv:syncSlotsWithClients(slots,full)r.sync[#r.sync+1]={slots=H.copy(slots),full=full}end
        r.records[src]=inv;return inv
    end
    return r
end
return A

