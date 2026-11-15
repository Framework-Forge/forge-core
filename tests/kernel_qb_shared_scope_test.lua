local T=dofile('tests/kernel_qb_shared_harness.lua');local H=T.H;local n=0
local ops={function(i)return i.any end,function(i)i.any={}end,function(i)return pairs(i)end,function(i)return #i end}
for _,op in ipairs(ops)do
    local a,b=T.shared(false,{}),T.shared(true,{})
    local ok,x=pcall(op,a.shared.Items);local ok2,y=pcall(op,b.shared.Items)
    assert(not ok and not ok2);local needle='QBCore.Shared.Items foi removido.'
    assert(x:find(needle,1,true)and y:find(needle,1,true));assert(getmetatable(b.shared.Items)==false);n=n+1
end
local factory=H.load('../pr_bridge/bridge/frameworks/forge/qb_item_conversion_factory.lua',H.environment())
for _,ports in ipairs({{}, {inventory={}}, {inventory={readItemsFile=function()end,writeItemsFile=function()end},scheduler={}}})do assert(not pcall(factory,ports));n=n+1 end
local r=T.shared(true,{});r.shared.StarterItems.new={item='new'};assert(r.canonical.StarterItems==nil)
print('PASS lot87 scopes:'..n..' rejection checks;Items read/write/iterate/length blocked,explicit ports mandatory,no construction IO')
