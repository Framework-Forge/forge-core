local R=dofile('tests/kernel_qbx_relay_harness.lua');local H=R.H;local T={R=R,H=H,root='../../../../.planning/migration/staging/qbx_core/'}
function T.read(path)local file=assert(io.open(T.root..path,'rb'));local source=file:read('*a');file:close();return source end
function T.new(side)
    local r=R.new(side);r.physicalEvents={};r.readPhysical={};r.forgeState='started';r.physicalName='qbx_core'
    local proxy={ForgeQbxCompatDescribe=function()if r.handshakeHook then r.handshakeHook()end;return r.gateway.Describe()end,
        ForgeQbxCompatCall=function(_,...)return r.gateway.Call(...)end}
    local exported=setmetatable({['forge-core']=proxy},{__call=function(_,name,fn)r.published[name]=fn;if r.physicalPublishHook then r.physicalPublishHook(name,fn)end end})
    r.physicalEnv=H.environment({load=load,exports=exported,
        GetCurrentResourceName=function()return r.physicalName end,IsDuplicityVersion=function()return side=='server'end,
        GetResourceState=function(name)assert(name=='forge-core');return r.forgeState end,
        GetInvokingResource=function()return r.caller end,
        LoadResourceFile=function(resource,path)assert(resource=='qbx_core');r.readPhysical[#r.readPhysical+1]=path
            if r.physicalReadHook then r.physicalReadHook(path)end;return T.read(path)
        end,
        AddEventHandler=function(name,fn)local t={name=name,fn=fn};r.physicalEvents[#r.physicalEvents+1]=t
            if r.physicalListenHook then r.physicalListenHook(t)end;return t
        end,
        RemoveEventHandler=function(token)if r.refusePhysicalRemove then return false end;token.removed=true end})
    r.physicalEnv._ENV=r.physicalEnv
    function r.loadPhysical()return assert(load(T.read('compat/main.lua'),'@@qbx_core/compat/main.lua','t',r.physicalEnv))()end
    function r.stopPhysical()for _,t in ipairs(r.physicalEvents)do if not t.removed and t.name=='onResourceStop'then t.fn('qbx_core')end end end
    return r
end
return T
