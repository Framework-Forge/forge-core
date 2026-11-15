local R=dofile('tests/kernel_owned_rpc_harness.lua');local O=dofile('tests/kernel_inventory_operations_harness.lua')
local B=dofile('tests/kernel_banking_harness.lua');local V=dofile('tests/kernel_vehicle_integration_harness.lua');local H=R.H
local T={R=R,O=O,B=B,V=V,H=H,path='kernel/pr_integration/core_services_factory.lua'}
function T.new(side)
    local r={wire=R.new(),inventory=O.new(),bank=B.new(),keys=V.new(),side=side or'server',state={},current=true,dbCalls={}}
    r.external={pr_bridge=r.wire.ports[r.side].environment.exports.pr_bridge,ox_inventory=r.inventory.proxy,['Renewed-Banking']=r.bank.proxy,pr_carkeys=r.keys.raw,
        oxmysql=setmetatable({},{__index=function(_,key)return function(_,...)r.dbCalls[#r.dbCalls+1]={key,...};return true end end})}
    local env=H.environment({Debug=function()end,Lang={t=function(_,key)return key end},json={decode=function(x)return x end},
        GetResourceState=function(name)return r.state[name]or'started'end})
    local rpc=r.wire.scopes[r.side];local native=r.wire.ports[r.side].native
    native.GetResourceState=function(name)return r.state[name]or'started'end
    native.LoadResourceFile=function(resource,file)return r.inventory.files[file]end
    r.ports={native=native,prCore=r.wire.prs[r.side],environment=env,external=r.external,rpc=rpc,isCurrent=function()return r.current end,
        load=function(path,target)
            if r.loadHook then r.loadHook(path)end
            local resource,name=path:match('^@([^/]+)/(.+)$')
            assert(resource=='pr_bridge'or resource=='forge-core','unexpected test resource: '..tostring(resource))
            name=name:gsub('%.lua$','')..'.lua'
            return H.load((resource=='forge-core'and''or'../pr_bridge/')..name,target or env)
        end}
    env.PRCore=r.ports.prCore;env.exports=r.external;env.PRCore.load=r.ports.load
    for name,value in pairs(native)do if rawget(env,name)==nil then env[name]=value end end
    r.factory=H.load(T.path,H.environment());function r.allocate()r.api=r.factory(r.ports);return r.api end
    function r.open()r.wire.open();r.allocate();assert(r.api.Prepare());assert(r.api.Open())end
    function r.close()if r.api then r.api.Close()end;r.wire.close()end
    return r
end
return T
