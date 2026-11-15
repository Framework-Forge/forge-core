local S=dofile('tests/kernel_forge_server_adapter_harness.lua');local C=dofile('tests/kernel_forge_adapter_harness.lua')
local H,P=S.H,S.P;local T={S=S,C=C,H=H,P=P,path='../pr_bridge/bridge/frameworks/forge/normalization_factory.lua'}
function T.new(ported,side,mode)
    local r={current=true,trace={},deferred={}};r.source=side=='server'and S.new(ported,mode)or C.new(ported)
    local f=r.source.framework
    local function record(name,...)r.trace[#r.trace+1]={name=name,args=P.snapshot(table.pack(...))}end
    local native={GetPlayers=function()return{'1','2'}end,joaat=function(model)record('hash',model);return 7 end,
        DoesEntityExist=function(entity)return entity==10 end,IsEntityDead=function()return false end,PlayerPedId=function()return 10 end}
    for k,v in pairs(r.source.ports.native or{})do native[k]=v end
    local vehicles={[7]={model='car',name='Car'}}
    r.core={GetVehiclesByHash=function(hash)record('vehicles',hash);if r.hook then r.hook('vehicles')end;return vehicles[hash]or vehicles end,
        EnablePersistence=function(entity)record('enable',entity);return nil end,DisablePersistence=function(entity)record('disable',entity);return false end,
        GetJobs=function()record('jobs');if r.hook then r.hook('jobs')end;return{police={label='Police'}}end,
        GetGangs=function()record('gangs');return{none={label='None'}}end}
    local inventory={GetResourceName=function()return'ox_inventory'end}
    for _,name in ipairs({'AddItem','RemoveItem','GetItemCount','HasItem','GetInventoryItems','GetItemLabel'})do
        inventory[name]=function(...)record('inventory.'..name,...);return false,nil,84 end
    end
    local banking={GetResourceName=function()return mode=='framework-bank'and'framework'or'Renewed-Banking'end,
        GetJobAccountBalance=function(...)record('bank',...);return 84 end}
    local notify={Notify=function(...)record('notify',...);return 84 end}
    local textui={Show=function(...)record('show',...);return false end,Hide=function(...)record('hide',...);return nil,84 end}
    r.ports={side=side,framework=f,resourceName='qbx_core',isCurrent=function()return r.current end,
        core=r.core,native=native,inventory=inventory,banking=banking,notify=notify,textui=textui}
    if ported then r.api=H.load(T.path,H.environment())(r.ports);r.framework=r.api.Framework
    else
        local proxy={};for name,fn in pairs(r.core)do proxy[name]=function(receiver,...)assert(receiver==proxy);return fn(...)end end
        local env=H.environment({exports={qbx_core=proxy},PRCore={load=function(path)
            assert(path=='@pr_bridge/bridge/frameworks/compat_install'or path=='@pr_bridge/bridge/frameworks/qbx/compat'or path=='@pr_bridge/bridge/frameworks/qb_adapter_install')
            return function()r.deferred[#r.deferred+1]=path;return{}end
        end}})
        env._ENV=env;for name,fn in pairs(native)do env[name]=fn end
        r.framework=H.load('../pr_bridge/bridge/framework_normalizer.lua',env)(f,side,inventory,banking,notify,textui,'qbx')
    end
    return r
end
return T
