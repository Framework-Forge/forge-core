local C=dofile('tests/kernel_server_delivery_harness.lua');local R=dofile('tests/kernel_owned_rpc_harness.lua');local H=R.H
local T={C=C,R=R,H=H,path='../pr_bridge/bridge/delivery/forge_native_library.lua'}
function T.new(side)
    local r={host=C.provider(),wire=R.new(),side=side or'server',current=true,public={},loads={}};r.wire.open()
    -- FiveM supplies table.clone; keep this native fixture local to the module environment.
    local nativeTable={};for k,v in pairs(table)do nativeTable[k]=v end
    nativeTable.clone=function(value)local out={};for k,v in pairs(value)do out[k]=v end;return out end
    local env=H.environment({table=nativeTable,GetCurrentResourceName=function()return'forge-core'end,IsDuplicityVersion=function()return r.side=='server'end,
        GetGameTimer=function()return r.host.now end,GetConvar=function(_,v)return v end,os=os,debug=debug,require=function()error('no external require')end,
        exports={pr_bridge={accessCacheState=function(_,...)return r.host.access(...)end}}})
    r.nativeCache={resource='forge-core',game=r.side=='server'and'fxserver'or'gta5',ped=42}
    r.ports={native={GetCurrentResourceName=env.GetCurrentResourceName,IsDuplicityVersion=env.IsDuplicityVersion},prCore=r.wire.prs[r.side],public=r.public,
        environment=env,rpc=r.wire.scopes[r.side],nativeCache=r.nativeCache,isCurrent=function()return r.current end,
        load=function(path,target)r.loads[#r.loads+1]=path;if r.loadHook then r.loadHook(path)end;return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end}
    r.factory=H.load(T.path,H.environment());function r.allocate()r.api=r.factory(r.ports);return r.api end
    function r.finish()if r.api then r.api.Close()end;r.wire.close()end
    return r
end
return T
