local T=dofile('tests/kernel_native_seed_harness.lua');local H=T.H
local root='../../../../.planning/migration/staging/'
local function read(path)local f=assert(io.open(root..path,'rb'));local text=f:read('*a');f:close();return text end
for _,side in ipairs({'server','client'})do
    local r=T.C.S.new(side);assert(r.wire.scopes[side].Close());local i=T.io(side);local clock=dofile('tests/kernel_worker_harness.lua').clock()
    local n={};for k,v in pairs(r.ports.native)do n[k]=v end;for k,v in pairs(i.native)do n[k]=v end
    n.Wait,n.CreateThread=clock.native.Wait,clock.native.CreateThread;n.GetConvar=function(_,fallback)return fallback end
    local file=n.LoadResourceFile;n.LoadResourceFile=function(resource,path)return file(resource,path)or r.inventory.files[path]end
    local host=T.L.C.provider();r.external.pr_bridge={accessCacheState=function(_,...)return host.access(...)end}
    local env=H.environment(n);env.PRCore=i.core;env.exports=r.external;env.json=i.codec;env.load=load;env.coroutine=coroutine;env.os=os;env.debug=debug;env.print=function()end
    env.Debug=function()end;env.Lang={t=function(_,key)return key end};env._ENV=env
    env.require=function()error('physical seed must not import an external framework')end
    local nativeTable={};for k,v in pairs(table)do nativeTable[k]=v end;nativeTable.clone=function(value)local out={};for k,v in pairs(value)do out[k]=v end;return out end;env.table=nativeTable
    local base=r.wire[side].env;local mt=getmetatable(env);local before=mt.__index;mt.__index=function(t,key)if key=='source'then return base.source end;return before(t,key)end
    local raw=assert(load(read('125/pr_bridge/bridge/forge_raw_core.lua'),'@@raw125','t',env))()({isCurrent=function()return r.current end,
        namespaceAvailable=r.wire.ports[side].available,beforeClose=function()return true end})
    assert(raw.Prepare());local beforeListeners=r.wire[side].active()
    local entry=assert(load(read('130/pr_bridge/bridge/forge_native_seed.lua'),'@@native_seed130','t',env))()
    local public={};local options={isCurrent=function()return r.current end,public=public,nativeCache={resource='forge-core',game=side=='server'and'fxserver'or'gta5'},
        events={},inventoryBridgeProbe=function()return{}end}
    local seed=entry(raw,options);local prepared,reason=seed.Prepare();assert(prepared,reason);assert(r.wire[side].active()==beforeListeners)
    assert(seed.Registry.Require('kernel.entry.native_seed')and public.library.callback==raw.RPC.Native)
    assert(seed.IO.Codec.decode(seed.IO.Files.LoadResourceFile('forge-core','kernel/locales/pt-br.json')))
    assert(seed.Close()and raw.RPC.Owners.native.IsReady());assert(raw.Close()and r.wire[side].active()==0 and #i.writes==0);r.close()
end
local package=test_decode_json(read('130/package.json'));local count=0
for _,f in ipairs(package.files)do if f.path:match('%.lua$')then assert(load(read('130/'..f.path),'@@package130/'..f.path,'t',{}));count=count+1 end end
assert(count==42 and not package.operationalReady)
print('PASS lot130 physical seed entry both sides after actual raw125/PRCore,owned122/123 identity/no extra listeners,installed IO/locale,42 Lua compiled;no operational changes')
