local E=dofile('tests/kernel_native_execution_harness.lua');local H=E.H;local T={E=E,H=H,path='../pr_bridge/bridge/delivery/forge_native_ports.lua'}
function T.new(side,schema)
    local r=E.new(side);r.schema=schema or H.load('kernel/entry/server_engine_schema.lua',H.environment())();r.effects={}
    for _,target in pairs(r.schema)do if target:sub(1,1)~='$'and r.native[target]==nil then
        r.native[target]=function(...)r.effects[#r.effects+1]={target,table.pack(...)};return target,nil,false,7 end
    end end
    r.allocate();r.port146={execution=r.api,side=r.side,isCurrent=function()return r.current end,
        time=function()return 101 end,date=function(...)return ...end,locale=function(...)return ...end,
        newPromise=function()return{promise=true}end,awaitPromise=function(p)return p.value,nil,false end}
    r.factory146=H.load(T.path,H.environment());function r.mount146()r.engine=r.factory146(r.port146);return r.engine end
    function r.finish146()if r.engine then r.engine.Close()end;r.api.Close()end
    return r
end
return T
