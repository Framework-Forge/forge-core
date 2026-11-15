local T=dofile('tests/kernel_forge_preflight_harness.lua');local H=T.H;local M={H=H,T=T,path='../pr_bridge/bridge/delivery/forge_native_io.lua'}
function M.new(side)
    local r={side=side or'server',name='forge-core',current=true,files={},writes={},reads={},saveResult=1}
    local function read(resource,path)
        r.reads[#r.reads+1]={resource,path};if r.readHook then r.readHook(resource,path)end
        if r.files[resource..'/'..path]~=nil then return r.files[resource..'/'..path]end
        if resource=='pr_bridge'then local f=io.open('../pr_bridge/'..path,'rb');if f then local s=f:read('*a');f:close();return s end end
        if resource=='forge-core'and(path=='data/character_previews.json'or path=='kernel/locales/pt-br.json')then
            local f=io.open(path,'rb');if f then local s=f:read('*a');f:close();return s end
        end
    end
    local function save(resource,path,content,length)
        assert(#content==length);r.writes[#r.writes+1]={resource,path,content,length}
        if r.saveHook then r.saveHook(resource,path,content)end
        if r.saveResult==1 or r.saveResult==true then r.files[resource..'/'..path]=content end;return r.saveResult
    end
    r.codec={decode=function(raw)return test_decode_json(raw)end,encode=function(v)return('{"value":%d}'):format(v.value)end}
    local env=H.environment({PRCore=false,GetCurrentResourceName=function()return r.name end,IsDuplicityVersion=function()return r.side=='server'end,
        LoadResourceFile=read,SaveResourceFile=save,json=r.codec,load=load,print=function()end,coroutine=coroutine,debug=debug})
    env._ENV=env;H.load('../pr_bridge/bridge/core.lua',env);r.core=env.PRCore
    r.native={GetCurrentResourceName=env.GetCurrentResourceName,IsDuplicityVersion=env.IsDuplicityVersion,LoadResourceFile=read,SaveResourceFile=save}
    r.ports={native=r.native,core=r.core,json=r.codec,isCurrent=function()return r.current end}
    r.factory=H.load(M.path,H.environment());function r.allocate()r.api=r.factory(r.ports);return r.api end
    return r
end
return M
