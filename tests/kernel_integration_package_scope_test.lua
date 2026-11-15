local H=dofile('tests/kernel_harness.lua');local root='../../../../.planning/migration/staging/115/'
local function source(name)local f=assert(io.open(root..name,'rb'));local s=f:read('*a');f:close();return s end
local function entry(path,env)return assert(load(source(path),'@@package115/'..path,'t',H.environment(env)))()end
local count=0
for _,side in ipairs({'client','server'})do
    assert(not pcall(entry,'pr_bridge/bridge/frameworks/forge/'..side..'.lua',{PRCore={context=side},ActiveBridges={frameworks='forge'}}));count=count+1
    assert(not pcall(entry,'pr_bridge/bridge/frameworks/forge/'..side..'.lua',{PRCore={context=side,forgeLateBinding={Attach=function()end,Framework={}}},ActiveBridges={frameworks='forge'}}));count=count+1
    assert(not pcall(entry,'pr_bridge/bridge/frameworks/forge/'..side..'.lua',{PRCore={context=side},ActiveBridges={frameworks='qbx'}}));count=count+1
end
local target={foreign=true};assert(not pcall(entry,'ox_inventory/modules/bridge/forge/server.lua',{pr_lib={forgeLateBinding={Attach=function()end,Inventory={UseItem=function()end}}},server=target}))
assert(target.foreign and target.UseItem==nil,'preflight all inventory methods before publication');count=count+1
assert(count==7)
print('PASS lot115 seven physical entry refusals:missing late binding/normalization,wrong profile,incomplete OX facade leaves namespace intact;no implicit Attach/core fallback')
