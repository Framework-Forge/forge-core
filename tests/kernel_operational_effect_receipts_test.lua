local function read(path)local f=assert(io.open('../../../../.planning/migration/staging/278/'..path,'rb'));local s=f:read('*a');f:close();return s end
local H=dofile('tests/kernel_native_bindings_harness.lua').H
local hooks={};local exp={};local caller='forge-core'
local env=setmetatable({pr_lib={cache={resource='ox_inventory'}},os={microtime=function()return 0 end},
 exports=function(name,fn)exp[name]=fn end,AddEventHandler=function()end,
 GetInvokingResource=function()return caller end,GetConvar=function()return'receipts278'end},{__index=_G})
assert(load(read('ox_inventory/modules/hooks/server.lua'),'@@ox_inventory/modules/hooks/server.lua','t',env))()
local a=exp.registerHook('useItem',{},{});local b=exp.registerHook('useItem',{},{});assert(a~=b)
local s=exp.ForgeOwnedHookSnapshot();assert(s.count==2 and s.duplicates==0)
exp.removeHooks(a);local c=exp.registerHook('useItem',{},{});assert(c==b)
s=exp.ForgeOwnedHookSnapshot();assert(s.count==2 and s.duplicates==1)
caller='foreign';assert(not pcall(exp.ForgeOwnedHookSnapshot))
for _,pass in ipairs({true,false})do
 local exports,thread={};local transactions=0
 local bank=read('Renewed-Banking/server/main.lua'):match('^(.-)function UpdatePlayerAccount')
 local e=setmetatable({exports=function(n,fn)exports[n]=fn end,GetInvokingResource=function()return'forge-core'end,
 GetConvar=function()return'receipts278'end,CreateThread=function(fn)thread=fn end,Wait=function()end,
 GetCurrentResourceName=function()return'Renewed-Banking'end,LoadResourceFile=function()return'compiled ui'end,locale=function(s)return s end,
 GetFrameworkGroups=function()return{police={}},{ }end,GetSocietyLabel=function()return'Police'end,json={encode=function()return'{}'end},
 pr_lib={cache={set=function()end},database={query=function()return{}end,transaction=function()transactions=transactions+1;return pass end}}},{__index=_G})
 assert(load(bank,'@@Renewed-Banking/server/main.lua','t',e))();assert(exports.ForgeBankingReadiness().phase=='loading')
 thread();local d=exports.ForgeBankingReadiness();assert(d.query and d.transaction==pass and transactions==1)
 assert(d.phase==(pass and'ready'or'failed')and d.accounts==nil and d.balances==nil)
end
print('PASS278 actual hook ID reuse detected without changing hooks;actual bank startup receipt refuses failed SQL transaction;no balance/player fields exposed;SQL virtual')
