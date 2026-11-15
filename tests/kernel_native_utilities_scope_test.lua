local T=dofile('tests/kernel_native_utilities_harness.lua');local r=T.new();r.allocate();local held=r.api138.Library.getClosestPlayer
r.current=false;assert(not pcall(held));r.current=true;r.api138.Close();assert(not pcall(held))
for _,path in ipairs(r.loads)do assert(not path:find('/framework',1,true)and not path:find('/init',1,true))end
local q=T.new();q.allocate();q.waitHook=function()q.api138.Close()end
local result=q.api138.Library.waitFor(function()if q.api138.Progress().closed then return 7 end end,nil,false)
assert(result==7 and q.api138.Progress().complete)
print('PASS lot138 four stale/closed/module-selection/accepted-wait checks;accepted result preserved without implicit cancellation')
