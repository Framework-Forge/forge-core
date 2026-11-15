local H=dofile('tests/kernel_harness.lua');local f=H.load('../pr_bridge/bridge/delivery/forge_graph_utilities.lua',H.environment())
local current=true;local env=H.environment({os={time=os.time,date=os.date,microtime=function()return 1234 end}})
env.string.strsplit=function(sep,text)local out={};for value in text:gmatch('[^'..sep..']+')do out[#out+1]=value end;return table.unpack(out)end
local loads={};local foundation={Side='server',IsCurrent=function()return current end,Seed={Library={Library={print={warn=function()end,error=function()end}}}}}
local a=f({foundation=foundation,environment=env,checkDependency=function()return true end,loadPR=function(path,target)
 loads[#loads+1]=path;return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target)
end})
assert(#loads==4 and a.Library.framework==nil and a.Library.callback==nil)
assert(a.Library.math.round(1.234,2)==1.23 and a.Groupdigits(1234567)=='1,234,567')
local s=table.pack(a.Strsplit(':','one:two'));assert(s.n==2 and s[2]=='two')
local t={x=3};assert(a.Library.table.clone(t).x==3 and a.Library.table.type({1,2})=='array')
assert(a.Clock.microtime()==1234);a.Close();assert(not pcall(a.Library.math.round,2,0)and not pcall(a.Clock.time))
print('PASS197 installed PR math/table/string/waitFor plus Cfx clock/strsplit;no framework/RPC bootstrap;algorithms and scope retained')
