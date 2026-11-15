local T=dofile('tests/kernel_native_foundation_harness.lua');local req,env=T.loader()
local E=dofile('tests/kernel_engine_ports_harness.lua');local factory=req('kernel.entry.native_engine_inputs')
for _,side in ipairs({'server','client'})do
 local schema=req('kernel.entry.'..side..'_engine_schema')();local r=E.new(side,schema)
 local a=factory({side=side,execution=r.api,isCurrent=function()return r.current end,adjuncts=r.port146,
 loadPR=function(path)assert(path=='@pr_bridge/bridge/delivery/forge_native_ports');return r.factory146 end})
 local aliases={};for name in pairs(schema)do aliases[#aliases+1]=name end
 local view=a.Select(aliases);assert(#a.Describe()==#aliases)
 for name in pairs(schema)do assert(type(view[name])=='function')end
 assert(not pcall(a.Select,{'madeUpNative'}));assert(not pcall(a.Select,{'RegisterCommand'}))
 local dynamic=a.Select({'source'});assert(dynamic.source()==1);r.source=71;assert(dynamic.source()==71)
 if side=='server'then assert(a.Select({'date'}).date('%Y')=='%Y')end
 local fn=a.Select({'GetEntityCoords'}).GetEntityCoords;local result=table.pack(fn(12));assert(result.n==4 and result[2]==nil and result[3]==false)
 r.native.GetEntityCoords=nil;assert(not a.IsCurrent());a.Close();assert(not pcall(fn,12));r.api.Close()
end
local r=E.new('server');r.native.GetEntityCoords=nil
local a=factory({side='server',execution=r.api,isCurrent=function()return r.current end,adjuncts=r.port146,loadPR=function()return r.factory146 end})
assert(not pcall(a.Select,{'GetEntityCoords'}));a.Close();r.api.Close()
print('PASS177 native inputs resolved from both installed schemas;dynamic source,exact returns,missing/unknown/registration functions refused')
