local H=dofile('tests/kernel_harness.lua');local make=H.load('../pr_bridge/bridge/delivery/forge_graph_utilities.lua',H.environment())
local function environment()
 local e=H.environment();local prior=getmetatable(e).__index
 getmetatable(e).__index=function(t,k)if k=='os'then return nil end;return prior(t,k)end
 e.string.strsplit=function(_,v)return v end;return e
end
local function input(side,e)
 return{foundation={Side=side,IsCurrent=function()return true end,Seed={Library={Library={print={warn=function()end}}}}},
  environment=e,checkDependency=function()return true end,
  loadPR=function(path,env)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',env)end}
end
local e=environment();assert(e.os==nil)
local client=make(input('client',e));assert(next(client.Clock)==nil,'do not manufacture client wall-clock functions')
assert(client.Library.math.round(2.51)==3 and client.Library.table.clone({x=1}).x==1)
assert(client.Close()and not pcall(client.Library.math.round,2.5))
local ok,why=pcall(make,input('server',e));assert(not ok and tostring(why):find('server os library required',1,true))
for _,missing in ipairs({'time','date','microtime'})do
 local s=environment();s.os={time=os.time,date=os.date,microtime=function()return 3 end};s.os[missing]=nil
 assert(not pcall(make,input('server',s)),'server clock remains required: '..missing)
end
print('PASS client utilities without os and without fake calendar; math/table preserved; server requires time/date/microtime; Close revokes library')
