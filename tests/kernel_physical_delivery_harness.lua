local Q=dofile('tests/kernel_qbx_qb_extension_harness.lua');local D=dofile('tests/kernel_consumer_delivery_harness.lua')
local H=Q.H;local T={Q=Q,D=D,H=H,root='../../../../.planning/migration/staging/107/qbx_core/',key='__forge_qbx_consumer_delivery107'}
function T.read(path)local f=io.open(T.root..path,'rb');if not f then return nil end;local s=f:read('*a');f:close();return s end
function T.new(side,enabled)
    local r=side=='server'and Q.new(enabled)or Q.R.new('client');r.side=side;r.physicalEvents={};r.physicalReads={};r.consumers={}
    r.forgeState='started';r.physicalName='qbx_core';local proxy={
        ForgeQbxCompatDescribe=function()return r.gateway.Describe()end,
        ForgeQbxCompatCall=function(_,...)return r.gateway.Call(...)end,
        ForgeQbxCompatQBDescribe=function()
            if r.extensionDescribe then return r.extensionDescribe()end
            return side=='server'and r.qbGateway.Describe()or{protocol='forge-qbx-qb/1',side='client',generation='client107',setField=false}
        end,ForgeQbxCompatQBCall=function(_,...)return r.qbGateway.Call(...)end}
    local native=setmetatable({['forge-core']=proxy},{__call=function(_,name,fn)
        r.published[name]=fn;if r.physicalPublishHook then r.physicalPublishHook(name,fn)end
    end})
    r.physicalEnv=H.environment({load=load,exports=native,GetCurrentResourceName=function()return r.physicalName end,
        IsDuplicityVersion=function()return side=='server'end,GetInvokingResource=function()return r.caller end,
        GetResourceState=function(name)assert(name=='forge-core');return r.forgeState end,
        LoadResourceFile=function(resource,path)assert(resource=='qbx_core');r.physicalReads[#r.physicalReads+1]=path
            if r.physicalReadHook then local handled,value=r.physicalReadHook(path);if handled then return value end end;return T.read(path)end,
        AddEventHandler=function(name,fn)local token={name=name,fn=fn};r.physicalEvents[#r.physicalEvents+1]=token
            if r.physicalListenHook then r.physicalListenHook(token)end;return token end,
        RemoveEventHandler=function(token)if r.refusePhysicalRemove then return false end;token.removed=true end})
    r.physicalEnv._ENV=r.physicalEnv
    function r.loadPhysical()return assert(load(T.read('compat/main.lua'),'@@qbx_core/compat/main.lua','t',r.physicalEnv))()end
    function r.stopPhysical()for _,t in ipairs(r.physicalEvents)do if not t.removed then t.fn('qbx_core')end end end
    function r.consumer()
        local c=D.new(side);r.consumers[#r.consumers+1]=c;c.physicalEvents={};c.physicalReads={}
        local env=c.target;env.ForgeQbxConsumerPorts=c.deliveryPorts
        if side=='client'then c.consumerPorts.getPlayerData=function()return r.published.GetPlayerData()end end
        env.GetCurrentResourceName=function()return'consumer107'end;env.IsDuplicityVersion=function()return side=='server'end
        env.LoadResourceFile=function(resource,path)assert(resource=='qbx_core');c.physicalReads[#c.physicalReads+1]=path
            if c.physicalReadHook then local handled,value=c.physicalReadHook(path);if handled then return value end end;return T.read(path)end
        env.AddEventHandler=function(name,fn)local t={name=name,fn=fn};c.physicalEvents[#c.physicalEvents+1]=t
            if c.physicalListenHook then c.physicalListenHook(t)end;return t end
        env.RemoveEventHandler=function(token)if c.refusePhysicalRemove then return false end;token.removed=true end
        function c.loadEntry(path)return assert(load(T.read(path),'@@qbx_core/'..path,'t',env))()end
        function c.stopPhysical()for _,t in ipairs(c.physicalEvents)do if not t.removed then t.fn('consumer107')end end end
        return c
    end
    local finish=r.finish
    function r.finish()
        for _,c in ipairs(r.consumers)do local scope=rawget(c.target,T.key);if scope then scope.Close()end end
        r.stopPhysical();return finish()
    end
    return r
end
return T
